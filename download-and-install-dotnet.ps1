# The install script should be downloaded by the CustomScriptExtension on the VM ScaleSet
.\dotnet-install.ps1 -Runtime dotnet -Channel 9.0 -Quality GA -InstallDir "C:\Program Files\dotnet"

[System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\dotnet", [System.EnvironmentVariableTarget]::Machine)
