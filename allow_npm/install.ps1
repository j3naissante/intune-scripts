$ErrorActionPreference = 'Stop'
$target = Join-Path $env:ProgramData 'npmallow'
$programFiles64 = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
$node = Join-Path $programFiles64 'nodejs'
$oldTargets = @(
    (Join-Path $env:ProgramData 'NpmCmd'),
    (Join-Path $programFiles64 'NpmCmd'),
    (Join-Path ${env:ProgramFiles(x86)} 'NpmCmd')
) | Where-Object { $_ -and $_ -ine $target } | Select-Object -Unique
$source = Split-Path -Parent $MyInvocation.MyCommand.Path

New-Item -ItemType Directory -Path $target -Force | Out-Null
$logFile = Join-Path $target 'install.log'
try {
    "$(Get-Date -Format s) Starting as $([Security.Principal.WindowsIdentity]::GetCurrent().Name), 64-bit process: $([Environment]::Is64BitProcess)" | Set-Content -LiteralPath $logFile
    foreach ($name in @('npm', 'npx')) {
        if (-not (Test-Path -LiteralPath (Join-Path $node "$name.cmd") -PathType Leaf)) {
            throw "Missing $name.cmd in $node. Install Node.js first (standard 64-bit location)."
        }
        if (-not (Test-Path -LiteralPath (Join-Path $source "$name.cmd") -PathType Leaf)) {
            throw "Missing packaged launcher: $name.cmd"
        }
    }

    foreach ($name in @('npm', 'npx')) {
        Copy-Item -LiteralPath (Join-Path $source "$name.cmd") -Destination (Join-Path $target "$name.cmd") -Force
    }

    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $parts = @($machinePath -split ';' | Where-Object {
        $part = $_.Trim().TrimEnd('\')
        $part -and $part -ine $target.TrimEnd('\') -and $part -notin $oldTargets
    })
    # A bare npm must resolve to this npm.cmd before Node.js's npm.ps1.
    [Environment]::SetEnvironmentVariable('Path', ((@($target) + $parts) -join ';'), 'Machine')

    # Remove only the launchers owned by earlier versions of this package.
    foreach ($oldTarget in $oldTargets) {
        foreach ($name in @('npm', 'npx')) {
            $oldFile = Join-Path $oldTarget "$name.cmd"
            if (Test-Path -LiteralPath $oldFile) { Remove-Item -LiteralPath $oldFile -Force }
        }
        if ((Test-Path -LiteralPath $oldTarget) -and
            -not @(Get-ChildItem -LiteralPath $oldTarget -Force).Count) {
            Remove-Item -LiteralPath $oldTarget -Force
        }
    }
    "$(Get-Date -Format s) Installed at $target" | Add-Content -LiteralPath $logFile
    Write-Output "Installed npm/npx launchers at $target. Reopen terminals to refresh PATH."
    exit 0
} catch {
    $message = "$(Get-Date -Format s) FAILED: $($_.Exception.Message)"
    $message | Add-Content -LiteralPath $logFile
    Write-Error $message
    exit 1
}
