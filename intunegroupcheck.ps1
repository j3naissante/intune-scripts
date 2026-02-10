# Connect to Microsoft Graph
Connect-MgGraph -Scopes `
    "DeviceManagementManagedDevices.Read.All",
    "Group.Read.All",
    "Directory.Read.All"

# Path to device list
$deviceListPath = ""

# Read device names from TXT
$deviceNames = Get-Content $deviceListPath

foreach ($deviceName in $deviceNames) {

    Write-Host "`nProcessing device: $deviceName" -ForegroundColor Cyan

    # Get Intune device
    $intuneDevice = Get-MgDeviceManagementManagedDevice `
        -Filter "deviceName eq '$deviceName'" `
        -ErrorAction SilentlyContinue

    if (!$intuneDevice) {
        Write-Warning "Device not found in Intune"
        continue
    }

    # Get Entra ID device
    $aadDevice = Get-MgDevice `
        -Filter "deviceId eq '$($intuneDevice.AzureADDeviceId)'" `
        -ErrorAction SilentlyContinue

    if (!$aadDevice) {
        Write-Warning "Azure AD device not found"
        continue
    }

    # Get ALL groups the device is a member of (static + dynamic)
    $groupIds = Get-MgDeviceMemberGroup `
        -DeviceId $aadDevice.Id `
        -SecurityEnabledOnly:$false

    $foundGroups = @()


   #Add your keyword 
    foreach ($gid in $groupIds) {
        $group = Get-MgGroup -GroupId $gid -ErrorAction SilentlyContinue
        if ($group.DisplayName -like "**") {
            $foundGroups += $group.DisplayName
        }
    }

    if ($foundGroups.Count -gt 0) {
        foreach ($g in $foundGroups) {
            Write-Host "  - $g"
        }
    }
    else {
        Write-Host "  - No matching 'seadmed' groups"
    }
}