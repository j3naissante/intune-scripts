Write-Output "Checking for NVIDIA drivers..."

# Use Get-WmiObject
$nvidiaDrivers = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE '%NVIDIA%'"

if ($nvidiaDrivers) {
    foreach ($driver in $nvidiaDrivers) {
        Write-Output "Uninstalling NVIDIA driver: $($driver.Name)"
        $uninstallResult = $driver.Uninstall()
        if ($uninstallResult.ReturnValue -eq 0) {
            Write-Output "Successfully uninstalled: $($driver.Name)"
        } else {
            Write-Output "Failed to uninstall: $($driver.Name). Error code: $($uninstallResult.ReturnValue)"
        }
    }
} else {
    Write-Output "No NVIDIA drivers found on this device."
}

Write-Output "Restarting computer (if necessary)..."
Restart-Computer -Force
