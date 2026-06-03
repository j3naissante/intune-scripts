$log = "$env:TEMP\dism_check.log"

$check = Start-Process -FilePath "dism.exe" `
    -ArgumentList "/Online /Cleanup-Image /CheckHealth" `
    -NoNewWindow -Wait -PassThru -RedirectStandardOutput $log

$content = Get-Content $log -ErrorAction SilentlyContinue

if ($content -match "No component store corruption detected") {
    Write-Output "Healthy"
    exit 0
}
else {
    Write-Output "Corruption detected or unknown state"
    exit 1
}