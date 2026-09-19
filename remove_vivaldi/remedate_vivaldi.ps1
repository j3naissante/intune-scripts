$vivaldiPath = "$env:LOCALAPPDATA\Vivaldi\Application\vivaldi.exe"

if (Test-Path $vivaldiPath) {
    Write-Output "Uninstalling Vivaldi"

    try {
        Start-Process "cmd.exe" -ArgumentList "/c `"$vivaldiPath --uninstall --silent --forceuninstall --system-level=false`"" -Wait -NoNewWindow
        Write-Output "Vivaldi uninstalled successfully."
    }
    catch {
        Write-Error "Failed to uninstall Vivaldi: $_"
    }
}
else {
    Write-Output "Vivaldi not found"
}

$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

Get-ChildItem -Path $StartMenuPath -Recurse -Filter "*Vivaldi*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }
$desktopPath = [System.Environment]::GetFolderPath("Desktop")
Get-ChildItem -Path $desktopPath -Recurse -Filter "*Vivaldi*.lnk" -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Output "Removing desktop shortcut: $($_.FullName)"
        Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
    }