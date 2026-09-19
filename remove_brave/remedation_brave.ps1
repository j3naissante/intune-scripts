$bravePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"

if (Test-Path $bravePath) {
    Write-Output "Uninstalling Brave"

    try {
        Start-Process "cmd.exe" -ArgumentList "/c `"$bravePath --uninstall --silent --forceuninstall --system-level=false`"" -Wait -NoNewWindow
        Write-Output "Brave uninstalled successfully."
    }
    catch {
        Write-Error "Failed to uninstall Brave: $_"
    }
}
else {
    Write-Output "Brave not found"
}

$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

Get-ChildItem -Path $StartMenuPath -Recurse -Filter "*Brave*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }
$desktopPath = [System.Environment]::GetFolderPath("Desktop")
Get-ChildItem -Path $desktopPath -Recurse -Filter "*Brave*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing desktop shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }