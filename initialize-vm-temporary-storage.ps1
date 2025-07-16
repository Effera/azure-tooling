# This script initializes the temporary storage disk in a Windows VM.
# It reassigns the DVD drive letter to Z: if a an uninitialized disk exists,
# and initializes the temporary disk, formats and assigns it to drive letter D and continues to assign subsequent disks to E, F, etc.

# Find uninitialized disk (likely temporary disk)
$disk = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' -and $_.OperationalStatus -eq 'Online' }

if ($disk) {
    # Reassign dvd drive D: to Z: if it exists
    $dvdDrive = Get-WmiObject Win32_Volume | Where-Object { $_.DriveType -eq 5 }
    if ($dvdDrive) {
        $dvdDrive.DriveLetter = $null
        $dvdDrive.Put()

        Start-Sleep -Seconds 5

        $dvdDrive.DriveLetter = 'Z:'
        $dvdDrive.Put()
        Start-Sleep -Seconds 5
    }

    # Initialize with GPT
    Initialize-Disk -Number $disk.Number -PartitionStyle GPT -Confirm:$false

    # Create a new partition using all space
    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize -AssignDriveLetter

    # Format it as NTFS and label it
    Format-Volume -Partition $partition -FileSystem NTFS -NewFileSystemLabel "Temporary Storage" -Confirm:$false
}
