$claudeRoot = Join-Path $env:LOCALAPPDATA "AnthropicClaude"
$claudePath = Join-Path $claudeRoot "update.exe"

if (Test-Path $claudePath) {
    Write-Output "Uninstalling Claude"
    $p = Start-Process -FilePath $claudePath -ArgumentList "--uninstall","-s" -Wait -PassThru
    if ($p.ExitCode -eq 0) { Write-Output "Claude uninstalled successfully." }
    else { Write-Error "Uninstall exited with code $($p.ExitCode)" }
} else {
    Write-Output "Claude (Squirrel install) not found"
}


$shortcutRoots = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
    [Environment]::GetFolderPath("Desktop")
)
foreach ($root in $shortcutRoots) {
    Get-ChildItem -Path $root -Recurse -Filter "*Claude*.lnk" -ErrorAction SilentlyContinue |
        ForEach-Object {
            Write-Output "Removing shortcut: $($_.FullName)"
            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
        }
}


if (Test-Path $claudeRoot) {
    Remove-Item -Path $claudeRoot -Recurse -Force -ErrorAction SilentlyContinue
}
