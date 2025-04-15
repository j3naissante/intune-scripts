$languages = Get-WinUserLanguageList
$requiredLanguages = @("en-US", "et-EE", "ru-RU")
$missingLanguages = $requiredLanguages | Where-Object { $_ -notin $languages.LanguageTag }

if ($missingLanguages.Count -gt 0) {
    exit 1
} else {
    exit 0
}
