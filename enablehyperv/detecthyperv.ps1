$feature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
if ($feature -and $feature.State -eq 'Enabled') {
    Write-Output "Hyper-V enabled"
    exit 0
} else {
    exit 1
}