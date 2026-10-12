$out = (& "$env:windir\System32\sfc.exe" /verifyonly | Out-String) -replace "`0",""
if ($out -match "found integrity violations") { Write-Output "SFC: integrity violations found"; exit 1 }
Write-Output "SFC: clean"; exit 0