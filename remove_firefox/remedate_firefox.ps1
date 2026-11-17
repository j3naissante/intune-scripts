$ErrorActionPreference = 'Continue'
$hadErrors = $false

$profiles = Get-CimInstance Win32_UserProfile |
    Where-Object {
        -not $_.Special -and
        $_.LocalPath -like 'C:\Users\*'
    }

foreach ($profile in $profiles) {

    $userPath = $profile.LocalPath
    Write-Output "Checking profile: $userPath"

    $firefoxDir = Join-Path $userPath 'AppData\Local\Mozilla Firefox'
    $firefoxExe = Join-Path $firefoxDir 'firefox.exe'
    $uninstaller = Join-Path $firefoxDir 'uninstall\helper.exe'

    $firefoxRoaming = Join-Path $userPath 'AppData\Roaming\Mozilla'
    $firefoxLocal = Join-Path $userPath 'AppData\Local\Mozilla'

    $startMenuPath = Join-Path $userPath 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs'
    $desktopPath = Join-Path $userPath 'Desktop'

    # Uninstall Firefox
    if (Test-Path -LiteralPath $uninstaller) {

        Write-Output "Uninstalling Firefox: $uninstaller"

        try {
            $process = Start-Process -FilePath $uninstaller `
                -ArgumentList '/S' `
                -Wait -PassThru -ErrorAction Stop

            Write-Output "Firefox uninstaller exit code: $($process.ExitCode)"

            if (-not (Test-Path -LiteralPath $firefoxExe)) {
                Write-Output "Firefox successfully uninstalled."
            }
            else {
                Write-Warning "Firefox executable still exists after uninstall."
                $hadErrors = $true
            }
        }
        catch {
            Write-Warning "Firefox uninstall failed: $_"
            $hadErrors = $true
        }
    }
    elseif (Test-Path -LiteralPath $firefoxExe) {
        Write-Warning "Firefox installed but uninstaller not found: $firefoxDir"
        $hadErrors = $true
    }
    else {
        Write-Output "Firefox not installed in this profile."
    }

    # Remove Firefox Roaming profile
    if (Test-Path -LiteralPath $firefoxRoaming) {

        Write-Output "Removing Firefox Roaming profile: $firefoxRoaming"

        try {
            Remove-Item -LiteralPath $firefoxRoaming `
                -Recurse -Force -ErrorAction Stop

            Write-Output "Firefox Roaming profile removed."
        }
        catch {
            Write-Warning "Failed to remove Firefox Roaming profile: $_"
            $hadErrors = $true
        }
    }

    # Remove Mozilla Local AppData folder
    if (Test-Path -LiteralPath $firefoxLocal) {

        Write-Output "Removing Mozilla Local folder: $firefoxLocal"

        try {
            Remove-Item -LiteralPath $firefoxLocal `
                -Recurse -Force -ErrorAction Stop

            Write-Output "Mozilla Local folder removed."
        }
        catch {
            Write-Warning "Failed to remove Mozilla Local folder: $_"
            $hadErrors = $true
        }
    }

    # Remove Start Menu shortcuts
    if (Test-Path -LiteralPath $startMenuPath) {

        Get-ChildItem -LiteralPath $startMenuPath `
            -Recurse -Filter '*Mozilla Firefox*.lnk' `
            -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    Write-Output "Removing Start Menu shortcut: $($_.FullName)"
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                }
                catch {
                    Write-Warning "Failed to remove shortcut: $_"
                    $hadErrors = $true
                }
            }
    }

    # Remove Desktop shortcuts
    if (Test-Path -LiteralPath $desktopPath) {

        Get-ChildItem -LiteralPath $desktopPath `
            -Filter '*Mozilla Firefox*.lnk' `
            -ErrorAction SilentlyContinue |
            ForEach-Object {
                try {
                    Write-Output "Removing desktop shortcut: $($_.FullName)"
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                }
                catch {
                    Write-Warning "Failed to remove shortcut: $_"
                    $hadErrors = $true
                }
            }
    }

    Write-Output "Finished processing: $userPath"
}

if ($hadErrors) {
    Write-Warning "Firefox cleanup completed with errors. Review output."
    exit 1
}
else {
    Write-Output "Firefox cleanup completed successfully."
    exit 0
}