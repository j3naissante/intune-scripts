# Uninstall NVIDIA Graphics Driver using rundll32.exe
Start-Process -FilePath "rundll32.exe" -ArgumentList '"C:\Program Files\NVIDIA Corporation\Installer2\installer.0\NVI2.DLL",UninstallPackage Display.Driver' -Wait

# Force restart the system
Restart-Computer -Force
