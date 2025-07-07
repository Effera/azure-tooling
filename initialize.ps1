param (
    [string]$Username,
    [bool]$EnableDocker = $false
)

# Auto-schedule self on reboot
# This script will run on every boot to ensure the VM is initialized correctly if they are re-imaged, re-deployed or deallocated
$taskName = "InitializeVMOnReboot"

# Get the absolute path of the current script
$scriptPath = $MyInvocation.MyCommand.Path

# Reconstruct the original arguments
$rawArgs = $PSBoundParameters.GetEnumerator() | ForEach-Object {
    if ($_.Value -is [bool]) {
        if ($_.Value) { "-$($_.Key)" }  # Only add flag if true
    } else {
        "-$($_.Key) `"$($_.Value)`""
    }
} | Out-String
$argString = $rawArgs -replace "`r?`n", ' '  # Flatten line breaks

Write-Host "🛠️  (Re)creating scheduled task '$taskName' to run on every boot..."

# Remove the existing task (if any)
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Create the new task with current path and parameters
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" $argString"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal

.\apply-telemetry-settings.ps1
.\configure-msedge.ps1
.\initialize-vm-temporary-storage.ps1
.\disable-server-manager-autostart.ps1
.\remove-arc-setup-prompt.ps1
.\download-and-install-dotnet.ps1
.\set-password-never-expires.ps1 -Username $Username

if ($EnableDocker) {
    .\enable-docker.ps1
}