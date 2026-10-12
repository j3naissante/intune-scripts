$ErrorActionPreference = 'Stop'
$target = Join-Path $env:ProgramData 'npmallow'
$programFiles64 = if ($env:ProgramW6432) { $env:ProgramW6432 } else { $env:ProgramFiles }
$targets = @(
    $target,
    (Join-Path $env:ProgramData 'NpmCmd'),
    (Join-Path $programFiles64 'NpmCmd'),
    (Join-Path ${env:ProgramFiles(x86)} 'NpmCmd')
) | Where-Object { $_ } | Select-Object -Unique

foreach ($folder in $targets) {
    foreach ($name in @('npm', 'npx')) {
        $file = Join-Path $folder "$name.cmd"
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
    }
    $log = Join-Path $folder 'install.log'
    if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log -Force }
    if ((Test-Path -LiteralPath $folder) -and
        -not @(Get-ChildItem -LiteralPath $folder -Force).Count) {
        Remove-Item -LiteralPath $folder -Force
    }
}

$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$parts = @($machinePath -split ';' | Where-Object {
    $part = $_.Trim().TrimEnd('\')
    $part -and $part -notin $targets
})
[Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'Machine')
Write-Output 'Removed npm/npx launchers. Reopen terminals to refresh PATH.'
