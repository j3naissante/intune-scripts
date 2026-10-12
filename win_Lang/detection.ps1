$TaskName   = "Set Keyboard Languages"
$ScriptPath = "C:\ProgramData\KeyboardLanguages\Set-KeyboardLanguages.ps1"

$Task = Get-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

if ($Task -and (Test-Path $ScriptPath)) {
    Write-Output "Detected: Keyboard language task and script exist."
    exit 0
}

exit 1