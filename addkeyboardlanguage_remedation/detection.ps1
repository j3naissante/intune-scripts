# Detection Script: Checks if en-US, ru-RU, and et-EE are present

$RequiredLangs = @("en-US", "ru-RU", "et-EE")
$CurrentLangs = (Get-WinUserLanguageList).LanguageTag

$MissingLangs = $RequiredLangs | Where-Object { $_ -notin $CurrentLangs }

if ($MissingLangs.Count -eq 0) {
    Write-Host "Compliant: All required languages ($RequiredLangs) are present."
    exit 0
} else {
    Write-Host "Non-compliant: Missing languages - $MissingLangs"
    exit 1
}
