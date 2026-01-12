if (Test-Path "HKCU:\Network\M") {
    Write-Output "Drive M detected"
    exit 1
}
else {
    Write-Output "Drive M not present"
    exit 0
}
