
$deviceListPath = ""
$targetGroupId  = ""

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

    if ($groupIds -notcontains $targetGroupId) {
        Write-Host "  - Not a member of group" -ForegroundColor Yellow
        continue
    }

    try {
        Remove-MgGroupMemberByRef -GroupId $targetGroupId -DirectoryObjectId $aadDevice.Id
        Write-Host "  - Removed from group" -ForegroundColor Green
    }
    catch {
        Write-Error "  - Failed to remove device"
    }
}
