$App = Get-AppxPackage -Name "5319275A.WhatsAppDesktop" -AllUsers -ErrorAction SilentlyContinue

if ($App) {
    Write-Output "WhatsApp detected"
    exit 1
} else {
    Write-Output "WhatsApp not detected"
    exit 0
}
