
$ServiceName = "dashclientservice"

try {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($null -eq $Service) {
        Write-Output "Success: Service '$ServiceName' was already absent."
        exit 0
    }

    Write-Output "Neutralizing service '$ServiceName'..."
    Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
    Write-Output "Service '$ServiceName' has been set to Disabled."

    if ($Service.Status -ne 'Stopped') {
        Write-Output "Stopping the active service..."
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        Write-Output "Service '$ServiceName' has been stopped."
    } else {
        Write-Output "Service was already stopped."
    }

    exit 0

} catch {
    Write-Output "Error: Failed to disable service. Details: $($_.Exception.Message)"
    exit 1
}