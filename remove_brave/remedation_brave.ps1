Write-Host "Removing Brave Browser"

Get-Process "brave" -ErrorAction -SilentlyContinue | Stop-Process -Force -ErrorAction -SilentlyContinue

$profiles = Get-ChildItem "C:\Users" -Directory -SilentlyContinue

foreach ($profile in $profiles) {
    $braveRoot "C:\Users\$($profile.Name)\AppData\Local\BraveSoftware"

    if (Test-Path $braveRoot) {
        Write-Host "Removing brave from profile $($profile.Name)"

        Remove-Item -Path $braveRoot -Recurse -Force -ErrorAction -SilentlyContinue
    }

    $shortcutPath = "C:\Users\$($profile.Name)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Brave.Ink"
    if (Test-Path $shortcutPath) {
        Remove-Item $shortcutPath -Force -ErrorAction -SilentlyContinue
    }

    $desktopShortcut = "C:\Users\$($profile.Name)\Desktop\Brave.Ink"
    if (Test-Path $desktopShortcut) {
        Remove-Item $desktopShortcut -Force -ErrorAction -SilentlyContinue
    }
}

Write-Host "Brave removed"
exit 0