# ==============================
# Intune Remediation - GCompris
# ==============================

$appPattern = "*GCompris*"

Write-Output "Starting uninstall for GCompris..."

# -----------------------------
# 1. Kill running process (if any)
# -----------------------------
Get-Process *gcompris* -ErrorAction SilentlyContinue | Stop-Process -Force

# -----------------------------
# 2. Remove installed AppX packages
# -----------------------------
$appx = Get-AppxPackage -AllUsers $appPattern -ErrorAction SilentlyContinue

if ($appx) {
    foreach ($app in $appx) {
        Write-Output "Removing AppX: $($app.Name)"
        Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    }
}

# -----------------------------
# 3. Remove provisioned package (prevents reinstall)
# -----------------------------
$prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object DisplayName -like $appPattern

if ($prov) {
    foreach ($p in $prov) {
        Write-Output "Removing provisioned package: $($p.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction SilentlyContinue
    }
}

# -----------------------------
# 4. Verify removal
# -----------------------------
$remaining = Get-AppxPackage -AllUsers $appPattern

if ($remaining) {
    Write-Output "RESULT: FAILED - still present"
    exit 1
} else {
    Write-Output "RESULT: SUCCESS - fully removed"
    exit 0
}