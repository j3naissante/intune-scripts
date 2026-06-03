<#
.SYNOPSIS
    Installs WinGet (App Installer) and its dependencies, then installs PowerShell 7.
.NOTES
    Exit 0 = Success
    Exit 1 = Failure
#>

#region --- Config ---
$workDir  = "C:\ProgramData\WingetRemediation"
$logFile  = "$workDir\remediation.log"
$ProgressPreference = 'SilentlyContinue'
#endregion

#region --- Logging ---
function Write-Log {
    param([string]$Message, [ValidateSet("INFO","WARN","ERROR")][string]$Level = "INFO")
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Write-Output $entry
    Add-Content -Path $logFile -Value $entry
}
#endregion

#region --- Helpers ---
function Wait-ForCondition {
    param(
        [scriptblock]$Condition,
        [int]$TimeoutSeconds = 60,
        [int]$IntervalSeconds = 5,
        [string]$Description = "condition"
    )
    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        if (& $Condition) { return $true }
        Write-Log "Waiting for $Description... ($elapsed/$TimeoutSeconds s)" "INFO"
        Start-Sleep -Seconds $IntervalSeconds
        $elapsed += $IntervalSeconds
    }
    return $false
}

function Get-WingetExe {
    $paths = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" `
        -ErrorAction SilentlyContinue
    if ($paths) {
        return ($paths | Sort-Object Path | Select-Object -Last 1).Path
    }
    return $null
}
#endregion

#region --- Main ---
try {
    # Setup
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    Write-Log "Starting WinGet remediation. Work dir: $workDir"

    # --- Step 1: Download dependencies ---
    Write-Log "Downloading WinGet dependencies..."

    $downloads = @(
        @{
            Uri     = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
            OutFile = "$workDir\Microsoft.VCLibs.x64.14.00.Desktop.appx"
            Name    = "VCLibs"
        },
        @{
            Uri     = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
            OutFile = "$workDir\Microsoft.UI.Xaml.2.8.x64.appx"
            Name    = "UI.Xaml 2.8"
        },
        @{
            Uri     = "https://aka.ms/getwinget"
            OutFile = "$workDir\Microsoft.DesktopAppInstaller.msixbundle"
            Name    = "WinGet (App Installer)"
        }
    )

    foreach ($dl in $downloads) {
        Write-Log "Downloading $($dl.Name)..."
        Invoke-WebRequest -Uri $dl.Uri -OutFile $dl.OutFile -UseBasicParsing
        if (-not (Test-Path $dl.OutFile)) {
            throw "Download failed for $($dl.Name)"
        }
        Write-Log "Downloaded $($dl.Name) OK."
    }

    # --- Step 2: Install dependencies ---
    Write-Log "Installing VCLibs (failure OK if already present)..."
    Add-AppxProvisionedPackage -Online `
        -PackagePath "$workDir\Microsoft.VCLibs.x64.14.00.Desktop.appx" `
        -SkipLicense -ErrorAction SilentlyContinue | Out-Null

    Write-Log "Installing UI.Xaml 2.8 (failure OK if already present)..."
    Add-AppxProvisionedPackage -Online `
        -PackagePath "$workDir\Microsoft.UI.Xaml.2.8.x64.appx" `
        -SkipLicense -ErrorAction SilentlyContinue | Out-Null

    Write-Log "Installing WinGet (App Installer)..."
    Add-AppxProvisionedPackage -Online `
        -PackagePath "$workDir\Microsoft.DesktopAppInstaller.msixbundle" `
        -SkipLicense | Out-Null

    # --- Step 3: Wait for winget.exe to appear ---
    Write-Log "Waiting for winget.exe to become available..."
    $found = Wait-ForCondition -Condition { Get-WingetExe } -TimeoutSeconds 90 -Description "winget.exe"
    if (-not $found) {
        throw "winget.exe not found after installation — timed out after 90s."
    }

    $wingetExe = Get-WingetExe
    Write-Log "Found winget.exe at: $wingetExe"

    # --- Step 4: Reset and update WinGet sources ---
    Write-Log "Resetting WinGet sources..."
    $resetLog = "$workDir\winget-source-reset.log"
    Start-Process -FilePath $wingetExe -NoNewWindow -Wait `
        -ArgumentList "source reset --force --verbose-logs" `
        -RedirectStandardOutput $resetLog
    Write-Log "Source reset complete. See: $resetLog"

    Write-Log "Updating WinGet sources..."
    $updateLog = "$workDir\winget-source-update.log"
    Start-Process -FilePath $wingetExe -NoNewWindow -Wait `
        -ArgumentList "source update" `
        -RedirectStandardOutput $updateLog
    Write-Log "Source update complete. See: $updateLog"

    # --- Step 5: Install PowerShell 7 ---
    Write-Log "Installing PowerShell 7 via WinGet..."
    $ps7Log = "$workDir\winget-install-ps7.log"
    $proc = Start-Process -FilePath $wingetExe -NoNewWindow -Wait -PassThru `
        -ArgumentList "install Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements" `
        -RedirectStandardOutput $ps7Log

    if ($proc.ExitCode -ne 0) {
        throw "WinGet install PowerShell 7 exited with code $($proc.ExitCode). See: $ps7Log"
    }
    Write-Log "PowerShell 7 installation completed successfully."

    # --- Done ---
    Write-Log "Remediation completed successfully."
    exit 0

} catch {
    Write-Log "FATAL: $($_.Exception.Message)" "ERROR"
    exit 1
}
#endregion