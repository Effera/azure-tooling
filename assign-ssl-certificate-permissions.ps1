param (
    [string]$CertificateCommonName
)

Get-ChildItem Cert:\LocalMachine\My | Where-Object {
    $_.PrivateKey -and
    $_.Subject -like "*CN=$CertificateCommonName*"
} | ForEach-Object {
    $keyPath = "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys\$($_.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName)"
    if (Test-Path $keyPath) {
        $acl = Get-Acl $keyPath
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "NETWORK SERVICE", "Read", "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl $keyPath $acl
        Write-Host "Granted read access to NETWORK SERVICE for key container: $($_.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName)"
    } else {
        Write-Warning "Key path not found for certificate: $($_.Subject)"
    }
}

