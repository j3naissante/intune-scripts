$discordPath = "$env:LOCALAPPDATA\Discord\Update.exe"

if (Test-Path $discordPath) {
    Write-Output "Discord detected at $discordPath"
    exit 1
}
else {
    Write-Output "Discord not found"
    exit 0
}
