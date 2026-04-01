
# Get-LastLogon.ps1
#
# USAGE:
#   Single device:
#     .\Get-LastLogon.ps1 -DeviceName MYPC
#
#   Multiple devices from a txt file:
#     .\Get-LastLogon.ps1 -DeviceList .\devices.txt
# REQUIREMENTS:
#   Install-Module Microsoft.Graph -Scope CurrentUser
#   Please add your preffered domain on line 77 where AccountDomain contains `"domainname`"


param(
    [string]$DeviceName,
    [string]$DeviceList
)


$devices = @()

if ($DeviceName -like "*.txt") {
    $DeviceList = $DeviceName
    $DeviceName = ""
}

if ($DeviceList) {
    $DeviceList = $DeviceList.Trim('"').Trim("'")
    if (-not (Test-Path $DeviceList)) {
        Write-Host "ERROR: File not found: $DeviceList" -ForegroundColor Red
        exit 1
    }
    $devices = Get-Content $DeviceList | Where-Object { $_.Trim() -ne "" }
}
elseif ($DeviceName) {
    $devices = @($DeviceName.Trim())
}
else {
    $userInput = Read-Host "Enter device name or path to .txt file"
    $userInput = $userInput.Trim('"').Trim("'")
    if ($userInput -like "*.txt") {
        if (-not (Test-Path $userInput)) {
            Write-Host "ERROR: File not found: $userInput" -ForegroundColor Red
            exit 1
        }
        $devices = Get-Content $userInput | Where-Object { $_.Trim() -ne "" }
    }
    else {
        $devices = @($userInput)
    }
}

if ($devices.Count -eq 0) {
    Write-Host "ERROR: No devices to query." -ForegroundColor Red
    exit 1
}

Write-Host "Devices to query: $($devices.Count)" -ForegroundColor DarkCyan
$devices | ForEach-Object { Write-Host "  - $_" }
Write-Host ""


Write-Host "Connecting to Microsoft Graph..." -ForegroundColor DarkCyan
Connect-MgGraph -Scopes "ThreatHunting.Read.All" -NoWelcome
Write-Host "Connected." -ForegroundColor Green
Write-Host ""


$allResults = @()

foreach ($device in $devices) {
    $device = $device.Trim()
    Write-Host "Querying: $device..." -ForegroundColor DarkCyan

    try {
        $query = "DeviceLogonEvents | where Timestamp > ago(30d) | where DeviceName =~ `"$device`" | where AccountDomain contains `"`" | extend CleanAccount = tostring(split(AccountName, `"@`")[0]) | summarize LastLogon = max(Timestamp) by CleanAccount, AccountDomain, DeviceName | order by LastLogon desc"

        $body = [PSCustomObject]@{ Query = $query } | ConvertTo-Json -Compress
        $body = $body -replace '\\u003e', '>'

        $result = Invoke-MgGraphRequest `
                    -Method POST `
                    -Uri "https://graph.microsoft.com/v1.0/security/microsoft.graph.security.runHuntingQuery" `
                    -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                    -ContentType "application/json; charset=utf-8"

        $rows = $result.results

        if (-not $rows -or $rows.Count -eq 0) {
            Write-Host "  No results found for '$device'." -ForegroundColor Yellow
        }
        else {
            Write-Host "  Found $($rows.Count) user(s)." -ForegroundColor Green
            foreach ($row in $rows) {
                $allResults += [PSCustomObject]@{
                    DeviceName  = $row.DeviceName
                    AccountName = $row.CleanAccount
                    Domain      = $row.AccountDomain
                    LastLogon   = ([datetime]$row.LastLogon).ToString("yyyy-MM-dd HH:mm:ss")
                }
            }
        }
    }
    catch {
        Write-Host "  ERROR querying '$device': $_" -ForegroundColor Red
    }
}


Write-Host ""

if ($allResults.Count -eq 0) {
    Write-Host "No results found." -ForegroundColor Yellow
}
else {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Results" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    $allResults | Format-Table -AutoSize
    Write-Host "  Devices queried  : $($devices.Count)"
    Write-Host "  Total users found: $($allResults.Count)"
    Write-Host ""

    $export = Read-Host "Export to CSV? (y/n)"
    if ($export -eq "y") {
        $csvPath = ".\DefenderUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $allResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Saved to: $csvPath" -ForegroundColor Green
        Start-Process $csvPath
    }
}

Write-Host ""
Disconnect-MgGraph | Out-Null