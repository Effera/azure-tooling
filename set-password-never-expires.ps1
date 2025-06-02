param (
    [string]$Username
)

Set-LocalUser -Name $Username -PasswordNeverExpires $true
