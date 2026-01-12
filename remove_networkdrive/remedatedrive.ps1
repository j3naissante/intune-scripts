if (Test-Path "HKCU:\Network\M") {
    cmd.exe /c "net use M: /delete /y" | Out-Null
    Remove-Item "HKCU:\Network\M" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Output "Drive M removed"
}

# Refresh Explorer to clear cached drives
Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force

exit 0

