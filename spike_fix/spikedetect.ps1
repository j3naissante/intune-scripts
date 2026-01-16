$ProductCode = "{DADC19BA-01E1-4CAD-A639-22DA540E80C5}"

$App = Get-ItemProperty `
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -eq $ProductCode }

if ($App) {
    Write-Output "Application is installed."
    exit 1
} else {
    Write-Output "Application is not installed."
    exit 0
}
