$LogPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\TimeSyncRestart.log"

function Write-Log {
    param([string]$Message)
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Stamp - $Message" | Out-File -FilePath $LogPath -Append
}

Write-Log "Starting Time Sync fix"

try {
    
    Set-Service -Name W32Time -StartupType Automatic -ErrorAction Stop
    
    
    Restart-Service -Name W32Time -Force -ErrorAction Stop
    Start-Sleep -Seconds 5 

    
    $SyncResult = w32tm /resync /force
    Write-Log "Sync result: $SyncResult"
    
    Write-Output "Success: Service restarted and synced."
    exit 0 
}
catch {
    $ErrorMsg = $_.Exception.Message
    Write-Log "Fail: $ErrorMsg"
    Write-Error "Failed: $ErrorMsg"
    exit 1 
}