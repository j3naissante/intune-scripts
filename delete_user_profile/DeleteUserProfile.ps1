Get-CimInstance -ClassName Win32_UserProfile -Filter "Loaded=False and LocalPath Like '%username%'" | Remove-CimInstance