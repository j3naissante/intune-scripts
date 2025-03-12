# Specify the package name
$PackageName = "Enter your PackageName"

# Remove the package
Remove-WindowsPackage -Online -PackageName $PackageName -NoRestart
Write-Host "Package $PackageName has been removed successfully."
