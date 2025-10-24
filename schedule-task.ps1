param (
    [Parameter(Mandatory)]
    [string]$TaskName,

    [Parameter(Mandatory)]
    [string]$ScriptPath,

    [string]$ScriptArguments = ""
)

# Validate script path
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script path '$ScriptPath' does not exist."
    exit 1
}

# Resolve full path
$ResolvedScriptPath = (Resolve-Path $ScriptPath).Path

# Compose full argument string for powershell.exe
$FullArguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ResolvedScriptPath`""
if ($ScriptArguments) {
    $FullArguments += " $ScriptArguments"
}

# Define task action
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $FullArguments

# Define task trigger (at startup)
$Trigger = New-ScheduledTaskTrigger -AtStartup

# Define task principal (run with highest privileges)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register or overwrite the task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force
    Write-Host "Scheduled task '$TaskName' registered (or updated) to run '$ResolvedScriptPath' at startup."
} catch {
    Write-Error "Failed to register scheduled task: $_"
}
