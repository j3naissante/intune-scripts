# Detect ANY AMD display adapter (enabled or disabled)
$gpu = Get-PnpDevice | Where-Object {
    $_.Class -eq "Display" -and $_.FriendlyName -match "AMD"
}

# If no AMD GPU is found → not compliant (we want remediation to run)
if (-not $gpu) {
    Write-Output "AMD GPU missing or not enumerated"
    exit 1
}

Write-Output "AMD GPU status: $($gpu.Status)"

# If GPU is disabled, we need remediation
if ($gpu.Status -eq "Disabled") {
    Write-Output "AMD GPU is DISABLED"
    exit 1
}

# Check for basic display driver (means AMD driver is not installed properly)
if ($gpu.FriendlyName -match "Microsoft Basic Display Adapter") {
    Write-Output "AMD GPU using Microsoft Basic Display Adapter (driver failure)"
    exit 1
}

# Check for error states
if ($gpu.Status -match "Error" -or $gpu.Problem) {
    Write-Output "AMD GPU has error/problem code"
    exit 1
}

# If everything is fine:
Write-Output "AMD GPU enabled + driver loaded"
exit 0
