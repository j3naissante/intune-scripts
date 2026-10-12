$ErrorActionPreference = 'Stop'

try {
    $found = Get-WindowsDriver -Online | Where-Object {
        $name = Split-Path $_.OriginalFileName -Leaf

        ($name -eq 'e1d.inf' -and
         [version]$_.Version -ge [version]'12.19.2.66') -or
        ($name -eq 'e1dn.inf' -and
         [version]$_.Version -ge [version]'20.0.3.28')
    }

    if ($found) {
        Write-Output 'Intel Ethernet driver detected'
        exit 0
    }
} catch {}

exit 1