# Intune Detection Script - MakeCode micro:bit (User Install)
# Run as: Logged-on user (NOT System)

$installDir = "$env:LOCALAPPDATA\makecode_microbit"
$updateExe  = "$installDir\Update.exe"

# Find the versioned app folder (e.g., app-4.1.0)
$appFolder = Get-ChildItem -Path $installDir -Filter "app-*" -Directory -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    Select-Object -First 1

$exe = if ($appFolder) {
    Get-ChildItem -Path $appFolder.FullName -Filter "*.exe" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notlike "squirrel*" } |
        Select-Object -First 1
}

if (
    (Test-Path $installDir) -and
    (Test-Path $updateExe) -and
    ($null -ne $exe)
) {
    Write-Host "Detected: MakeCode micro:bit installed at $($exe.FullName)"
    exit 0  # Detected — Intune marks app as Installed
} else {
    Write-Host "Not detected"
    exit 1  # Not detected — Intune marks app as Not Installed
}