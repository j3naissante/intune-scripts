Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Load ImportExcel module if missing
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module ImportExcel -Scope CurrentUser -Force
}

# Create GUI
$form = New-Object System.Windows.Forms.Form
$form.Text = "Intune Device Filter"
$form.Size = New-Object System.Drawing.Size(600, 350)
$form.StartPosition = "CenterScreen"

# AllDevices label & textbox
$lblAll = New-Object System.Windows.Forms.Label
$lblAll.Text = "AllDevices File:"
$lblAll.Location = New-Object System.Drawing.Point(20,20)
$lblAll.AutoSize = $true
$form.Controls.Add($lblAll)

$txtAll = New-Object System.Windows.Forms.TextBox
$txtAll.Location = New-Object System.Drawing.Point(150,17)
$txtAll.Size = New-Object System.Drawing.Size(300,20)
$form.Controls.Add($txtAll)

$btnAll = New-Object System.Windows.Forms.Button
$btnAll.Text = "Browse..."
$btnAll.Location = New-Object System.Drawing.Point(460,15)
$btnAll.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Excel (*.xlsx)|*.xlsx|CSV (*.csv)|*.csv"
    if ($dialog.ShowDialog() -eq "OK") { $txtAll.Text = $dialog.FileName }
})
$form.Controls.Add($btnAll)

# Device list label & textbox
$lblList = New-Object System.Windows.Forms.Label
$lblList.Text = "DeviceName List:"
$lblList.Location = New-Object System.Drawing.Point(20,70)
$lblList.AutoSize = $true
$form.Controls.Add($lblList)

$txtList = New-Object System.Windows.Forms.TextBox
$txtList.Location = New-Object System.Drawing.Point(150,67)
$txtList.Size = New-Object System.Drawing.Size(300,20)
$form.Controls.Add($txtList)

$btnList = New-Object System.Windows.Forms.Button
$btnList.Text = "Browse..."
$btnList.Location = New-Object System.Drawing.Point(460,65)
$btnList.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "All Supported|*.txt;*.csv;*.xlsx|Text (*.txt)|*.txt|CSV (*.csv)|*.csv|Excel (*.xlsx)|*.xlsx"
    if ($dialog.ShowDialog() -eq "OK") { $txtList.Text = $dialog.FileName }
})
$form.Controls.Add($btnList)

# Status box
$txtStatus = New-Object System.Windows.Forms.TextBox
$txtStatus.Location = New-Object System.Drawing.Point(20,150)
$txtStatus.Size = New-Object System.Drawing.Size(540,120)
$txtStatus.Multiline = $true
$txtStatus.ReadOnly = $true
$form.Controls.Add($txtStatus)

# Run Filter button
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Filter"
$btnRun.Location = New-Object System.Drawing.Point(240,110)
$btnRun.Size = New-Object System.Drawing.Size(120,30)
$form.Controls.Add($btnRun)

# Run logic
$btnRun.Add_Click({
    try {
        $txtStatus.AppendText("Starting filtering process...`r`n")

        $allPath  = $txtAll.Text
        $listPath = $txtList.Text

        if (!(Test-Path $allPath))  { throw "AllDevices file not found." }
        if (!(Test-Path $listPath)) { throw "Device list file not found." }

        # Load AllDevices file
        $txtStatus.AppendText("Importing AllDevices file...`r`n")
        switch -Wildcard ($allPath) {
            "*.xlsx" { $AllDevices = Import-Excel $allPath }
            "*.csv"  { $AllDevices = Import-Csv $allPath }
            default  { throw "Unsupported AllDevices file type. Use .xlsx or .csv" }
        }

        # Load Device list
        $txtStatus.AppendText("Importing DeviceName list...`r`n")
        switch -Wildcard ($listPath) {
            "*.txt"  { $WantedList = Get-Content $listPath }
            "*.csv"  { $WantedList = (Import-Csv $listPath).DeviceName }
            "*.xlsx" { $WantedList = (Import-Excel $listPath).DeviceName }
            default  { throw "Unsupported device list file type." }
        }

        # Normalize device names
        $WantedList = $WantedList | ForEach-Object { $_.Trim().ToLower() }

        # Detect the column in AllDevices
        $AllColumns = $AllDevices | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        $PossibleColumns = @("DeviceName","Device Name","device_name","device name","Device","Name")
        $DeviceColumn = $PossibleColumns | Where-Object { $AllColumns -contains $_ } | Select-Object -First 1
        if (-not $DeviceColumn) { throw "No Device Name column found. Columns detected: $($AllColumns -join ', ')" }

        $txtStatus.AppendText("Using column: $DeviceColumn`r`n")
        $txtStatus.AppendText("Filtering...`r`n")

        # Filter safely
        $Filtered = $AllDevices | Where-Object {
            $val = $_.$DeviceColumn
            if ($null -eq $val) { return $false }
            $WantedList -contains $val.ToString().Trim().ToLower()
        }

        # Export result
        $OutputPath = Join-Path (Split-Path $allPath) "FilteredDevices.xlsx"
        $Filtered | Export-Excel $OutputPath -AutoSize

        $txtStatus.AppendText("Filtering complete!`r`nSaved to: $OutputPath`r`n")
    }
    catch {
        $txtStatus.AppendText("ERROR: $($_.Exception.Message)`r`n")
    }
})

# Show GUI
$form.Topmost = $true
$form.ShowDialog()
