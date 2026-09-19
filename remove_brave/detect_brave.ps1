$bravePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"

if (Test-Path $bravePath) {
    Write-Output "Brave Browser found at $bravePath"
    exit 1
}
else {
    Write-Output "Brave Browser not found"
    exit 0
}