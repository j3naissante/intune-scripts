$Task = Get-ScheduledTask `
    -TaskName "Force Time Sync at Logon" `
    -TaskPath "\" `
    -ErrorAction SilentlyContinue

if ($Task) {
    Write-Output "Detected"
    exit 0
}

exit 1