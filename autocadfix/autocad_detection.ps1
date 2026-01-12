# Paths to check for AutoCAD executables
$paths = @(
    "C:\Program Files\Autodesk\AutoCAD 2024\acad.exe",
    "C:\Program Files\Autodesk\AutoCAD 2023\acad.exe",
    "C:\Program Files\Autodesk\AutoCAD 2026\acad.exe"
)

# Registry path and expected values
$baseKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$whitelistKeyName = "SecureRepairWhitelist"
$policyValueName = "SecureRepairPolicy"
$expectedPolicyValue = 2

# List of MSI ProductCodes to check in whitelist (add your MSI ProductCodes here)
$productCodesToCheck = @(
    "{28B89EEF-6101-0409-2102-CF3F3A09B77D}",  # Example AutoCAD 2023 ProductCode
    "{28B89EEF-7101-0409-2102-CF3F3A09B77D}",
    "{28B89EEF-9101-0409-2102-CF3F3A09B77D}"
)

# --- Check executables ---
$foundExe = $false
foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Output "Found AutoCAD executable: $path"
        $foundExe = $true
        break
    }
}

if (-not $foundExe) {
    Write-Output "Neither AutoCAD 2023 nor 2024 executables found."
    Exit 1
}

# --- Check SecureRepairPolicy registry value ---
try {
    $policyValue = Get-ItemPropertyValue -Path $baseKeyPath -Name $policyValueName -ErrorAction Stop
    if ($policyValue -ne $expectedPolicyValue) {
        Write-Output "Registry value $policyValueName is $policyValue but expected $expectedPolicyValue"
        Exit 1
    } else {
        Write-Output "$policyValueName is correctly set to $expectedPolicyValue"
    }
}
catch {
    Write-Output "Registry value $policyValueName not found at $baseKeyPath"
    Exit 1
}

# --- Check SecureRepairWhitelist keys ---
$whitelistPath = Join-Path $baseKeyPath $whitelistKeyName
if (-not (Test-Path -Path $whitelistPath)) {
    Write-Output "Whitelist registry key not found: $whitelistPath"
    Exit 1
}

foreach ($code in $productCodesToCheck) {
    try {
        $value = Get-ItemPropertyValue -Path $whitelistPath -Name $code -ErrorAction Stop
        # Per MS doc, the value can be empty or any string, so no strict check here
        Write-Output "Whitelist entry found for ProductCode: $code"
    }
    catch {
        Write-Output "Whitelist entry for ProductCode $code not found."
        Exit 1
    }
}

# All checks passed
Write-Output "All detection checks passed."
Exit 0
