# Get all AMD display adapters (including disabled ones)
$gpuList = Get-PnpDevice -Class Display | Where-Object {
    $_.FriendlyName -match "AMD"
}

if (-not $gpuList) {
    Write-Output "No AMD display adapter found."
    exit 1
}

foreach ($gpu in $gpuList) {

    Write-Output "Found: $($gpu.FriendlyName)"
    Write-Output "Current Status: $($gpu.Status)"

    # If disabled → enable it
    if ($gpu.Status -eq "Disabled") {
        Write-Output "Enabling AMD GPU..."

        try {
            Enable-PnpDevice -InstanceId $gpu.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 5

            $refreshed = Get-PnpDevice -InstanceId $gpu.InstanceId
            if ($refreshed.Status -eq "OK") {
                Write-Output "AMD GPU successfully enabled and healthy."
            } else {
                Write-Output "AMD GPU enabled but still in bad state: $($refreshed.Status)"
                exit 1
            }
        }
        catch {
            Write-Output "Failed to enable AMD GPU: $_"
            exit 1
        }
    }

    # If device has error state → restart it
    elseif ($gpu.Status -match "Error" -or $gpu.Problem) {
        Write-Output "GPU has problem state. Attempting restart..."

        try {
            Disable-PnpDevice -InstanceId $gpu.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 2
            Enable-PnpDevice -InstanceId $gpu.InstanceId -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 5

            $refreshed = Get-PnpDevice -InstanceId $gpu.InstanceId
            if ($refreshed.Status -eq "OK") {
                Write-Output "GPU restarted and healthy."
            } else {
                Write-Output "GPU still in bad state after restart: $($refreshed.Status)"
                exit 1
            }
        }
        catch {
            Write-Output "Failed to restart AMD GPU: $_"
            exit 1
        }
    }
    else {
        Write-Output "AMD GPU already enabled and healthy."
    }
}

exit 0