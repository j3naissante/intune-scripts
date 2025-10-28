$discordPath = "$env:LOCALAPPDATA\Discord\Update.exe"

if (Test-Path $discordPath) {
    Write-Output "Uninstalling Discord"
    try {
        Start-Process "cmd.exe" -ArgumentList "/c `"$discordPath --uninstall -s`"" -Wait -NoNewWindow
        Write-Output "Discord uninstalled successfully."
    } catch {
        Write-Error "Failed to uninstall Discord: $_"
    }
} else {
    Write-Output "Discord not found"
}
