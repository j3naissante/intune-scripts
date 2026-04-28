# ============================================================
#  Get-IntuneDeviceGroups.ps1
#  Queries Intune + Entra ID group membership for devices
#  listed in a TXT file, checks last activity, and exports
# ============================================================

# ---- CONFIGURATION -----------------------------------------
$deviceListPath = ""          # Path to your device list TXT
$groupKeyword   = "**" # Change to your keyword pattern
$outputCsvPath  = ".\IntuneDeviceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
# ------------------------------------------------------------

# Connect to Microsoft Graph
Connect-MgGraph -Scopes `
    "DeviceManagementManagedDevices.Read.All",
    "Group.Read.All",
    "Directory.Read.All"

$deviceNames = Get-Content $deviceListPath

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($deviceName in $deviceNames) {

    Write-Host "`nProcessing device: $deviceName" -ForegroundColor Cyan

    $intuneDevice = Get-MgDeviceManagementManagedDevice `
        -Filter "deviceName eq '$deviceName'" `
        -ErrorAction SilentlyContinue

    if (!$intuneDevice) {
        Write-Warning "[$deviceName] Not found in Intune"
        $results.Add([PSCustomObject]@{
            DeviceName          = $deviceName
            IntuneFound         = $false
            EntraFound          = $false
            OS                  = ""
            OSVersion           = ""
            Compliance          = ""
            LastIntuneSync      = ""
            LastEntraActivity   = ""
            LastActivitySource  = "N/A"
            LastActivityDate    = ""
            MatchingGroups      = "NOT FOUND IN INTUNE"
        })
        continue
    }

    $aadDevice = Get-MgDevice `
        -Filter "deviceId eq '$($intuneDevice.AzureADDeviceId)'" `
        -ErrorAction SilentlyContinue

    if (!$aadDevice) {
        Write-Warning "[$deviceName] Not found in Entra ID"
        $results.Add([PSCustomObject]@{
            DeviceName          = $deviceName
            IntuneFound         = $true
            EntraFound          = $false
            OS                  = $intuneDevice.OperatingSystem
            OSVersion           = $intuneDevice.OsVersion
            Compliance          = $intuneDevice.ComplianceState
            LastIntuneSync      = $intuneDevice.LastSyncDateTime
            LastEntraActivity   = ""
            LastActivitySource  = "Intune only"
            LastActivityDate    = $intuneDevice.LastSyncDateTime
            MatchingGroups      = "ENTRA DEVICE NOT FOUND"
        })
        continue
    }

    $lastIntuneSync    = $intuneDevice.LastSyncDateTime
    $lastEntraActivity = $aadDevice.ApproximateLastSignInDateTime

    $lastActivitySource = "N/A"
    $lastActivityDate   = $null

    if ($lastIntuneSync -and $lastEntraActivity) {
        if ($lastIntuneSync -ge $lastEntraActivity) {
            $lastActivitySource = "Intune Sync"
            $lastActivityDate   = $lastIntuneSync
        } else {
            $lastActivitySource = "Entra Sign-In"
            $lastActivityDate   = $lastEntraActivity
        }
    } elseif ($lastIntuneSync) {
        $lastActivitySource = "Intune Sync"
        $lastActivityDate   = $lastIntuneSync
    } elseif ($lastEntraActivity) {
        $lastActivitySource = "Entra Sign-In"
        $lastActivityDate   = $lastEntraActivity
    }

    $activityAge = if ($lastActivityDate) {
        $days = (New-TimeSpan -Start $lastActivityDate -End (Get-Date)).Days
        "$days day(s) ago"
    } else { "Unknown" }

    Write-Host "  Last Activity : $lastActivitySource — $lastActivityDate ($activityAge)" `
        -ForegroundColor $(if ($lastActivityDate -and ((Get-Date) - $lastActivityDate).Days -gt 90) { "Yellow" } else { "Green" })

   
    $groupIds = Get-MgDeviceMemberGroup `
        -DeviceId $aadDevice.Id `
        -SecurityEnabledOnly:$false

    $foundGroups = @()

    foreach ($gid in $groupIds) {
        $group = Get-MgGroup -GroupId $gid -ErrorAction SilentlyContinue
        if ($group.DisplayName -like $groupKeyword) {
            $foundGroups += $group.DisplayName
        }
    }

    if ($foundGroups.Count -gt 0) {
        Write-Host "  Matching groups:" -ForegroundColor Green
        foreach ($g in $foundGroups) { Write-Host "    - $g" }
    } else {
        Write-Host "  No matching groups found." -ForegroundColor DarkGray
    }

    $results.Add([PSCustomObject]@{
        DeviceName          = $deviceName
        IntuneFound         = $true
        EntraFound          = $true
        OS                  = $intuneDevice.OperatingSystem
        OSVersion           = $intuneDevice.OsVersion
        Compliance          = $intuneDevice.ComplianceState
        LastIntuneSync      = if ($lastIntuneSync)    { $lastIntuneSync.ToString("yyyy-MM-dd HH:mm:ss")    } else { "" }
        LastEntraActivity   = if ($lastEntraActivity) { $lastEntraActivity.ToString("yyyy-MM-dd HH:mm:ss") } else { "" }
        LastActivitySource  = $lastActivitySource
        LastActivityDate    = if ($lastActivityDate)  { $lastActivityDate.ToString("yyyy-MM-dd HH:mm:ss")  } else { "" }
        InactiveDays        = if ($lastActivityDate)  { (New-TimeSpan -Start $lastActivityDate -End (Get-Date)).Days } else { "" }
        MatchingGroups      = if ($foundGroups.Count -gt 0) { $foundGroups -join " | " } else { "None" }
    })
}

$results | Export-Csv -Path $outputCsvPath -NoTypeInformation -Encoding UTF8
Write-Host "`n Report exported to: $outputCsvPath" -ForegroundColor Green
Write-Host "   Total devices processed : $($deviceNames.Count)"
Write-Host "   Total rows in report    : $($results.Count)"