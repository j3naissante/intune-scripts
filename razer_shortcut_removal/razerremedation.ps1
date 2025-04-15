# Define the paths of the shortcuts to delete
$shortcutPaths = @(
    "C:\Users\Public\Desktop\Razer Synapse.lnk",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Razer\Razer Synapse.lnk"
)

# Iterate over each path and delete if it exists
foreach ($shortcutPath in $shortcutPaths) {
    if (Test-Path $shortcutPath) {
        try {
            # Attempt to remove the item (shortcut)
            Remove-Item $shortcutPath -Force
            Write-Host "Deleted: $shortcutPath"
        }
        catch {
            Write-Host "Failed to delete $shortcutPath. Error: $_"
            Exit 1
        }
    } else {
        Write-Host "Shortcut not found: $shortcutPath"
    }
}

# Exit the script with a success code (0)
exit 0
