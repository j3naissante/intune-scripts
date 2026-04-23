
$appPattern = "*GCompris*"

$appx = Get-AppxPackage -AllUsers $appPattern -ErrorAction SilentlyContinue

$prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
        Where-Object DisplayName -like $appPattern

if ($appx) {
    foreach ($a in $appx) {
        Write-Output "FOUND APPX: $($a.Name)"
        Write-Output "INSTALL LOCATION: $($a.InstallLocation)"
    }
}

if ($prov) {
    Write-Output "FOUND PROVISIONED PACKAGE: $appPattern"
}

if ($appx -or $prov) {
    Write-Output "RESULT: NON-COMPLIANT"
    exit 1
}

Write-Output "RESULT: COMPLIANT"
exit 0