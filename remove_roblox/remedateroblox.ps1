$RobloxPath = "$env:LOCALAPPDATA\Roblox\Versions\version-*\RobloxPlayerBeta.exe"

if (Test-Path $RobloxPath) {
    Write-Output "Uninstalling Roblox"

    try {
        Start-Process "cmd.exe" -ArgumentList "/c `"$RobloxPath --uninstall -s`"" -Wait -NoNewWindow
        Write-Output "Roblox uninstalled successfully."
    } catch {
        Write-Error "Failed to uninstall Roblox: $_"
    }
} else {
    Write-Output "Roblox not found"
}

$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

Get-ChildItem -Path $StartMenuPath -Recurse -Filter "*Roblox*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }
$desktopPath = [System.Environment]::GetFolderPath("Desktop")
Get-ChildItem -Path $desktopPath -Recurse -Filter "*Roblox*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing desktop shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }