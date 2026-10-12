$ErrorActionPreference = "Stop"

try {
    $UsbHubs = Get-CimInstance -ClassName Win32_USBHub

    $PowerDevices = Get-CimInstance `
        -Namespace "root\wmi" `
        -ClassName MSPower_DeviceEnable
}
catch {
    Write-Output "ERROR querying USB power settings: $($_.Exception.Message)"
    exit 1
}

$EnabledDevices = @()

foreach ($Hub in $UsbHubs) {

    if ([string]::IsNullOrWhiteSpace($Hub.PNPDeviceID)) {
        continue
    }

    $PNPDeviceID = [WildcardPattern]::Escape($Hub.PNPDeviceID)

    $MatchingDevices = @(
        $PowerDevices | Where-Object {
            $_.InstanceName -like "$PNPDeviceID*"
        }
    )

    foreach ($Device in $MatchingDevices) {

        if ($Device.Enable -eq $true) {

            $EnabledDevices += [PSCustomObject]@{
                Name         = $Hub.Name
                PNPDeviceID  = $Hub.PNPDeviceID
                InstanceName = $Device.InstanceName
            }
        }
    }
}

if ($EnabledDevices.Count -gt 0) {

    Write-Output "USB power saving enabled on $($EnabledDevices.Count) device(s)."

    foreach ($Device in $EnabledDevices) {
        Write-Output "$($Device.Name)"
        Write-Output "PNP: $($Device.PNPDeviceID)"
        Write-Output "WMI: $($Device.InstanceName)"
    }

    # Non-compliant -> Intune runs remediation
    exit 1
}

Write-Output "USB power saving is already disabled."
exit 0