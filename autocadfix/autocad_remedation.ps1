$ProductCodes = @(
    "{28B89EEF-6101-0409-2102-CF3F3A09B77D}",  # AutoCAD 2023
    "{28B89EEF-7101-0409-2102-CF3F3A09B77D}",  # AutoCAD 2024
    "{28B89EEF-9101-0409-2102-CF3F3A09B77D}"   # AutoCAD 2026
)

$baseKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$whitelistKeyName = "SecureRepairWhitelist"
$policyValueName = "SecureRepairPolicy"
$policyValue = 2

# 1. Create base registry key if it doesn't exist
if (-not (Test-Path -Path $baseKeyPath)) {
    try {
        New-Item -Path $baseKeyPath -Force | Out-Null
        Write-Output "Created base key: $baseKeyPath"
    }
    catch {
        Write-Error "Failed to create base registry key: $baseKeyPath. $_"
        exit 1
    }
}

# 2. Set SecureRepairPolicy to 2 if not already set
$existingPolicyValue = $null
try {
    $existingPolicyValue = Get-ItemPropertyValue -Path $baseKeyPath -Name $policyValueName -ErrorAction Stop
}
catch {
    # Value not found, will create it
}

if ($existingPolicyValue -ne $policyValue) {
    try {
        New-ItemProperty -Path $baseKeyPath -Name $policyValueName -PropertyType DWord -Value $policyValue -Force | Out-Null
        Write-Output "Set $policyValueName to $policyValue"
    }
    catch {
        Write-Error "Failed to set $policyValueName. $_"
        exit 1
    }
} else {
    Write-Output "$policyValueName already set to $policyValue"
}

# 3. Create whitelist subkey if it doesn't exist
$whitelistPath = Join-Path $baseKeyPath $whitelistKeyName
if (-not (Test-Path -Path $whitelistPath)) {
    try {
        New-Item -Path $whitelistPath -Force | Out-Null
        Write-Output "Created whitelist key: $whitelistPath"
    }
    catch {
        Write-Error "Failed to create whitelist key: $whitelistPath. $_"
        exit 1
    }
} else {
    Write-Output "Whitelist key already exists: $whitelistPath"
}

# 4. Add product codes as string values if not present
foreach ($code in $ProductCodes) {
    if ($code -notmatch '^\{[0-9A-Fa-f\-]+\}$') {
        Write-Warning "ProductCode '$code' is not in valid GUID-with-braces format. Skipping."
        continue
    }

    $existingValue = $null
    try {
        $existingValue = Get-ItemPropertyValue -Path $whitelistPath -Name $code -ErrorAction Stop
        Write-Output "Whitelist entry for ProductCode $code already exists."
    }
    catch {
        # Value does not exist, create it
        try {
            New-ItemProperty -Path $whitelistPath -Name $code -PropertyType String -Value "" -Force | Out-Null
            Write-Output "Created whitelist entry for ProductCode: $code"
        }
        catch {
            Write-Error "Failed to create whitelist entry for ProductCode $code. $_"
        }
    }
}

exit 0
