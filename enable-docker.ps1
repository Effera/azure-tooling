$dockerScriptUrl = "https://aka.ms/install-docker"
$dockerScriptPath = "$env:ProgramData\install-docker.ps1"
$bootstrapScriptPath = "$env:ProgramData\docker-bootstrap.ps1"
$taskName = "InstallDockerAfterReboot"

# Ensure the install script is downloaded once
if (!(Test-Path $dockerScriptPath)) {
    Invoke-WebRequest $dockerScriptUrl -UseBasicParsing -OutFile $dockerScriptPath
}

# Build the bootstrap script (invoked both directly and post-reboot)
$bootstrapScript = @"
powershell -ExecutionPolicy Bypass -Command {
    & '$dockerScriptPath'
    Start-Service docker
    Set-Service docker -StartupType Automatic
    schtasks /Delete /TN '$taskName' /F
    Remove-Item -Path '$bootstrapScriptPath','dockerScriptPath' -Force -ErrorAction SilentlyContinue
}
"@
$bootstrapScript | Out-File -FilePath $bootstrapScriptPath -Encoding UTF8

$feature = Get-WindowsFeature -Name Containers
if (-not $feature.Installed) {
    Write-Host "🔧 Enabling Containers feature and scheduling Docker install after reboot..."
    Install-WindowsFeature -Name Containers

    # Register one-time startup task that reuses our shared bootstrap script
    schtasks /Create /TN $taskName /TR "powershell -ExecutionPolicy Bypass -File $bootstrapScriptPath" /SC ONSTART /RL HIGHEST /F
    Restart-Computer -Force
    exit
}

Write-Host "✅ Containers already enabled. Proceeding with Docker install immediately..."
powershell -ExecutionPolicy Bypass -File $bootstrapScriptPath
