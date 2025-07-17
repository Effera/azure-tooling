# Reassign DVD to Z: if needed
$dvdDrive = Get-WmiObject Win32_Volume | Where-Object { $_.DriveType -eq 5 }
if ($dvdDrive) {
    $dvdDrive.DriveLetter = $null
    $dvdDrive.Put()
    Start-Sleep -Seconds 5
    $dvdDrive.DriveLetter = 'Z:'
    $dvdDrive.Put()
    Start-Sleep -Seconds 5
}

# Identify all RAW, online disks
$rawDisks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -and $_.OperationalStatus -eq 'Online' }

foreach ($disk in $rawDisks) {
    $label = "Storage Disk"  # Default

    # Heuristics to identify ephemeral/tempo disk
    if (
        $disk.Model -match "Direct Disk"
    ) {
        $label = "Temporary Storage"
    }

    Write-Host "Initializing Disk #$($disk.Number) as '$label'..."

    Initialize-Disk -Number $disk.Number -PartitionStyle GPT -Confirm:$false
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter
    Start-Sleep -Seconds 5
    Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel $label -Confirm:$false
}