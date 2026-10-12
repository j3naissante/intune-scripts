$ErrorActionPreference = "Stop"

$InstallFolder = "C:\ProgramData\TimeSync"
$ScriptPath    = "$InstallFolder\TimeSync.ps1"
$TaskName      = "Force Time Sync at Logon"
$TaskPath      = "\"
$TaskFile      = "C:\Windows\System32\Tasks\$TaskName"

try {

    # Create local folder
    if (-not (Test-Path $InstallFolder)) {
        New-Item -Path $InstallFolder -ItemType Directory -Force | Out-Null
    }

    # Create the actual sync script
    $TimeSyncScript = @'
$ErrorActionPreference = "Stop"

try {
    $Service = Get-Service -Name "W32Time"

    if ($Service.Status -ne "Running") {
        Start-Service -Name "W32Time"
        Start-Sleep -Seconds 2
    }

    & "$env:SystemRoot\System32\w32tm.exe" /resync /force

    exit 0
}
catch {
    exit 1
}
'@

    Set-Content `
        -Path $ScriptPath `
        -Value $TimeSyncScript `
        -Encoding UTF8 `
        -Force

    if (-not (Test-Path $ScriptPath)) {
        throw "Failed to create $ScriptPath"
    }

    # Remove properly registered old task, if present
    $ExistingTask = Get-ScheduledTask `
        -TaskName $TaskName `
        -TaskPath $TaskPath `
        -ErrorAction SilentlyContinue

    if ($ExistingTask) {
        Unregister-ScheduledTask `
            -TaskName $TaskName `
            -TaskPath $TaskPath `
            -Confirm:$false `
            -ErrorAction Stop
    }

    # If an orphaned task file exists, remove it
    if (
        (Test-Path $TaskFile) -and
        -not (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)
    ) {
        Remove-Item `
            -Path $TaskFile `
            -Force `
            -ErrorAction Stop
    }

    # Task action
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

    # Trigger at every real user logon
    $Trigger = New-ScheduledTaskTrigger -AtLogOn

    # Run as SYSTEM
    $Principal = New-ScheduledTaskPrincipal `
        -UserId "SYSTEM" `
        -LogonType ServiceAccount `
        -RunLevel Highest

    # Task settings
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    # Register task
    Register-ScheduledTask `
        -TaskName $TaskName `
        -TaskPath $TaskPath `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings `
        -Description "Forces Windows time synchronization at user logon." `
        -Force `
        -ErrorAction Stop | Out-Null

    # Verify registration
    $CreatedTask = Get-ScheduledTask `
        -TaskName $TaskName `
        -TaskPath $TaskPath `
        -ErrorAction SilentlyContinue

    if (-not $CreatedTask) {
        throw "Scheduled task was not registered successfully."
    }

    Write-Output "TimeSync installed successfully."
    exit 0
}
catch {
    Write-Error "INSTALL FAILED: $($_.Exception.Message)"
    exit 1
}