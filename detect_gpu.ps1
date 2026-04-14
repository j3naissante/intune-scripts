Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

$groupId = "YOUR-GROUP-ID"


$members = Get-MgGroupMember -GroupId $groupId -All

foreach ($member in $members) {
    $deviceId = $member.Id
    $inventory = (Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$deviceId/deviceInventories" -Method GET).value
    $gpu = $inventory | Where-Object { $_.className -eq "Win32_VideoController" }
    Write-Output "$($member.Id) - $($gpu.properties)"
}