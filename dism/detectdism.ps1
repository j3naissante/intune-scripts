$marker = "C:\ProgramData\Remediation\dism_done.txt"

if (Test-Path $marker) {
    Write-Output "DISM RestoreHealth already completed."
    exit 0
}

Write-Output "DISM RestoreHealth not yet run."
exit 1