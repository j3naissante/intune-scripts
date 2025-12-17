$MaxDriftSeconds = 5

# Check Windows Time service
$w32time = Get-Service -Name w32time -ErrorAction SilentlyContinue
if ($null -eq $w32time -or $w32time.Status -ne 'Running') {
    Write-Output "Windows Time service not running"
    exit 1
}

# Get time offset
$timeStatus = w32tm /query /status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Output "Time status query failed"
    exit 1
}

$offsetLine = $timeStatus | Select-String "Clock offset"
if ($offsetLine) {
    $offset = [math]::Abs(
        ($offsetLine -replace '.*:\s*','' -replace 's','')
    )

    if ($offset -gt $MaxDriftSeconds) {
        Write-Output "Time drift detected: $offset seconds"
        exit 1
    }
}

Write-Output "Time is synchronized"
exit 0
