$winget = Get-Command winget.exe -ErrorAction SilentlyContinue

if (-not $winget) {
    exit 1
}

Start-Process -FilePath "winget.exe" `
-ArgumentList "install --id Microsoft.Windows.Photos --exact --scope machine --accept-source-agreements --accept-package-agreements --silent" `
-Wait -NoNewWindow

Start-Sleep -Seconds 10

$check = Get-AppxPackage -AllUsers Microsoft.Windows.Photos

if ($check) {
    exit 0
}
else {
    exit 1
}