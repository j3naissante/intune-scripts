# Get current user languages
$LanguageList = Get-WinUserLanguageList

# Spanish (Spain) language tag
$Spanish = "es-ES"

# Remediation
if (-not ($LanguageList.LanguageTag -contains $Spanish)) {
    $LanguageList.Add($Spanish)
    Set-WinUserLanguageList $LanguageList -Force
    Write-Output "Spanish (es-ES) has been added."
} else {
    Write-Output "Spanish (es-ES) is already installed. No changes made."
}
