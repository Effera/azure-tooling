param (
    [string]$Username,
    [string]$CertificateCommonName = $null
)

.\apply-telemetry-settings.ps1
.\configure-msedge.ps1
.\initialize-vm-temporary-storage.ps1
.\disable-server-manager-autostart.ps1
.\remove-arc-setup-prompt.ps1
.\download-and-install-dotnet.ps1
.\set-password-never-expires.ps1 -Username $Username

if ($CertificateCommonName) {
    .\assign-ssl-certificate-permissions.ps1 -CertificateCommonName $CertificateCommonName
}
