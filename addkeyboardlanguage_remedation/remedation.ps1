
# Define required languages and their keyboard InputTips
$RequiredLangs = @{
    "en-US" = "0409:00000409"  # English US
    "ru-RU" = "0419:00000419"  # Russian
    "et-EE" = "0425:00000425"  # Estonian
}

# Define log file
$LogPath = "C:\ProgramData\LanguageRemediation.log"

# Function to log messages
function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "$Timestamp - $Message"
}

Write-Log "===== Language Remediation Script Started ====="

try {
    # Preserve current UI language
    $CurrentUILang = Get-WinUILanguageOverride
    if (-not $CurrentUILang) {
        $CurrentUILang = (Get-WinUserLanguageList)[0].LanguageTag
    }
    Write-Log "Current UI language: $CurrentUILang"

    # Get current user language list
    $LanguageList = Get-WinUserLanguageList
    $CurrentLangs = $LanguageList.LanguageTag
    Write-Log "Current languages: $($CurrentLangs -join ', ')"

    # Add missing languages with keyboards
    foreach ($Lang in $RequiredLangs.Keys) {
        if ($CurrentLangs -notcontains $Lang) {
            Write-Log "Adding language: $Lang"
            $NewLang = New-WinUserLanguageList $Lang
            $NewLang[0].InputMethodTips.Add($RequiredLangs[$Lang])
            $LanguageList.AddRange($NewLang)
        } else {
            # Ensure keyboard is present
            $LangObj = $LanguageList | Where-Object LanguageTag -eq $Lang
            if (-not ($LangObj.InputMethodTips -contains $RequiredLangs[$Lang])) {
                Write-Log "Adding missing keyboard for $Lang"
                $LangObj.InputMethodTips.Add($RequiredLangs[$Lang])
            } else {
                Write-Log "Language $Lang already has keyboard installed"
            }
        }
    }

    # Apply updated language list
    Set-WinUserLanguageList $LanguageList -Force
    Write-Log "Updated language list applied"

    # Reapply UI language override
    Set-WinUILanguageOverride -Language $CurrentUILang
    Write-Log "UI language override reapplied ($CurrentUILang)"

    # Set default input method to et-EE
    Set-WinDefaultInputMethodOverride -InputTip $RequiredLangs["et-EE"]
    Write-Log "Default input method set to et-EE ($($RequiredLangs["et-EE"]))"

    # Verification: log final languages and keyboards
    $FinalLangs = Get-WinUserLanguageList | Select-Object LanguageTag, InputMethodTips
    Write-Log "Final languages and keyboards:"
    foreach ($lang in $FinalLangs) {
        Write-Log "$($lang.LanguageTag) -> $($lang.InputMethodTips -join ', ')"
    }

    # Verify default input method
    $CurrentInputMethod = Get-WinDefaultInputMethodOverride
    Write-Log "Current default input method: $CurrentInputMethod"

    Write-Log "===== Language Remediation Script Completed Successfully ====="
    exit 0
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
