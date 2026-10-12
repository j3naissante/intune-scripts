$TaskName     = "Force Time Sync at Logon"
$TaskPath     = "\"
$InstallFolder = "C:\ProgramData\TimeSync"
$TaskFile     = "C:\Windows\System32\Tasks\$TaskName"

Unregister-ScheduledTask `
    -TaskName $TaskName `
    -TaskPath $TaskPath `
    -Confirm:$false `
    -ErrorAction SilentlyContinue

if (Test-Path $TaskFile) {
    Remove-Item $TaskFile -Force -ErrorAction SilentlyContinue
}

if (Test-Path $InstallFolder) {
    Remove-Item $InstallFolder -Recurse -Force -ErrorAction SilentlyContinue
}

exit 0