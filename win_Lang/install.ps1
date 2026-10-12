$ErrorActionPreference = "Stop"

$FolderPath = "C:\ProgramData\KeyboardLanguages"
$ScriptPath = "$FolderPath\Set-KeyboardLanguages.ps1"
$TaskName   = "Set Keyboard Languages"


if (-not (Test-Path $FolderPath)) {
    New-Item -Path $FolderPath -ItemType Directory -Force | Out-Null
}


$LanguageScript = @'
$ErrorActionPreference = "SilentlyContinue"

$LanguageList = Get-WinUserLanguageList
$InstalledLanguages = @($LanguageList.LanguageTag)

Write-Output "Current user: $env:USERNAME"
Write-Output "Current languages: $($InstalledLanguages -join ', ')"

$Changed = $false


# ------------------------------------------------------------
# English
# Accept en-US
# ------------------------------------------------------------

if ($InstalledLanguages -notcontains "en-US") {

    Write-Output "Adding English (en-US)"
    $LanguageList.Add("en-US")
    $Changed = $true
}
else {
    Write-Output "English is already present."
}


# ------------------------------------------------------------
# Estonian
# Windows may report this as et or et-EE
# ------------------------------------------------------------

$EstonianInstalled = $InstalledLanguages | Where-Object {
    $_ -eq "et" -or $_ -eq "et-EE"
}

if (-not $EstonianInstalled) {

    Write-Output "Adding Estonian (et-EE)"
    $LanguageList.Add("et-EE")
    $Changed = $true
}
else {
    Write-Output "Estonian is already present."
}


# ------------------------------------------------------------
# Russian
# Windows may report this as ru or ru-RU
# ------------------------------------------------------------

$RussianInstalled = $InstalledLanguages | Where-Object {
    $_ -eq "ru" -or $_ -eq "ru-RU"
}

if (-not $RussianInstalled) {

    Write-Output "Adding Russian (ru-RU)"
    $LanguageList.Add("ru-RU")
    $Changed = $true
}
else {
    Write-Output "Russian is already present."
}


# ------------------------------------------------------------
# Apply only if something was missing
# ------------------------------------------------------------

if ($Changed) {

    Write-Output "Applying updated keyboard language list..."

    Set-WinUserLanguageList `
        -LanguageList $LanguageList `
        -Force

    $UpdatedLanguages = @(
        (Get-WinUserLanguageList).LanguageTag
    )

    Write-Output "Updated languages: $($UpdatedLanguages -join ', ')"
}
else {
    Write-Output "All required keyboard languages are already present. No changes required."
}

exit 0
'@

Set-Content `
    -Path $ScriptPath `
    -Value $LanguageScript `
    -Encoding UTF8 `
    -Force


$ExistingTask = Get-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false
}


$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger -AtLogOn

$Principal = New-ScheduledTaskPrincipal `
    -GroupId "BUILTIN\Users" `
    -RunLevel Limited

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description "Ensures en-US, Estonian and Russian keyboard languages are configured for each user." `
    -Force | Out-Null


Write-Output "Keyboard language scheduled task installed successfully."
Write-Output "Script: $ScriptPath"
Write-Output "Task: $TaskName"

exit 0