$claudePath = "$env:LOCALAPPDATA\AnthropicClaude\update.exe"

if (Test-Path $claudePath) {
    Write-Output "Uninstalling Claude"

    try {
        Start-Process "cmd.exe" -ArgumentList "/c `"$claudePath --uninstall -s`"" -Wait -NoNewWindow
        Write-Output "Claude uninstalled successfully."
    }
    catch {
        Write-Error "Failed to uninstall Claude: $_"
    }
}
else {
    Write-Output "Claude not found"
}

$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

Get-ChildItem -Path $StartMenuPath -Recurse -Filter "*Claude*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }
$desktopPath = [System.Environment]::GetFolderPath("Desktop")
Get-ChildItem -Path $desktopPath -Recurse -Filter "*Claude*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing desktop shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }