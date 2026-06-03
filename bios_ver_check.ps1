Import-Module Microsoft.Graph.Beta
Import-Module Microsoft.Graph.Beta.DeviceManagement

Connect-MgGraph -Scopes `
    "Group.Read.All",
    "Device.Read.All", `
    "DeviceManagementManagedDevices.Read.All"

$GroupId = ""
$OutputFile = "C:\Temp\BiosVersions.csv"

# Recursive function to get all devices including nested groups
function Get-NestedGroupDevices {
    param([Parameter(Mandatory)][string]$GroupId)

    $Members = Get-MgGroupMember -GroupId $GroupId -All

    foreach ($Member in $Members) {
        switch ($Member.AdditionalProperties.'@odata.type') {
            '#microsoft.graph.device' { $Member }
            '#microsoft.graph.group'  { Get-NestedGroupDevices -GroupId $Member.Id }
        }
    }
}

# Get all devices from the group
Write-Host "Collecting devices from group..."
$Devices = Get-NestedGroupDevices -GroupId $GroupId | Sort-Object Id -Unique
Write-Host "Found $($Devices.Count) unique devices."

# Loop through each device and pull BIOS version from Intune
$Results = foreach ($DeviceObject in $Devices) {
    try {
        # Get DeviceId from Entra
        $EntraDevice = Get-MgDevice -DeviceId $DeviceObject.Id -ErrorAction Stop

        # find the Intune managed device ID by filtering on azureADDeviceId
        $FindUri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices" +
                   "?`$filter=azureADDeviceId eq '$($EntraDevice.DeviceId)'" +
                   "&`$select=id,deviceName"

        $FindResponse = Invoke-MgGraphRequest -Method GET -Uri $FindUri
        $ManagedDevice = $FindResponse.value | Select-Object -First 1

        if ($ManagedDevice) {
            # fetch hardwareInformation by individual device ID
            $HwUri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($ManagedDevice.id)" +
                     "?`$select=deviceName,hardwareInformation"

            $HwResponse = Invoke-MgGraphRequest -Method GET -Uri $HwUri

            [PSCustomObject]@{
                DeviceName   = $HwResponse.deviceName
                BIOSVersion  = $HwResponse.hardwareInformation.systemManagementBIOSVersion
            }
        }
        else {
            Write-Warning "No Intune record found for: $($EntraDevice.DisplayName)"
        }
    }
    catch {
        Write-Warning "Failed: $($DeviceObject.Id) — $($_.Exception.Message)"
    }
}

Write-Host "Total devices with results: $($Results.Count)"

if (-not (Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
}

$Results |
    Sort-Object DeviceName |
    Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "Done! File saved to: $OutputFile"