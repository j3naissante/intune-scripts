$found = $false

$profiles = Get-ChildItem "C:\Users" -Directory | Where-Object {
    $_.Name -notin @("Public", "Default", "Default User", "All Users")
}

foreach ($profile in $profiles) {
    $hydraPath = Join-Path $profile.FullName "AppData\Local\Programs\Hydra\Hydra.exe"
    
    if (Test-Path $hydraPath) {
        Write-Output "Hydra found in $($profile.FullName)"
        $found = $true
    }
}

if ($found) {
    exit 1
} else {
    exit 0
}