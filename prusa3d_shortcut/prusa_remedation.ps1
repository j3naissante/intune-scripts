# ============================================================
# Intune Remediation - REMEDIATION Script
# Purpose : Create an All Users Start Menu shortcut for
#           PrusaSlicer 2.9.4.0.
# Exit 0  = Success
# Exit 1  = Failure
# ============================================================

$ExePath      = "C:\Program Files\Prusa3D\PrusaSlicer\prusa-slicer.exe"
$RequiredVer  = [Version]"2.9.4.0"
$StartMenuDir = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
$ShortcutPath = "$StartMenuDir\PrusaSlicer.lnk"
$IconPath     = $ExePath   # exe contains its own icon

try {
    # --- 1. Safety checks before doing anything ---
    if (-not (Test-Path $ExePath)) {
        Write-Host "ERROR: PrusaSlicer executable not found at '$ExePath'."
        exit 1
    }

    $RawVer  = (Get-Item $ExePath).VersionInfo.FileVersionRaw
    $FileVer = [Version]("{0}.{1}.{2}.{3}" -f $RawVer.Major, $RawVer.Minor, $RawVer.Build, $RawVer.Revision)
    Write-Host "Detected PrusaSlicer version: $FileVer"
    if ($FileVer -ne $RequiredVer) {
        Write-Host "ERROR: Expected version $RequiredVer but found $FileVer. Aborting."
        exit 1
    }

    # --- 2. Ensure target directory exists ---
    if (-not (Test-Path $StartMenuDir)) {
        New-Item -ItemType Directory -Path $StartMenuDir -Force | Out-Null
    }

    # --- 3. Create the shortcut ---
    $WshShell  = New-Object -ComObject WScript.Shell
    $Shortcut  = $WshShell.CreateShortcut($ShortcutPath)

    $Shortcut.TargetPath       = $ExePath
    $Shortcut.WorkingDirectory = Split-Path $ExePath -Parent
    $Shortcut.Description      = "PrusaSlicer $RequiredVer"
    $Shortcut.IconLocation     = "$IconPath,0"
    $Shortcut.Save()

    # --- 4. Verify shortcut was created ---
    if (Test-Path $ShortcutPath) {
        Write-Host "SUCCESS: Shortcut created at '$ShortcutPath'."
        exit 0
    } else {
        Write-Host "ERROR: Shortcut file was not found after save attempt."
        exit 1
    }

} catch {
    Write-Host "ERROR: An unexpected error occurred - $_"
    exit 1
}