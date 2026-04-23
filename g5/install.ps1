$LogPath = "C:\ProgramData\HP\DockFirmware\install.log"
New-Item -ItemType Directory -Force -Path (Split-Path $LogPath) | Out-Null

function Write-Log {
    param($Message)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Add-Content -Path $LogPath -Value $entry
}

Write-Log "Extracting softpaq..."
Start-Process -FilePath "$PSScriptRoot\sp165907.exe" -ArgumentList "-e -s" -Wait

Write-Log "Running firmware updater silently..."
$result = Start-Process -FilePath "C:\SWSetup\sp165907\HPFirmwareInstaller.exe" -ArgumentList "-s -f" -Wait -PassThru

Write-Log "Exit code: $($result.ExitCode)"

# Exit code 0 = success, 3 = already up to date
if ($result.ExitCode -eq 0 -or $result.ExitCode -eq 3) {
    Write-Log "Success - cleaning up SWSetup folder..."
    Remove-Item -Path "C:\SWSetup\sp165907" -Recurse -Force
    Write-Log "Cleanup done"
} else {
    Write-Log "Update failed - skipping cleanup for troubleshooting"
}

exit $result.ExitCode