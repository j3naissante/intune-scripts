

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    [Console]::Error.WriteLine("$timestamp  $Message")
}

Write-Log "===== Vivaldi Remediation Start ====="
Write-Log "User: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Log "PS arch: $([IntPtr]::Size * 8)-bit"

$anyError = $false

try {
    $procs = Get-Process -Name "vivaldi*" -ErrorAction SilentlyContinue
    if ($procs) {
        Write-Log "Killing $($procs.Count) Vivaldi process(es)..."
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        Write-Log "Processes killed."
    } else {
        Write-Log "No Vivaldi processes running."
    }
} catch {
    Write-Log "WARNING: Error killing processes - $($_.Exception.Message)"
}

Write-Log "--- Scanning user profiles ---"
$userProfiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
Write-Log "Profiles: $($userProfiles.Name -join ', ')"

foreach ($profile in $userProfiles) {
    $vivaldiPath = Join-Path $profile.FullName "AppData\Local\Vivaldi"

    if (-not (Test-Path $vivaldiPath)) {
        Write-Log "Not present: $vivaldiPath"
        continue
    }

    Write-Log "Found: $vivaldiPath — removing..."

    # Suppress all output from takeown/icacls - their stderr noise causes Intune to flag as failed
    & takeown.exe /F "$vivaldiPath" /R /D Y 2>$null | Out-Null
    & icacls.exe "$vivaldiPath" /grant "SYSTEM:(OI)(CI)F" /T /Q 2>$null | Out-Null
    Write-Log "Ownership and permissions set."

    try {
        Remove-Item -Path $vivaldiPath -Recurse -Force -ErrorAction Stop
        Write-Log "SUCCESS: Removed $vivaldiPath"
    } catch {
        Write-Log "Remove-Item failed: $($_.Exception.Message) — trying rd..."
        & cmd.exe /c "rd /s /q `"$vivaldiPath`"" 2>$null | Out-Null

        if (Test-Path $vivaldiPath) {
            Write-Log "ERROR: $vivaldiPath still exists after all attempts."
            $anyError = $true
        } else {
            Write-Log "SUCCESS (rd fallback): Removed $vivaldiPath"
        }
    }
}


Write-Log "--- Scheduled tasks ---"

try {
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue |
             Where-Object { $_.TaskName -like "VivaldiUpdateCheck*" }

    if ($tasks) {
        foreach ($task in $tasks) {
            Write-Log "Found task: '$($task.TaskPath)$($task.TaskName)'"
            try {
                Unregister-ScheduledTask -TaskName $task.TaskName `
                    -TaskPath $task.TaskPath -Confirm:$false -ErrorAction Stop
                Write-Log "SUCCESS: Removed task '$($task.TaskName)'"
            } catch {
                Write-Log "ERROR: Could not remove '$($task.TaskName)' - $($_.Exception.Message)"
                $anyError = $true
            }
        }
    } else {
        Write-Log "No VivaldiUpdateCheck tasks found via Get-ScheduledTask."
    }
} catch {
    Write-Log "WARNING: Get-ScheduledTask failed - $($_.Exception.Message)"
}

# schtasks.exe sweep fallback
try {
    $raw = & schtasks.exe /query /fo LIST 2>$null
    $matchLines = ($raw | Select-String "TaskName:.*VivaldiUpdateCheck")
    foreach ($match in $matchLines) {
        $taskName = ($match.Line -replace "TaskName:\s*", "").Trim()
        Write-Log "Found via schtasks: '$taskName'"
        & schtasks.exe /delete /tn "$taskName" /f 2>$null | Out-Null
        Write-Log "schtasks delete issued for: $taskName"
    }
} catch {
    Write-Log "WARNING: schtasks sweep failed - $($_.Exception.Message)"
}

Write-Log "--- Registry ---"
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tree\Vivaldi",
    "HKLM:\SOFTWARE\WOW6432Node\Vivaldi",
    "HKLM:\SOFTWARE\Vivaldi"
)

foreach ($reg in $regPaths) {
    if (Test-Path $reg) {
        try {
            Remove-Item -Path $reg -Recurse -Force -ErrorAction Stop
            Write-Log "Removed registry: $reg"
        } catch {
            Write-Log "WARNING: Could not remove $reg - $($_.Exception.Message)"
        }
    } else {
        Write-Log "Not present: $reg"
    }
}

Write-Log "===== Done — AnyError: $anyError ====="

if ($anyError) {
    exit 1
} else {
    exit 0
}