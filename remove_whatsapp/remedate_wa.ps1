Get-AppxPackage -AllUsers -Name "5319275A.WhatsAppDesktop" -ErrorAction SilentlyContinue |
Remove-AppxPackage -AllUsers

Get-AppxProvisionedPackage -Online |
Where-Object DisplayName -eq "5319275A.WhatsAppDesktop" |
Remove-AppxProvisionedPackage -Online
