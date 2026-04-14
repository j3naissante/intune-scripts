# ============================================================
# Intune Remediation - DETECTION Script
# Purpose : Detect if PrusaSlicer 2.9.4.0 is installed but
#           the All Users Desktop shortcut is missing.
# Exit 0  = Compliant   (no remediation needed)
# Exit 1  = Non-compliant (remediation will run)
# ============================================================

$ExePath      = "C:\Program Files\Prusa3D\PrusaSlicer\prusa-slicer.exe"
$RequiredVer  = [Version]"2.9.4.0"
$DesktopLnk   = "C:\Users\Public\Desktop\PrusaSlicer.lnk"

# --- 1. Check executable exists ---
if (-not (Test-Path $ExePath)) {
    Write-Host "PrusaSlicer executable not found. Compliant (nothing to do)."
    exit 0
}

# --- 2. Read raw file version from binary resource ---
$RawVer  = (Get-Item $ExePath).VersionInfo.FileVersionRaw
$FileVer = [Version]("{0}.{1}.{2}.{3}" -f $RawVer.Major, $RawVer.Minor, $RawVer.Build, $RawVer.Revision)

Write-Host "Detected PrusaSlicer version: $FileVer"

if ($FileVer -ne $RequiredVer) {
    Write-Host "Version is $FileVer (not $RequiredVer). Compliant (nothing to do)."
    exit 0
}

# --- 3. Version matches - check if Desktop shortcut exists ---
if (Test-Path $DesktopLnk) {
    Write-Host "PrusaSlicer $RequiredVer detected and Desktop shortcut already exists. Compliant."
    exit 0
}

# Desktop shortcut missing - remediation needed
Write-Host "PrusaSlicer $RequiredVer detected but Desktop shortcut is MISSING. Non-compliant."
exit 1