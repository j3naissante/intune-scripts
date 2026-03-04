# Detection Script for WPS Office

# Flag to indicate if WPS Office exists
$WPSFound = $false

# Get all non-system user profiles
$UserProfiles = Get-WmiObject Win32_UserProfile | Where-Object { $_.Special -eq $false -and $_.LocalPath -match "C:\\Users\\" }

foreach ($Profile in $UserProfiles) {
    $UserPath = $Profile.LocalPath
    $WPSPath = "$UserPath\AppData\Local\Kingsoft\WPS Office"

    if (Test-Path $WPSPath) {
        $WPSFound = $true
        break  # No need to continue scanning other profiles
    }
}

# Exit codes for Intune Detection:
# 0 = No remediation needed (app not found)
# 1 = Remediation needed (app found)
if ($WPSFound) { exit 1 } else { exit 0 }