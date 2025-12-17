

$perplexityFolder = "$env:LOCALAPPDATA\Perplexity"
$desktopShortcut = "$env:USERPROFILE\Desktop\Comet.lnk"
$startMenuShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Comet.lnk"

# Stop Comet process if it exists
$cometProcess = Get-Process -Name "comet" -ErrorAction SilentlyContinue
if ($cometProcess) {
    Write-Host "Stopping Comet process..."
    $cometProcess | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# Remove Desktop shortcut
if (Test-Path $desktopShortcut) {
    Remove-Item -Path $desktopShortcut -Force
    Write-Host "Removed Desktop shortcut"
}

# Remove Start Menu shortcut
if (Test-Path $startMenuShortcut) {
    Remove-Item -Path $startMenuShortcut -Force
    Write-Host "Removed Start Menu shortcut"
}

# Remove entire Perplexity folder (force attributes to normal first)
if (Test-Path $perplexityFolder) {
    try {
        Write-Host "Removing Perplexity folder..."

        # Set all files/folders to normal attributes
        Get-ChildItem -Path $perplexityFolder -Recurse -Force | ForEach-Object {
            $_.Attributes = 'Normal'
        }

        # Remove folder recursively
        Remove-Item -Path $perplexityFolder -Recurse -Force
        Write-Host "Successfully removed Perplexity folder"
    } catch {
        Write-Host "Failed to remove Perplexity folder: $_"
    }
} else {
    Write-Host "Perplexity folder not found"
}
