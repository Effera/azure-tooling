<#
.SYNOPSIS
    Installs Docker on a Windows Server VMSS instance, handling required Windows features and reboot.

.DESCRIPTION
    - Ensures required features (Hyper-V, Containers) are installed.
    - If needed, safely reboots the node via Azure REST API using Managed Identity.
    - After reboot, installs Docker from the official ZIP and registers it as a Windows service.
    - Written for Windows Server 2025 Datacenter G2 running in a VMSS (Uniform orchestration).

.REQUIREMENTS
    - System-assigned Managed Identity enabled on the VM
    - Identity has "Virtual Machine Contributor" role for restart permission
    - Docker is installed at C:\Program Files\Docker and starts as a service

.NOTES
    - Uses a marker file (C:\DockerFeatureInstallComplete.txt) to coordinate reboot-to-install flow
#>

$featureMarker   = "C:\DockerFeatureInstallComplete.txt"
$installDir      = "C:\Program Files\Docker"
$dockerZipUrl    = "https://download.docker.com/win/static/stable/x86_64/docker-24.0.7.zip"
$dockerZipPath   = "$env:TEMP\docker.zip"
$tempUnzipPath   = "$env:TEMP\docker-unzip"

function Install-RequiredWindowsFeatures {
    $features = @("Hyper-V", "Containers")
    $installed = Get-WindowsFeature | Where-Object { $_.Name -in $features -and $_.Installed }

    if ($installed.Count -lt $features.Count) {
        Write-Host "Installing missing features: $($features -join ', ')"
        Install-WindowsFeature -Name $features -IncludeManagementTools -Restart:$false
        New-Item -ItemType File -Path $featureMarker -Force | Out-Null
        return $true
    }

    return $false
}

function Install-Docker {
    $dockerExists = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerExists) {
        Write-Host "Docker is already installed. Skipping installation."
        return
    }

    # Ensure destination is a proper directory (not a file)
    if (Test-Path $installDir) {
        if (-not (Get-Item $installDir).PSIsContainer) {
            Write-Host "Removing unexpected file at $installDir and creating directory..."
            Remove-Item $installDir -Force
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        }
    } else {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    # Prepare unzip path
    if (-not (Test-Path $tempUnzipPath)) {
        New-Item -ItemType Directory -Path $tempUnzipPath -Force | Out-Null
    }

    # Download and extract Docker
    Write-Host "Downloading Docker from $dockerZipUrl"
    Invoke-WebRequest -Uri $dockerZipUrl -OutFile $dockerZipPath -UseBasicParsing

    Expand-Archive -Path $dockerZipPath -DestinationPath $tempUnzipPath -Force
    Copy-Item -Path "$tempUnzipPath\docker\*" -Destination $installDir -Recurse -Force
    Remove-Item $dockerZipPath, $tempUnzipPath -Recurse -Force -ErrorAction SilentlyContinue

    # Update PATH
    $env:Path += ";$installDir"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)

    # Register and start Docker service
    $dockerd = Join-Path $installDir "dockerd.exe"
    if (Test-Path $dockerd) {
        & $dockerd --register-service
        Start-Service docker
        Write-Host "Docker service registered and started."
    } else {
        Write-Host "Error: dockerd.exe not found at expected path: $dockerd"
    }

    if (Test-Path $featureMarker) {
        Remove-Item $featureMarker -Force
    }
}

function Restart-ThisVmssInstance {
    Write-Host "Initiating VMSS reboot via Azure REST API..."

    $imds = Invoke-RestMethod -Headers @{Metadata='true'} `
        -Method GET `
        -Uri 'http://169.254.169.254/metadata/instance?api-version=2021-02-01'

    $subscriptionId = $imds.compute.subscriptionId
    $resourceGroup  = $imds.compute.resourceGroupName
    $vmssName       = $imds.compute.vmScaleSetName
    $resourceId     = $imds.compute.resourceId
    $instanceId     = ($resourceId -split "/")[-1].Trim()

    if (-not ($instanceId -match '^\d+$')) {
        Write-Host "Error: Could not determine valid numeric instanceId."
        return
    }

    $token = (Invoke-RestMethod -Headers @{Metadata='true'} -Method GET `
        -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/").access_token

    $restartUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachineScaleSets/$vmssName/restart?api-version=2023-09-01"
    $body = @{ instanceIds = @($instanceId) } | ConvertTo-Json -Depth 2

    try {
        Invoke-RestMethod -Method POST -Uri $restartUri `
            -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
            -Body $body
        Write-Host "Restart request sent for instance ID $instanceId."
    } catch {
        Write-Host "Failed to restart VMSS instance: $($_.Exception.Message)"
    }
}

# ------------------ MAIN ------------------

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (Test-Path $featureMarker) {
    Write-Host "Detected marker file — proceeding with Docker installation after reboot."
    Install-Docker
    return
}

$needsReboot = Install-RequiredWindowsFeatures
if ($needsReboot) {
    Restart-ThisVmssInstance
} else {
    Install-Docker
}
