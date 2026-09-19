$vivaldiPath = "$env:LOCALAPPDATA\Vivaldi\Application\vivaldi.exe"

if (test-path $vivaldiPath) {
    Write-Output "Vivaldi found at $vivaldiPath"
    exit 1
}
else {
    Write-Output "Vivaldi not found"
    exit 0
}