This Remedation script uninstalls selected Windows update.

End users must must restart their systems after the script has ran.

To get the package file, use the following command
Get-WindowsPackage -Online

Ensure that the PackageName starts with "Package_for_RollupFix" followed by version 

