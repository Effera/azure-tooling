param (
    [string]$Username,
    [bool]$EnableDocker = $false
)

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