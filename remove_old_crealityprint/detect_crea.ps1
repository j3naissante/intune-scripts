$NewExe    = "C:\Program Files\Creality\Creality Print 7.1\CrealityPrint.exe"
$OldUnins  = "C:\Program Files\Creality\Creality Print 6.3\Uninstall.exe"

if ((Test-Path $NewExe) -and (Test-Path $OldUnins)) {
    Write-Output "Detected: Creality Print 7.1 present and 6.3 uninstaller found — remediation required."
    exit 1   
}

Write-Output "Not detected: no action required."
exit 0