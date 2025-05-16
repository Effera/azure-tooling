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


# Find uninitialized disk (likely temporary disk)
$disk = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -and $_.OperationalStatus -eq 'Online' }

if ($disk) {
    # Initialize with GPT
    Initialize-Disk -Number $disk.Number -PartitionStyle GPT -Confirm:$false

    # Create a new partition using all space
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter -DriveLetter 'D'

    # Format it as NTFS and label it
    Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "Temporary Storage" -Confirm:$false
}
