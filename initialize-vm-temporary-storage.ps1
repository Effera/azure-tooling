# Reassign D: to E: if it exists
$dvdDrive = Get-WmiObject Win32_Volume | Where-Object { $_.DriveType -eq 5 }
if ($dvdDrive) {
    $dvdDrive.DriveLetter = $null
    $dvdDrive.Put()

    Start-Sleep -Seconds 5

    $dvdDrive.DriveLetter = 'E:'
    $dvdDrive.Put()
    Start-Sleep -Seconds 5
}
# Get the boot/system volume drive letter
$bootDrive = (Get-Volume | Where-Object { $_.BootVolume -or $_.SystemVolume }).DriveLetter

# Get all disks
$allDisks = Get-Disk | Where-Object { $_.OperationalStatus -eq 'Online' }

# Filter disks that have no partitions with drive letters and are not the boot/system disk
$eligibleDisks = foreach ($disk in $allDisks) {
    $partitions = Get-Partition -DiskNumber $disk.Number
    $hasDriveLetter = $partitions | Where-Object { $_.DriveLetter }
    $isBootDisk = $partitions | Where-Object { $_.DriveLetter -eq $bootDrive }

    if ($hasDriveLetter.Count -eq 0 -and $isBootDisk.Count -eq 0) {
        $disk
    }
}

foreach ($disk in $eligibleDisks) {
    try {
        # Create a new partition using maximum size
        $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter

        # Format the partition with NTFS
        Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "Temporary Storage" -Confirm:$false
        Write-Host "Partition created and formatted on Disk $($disk.Number)"
    } catch {
        Write-Warning "Failed to process Disk $($disk.Number): $_"
    }
}
