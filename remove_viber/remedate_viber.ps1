# Remediate-Viber.ps1
# Intune Proactive Remediation — REMEDIATION script
# Run as: SYSTEM | 64-bit PowerShell: Yes
#
# Exit 0 = Remediation succeeded
# Exit 1 = Remediation failed (Intune will retry on next check-in)
#
# OneDrive - Tallinna Koolid KFM:
#   Desktop   → redirected to OneDrive (Töölaud)
#   Start Menu → stays in AppData\Roaming (not redirected)
# ─────────────────────────────────────────────────────────────

$ErrorActionPreference = "SilentlyContinue"
$failed = 0

$excludedProfiles = @("default", "default user", "public", "all users")
$userProfiles = Get-ChildItem "C:\Users" -Directory |
    Where-Object { $_.Name.ToLower() -notin $excludedProfiles }

# ── Helper: force-remove a path (file or folder) ─────────────
function Remove-ItemForcefully {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }

    try {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
        Write-Output "OK: Removed: $Path"
    } catch {
        if (Test-Path $Path -PathType Container) {
            & cmd /c "rd /s /q `"$Path`"" 2>&1 | Out-Null
        } else {
            & cmd /c "del /f /q `"$Path`"" 2>&1 | Out-Null
        }

        if (Test-Path $Path) {
            Write-Output "ERROR: Could not remove: $Path"
            $script:failed++
        } else {
            Write-Output "OK: Removed (via cmd): $Path"
        }
    }
}

# ══════════════════════════════════════════════════════════════
# 1. Kill Viber processes
# ══════════════════════════════════════════════════════════════
$procs = Get-Process -Name "Viber" -ErrorAction SilentlyContinue
if ($procs) {
    $procs | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force -ErrorAction Stop
            Write-Output "OK: Killed Viber PID $($_.Id)"
        } catch {
            Write-Output "WARN: Could not kill PID $($_.Id): $_"
        }
    }
    Start-Sleep -Seconds 3
} else {
    Write-Output "INFO: No running Viber processes."
}

# ══════════════════════════════════════════════════════════════
# 2. Remove files, folders and shortcuts per user profile
# ══════════════════════════════════════════════════════════════
foreach ($profile in $userProfiles) {
    $localAppData   = Join-Path $profile.FullName "AppData\Local"
    $roamingAppData = Join-Path $profile.FullName "AppData\Roaming"
    $oneDrivePath   = Join-Path $profile.FullName "OneDrive - Tallinna Koolid"

    $targets = [System.Collections.Generic.List[string]]@(
        # Core install folders
        (Join-Path $localAppData   "Viber"),
        (Join-Path $localAppData   "ViberPC"),
        (Join-Path $roamingAppData "Viber"),

        # Start Menu — confirmed in Roaming, not redirected by KFM
        (Join-Path $roamingAppData "Microsoft\Windows\Start Menu\Programs\Viber.lnk"),
        (Join-Path $roamingAppData "Microsoft\Windows\Start Menu\Programs\Viber"),

        # Desktop — standard (non-redirected)
        (Join-Path $profile.FullName "Desktop\Viber.lnk")
    )

    # Desktop — OneDrive KFM redirect (Estonian: Töölaud, English fallback: Desktop)
    if (Test-Path $oneDrivePath) {
        $targets.Add((Join-Path $oneDrivePath "Töölaud\Viber.lnk"))
        $targets.Add((Join-Path $oneDrivePath "Desktop\Viber.lnk"))
    }

    $profileHasViber = $false
    foreach ($t in $targets) {
        if (Test-Path $t) { $profileHasViber = $true; break }
    }

    if (-not $profileHasViber) {
        Write-Output "INFO: No Viber artifacts in profile: $($profile.Name)"
        continue
    }

    Write-Output "INFO: Remediating profile: $($profile.Name)"

    foreach ($t in $targets) {
        Remove-ItemForcefully -Path $t
    }

    # ── Registry cleanup ──────────────────────────────────────
    $ntuserPath = Join-Path $profile.FullName "NTUSER.DAT"
    if (-not (Test-Path $ntuserPath)) { continue }

    $hiveName = "VREM_$($profile.Name)"
    $null = & reg load "HKU\$hiveName" $ntuserPath 2>&1
    $mounted = $false

    if ($LASTEXITCODE -eq 0) {
        $hiveBase = "Registry::HKU\$hiveName"
        $mounted  = $true
    } else {
        try {
            $sid = (New-Object System.Security.Principal.NTAccount($profile.Name)).Translate(
                        [System.Security.Principal.SecurityIdentifier]).Value
            $liveHive = "Registry::HKU\$sid"
            if (Test-Path $liveHive) {
                $hiveBase = $liveHive
                Write-Output "INFO: Using live hive for: $($profile.Name)"
            } else {
                Write-Output "WARN: Could not access hive for: $($profile.Name)"
                continue
            }
        } catch {
            Write-Output "WARN: SID lookup failed for: $($profile.Name)"
            continue
        }
    }

    $regKeysToRemove = @(
        "Software\Viber Media S.a r.l.",
        "Software\Microsoft\Windows\CurrentVersion\Uninstall\Viber"
    )

    foreach ($regPath in $regKeysToRemove) {
        $fullKey = "$hiveBase\$regPath"
        if (Test-Path $fullKey) {
            try {
                Remove-Item -Path $fullKey -Recurse -Force -ErrorAction Stop
                Write-Output "OK: Removed registry key [$($profile.Name)]: $regPath"
            } catch {
                Write-Output "ERROR: Registry key removal failed [$($profile.Name)]: $regPath — $_"
                $failed++
            }
        }
    }

    $runKey = "$hiveBase\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $runKey) {
        if (Get-ItemProperty -Path $runKey -Name "Viber" -ErrorAction SilentlyContinue) {
            try {
                Remove-ItemProperty -Path $runKey -Name "Viber" -Force -ErrorAction Stop
                Write-Output "OK: Removed startup entry [$($profile.Name)]"
            } catch {
                Write-Output "ERROR: Startup entry removal failed [$($profile.Name)]: $_"
                $failed++
            }
        }
    }

    if ($mounted) {
        [GC]::Collect()
        Start-Sleep -Milliseconds 500
        & reg unload "HKU\$hiveName" 2>&1 | Out-Null
    }
}

# Public Desktop (never redirected by OneDrive KFM)
Remove-ItemForcefully -Path "$env:PUBLIC\Desktop\Viber.lnk"

# ══════════════════════════════════════════════════════════════
# 3. Exit
# ══════════════════════════════════════════════════════════════
if ($failed -gt 0) {
    Write-Output "RESULT: Remediation finished with $failed error(s). Intune will retry."
    exit 1
} else {
    Write-Output "RESULT: Viber fully removed from all user profiles."
    exit 0
}