# ==============================
# Intune Detection - GCompris
# ==============================

$appPattern = "*GCompris*"

# Check installed AppX packages (real install state)
$appx = Get-AppxPackage -AllUsers $appPattern -ErrorAction SilentlyContinue

# Check provisioned package (pre-installed for new users)
$prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object DisplayName -like $appPattern

# Output install location for visibility in Intune
if ($appx) {
    foreach ($a in $appx) {
        Write-Output "FOUND APPX: $($a.Name)"
        Write-Output "INSTALL LOCATION: $($a.InstallLocation)"
    }
}

if ($prov) {
    Write-Output "FOUND PROVISIONED PACKAGE: $appPattern"
}

# Decision logic
if ($appx -or $prov) {
    Write-Output "RESULT: NON-COMPLIANT"
    exit 1
}

Write-Output "RESULT: COMPLIANT"
exit 0