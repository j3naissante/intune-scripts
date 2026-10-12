$ErrorActionPreference = 'Stop'

# Intune may launch the installer in 32-bit PowerShell. Relaunch as 64-bit.
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    & "$env:WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
    exit $LASTEXITCODE
}

try {
    if (-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
        throw 'This package requires x64 Windows.'
    }
    $build = [int](Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
    if ($build -lt 17763) { throw 'This package requires Windows build 17763 or later.' }

    $packages = @('Drivers\I219\NDIS\e1d.inf')
    if ($build -ge 22000) {
        $packages += 'Drivers\I219\NCX\e1dn.inf', 'Drivers\I219\NCX\e1d_ext.inf'
    }
    # Validate source paths before making changes.
    foreach ($relativePath in $packages) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $relativePath))) {
            throw "Missing driver: $relativePath"
        }
    }
    $result = 0
    foreach ($relativePath in $packages) {
        & "$env:WINDIR\System32\pnputil.exe" /add-driver (Join-Path $PSScriptRoot $relativePath) /install
        $code = $LASTEXITCODE
        if ($code -notin @(0, 3010)) { throw "PnPUtil failed for $relativePath with exit code $code." }
        if ($code -eq 3010) { $result = 3010 }
    }
    exit $result
} catch {
    Write-Error $_
    exit 1
}
