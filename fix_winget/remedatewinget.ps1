﻿# Define log file path and log function
$logPath = "C:\Program Files\Install\Winget\Powershell7\winget_Install_Powershell7.log"
$logErrorPath = "C:\Program Files\Install\Winget\Powershell7\winget_install_errors.log"
$ProgressPreference = 'SilentlyContinue'


# Log function to append messages with timestamps
function Log-Message {
    param (
        [string]$Message,
        [string]$LogFile = $logPath
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    
    # Output to console
    Write-Host $logMessage

    # Append to log file
    Add-Content -Path $LogFile -Value $logMessage
}

# Create necessary directories
New-Item -ItemType directory -Path "C:\Program Files\Install\Winget\Powershell7" -ErrorAction SilentlyContinue
Log-Message "Created or verified 'C:\Program Files\Install\Winget\Powershell7' directory."

# Start logging session
Log-Message "Starting Winget installation process..."



# Download required components
Log-Message "Downloading Winget components..."
try {
    Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile "C:\Program Files\Install\Winget\Powershell7\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    Log-Message "Downloaded Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle."

    Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile "C:\Program Files\Install\Winget\Powershell7\Microsoft.VCLibs.x64.14.00.Desktop.appx"
    Log-Message "Downloaded Microsoft.VCLibs.x64.14.00.Desktop.appx."

    Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -OutFile "C:\Program Files\Install\Winget\Powershell7\Microsoft.UI.Xaml.2.8.x64.appx"
    Log-Message "Downloaded Microsoft.UI.Xaml.2.8.x64.appx."
}
catch {
    Log-Message "Error downloading components: $_" -LogFile $logErrorPath
    exit 1
}

# Install components
#Component Microsoft.VCLibs is okay to fail because Windows might be patched already
Log-Message "Installing Winget components..."
try {
  #Add-AppxProvisionedPackage -Online -PackagePath 'C:\Program Files\Install\Winget\Microsoft.VCLibs.x64.14.00.Desktop.appx' -SkipLicense -ErrorAction SilentlyContinue
    #Log-Message "Installed Microsoft.VCLibs.x64.14.00.Desktop.appx (ignore if already installed)."

    #Add-AppxProvisionedPackage -Online -PackagePath 'C:\Program Files\Install\Winget\Microsoft.UI.Xaml.2.8.x64.appx' -SkipLicense -ErrorAction SilentlyContinue
    #Log-Message "Installed Microsoft.UI.Xaml.2.8.x64.appx (ignore if already installed)."

    Add-AppxProvisionedPackage -Online -PackagePath 'C:\Program Files\Install\Winget\Powershell7\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' -SkipLicense
    Log-Message "Installed Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle."
}
catch {
    Log-Message "Error during installation: $_" -LogFile $logErrorPath
    exit 1
}

# Sleep for a short time to ensure installation completes
Start-Sleep -Seconds 15

# Select the newest Winget.exe and log the file found
Log-Message "Searching for the most recent winget.exe file..."
$winget = Get-ChildItem -Path 'C:\Program Files\WindowsApps\' -Filter winget.exe -Recurse | Sort-Object -Property 'FullName' -Descending | Select-Object -First 1 -ExpandProperty FullName | Tee-Object -FilePath "C:\Program Files\Install\Winget\Winget-file-found-from.log"

if ($winget) {
    Log-Message "Found winget.exe: $winget"
} else {
    Log-Message "No winget.exe found!" -LogFile $logErrorPath
    exit 1
}

# Reset Winget source
Log-Message "Resetting Winget source..."
try {
    Start-Process -FilePath $winget -NoNewWindow -Wait -ArgumentList 'source reset --force --verbose-logs' -RedirectStandardOutput "C:\Program Files\Install\Winget\Powershell7\Winget-source-reset.log"
    Log-Message "Winget source reset completed."
}
catch {
    Log-Message "Error resetting Winget source: $_" -LogFile $logErrorPath
    exit 1
}

Start-Sleep -Seconds 15

# Install Winget source
Log-Message "Updating Winget source..."
try {
    Start-Process -FilePath $winget -NoNewWindow -Wait -ArgumentList 'source Install' -RedirectStandardOutput "C:\Program Files\Install\Winget\Powershell7\Winget-source-Install.log"
    Log-Message "Winget source Install completed."
}
catch {
    Log-Message "Error updating Winget source: $_" -LogFile $logErrorPath
    exit 1
}

Start-Sleep -Seconds 15

# Install Powershell7 using Winget
Log-Message "Installing Powershell7 via Winget..."
try {
    Start-Process -FilePath $winget -NoNewWindow -Wait -ArgumentList 'install Microsoft.Powershell --silent --accept-package-agreements --accept-source-agreements' -RedirectStandardOutput "C:\Program Files\Install\Winget\Powershell7\Winget-Install-Powershell7.log"
    Log-Message "Powershell7 installation completed."
}
catch {
    Log-Message "Error installing Powershell7: $_" -LogFile $logErrorPath
    exit 1
}

Start-Sleep -Seconds 10

# Mark installation completion
Log-Message "Winget installation process completed."

# Stop logging session

