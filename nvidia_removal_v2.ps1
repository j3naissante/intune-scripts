# Define a function to uninstall NVIDIA drivers
Function Uninstall-NvidiaDrivers {
    Write-Output "Searching for NVIDIA drivers..."

    # Get all installed programs matching 'NVIDIA'
    $NvidiaPrograms = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*NVIDIA*" }

    # Check if NVIDIA programs are found
    if ($NvidiaPrograms) {
        foreach ($Program in $NvidiaPrograms) {
            Write-Output "Uninstalling: $($Program.Name)"
            $Program.Uninstall() | Out-Null
        }
        Write-Output "All NVIDIA drivers have been uninstalled."
    } else {
        Write-Output "No NVIDIA drivers found to uninstall."
    }
}

# Call the function
Uninstall-NvidiaDrivers
