
$deviceListPath = ""   # One device name per line
$targetGroupId  = ""      # Assigned (static) group only


Connect-MgGraph -Scopes "Device.Read.All","Group.ReadWrite.All","Directory.Read.All"


$deviceNames = Get-Content $deviceListPath

foreach ($deviceName in $deviceNames) {

    Write-Host "`nProcessing device: $deviceName" -ForegroundColor Cyan

    $intuneDevice = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$deviceName'" -ErrorAction SilentlyContinue

    if (!$intuneDevice) {
        Write-Warning "Device not found in Intune"
        continue
    }

    $aadDevice = Get-MgDevice -Filter "deviceId eq '$($intuneDevice.AzureADDeviceId)'" -ErrorAction SilentlyContinue

    if (!$aadDevice) {
        Write-Warning "Entra ID device not found"
        continue
    }

    $groupIds = Get-MgDeviceMemberGroup -DeviceId $aadDevice.Id -SecurityEnabledOnly:$false

    if ($groupIds -contains $targetGroupId) {
        Write-Host "  - Already a member" -ForegroundColor Yellow
        continue
    }

    try {
        New-MgGroupMember -GroupId $targetGroupId -DirectoryObjectId $aadDevice.Id
        Write-Host "  - Added to group" -ForegroundColor Green
    }
    catch {
        Write-Error "  - Failed to add device"
    }
}