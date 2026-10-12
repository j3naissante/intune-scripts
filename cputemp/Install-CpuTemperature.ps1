#requires -Version 5.1
#requires -RunAsAdministrator
param([ValidateSet('Install','Log','Uninstall')][string]$Mode = 'Install')
$ErrorActionPreference = 'Stop'
if (-not [Environment]::Is64BitProcess) { throw 'Use 64-bit Windows PowerShell.' }
$root = Join-Path $env:ProgramFiles 'IntuneCpuTemperature'
$data = Join-Path $env:ProgramData 'IntuneCpuTemperature'
$taskName = 'IntuneCpuTemperature'

function Stop-Logger {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Stop-ScheduledTask -TaskName $taskName
        for ($i = 0; $i -lt 30 -and (Get-ScheduledTask -TaskName $taskName).State -eq 'Running'; $i++) { Start-Sleep 1 }
        if ((Get-ScheduledTask -TaskName $taskName).State -eq 'Running') { throw 'Logger did not stop.' }
    }
}

if ($Mode -eq 'Uninstall') {
    Stop-Logger
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    foreach ($parent in @($env:ProgramFiles, $env:ProgramData)) {
        $target = [IO.Path]::GetFullPath((Join-Path $parent 'IntuneCpuTemperature'))
        if ([IO.Path]::GetDirectoryName($target) -ne [IO.Path]::GetFullPath($parent).TrimEnd('\')) { throw 'Unexpected removal path.' }
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
    }
    # Retain PawnIO because other applications can share it.
    exit 0
}

if ($Mode -eq 'Install') {
    Stop-Logger
    foreach ($path in @($root, $data)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        $acl = New-Object Security.AccessControl.DirectorySecurity
        $acl.SetAccessRuleProtection($true, $false)
        foreach ($sid in @('S-1-5-18', 'S-1-5-32-544')) {
            $identity = New-Object Security.Principal.SecurityIdentifier($sid)
            $rule = New-Object Security.AccessControl.FileSystemAccessRule($identity, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
            $acl.AddAccessRule($rule)
        }
        Set-Acl -LiteralPath $path -AclObject $acl
    }
    $marker = Join-Path $root 'simple-version.txt'
    if (Test-Path $marker) { Remove-Item -LiteralPath $marker -Force }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $zip = Join-Path $root 'LibreHardwareMonitor.zip'
    Invoke-WebRequest -UseBasicParsing 'https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/releases/download/v0.9.6/LibreHardwareMonitor.zip' -OutFile $zip
    if ((Get-FileHash $zip -Algorithm SHA256).Hash -ne '086D9F1B5A99E643EDC2CFAAAC16051685B551E4C5AC0B32A57C58C0E529C001') { throw 'Library checksum mismatch.' }
    Expand-Archive -LiteralPath $zip -DestinationPath "$root\lib" -Force
    foreach ($notice in @('LICENSE', 'THIRD-PARTY-NOTICES.txt')) {
        Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/LibreHardwareMonitor/LibreHardwareMonitor/v0.9.6/$notice" -OutFile "$root\lib\$notice"
    }
    Set-Content "$root\lib\SOURCE.txt" 'Source: https://github.com/LibreHardwareMonitor/LibreHardwareMonitor/tree/v0.9.6'
    $exitCode = 0
    # Preserve a newer installed PawnIO; otherwise install/upgrade to the pinned version.
    $pawnVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PawnIO' -ErrorAction SilentlyContinue).DisplayVersion
    if (-not $pawnVersion -or [version]$pawnVersion -lt [version]'2.2.0' -or -not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\PawnIO')) {
        $setup = Join-Path $root 'PawnIO_setup.exe'
        Invoke-WebRequest -UseBasicParsing 'https://github.com/namazso/PawnIO.Setup/releases/download/2.2.0/PawnIO_setup.exe' -OutFile $setup
        if ((Get-FileHash $setup -Algorithm SHA256).Hash -ne '1F519A22E47187F70A1379A48CA604981C4FCF694F4E65B734AAA74A9FBA3032') { throw 'PawnIO checksum mismatch.' }
        $process = Start-Process -FilePath $setup -ArgumentList '-install','-silent' -WindowStyle Hidden -Wait -PassThru
        if ($process.ExitCode -notin @(0,3010)) { throw "PawnIO failed with exit code $($process.ExitCode)." }
        $exitCode = $process.ExitCode
    }
    if (-not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\PawnIO')) { throw 'PawnIO driver registration missing.' }
    $installedScript = Join-Path $root 'Install-CpuTemperature.ps1'
    if ($PSCommandPath -ne $installedScript) { Copy-Item -LiteralPath $PSCommandPath -Destination $installedScript -Force }
    Get-ChildItem "$root\lib" -File -Recurse | Unblock-File
    $action = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" -Mode Log' -f $installedScript) -WorkingDirectory $root
    $triggers = @((New-ScheduledTaskTrigger -AtStartup), (New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5)))
    $principal = New-ScheduledTaskPrincipal -UserId SYSTEM -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -Hidden -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers -Principal $principal -Settings $settings -Force | Out-Null
    Start-ScheduledTask -TaskName $taskName
    Set-Content $marker '2.0.0'
    Write-Output 'Installed temperature logger and dependencies.'
    exit $exitCode
}

# Background logger follows. Change interval and size here before packaging.
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

$interval = 60
$maxBytes = 10MB
$logPath = Join-Path $env:ProgramData 'IntuneCpuTemperature\temperatures.csv'
$culture = [Globalization.CultureInfo]::InvariantCulture
$computer = $null

function Get-CpuReadings {
    param($Hardware)
    $Hardware.Update()
    foreach ($sensor in $Hardware.Sensors) {
        if ($sensor.SensorType.ToString() -eq 'Temperature' -and $null -ne $sensor.Value) {
            $value = [double]$sensor.Value
            if (-not [double]::IsNaN($value) -and -not [double]::IsInfinity($value)) {
                [pscustomobject]@{ Value = $value; Sensor = [string]$sensor.Name; Cpu = [string]$Hardware.Name }
            }
        }
    }
    foreach ($child in $Hardware.SubHardware) { Get-CpuReadings $child }
}

try {
    do {
        $record = [ordered]@{ TimestampUtc = [DateTime]::UtcNow.ToString('o'); MaxCelsius = ''; Cpu = ''; Sensor = ''; Status = 'OK'; Detail = '' }
        try {
            if ($null -eq $computer) {
                Add-Type -Path "$PSScriptRoot\lib\LibreHardwareMonitorLib.dll"
                $computer = New-Object LibreHardwareMonitor.Hardware.Computer
                $computer.IsCpuEnabled = $true
                $computer.Open()
            }
            $readings = @(foreach ($hardware in $computer.Hardware) {
                if ($hardware.HardwareType.ToString() -eq 'Cpu') { Get-CpuReadings $hardware }
            })
            if ($readings.Count -eq 0) { throw 'No CPU temperature sensors. Check hardware support and the signed PawnIO driver.' }
            $peak = $readings | Sort-Object Value -Descending | Select-Object -First 1
            $record.MaxCelsius = $peak.Value.ToString('F2', $culture)
            $record.Cpu = $peak.Cpu
            $record.Sensor = $peak.Sensor
        } catch {
            $record.Status = 'ERROR'
            $detail = $_.Exception.Message -replace '[\r\n]+', ' '
            $record.Detail = $detail.Substring(0, [Math]::Min(500, $detail.Length))
            if ($null -ne $computer) { try { $computer.Close() } catch { }; $computer = $null }
        }
        Add-TemperatureRecord -Path $logPath -Record ([pscustomobject]$record) -MaxBytes $maxBytes
        if ($true) { Start-Sleep -Seconds $interval }
    } while ($true)
} finally {
    if ($null -ne $computer) { $computer.Close() }
}

