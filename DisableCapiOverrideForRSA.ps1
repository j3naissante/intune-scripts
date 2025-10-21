$regPath = "HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust\Config"
$regKeyExists = Test-Path $regPath

if (!$regKeyExists) {
    try {
        Write-Host "Registry path does not exist. Creating key..."
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust" -Name "Config" -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "DisableCapiOverrideForRSA" -Value 0 -PropertyType DWord -Force | Out-Null
        Write-Host "Registry key and value created successfully."
        Exit 0
    }
    catch {
        Write-Host "Error creating registry key or setting value."
        Write-Error $_
        Exit 1
    }
}
else {
    # Check if the value already exists and its current value
    $currentValue = Get-ItemProperty -Path $regPath -Name "DisableCapiOverrideForRSA" -ErrorAction SilentlyContinue
    
    if ($null -eq $currentValue) {
        try {
            Write-Host "Registry key exists but value is missing. Creating value..."
            New-ItemProperty -Path $regPath -Name "DisableCapiOverrideForRSA" -Value 0 -PropertyType DWord -Force | Out-Null
            Write-Host "Value created successfully."
            Exit 0
        }
        catch {
            Write-Host "Error creating registry value."
            Write-Error $_
            Exit 1
        }
    }
    else {
        Write-Host "Registry key and value already exist. No action required."
        Exit 0
    }
}
