#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$ErrorActionPreference = 'Stop'
function Quote-PS([string]$Value) { "'" + $Value.Replace("'", "''") + "'" }
$form = New-Object Windows.Forms.Form
$form.Text = 'CopyWin'
$form.ClientSize = New-Object Drawing.Size(720, 625)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object Drawing.Font('Segoe UI', 10)
function Add-Control($Type, $Text, $X, $Y, $W, $H) {
    $c = New-Object "System.Windows.Forms.$Type"
    $c.Text = $Text
    $c.Location = New-Object Drawing.Point($X, $Y)
    $c.Size = New-Object Drawing.Size($W, $H)
    $form.Controls.Add($c)
    return $c
}
$null = Add-Control Label 'Application name' 20 15 680 23
$name = Add-Control TextBox '' 20 40 680 28
$null = Add-Control Label 'Source files / folders' 20 78 680 23
$sources = Add-Control ListBox '' 20 103 680 125
$sources.SelectionMode = 'MultiExtended'
$addFiles = Add-Control Button 'Add files' 20 232 125 32
$addFolder = Add-Control Button 'Add folder' 153 232 125 32
$remove = Add-Control Button 'Remove selected' 286 232 155 32
$clear = Add-Control Button 'Clear' 449 232 90 32
$null = Add-Control Label 'Destination on managed devices' 20 276 680 23
$destination = Add-Control TextBox 'C:\Users\Public\Desktop' 20 300 680 28
$null = Add-Control Label 'Output directory' 20 337 680 23
$output = Add-Control TextBox ([Environment]::GetFolderPath('DesktopDirectory')) 20 361 570 28
$browse = Add-Control Button 'Browse...' 600 359 100 30
$uninstall = Add-Control CheckBox 'Generate uninstall script (removes listed destination files)' 20 400 680 25
$uninstall.Checked = $true
$create = Add-Control Button 'Create IntuneWin package' 20 434 680 38
$log = Add-Control TextBox '' 20 485 680 120
$log.Multiline = $true
$log.ReadOnly = $true
$log.ScrollBars = 'Vertical'
function Log([string]$Message) { $log.AppendText("[$(Get-Date -Format HH:mm:ss)] $Message`r`n"); $log.Refresh() }
function Add-Source([string]$Path) { if (-not $sources.Items.Contains($Path)) { $null = $sources.Items.Add($Path) } }
$addFiles.Add_Click({
        $d = New-Object Windows.Forms.OpenFileDialog
        try { $d.Multiselect = $true; if ($d.ShowDialog() -eq 'OK') { foreach ($p in $d.FileNames) { Add-Source $p } } } finally { $d.Dispose() }
    })
$addFolder.Add_Click({
        $d = New-Object Windows.Forms.FolderBrowserDialog
        try { if ($d.ShowDialog() -eq 'OK') { Add-Source $d.SelectedPath } } finally { $d.Dispose() }
    })
$remove.Add_Click({ foreach ($p in @($sources.SelectedItems)) { $sources.Items.Remove($p) } })
$clear.Add_Click({ $sources.Items.Clear() })
$browse.Add_Click({
        $d = New-Object Windows.Forms.FolderBrowserDialog
        try { if ($d.ShowDialog() -eq 'OK') { $output.Text = $d.SelectedPath } } finally { $d.Dispose() }
    })
