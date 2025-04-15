 Get all user profiles excluding system profiles
$UserProfiles = Get-WmiObject Win32_UserProfile | Where-Object { $_.Special -eq $false -and $_.LocalPath -match "C:\\Users\\" }

foreach ($Profile in $UserProfiles) {
    $UserPath = $Profile.LocalPath  # Example: C:\Users\Username
    Write-Output "Processing user profile: $UserPath"

    # WPS Office installation directory
    $WPSLocal = "$UserPath\AppData\Local\Kingsoft\WPS Office"
    If (Test-Path $WPSLocal) {
        Write-Output "Found WPS Office directory at $WPSLocal"
        $UninstPath = Get-ChildItem -Path "$WPSLocal\*" -Include uninst.exe -Recurse -ErrorAction SilentlyContinue
        If ($UninstPath) {
            Write-Output "Uninstalling WPS Office using $UninstPath"
            Start-Process "$UninstPath" -ArgumentList "/s" -Wait
            Get-Process -Name "Au_" -ErrorAction SilentlyContinue | Wait-Process
        }
    }

    # Remove Kingsoft directories
    $KingsoftLocal = "$UserPath\AppData\Local\Kingsoft"
    If (Test-Path $KingsoftLocal) {
        Write-Output "Removing Kingsoft Local directory at $KingsoftLocal"
        Remove-Item -Path "$KingsoftLocal" -Force -Recurse -ErrorAction SilentlyContinue
    }

    $KingsoftRoaming = "$UserPath\AppData\Roaming\Kingsoft"
    If (Test-Path $KingsoftRoaming) {
        Write-Output "Removing Kingsoft Roaming directory at $KingsoftRoaming"
        Remove-Item -Path "$KingsoftRoaming" -Force -Recurse -ErrorAction SilentlyContinue
    }

    # Final message for each user
    Write-Output "Completed WPS Office remediation for user: $UserPath"
}

# Final message for the system context
Write-Output "WPS Office remediation completed for all user profiles."
Exit 0
