$profiles = Get-ChildItem "C:\Users" -Directory | Where-Object {
    $_.Name -notin @("Public", "Default", "Default User", "All Users")
}

foreach ($profile in $profiles) {
    $hydraFolder = Join-Path $profile.FullName "AppData\Local\Programs\Hydra"
    
    if (Test-Path $hydraFolder) {
        try {
            Write-Output "Removing Hydra from $($profile.FullName)"
            
            Get-Process -Name "Hydra" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            
            Remove-Item $hydraFolder -Recurse -Force -ErrorAction Stop
            
            Write-Output "Removed successfully from $($profile.FullName)"
        }
        catch {
            Write-Output "Failed to remove from $($profile.FullName): $_"
        }
    }
}