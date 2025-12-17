
$cometExe = "$env:LOCALAPPDATA\Perplexity\Comet\Application\comet.exe"

if (Test-Path $cometExe) {
    # Comet Browser detected → exit code 1 (non-compliant)
    exit 1
} else {
    # Not detected → exit code 0 (compliant)
    exit 0
}
