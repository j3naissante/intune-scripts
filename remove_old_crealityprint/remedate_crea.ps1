$NewExe    = "C:\Program Files\Creality\Creality Print 7.1\CrealityPrint.exe"
$OldUnins  = "C:\Program Files\Creality\Creality Print 6.3\Uninstall.exe"

if (-not (Test-Path $NewExe)) {
    Write-Output "Creality Print 7.1 not found — nothing to do."
    exit 0
}

if (-not (Test-Path $OldUnins)) {
    Write-Output "Creality Print 6.3 uninstaller not found — already removed."
    exit 0
}

Write-Output "Running silent uninstall of Creality Print 6.3..."

try {
    $proc = Start-Process -FilePath $OldUnins -ArgumentList "/S" -Wait -PassThru -ErrorAction Stop

    if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
        Write-Output "Uninstall completed successfully (exit code $($proc.ExitCode))."
        exit 0
    } else {
        Write-Output "Uninstaller returned unexpected exit code: $($proc.ExitCode)."
        exit 1
    }
} catch {
    Write-Output "Uninstall failed: $_"
    exit 1
}