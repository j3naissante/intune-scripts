$firefoxPath = "$env:LOCALAPPDATA\Mozilla Firefox\Firefox.exe"

if (Test-Path $firefoxPath) {
    Write-Output "Firefox Browser found at $firefoxPath"
    exit 1
}
else {
    Write-Output "Firefox Browser not found"
    exit 0
}