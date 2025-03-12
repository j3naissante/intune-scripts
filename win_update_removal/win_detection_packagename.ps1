# Specify the package name
$PackageName = "Enter your PackageName"

# Check if the package is installed
$package = Get-WindowsPackage -Online | Where-Object {$_.PackageName -eq $PackageName}

if ($package -ne $null) {
    Write-Host "Package $PackageName is installed."
    Exit 1
} else {
    Write-Host "Package $PackageName is not installed."
    Exit 0