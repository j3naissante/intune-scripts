# Detect-Viber.ps1
# Intune Proactive Remediation — DETECTION script
# Run as: SYSTEM
# 64-bit PowerShell: Yes
#
# Exit 0 = Compliant   (Viber not found)
# Exit 1 = Non-compliant (Viber found — triggers remediation)
# ─────────────────────────────────────────────────────────────

$ErrorActionPreference = "SilentlyContinue"

# Real user profiles only — exclude system stubs
$excludedProfiles = @("default", "default user", "public", "all users")
$userProfiles = Get-ChildItem "C:\Users" -Directory |
    Where-Object { $_.Name.ToLower() -notin $excludedProfiles }

function Test-ViberFiles {
    param([string]$ProfilePath)

    $localAppData  = Join-Path $ProfilePath "AppData\Local"
    $roamingAppData = Join-Path $ProfilePath "AppData\Roaming"

    $pathsToCheck = @(
        (Join-Path $localAppData   "Viber"),
        (Join-Path $localAppData   "ViberPC"),
        (Join-Path $roamingAppData "Viber"),
        (Join-Path $localAppData   "Viber\Viber.exe"),
        (Join-Path $localAppData   "ViberPC\Viber.exe"),
        (Join-Path $roamingAppData "Microsoft\Windows\Start Menu\Programs\Viber"),
        (Join-Path $roamingAppData "Microsoft\Windows\Start Menu\Programs\Viber.lnk"),
        (Join-Path $ProfilePath    "Desktop\Viber.lnk"),
        "$env:PUBLIC\Desktop\Viber.lnk"
    )

    foreach ($p in $pathsToCheck) {
        if (Test-Path $p) {
            Write-Output "DETECTED: $p"
            return $true
        }
    }
    return $false
}

function Test-ViberRegistry {
    $viberRegPaths = @(
        "Software\Viber Media S.a r.l.",
        "Software\Microsoft\Windows\CurrentVersion\Uninstall\Viber"
    )

    foreach ($profile in $userProfiles) {
        $ntuserPath = Join-Path $profile.FullName "NTUSER.DAT"
        if (-not (Test-Path $ntuserPath)) { continue }

        $hiveName = "VTMP_$($profile.Name)"
        $null = & reg load "HKU\$hiveName" $ntuserPath 2>&1

        foreach ($regPath in $viberRegPaths) {
            if (Test-Path "Registry::HKU\$hiveName\$regPath") {
                Write-Output "DETECTED: Registry key [$($profile.Name)]: $regPath"
                & reg unload "HKU\$hiveName" 2>&1 | Out-Null
                return $true
            }
        }

        # Check startup Run key
        $runKey = "Registry::HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Run"
        if ((Test-Path $runKey) -and
            (Get-ItemProperty -Path $runKey -Name "Viber" -ErrorAction SilentlyContinue)) {
            Write-Output "DETECTED: Viber startup entry [$($profile.Name)]"
            & reg unload "HKU\$hiveName" 2>&1 | Out-Null
            return $true
        }

        & reg unload "HKU\$hiveName" 2>&1 | Out-Null
    }
    return $false
}

# 1. Running process (SYSTEM can see all processes)
if (Get-Process -Name "Viber" -ErrorAction SilentlyContinue) {
    Write-Output "DETECTED: Viber process is running."
    exit 1
}

# 2. File system check across all profiles
foreach ($profile in $userProfiles) {
    if (Test-ViberFiles -ProfilePath $profile.FullName) {
        exit 1
    }
}

# 3. Registry check via hive mounting
if (Test-ViberRegistry) {
    exit 1
}

Write-Output "Compliant: No Viber artifacts found across any user profile."
exit 0