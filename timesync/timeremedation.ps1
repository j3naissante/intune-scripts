Write-Output "Starting Windows Time remediation"

# Ensure service exists
$service = Get-Service -Name w32time -ErrorAction SilentlyContinue
if ($null -eq $service) {
    Write-Output "Windows Time service not found"
    exit 1
}

# Restart service
if ($service.Status -ne 'Running') {
    Start-Service w32time
} else {
    Restart-Service w32time -Force
}

# Force time sync
w32tm /resync /force

if ($LASTEXITCODE -eq 0) {
    Write-Output "Time synchronization successful"
    exit 0
} else {
    Write-Output "Time synchronization failed"
    exit 1
}
