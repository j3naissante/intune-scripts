$Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "DisabledHotkeys"
$Value = "x"

try {
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty `
        -Path $Path `
        -Name $Name `
        -Value $Value `
        -PropertyType String `
        -Force | Out-Null

    $Verify = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name

    if ($Verify -eq $Value) {
        Write-Output "Remediation successful: $Name='$Value'."
        exit 0
    }
    else {
        Write-Error "Remediation failed. Current value is '$Verify'."
        exit 1
    }
}
catch {
    Write-Error "Remediation failed: $($_.Exception.Message)"
    exit 1
}