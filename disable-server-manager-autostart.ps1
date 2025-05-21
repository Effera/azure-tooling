# Set the registry key to disable Server Manager auto start
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\ServerManager' -Name 'DoNotOpenServerManagerAtLogon' -Value 1