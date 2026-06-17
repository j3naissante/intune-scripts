# Detection Script for WinGet (App Installer)
try {
    # Resolve the path to winget.exe which resides in a versioned folder
    $wingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue

    if ($wingetPath) {
        # If multiple versions exist, select the newest one
        if ($wingetPath.Count -gt 1) {
            $wingetPath = $wingetPath[-1].Path
        }
        
        Write-Output "WinGet detected at: $wingetPath"
        exit 0 # Detected
    } else {
        Write-Output "WinGet not found."
        exit 1 # Not detected
    }
} catch {
    Write-Output "Error during detection: $($_.Exception.Message)"
    exit 1
}