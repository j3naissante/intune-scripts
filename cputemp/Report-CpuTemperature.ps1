#requires -Version 5.1
param(
    [string]$LogPath = (Join-Path $env:ProgramData 'IntuneCpuTemperature\temperatures.csv'),
    [int]$StaleAfterMinutes = 5
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Add-TemperatureRecord {
    param([string]$Path, [psobject]$Record, [long]$MaxBytes)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $csv = @($Record | ConvertTo-Csv -NoTypeInformation)
    $header = $csv[0] + "`r`n"
    $line = $csv[1] + "`r`n"
    $required = $encoding.GetByteCount($header + $line)
    if ($required -gt $MaxBytes) { throw 'Log limit is smaller than one record.' }
    # Report and writer use the same mutex, including across log replacement.
    $mutex = New-Object System.Threading.Mutex($false, 'Global\IntuneCpuTemperatureLog')
    $locked = $false
    try {
        try { $locked = $mutex.WaitOne(30000) } catch [System.Threading.AbandonedMutexException] { $locked = $true }
        if (-not $locked) { throw 'Timed out waiting for the temperature log.' }
        if (Test-Path -LiteralPath $Path) {
            if ((Get-Item -LiteralPath $Path).Length + $encoding.GetByteCount($line) -gt $MaxBytes) {
                Remove-Item -LiteralPath $Path -Force
            }
        }
        if (-not (Test-Path -LiteralPath $Path)) { [IO.File]::WriteAllText($Path, $header, $encoding) }
        [IO.File]::AppendAllText($Path, $line, $encoding)
    } finally {
        if ($locked) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Read-TemperatureLog {
    param([string]$Path)
    $mutex = New-Object System.Threading.Mutex($false, 'Global\IntuneCpuTemperatureLog')
    $locked = $false
    try {
        try { $locked = $mutex.WaitOne(30000) } catch [System.Threading.AbandonedMutexException] { $locked = $true }
        if (-not $locked) { throw 'Timed out waiting for the temperature log.' }
        if (-not (Test-Path -LiteralPath $Path)) { throw 'Temperature log does not exist yet.' }
        $content = [IO.File]::ReadAllText($Path)
    } finally {
        if ($locked) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
    $content | ConvertFrom-Csv
}

try {
    $rows = @(Read-TemperatureLog -Path $LogPath)
    if ($rows.Count -eq 0) { throw 'Temperature log is empty.' }
    $culture = [Globalization.CultureInfo]::InvariantCulture
    $highest = $null
    $latest = $null
    $first = $null
    $samples = 0
    $errors = 0
    foreach ($row in $rows) {
        $time = [DateTimeOffset]::Parse($row.TimestampUtc, $culture)
        if ($null -eq $first -or $time -lt $first) { $first = $time }
        if ($null -eq $latest -or $time -ge $latest.Time) { $latest = @{ Time = $time; Row = $row } }
        if ($row.Status -eq 'OK') {
            $value = [double]::Parse($row.MaxCelsius, $culture)
            if ([double]::IsNaN($value) -or [double]::IsInfinity($value)) { throw 'Invalid temperature in log.' }
            $samples++
            if ($null -eq $highest -or $value -gt $highest.Value) { $highest = @{ Value = $value; Row = $row } }
        } else { $errors++ }
    }
    $state = 'OK'
    if ($latest.Time -gt [DateTimeOffset]::UtcNow.AddMinutes(5)) { $state = 'CLOCK_ERROR' }
    elseif ($latest.Time -lt [DateTimeOffset]::UtcNow.AddMinutes(-$StaleAfterMinutes)) { $state = 'STALE' }
    elseif ($latest.Row.Status -ne 'OK' -or $null -eq $highest) { $state = 'SENSOR_ERROR' }
    $peakText = 'MaxC=unavailable'
    if ($null -ne $highest) {
        $peakText = 'MaxC={0}; PeakUtc={1}; Sensor={2}' -f $highest.Value.ToString('F2', $culture), $highest.Row.TimestampUtc, $highest.Row.Sensor
    }
    $message = 'Status={0}; {1}; RetainedFromUtc={2}; LastRecordUtc={3}; Samples={4}; Errors={5}' -f $state, $peakText, $first.ToString('o'), $latest.Row.TimestampUtc, $samples, $errors
    if ($state -eq 'SENSOR_ERROR') { $message += '; Detail=' + $latest.Row.Detail }
    Write-Output $message.Substring(0, [Math]::Min(1900, $message.Length))
    if ($state -ne 'OK') { exit 1 }
    exit 0
} catch {
    $message = 'Status=UNAVAILABLE; ' + $_.Exception.Message
    Write-Output $message.Substring(0, [Math]::Min(1900, $message.Length))
    exit 1
}
