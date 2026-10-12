$dir    = "C:\ProgramData\Remediation"
$marker = Join-Path $dir "dism_done.txt"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

DISM.exe /Online /Cleanup-Image /RestoreHealth /LogPath:"$dir\DISM.log"
$exitCode = $LASTEXITCODE

if ($exitCode -in 0, 3010) {
    Set-Content -Path $marker -Value "Completed $(Get-Date -Format s), exit $exitCode"
    Write-Output "DISM RestoreHealth completed (exit $exitCode)."
    exit 0
}

Write-Output "DISM RestoreHealth failed. Exit code: $exitCode"
exit 1