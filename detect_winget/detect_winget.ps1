<#
.SYNOPSIS
    Detects whether WinGet (App Installer) is installed and functional.
.NOTES
    Exit 0 = WinGet detected and working
    Exit 1 = WinGet not found or not functional
#>

try {
    # Find all winget.exe instances and sort to get the newest version
    $wingetPaths = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" `
        -ErrorAction SilentlyContinue

    if (-not $wingetPaths) {
        Write-Output "WinGet not found."
        exit 1
    }

    # Sort and pick the newest version
    $wingetExe = ($wingetPaths | Sort-Object Path | Select-Object -Last 1).Path

    # Verify it actually runs
    $version = & $wingetExe --version 2>&1
    if ($LASTEXITCODE -eq 0 -and $version) {
        Write-Output "WinGet detected: $version at $wingetExe"
        exit 0
    } else {
        Write-Output "WinGet found but failed to run. Path: $wingetExe"
        exit 1
    }

} catch {
    Write-Output "Detection error: $($_.Exception.Message)"
    exit 1
}