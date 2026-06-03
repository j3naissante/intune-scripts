$PackageName = "Microsoft.Windows.Photos"

# Check if package exists for any user
$pkg = Get-AppxPackage -AllUsers | Where-Object {
    $_.Name -eq $PackageName
}

# Check if provisioned in OS image
$prov = Get-AppxProvisionedPackage -Online | Where-Object {
    $_.DisplayName -eq $PackageName
}

if ($pkg -or $prov) {
    Write-Output "Microsoft Photos detected."
    exit 0
}
else {
    Write-Output "Microsoft Photos missing."
    exit 1
}