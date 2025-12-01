
$LogFile = Join-Path -Path $Env:TEMP -ChildPath "RIKS_Install.log"

# Function to write log messages
Function Write-Log {
    Param([string]$Message)
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Line = "$TimeStamp - $Message"
    Write-Output $Line          # Shows in console
    Add-Content -Path $LogFile -Value $Line
}

# Start logging
Write-Log "Starting RIKS deployment..."

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "ERROR: Administrator rights are required. Exiting..."
    Exit 1
}

# Source & Destination
$SourceFolder = "$PSScriptRoot\RIKS"
$DestinationFolder = Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "RIKS"

If (-Not (Test-Path $DestinationFolder)) {
    Write-Log "Destination folder does not exist. Creating $DestinationFolder"
    New-Item -Path $DestinationFolder -ItemType Directory -Force
}

Try {
    Write-Log "Copying contents of $SourceFolder to $DestinationFolder"
    Copy-Item -Path "$SourceFolder\*" -Destination $DestinationFolder -Recurse -Force
    Write-Log "Folder successfully copied."
    Exit 0
} Catch {
    Write-Log "ERROR: Failed to copy folder. Exception: $_"
    Exit 1
}

$Exe1 = Join-Path $DestinationFolder "RIKS.exe"
$Exe2 = Join-Path $DestinationFolder "RIKSLug.exe"

if (Test-Path $Exe1) {
    New-Shortcut -TargetPath $Exe1 -ShortcutName "RIKS - Peamoodul" -Desktop -StartMenu -AllUsers
}

if (Test-Path $Exe2) {
    New-Shortcut -TargetPath $Exe2 -ShortcutName "RIKS - Lugejahaldus" -Desktop -StartMenu
}
