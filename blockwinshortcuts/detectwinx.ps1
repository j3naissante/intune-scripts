$Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "DisabledHotkeys"
$ExpectedValue = "x"

try {
    $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name

    if ($CurrentValue -eq $ExpectedValue) {
        Write-Output "Compliant: $Name is set to '$ExpectedValue'."
        exit 0
    }
    else {
        Write-Output "Not compliant: $Name is '$CurrentValue', expected '$ExpectedValue'."
        exit 1
    }
}
catch {
    Write-Output "Not compliant: Registry value does not exist."
    exit 1
}