#Kill scheduled tasks and services FIRST (they respawn processes)
$WpsTaskPatterns = @("*WPS*", "*Kingsoft*", "*kso*")
foreach ($Pattern in $WpsTaskPatterns) {
    Get-ScheduledTask -TaskName $Pattern -ErrorAction SilentlyContinue | 
        Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName $Pattern -ErrorAction SilentlyContinue | 
        Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
}

Get-Service -Name "*kingsoft*", "*wps*", "*kso*" -ErrorAction SilentlyContinue | 
    Stop-Service -Force -ErrorAction SilentlyContinue
Get-Service -Name "*kingsoft*", "*wps*", "*kso*" -ErrorAction SilentlyContinue | 
    Set-Service -StartupType Disabled -ErrorAction SilentlyContinue

# Kill all WPS processes (expanded list, retry loop)
$WpsProcs = @("wps", "wpp", "et", "wpscloud", "wpscenter", "ksolaunch", 
              "kso", "kcomsvcs", "kwpsdump", "ksum", "ksrepropt", "kaichatclient")

# Retry kill up to 3 times - some processes respawn
for ($i = 0; $i -lt 3; $i++) {
    $WpsProcs | ForEach-Object {
        Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    # Also kill anything with kingsoft in the path
    Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -like "*kingsoft*" -or $_.Path -like "*WPS Office*"
    } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Helper function: force-delete a locked file via cmd /c del (bypasses PS handle)
function Remove-LockedItem {
    param([string]$Path)
    if (Test-Path $Path) {
        # Strip read-only
        try { (Get-Item $Path -Force).Attributes = 'Normal' } catch {}
        # Try PowerShell first
        Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
        # If still there, use cmd del
        if (Test-Path $Path) {
            & cmd.exe /c "del /F /Q `"$Path`"" 2>$null
        }
        # If still there, schedule deletion on next reboot
        if (Test-Path $Path) {
            $null = Start-Process -FilePath "cmd.exe" `
                -ArgumentList "/c move `"$Path`" `"$Path.del`" && reg add `"HKLM\SYSTEM\CurrentControlSet\Control\Session Manager`" /v PendingFileRenameOperations /t REG_MULTI_SZ /d `"\??\$Path.del`n`" /f" `
                -WindowStyle Hidden -Wait
            Write-Warning "Scheduled for deletion on reboot: $Path"
        }
    }
}

# Loop through user profiles
$UserProfiles = Get-ChildItem -Path "C:\Users" -Directory

foreach ($Profile in $UserProfiles) {
    $WpsPath = "$($Profile.FullName)\AppData\Local\kingsoft\WPS Office"

    if (Test-Path $WpsPath) {
        # Run uninstaller
        $Uninstaller = Get-ChildItem -Path "$WpsPath\*\utility\uninstall.exe" -ErrorAction SilentlyContinue | 
            Select-Object -First 1

        if ($Uninstaller) {
            Write-Output "Uninstalling WPS for: $($Profile.Name)"
            try {
                Start-Process -FilePath $Uninstaller.FullName -ArgumentList "/S", "/qn" -Wait -WindowStyle Hidden
                Start-Sleep -Seconds 5  # Give uninstaller time to release handles
            } catch {
                Write-Warning "Uninstaller failed for $($Profile.Name), attempting manual cleanup."
            }
        }

        # Aggressive cleanup - files first, then folders (bottom-up)
        if (Test-Path $WpsPath) {
            try {
                # Clear attributes on everything
                Get-ChildItem -Path $WpsPath -Recurse -Force -ErrorAction SilentlyContinue | 
                    ForEach-Object { 
                        try { $_.Attributes = 'Normal' } catch {} 
                    }

                # Delete files first (deepest level), then directories
                Get-ChildItem -Path $WpsPath -Recurse -Force -File -ErrorAction SilentlyContinue | 
                    Sort-Object { $_.FullName.Length } -Descending |
                    ForEach-Object { Remove-LockedItem -Path $_.FullName }

                # Remove empty dirs bottom-up
                Get-ChildItem -Path $WpsPath -Recurse -Force -Directory -ErrorAction SilentlyContinue | 
                    Sort-Object { $_.FullName.Length } -Descending |
                    ForEach-Object { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue }

                # Remove root
                Remove-Item -Path $WpsPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Output "Cleaned up: $WpsPath"
            } catch {
                Write-Error "Failed to remove $WpsPath : $($_.Exception.Message)"
            }
        }
    }
}

# Registry cleanup
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

foreach ($Path in $RegistryPaths) {
    if (Test-Path $Path) {
        Get-ChildItem -Path $Path | ForEach-Object {
            $Props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if ($Props.DisplayName -like "*WPS Office*") {
                Write-Output "Removing registry key: $($_.PSPath)"
                Remove-Item -Path $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# Clean HKCU for each user (WPS stores per-user reg keys)
$UserSIDs = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" |
    Get-ItemProperty | Select-Object -ExpandProperty ProfileImagePath

foreach ($ProfilePath in $UserSIDs) {
    $SID = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | 
        Get-ItemProperty | Where-Object { $_.ProfileImagePath -eq $ProfilePath }).PSChildName
    if ($SID) {
        $HKU = "Registry::HKU\$SID\SOFTWARE\Kingsoft"
        if (Test-Path $HKU) {
            Remove-Item -Path $HKU -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "Removed HKU registry for SID: $SID"
        }
    }
}

# Final exit code for Intune
$criticalErrors = $Error | Where-Object { $_.CategoryInfo.Category -ne 'ObjectNotFound' }
if ($criticalErrors.Count -gt 0) { exit 1 } else { exit 0 }