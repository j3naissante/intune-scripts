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

$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

Get-ChildItem -Path $StartMenuPath -Recurse -Filter "*Discord*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }
$desktopPath = [System.Environment]::GetFolderPath("Desktop")
Get-ChildItem -Path $desktopPath -Recurse -Filter "*Discord*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing desktop shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }