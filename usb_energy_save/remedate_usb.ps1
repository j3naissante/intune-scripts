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

$Changed = 0
$Failed = 0

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

            Write-Output "Disabling USB power saving:"
            Write-Output "$($Hub.Name)"
            Write-Output "PNP: $($Hub.PNPDeviceID)"
            Write-Output "WMI: $($Device.InstanceName)"

            try {
                Set-CimInstance `
                    -InputObject $Device `
                    -Property @{
                        Enable = $false
                    } `
                    -ErrorAction Stop

                Write-Output "Successfully disabled."
                $Changed++
            }
            catch {
                Write-Output "FAILED: $($_.Exception.Message)"
                $Failed++
            }
        }
    }
}

Write-Output "Changed: $Changed"
Write-Output "Failed: $Failed"

if ($Failed -gt 0) {
    exit 1
}

exit 0