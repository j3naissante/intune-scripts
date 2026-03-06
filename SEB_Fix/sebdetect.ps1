
$ServiceName = "dashclientservice"

try {
    
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($Service) {
        
        Write-Output "Non-Compliant: Service '$ServiceName' was found on this machine."
        exit 1
    } else {
        
        Write-Output "Compliant: Service '$ServiceName' is not present."
        exit 0
    }

} catch {
    
    Write-Output "Error: Failed to verify service status. Details: $($_.Exception.Message)"
    exit 1
}