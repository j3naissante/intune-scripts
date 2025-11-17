# Get current user languages
$LanguageList = Get-WinUserLanguageList

# Spanish (Spain) language tag
$Spanish = "es-ES"

# Detection
if ($LanguageList.LanguageTag -contains $Spanish) {
    Write-Output "Compliant: Spanish (es-ES) is installed."
    exit 0   # Optional: exit code 0 = compliant
} else {
    Write-Output "Non-compliant: Spanish (es-ES) is not installed."
    exit 1   # Optional: exit code 1 = non-compliant
}
