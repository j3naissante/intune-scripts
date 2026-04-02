
$detected = $false
$reasons  = @()

$userProfiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue

foreach ($profile in $userProfiles) {
    $vivaldiPath = Join-Path $profile.FullName "AppData\Local\Vivaldi\Application"
    if (Test-Path $vivaldiPath) {
        $detected = $true
        $reasons += "Vivaldi folder found: $vivaldiPath"
    }
}

try {
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
             Where-Object { $_.TaskName -like "VivaldiUpdateCheck*" }

    foreach ($task in $tasks) {
        $detected = $true
        $reasons += "Scheduled task found: $($task.TaskName)"
    }
} catch {
    $reasons += "Warning: Could not query scheduled tasks - $($_.Exception.Message)"
}

if ($detected) {
    Write-Output "NON-COMPLIANT: $($reasons -join ' | ')"
    exit 1
} else {
    Write-Output "COMPLIANT: Vivaldi not detected."
    exit 0
}