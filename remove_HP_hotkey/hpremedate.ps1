# Remediate by stopping + disabling "HP Hotkey UWP Service"
$displayName = "HP Hotkey UWP Service"

try {
    $svc = Get-CimInstance Win32_Service -Filter "DisplayName='$displayName'" -ErrorAction SilentlyContinue

    if (-not $svc) {
        Write-Output "Service '$displayName' not found. Nothing to remediate."
        exit 0
    }

    $serviceName = $svc.Name
    Write-Output "Remediating: $($svc.DisplayName) | Name: $serviceName"

    $serviceObj = Get-Service -Name $serviceName -ErrorAction Stop
    if ($serviceObj.Status -ne "Stopped") {
        Stop-Service -Name $serviceName -Force -ErrorAction Stop
        Write-Output "Stopped service."
    } else {
        Write-Output "Service already stopped."
    }

    
    Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop
    Write-Output "Set StartupType to Disabled."

    
    $verify = Get-CimInstance Win32_Service -Filter "Name='$serviceName'" -ErrorAction Stop
    Write-Output "Verify: StartMode=$($verify.StartMode) State=$($verify.State)"

    if ($verify.StartMode -eq "Disabled" -and $verify.State -eq "Stopped") {
        Write-Output "Remediation successful."
        exit 0
    } else {
        Write-Output "Remediation attempted but verification failed."
        exit 1
    }
}
catch {
    Write-Output "Remediation error: $($_.Exception.Message)"
    exit 1
}
