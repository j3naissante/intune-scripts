$PackageName = "Block-Wi-Fi-SSID"
$Path_local = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs"
Start-Transcript -Path "$Path_local\$PackageName-install.log" -Force
netsh wlan delete profile name="SSID" i=*
netsh wlan add filter permission=block ssid="SSID" networktype=infrastructure
Stop-Transcript