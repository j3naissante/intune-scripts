# CopyWin

CopyWin is a lightweight PowerShell GUI tool for creating Microsoft Intune Win32 application packages for file and folder deployment.

## Features

- Select multiple files and folders.
- Copy entire folders, including their subfolders and contents.
- Automatically create missing destination directories.
- Overwrite existing files.
- Automatically generate installation, detection and optional uninstallation scripts.
- Automatically download and reuse Microsoft's IntuneWinAppUtil.exe.
- No additional PowerShell modules required.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or later
- Internet connection for the initial download of IntuneWinAppUtil.exe

## Usage

1. Run `CopyWin.ps1`.
2. Enter the application name.
3. Add the files or folders to deploy.
4. Specify the destination directory on managed devices.
5. Select the package output directory.
6. Click **Create IntuneWin package**.

## Generated files

| File | Description |
|---|---|
| `ApplicationName.intunewin` | Intune Win32 application package |
| `Detection.ps1` | File and folder existence detection |
| `Commands.txt` | Installation and uninstallation commands |

## Intune deployment

Upload the generated package as a Windows app (Win32), use the commands provided in `Commands.txt` and configure the following settings:

- **Install behavior:** System
- **Device restart behavior:** No specific action
- **Detection rules:** Use a custom detection script
- **Detection script:** Detection.ps1
- **Run script as 32-bit:** No

## Notes

Selected folders are copied in their entirety, including the parent folder. Existing files are overwritten when installation runs. Unrelated files remain untouched.

Detection is based on file and folder existence, not file contents. Uninstallation removes the deployed files but retains directories.

CopyWin uses Microsoft's official Win32 Content Prep Tool.