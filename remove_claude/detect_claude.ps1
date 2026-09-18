$claudePath = "$env:LOCALAPPDATA\AnthropicClaude\claude.exe"

if (Test-Path $claudePath) {
    Write-Output "Claude at $claudePath"
    exit 1
}
else {
    Write-Output "Claude not found"
    exit 0
}