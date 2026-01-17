$RobloxPath = "$env:LOCALAPPDATA\Roblox"

if (Test-Path $RobloxPath) {
    Write-Output "Roblox is installed."
    exit 1  # 
} else {
    Write-Output "Roblox is not installed."
    exit 0  # 
}
