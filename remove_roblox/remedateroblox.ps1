$RobloxPath = "$env:LOCALAPPDATA\Roblox"

if (Test-Path $RobloxPath) {
    try {
        Remove-Item -Path $RobloxPath -Recurse -Force
        Write-Output "Roblox installation removed successfully."
        exit 0  
    }
    catch {
        Write-Output "Failed to remove Roblox: $_"
        exit 1 
    }
} else {
    Write-Output "Roblox is not installed, nothing to remove."
    exit 0
}
