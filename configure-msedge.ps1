$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
New-Item -Path $edgePolicyPath -Force | Out-Null

Set-ItemProperty -Path $edgePolicyPath -Name "HideFirstRunExperience" -Type DWord -Value 1
Set-ItemProperty -Path $edgePolicyPath -Name "AutoImportAtFirstRun" -Type DWord -Value 0
Set-ItemProperty -Path $edgePolicyPath -Name "SignInAllowed" -Type DWord -Value 0
Set-ItemProperty -Path $edgePolicyPath -Name "ShowHomeButton" -Type DWord -Value 1
Set-ItemProperty -Path $edgePolicyPath -Name "ShowMicrosoftRewards" -Type DWord -Value 0
Set-ItemProperty -Path $edgePolicyPath -Name "ShowRecommendationsEnabled" -Type DWord -Value 0
