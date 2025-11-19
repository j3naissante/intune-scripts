$found = $false

$profile = Get-ChildItem "C:\Users" -Directory -ErrorAction -SilentlyContinue

foreach ($profile in $profiles) {
    $bravePath "C:\Users\$($profile.Name)\AppData\Local\BraveSoftware\Application\brave.exe"

    if (test-Path $bravePath){
        Write-Output "Brave Browser found for user: $($profile.Name)"
    }
}

if ($found) {
    exit 1
} else {
    exit 0 
}