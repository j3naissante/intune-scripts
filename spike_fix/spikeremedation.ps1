$ProductCode = "{DADC19BA-01E1-4CAD-A639-22DA540E80C5}"

Start-Process "msiexec.exe" `
    -ArgumentList "/x $ProductCode /qn /norestart" `
    -Wait `
    -NoNewWindow

Write-Output "Uninstall attempted."
