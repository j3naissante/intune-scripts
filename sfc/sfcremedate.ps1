$out = (& "$env:windir\System32\sfc.exe" /scannow | Out-String) -replace "`0",""
Write-Output (($out -replace '\s+',' ').Trim())
if ($out -match "unable to fix") { exit 1 }
exit 0