$create.Add_Click({
        $temp = $null
        $published = $false
        $final = $null
        $create.Enabled = $false
        try {
            $app = $name.Text.Trim()
            $dest = $destination.Text.Trim()
            if (-not $app -or $app.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0 -or $app.EndsWith('.') -or $app -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)') { throw 'Enter a valid application name.' }
            if ($sources.Items.Count -eq 0) { throw 'Select at least one source file or folder.' }
            if ($dest -notmatch '^(?:[A-Za-z]:\\|%[A-Za-z_][A-Za-z0-9_()]*%\\)' -or $dest -match '[*?"<>|]' -or $dest -match '(^|\\)\.\.(\\|$)') { throw 'Use an absolute local destination, e.g. C:\ProgramData\App or %ProgramData%\App.' }
            if ($dest -match '%(USERPROFILE|APPDATA|LOCALAPPDATA|USERNAME|HOMEPATH|HOMEDRIVE)%') { throw 'User-specific environment variables are not supported for SYSTEM deployment.' }
            if (-not (Test-Path -LiteralPath $output.Text -PathType Container)) { throw 'Select an existing output directory.' }
            $final = Join-Path $output.Text $app
            if (Test-Path -LiteralPath $final) { throw "Output folder already exists: $final. Choose another name or output directory." }
            $temp = Join-Path ([IO.Path]::GetTempPath()) ('CopyWin-' + [guid]::NewGuid().ToString('N'))
            $stage = Join-Path $temp 'Source'
            $payload = Join-Path $stage 'Files'
            $packed = Join-Path $temp 'Output'
            $null = New-Item -ItemType Directory -Path $payload, $packed -Force
            $entries = New-Object 'System.Collections.Generic.List[string]'
            $seen = @{}
            $directories = @{}
            foreach ($selected in $sources.Items) {
                $item = Get-Item -LiteralPath $selected -Force
                if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked sources are not supported: $($item.FullName)" }
                if ($item.PSIsContainer) {
                    $base = $item.FullName.TrimEnd('\') + '\'
                    $folderName = $item.Name
                    $directories[$folderName] = $true
                    $pending = New-Object 'System.Collections.Generic.Stack[string]'
                    $pending.Push($item.FullName)
                    $files = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
                    while ($pending.Count -gt 0) {
                        foreach ($child in (Get-ChildItem -LiteralPath ($pending.Pop()) -Force)) {
                            if ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked sources are not supported: $($child.FullName)" }
                            if ($child.PSIsContainer) {
                                $relativeDirectory = Join-Path $folderName $child.FullName.Substring($base.Length)
                                $directories[$relativeDirectory] = $true
                                $pending.Push($child.FullName)
                            }
                            else { $files.Add($child) }
                        }
                    }
                }
                else { $files = @($item); $base = $null }
                foreach ($file in $files) {
                    if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked files are not supported: $($file.FullName)" }
                    $rel = if ($base) {
                        Join-Path $folderName $file.FullName.Substring($base.Length)
                    }
                    else {
                        $file.Name
                    }
                    if ($seen.ContainsKey($rel)) { throw "Duplicate destination filename: $rel" }
                    $seen[$rel] = $true
                    $target = Join-Path $payload $rel
                    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
                    Copy-Item -LiteralPath $file.FullName -Destination $target -Force
                    $entries.Add($rel)
                }
            }
            foreach ($rel in $directories.Keys) {
                if ($seen.ContainsKey($rel)) { throw "Destination is both a file and a folder: $rel" }
            }
            if ($entries.Count -eq 0) { throw 'No files found in the selected sources.' }
            Log "Staged $($entries.Count) files and $($directories.Count) subfolders."
            $header = '$ErrorActionPreference = ''Stop''' + "`r`n" + '$Destination = [Environment]::ExpandEnvironmentVariables(' + (Quote-PS $dest) + ")`r`n" + '$Files = @(' + "`r`n" + (($entries | ForEach-Object { '    ' + (Quote-PS $_) }) -join "`r`n") + "`r`n)" + "`r`n"
            $header += '$Directories = @(' + "`r`n" + (($directories.Keys | Sort-Object | ForEach-Object { '    ' + (Quote-PS $_) }) -join "`r`n") + "`r`n)`r`n"
            $header += @'
if ($Destination -notmatch '^[A-Za-z]:\\' -or $Destination -match '%[^%]+%') { exit 1 }
'@ + "`r`n"
            $installBody = @'
try {
    $null = [IO.Directory]::CreateDirectory($Destination)
    foreach ($Directory in $Directories) {
        $null = [IO.Directory]::CreateDirectory((Join-Path $Destination $Directory))
    }
    foreach ($File in $Files) {
        $Target = Join-Path $Destination $File
        $Source = Join-Path (Join-Path $PSScriptRoot 'Files') $File
        if (Test-Path -LiteralPath $Target -PathType Container) { throw "Destination is a directory: $Target" }
        $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Target))
        Copy-Item -LiteralPath $Source -Destination $Target -Force
        Write-Output "Copied: $Target"
    }
    exit 0
} catch { Write-Error $_ -ErrorAction Continue; exit 1 }
'@
            Set-Content -LiteralPath (Join-Path $stage 'Install.ps1') -Value ($header + $installBody) -Encoding UTF8
            if ($uninstall.Checked) {
                $uninstallBody = @'
try {
    foreach ($File in $Files) {
        $Target = Join-Path $Destination $File
        if (Test-Path -LiteralPath $Target -PathType Leaf) {
            Remove-Item -LiteralPath $Target -Force
            Write-Output "Removed: $Target"
        }
    }
    exit 0
} catch { Write-Error $_ -ErrorAction Continue; exit 1 }
'@
                Set-Content -LiteralPath (Join-Path $stage 'Uninstall.ps1') -Value ($header + $uninstallBody) -Encoding UTF8
            }
            $detectBody = @'
try {
    foreach ($Directory in $Directories) {
        if (-not (Test-Path -LiteralPath (Join-Path $Destination $Directory) -PathType Container)) { exit 1 }
    }
    foreach ($File in $Files) {
        if (-not (Test-Path -LiteralPath (Join-Path $Destination $File) -PathType Leaf)) { exit 1 }
    }
    Write-Output 'Installed'
    exit 0
} catch { exit 1 }
'@
            $tool = Join-Path $PSScriptRoot 'IntuneWinAppUtil.exe'
            if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
                $cache = Join-Path $env:LOCALAPPDATA 'CopyWin'
                $null = [IO.Directory]::CreateDirectory($cache)
                $tool = Join-Path $cache 'IntuneWinAppUtil.exe'
                if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
                    Log 'Downloading Microsoft Win32 Content Prep Tool...'
                    $download = Join-Path $temp 'IntuneWinAppUtil.exe'
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/IntuneWinAppUtil.exe' -OutFile $download
                    Copy-Item -LiteralPath $download -Destination $tool -Force
                }
            }
            Log 'Creating IntuneWin package...'
            $process = Start-Process -FilePath $tool -ArgumentList ('-c "{0}" -s "{1}" -o "{2}" -q' -f $stage, (Join-Path $stage 'Install.ps1'), $packed) -Wait -PassThru -WindowStyle Hidden
            $package = Join-Path $packed 'Install.intunewin'
            if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $package -PathType Leaf) -or (Get-Item -LiteralPath $package).Length -eq 0) { throw "Packaging failed (exit code $($process.ExitCode))." }
            $null = New-Item -ItemType Directory -Path $final -ErrorAction Stop
            $published = $true
            Copy-Item -LiteralPath $package -Destination (Join-Path $final ($app + '.intunewin'))
            Set-Content -LiteralPath (Join-Path $final 'Detection.ps1') -Value ($header + $detectBody) -Encoding UTF8
            $installCommand = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File Install.ps1'
            $uninstallCommand = if ($uninstall.Checked) {
                'powershell.exe -NoProfile -ExecutionPolicy Bypass -File Uninstall.ps1'
            }
            else {
                'cmd.exe /c exit 1'
            }
            $commands = @('Install command:', $installCommand, '', 'Uninstall command:', $uninstallCommand)
            if (-not $uninstall.Checked) { $commands += @('', 'Uninstall script was not generated. The uninstall command intentionally returns failure without removing files.') }
            Set-Content -LiteralPath (Join-Path $final 'Commands.txt') -Value $commands -Encoding UTF8
            Log "Success: $final"
            $published = $false
            [void][Windows.Forms.MessageBox]::Show("Package created:`r`n$final", 'Success')
        }
        catch {
            Log "ERROR: $($_.Exception.Message)"
            if ($published) { Remove-Item -LiteralPath $final -Recurse -Force -ErrorAction SilentlyContinue }
            [void][Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Packaging failed')
        }
        finally {
            if ($temp -and (Test-Path -LiteralPath $temp)) { Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue }
            $create.Enabled = $true
        }
    })
Log 'Ready to create package.'
[void]$form.ShowDialog()
$form.Dispose()
