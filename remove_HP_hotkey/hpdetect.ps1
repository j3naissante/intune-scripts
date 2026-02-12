
$displayName = "HP Hotkey UWP Service"

try {
    $svc = Get-CimInstance Win32_Service -Filter "DisplayName='$displayName'" -ErrorAction SilentlyContinue

    if (-not $svc) {
        Write-Output "Service '$displayName' not found. Compliant."
        exit 0
    }

    $needsRemediation = ($svc.StartMode -ne "Disabled") -or ($svc.State -ne "Stopped")

    Write-Output "Found: $($svc.DisplayName) | Name: $($svc.Name) | StartMode: $($svc.StartMode) | State: $($svc.State)"

    if ($needsRemediation) {
        Write-Output "Non-compliant: service must be Disabled and Stopped."
        exit 1
    }

    Write-Output "Compliant."
    exit 0
}
catch {
    Write-Output "Detection error: $($_.Exception.Message)"
   
    exit 1
}
