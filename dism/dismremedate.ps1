# Remediation Script (simplest)

$logPath = "$env:TEMP\dism_restorehealth.log"

dism.exe /online /cleanup-image /restorehealth *>&1 | Out-File -FilePath $logPath -Encoding utf8

Write-Output "DISM completed. Log: $logPath"
exit 0