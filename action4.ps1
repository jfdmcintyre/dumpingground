Import-Module .\styles.ps1
Import-Module .\functions.ps1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-Notification {
    param (
        [string]$title,
        [string]$Message,
        [System.Windows.Forms.ToolTipIcon]$Icon = [System.Windows.Forms.ToolTipIcon]::Info
    )
    $balloon = New-Object System.Windows.Forms.NotifyIcon
    $balloon.Icon = [System.Drawing.SystemIcons]::Information
    $balloon.BalloonTipIcon = $Icon
    $balloon.BalloonTipTitle = $Title
    $balloon.BalloonTipText = $Message
    $balloon.Visible = $true
    $balloon.ShowBalloonTip(5000)
    $balloon.Dispose()
}

$wslBackupForm = New-Object System.Windows.Forms.Form
$wslBackupForm.Text = "WEnix Image Backup"
$wslBackupForm.Size = New-Object System.Drawing.Size(600, 400)
$wslBackupForm.StartPosition = "CenterScreen"
$wslBackupForm.Icon = "icons/Backup_Image.ico"
New-FormStyle -form $wslBackupForm

$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Size = New-Object System.Drawing.Size(100, 100)
$pictureBox.Location = New-Object System.Drawing.Point(473, 20)
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$imagePath = "icons/Backup_Image.ico"
if (Test-Path $imagePath) {
    $pictureBox.Image = [System.Drawing.Image]::FromFile($imagePath)
} else {
    Write-Warning "Image not found: $imagePath"
}
$wslBackupForm.Controls.Add($pictureBox)

$label1 = New-Object System.Windows.Forms.Label
$label1.Location = New-Object System.Drawing.Point(10, 20)
$label1.Size = New-Object System.Drawing.Size(565, 20)
$label1.Text = "Selected Image: $global:SelectedImageForBackup"
New-LabelStyle -label $label1
$wslBackupForm.Controls.Add($label1)

$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10, 50)
$label2.Size = New-Object System.Drawing.Size(565, 20)
$label2.Text = "Enter export file name:"
New-LabelStyle -label $label2
$wslBackupForm.Controls.Add($label2)

$exportNameTextBox = New-Object System.Windows.Forms.TextBox
$exportNameTextBox.Location = New-Object System.Drawing.Point(10, 80)
$exportNameTextBox.Size = New-Object System.Drawing.Size(450, 20)
$wslBackupForm.Controls.Add($exportNameTextBox)

$label3 = New-Object System.Windows.Forms.Label
$label3.Location = New-Object System.Drawing.Point(10, 110)
$label3.Size = New-Object System.Drawing.Size(565, 20)
$label3.Text = "Select image export location"
New-LabelStyle -label $label3
$wslBackupForm.Controls.Add($label3)

$exportLocationTextBox = New-Object System.Windows.Forms.TextBox
$exportLocationTextBox.Location = New-Object System.Drawing.Point(10, 140)
$exportLocationTextBox.Size = New-Object System.Drawing.Size(450, 20)
$wslBackupForm.Controls.Add($exportLocationTextBox)
Set-Watermark -TextBox $exportLocationTextBox -Watermark "Leave blank for default (C:\_WSL2)"

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(465, 138)
$browseButton.Size = New-Object System.Drawing.Size(110, 25)
$browseButton.Text = "Browse"
$browseButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select export location"
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $exportLocationTextBox.Text = $folderBrowser.SelectedPath
    }
})
New-ButtonStyle -button $browseButton
$wslBackupForm.Controls.Add($browseButton)

$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10, 180)
$outputTextBox.Size = New-Object System.Drawing.Size(565, 130)
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = "Vertical"
$outputTextBox.ReadOnly = $true
$outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
New-outputStyle -outputTextBox $outputTextBox
$wslBackupForm.Controls.Add($outputTextBox)

$executeButton = New-Object System.Windows.Forms.Button
$executeButton.Location = New-Object System.Drawing.Point(10, 320)
$executeButton.Size = New-Object System.Drawing.Size(280, 30)
$executeButton.Text = "Export WEnix Image"
New-ButtonStyle -button $executeButton
$wslBackupForm.Controls.Add($executeButton)

$spinner = New-Object System.Windows.Forms.PictureBox
$spinner.Size = New-Object System.Drawing.Size(32, 32)
$spinner.Location = New-Object System.Drawing.Point(550, 320)
$spinner.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$spinner.Image = [System.Drawing.Image]::FromFile("path/to/spinner.gif") # Replace with the path to your spinner GIF
$spinner.Visible = $false
$wslBackupForm.Controls.Add($spinner)

$executeButton.Add_Click({
    $exportName = $exportNameTextBox.Text.Trim()
    $exportLocation = $exportLocationTextBox.Text.Trim()
    $outputTextBox.Clear()
    $outputTextBox.AppendText("Selected Image: $global:SelectedImageForBackup`r`nExport Name: $exportName`r`n")

    if ($exportName) {
        if (-not $exportName.EndsWith(".tar")) {
            $exportName += ".tar"
        }

        if ($exportLocation -eq "" -or $exportLocation -eq "Leave blank for default (C:\_WSL2)") {
            $exportLocation = "C:\_WSL2"
        }

        $exportPath = Join-Path $exportLocation $exportName
        $outputTextBox.AppendText("Export Path: $exportPath`r`n")

        # Check available disk space
        try {
            $drive = Split-Path -Qualifier $exportPath
            if (-not $drive) {
                throw "Unable to determine drive from path: $exportPath"
            }
            $freeSpace = (Get-PSDrive $drive.TrimEnd(":")).Free
        }
        catch {
            $outputTextBox.AppendText("Error checking disk space: $_`r`n")
            [System.Windows.Forms.MessageBox]::Show("Unable to check disk space. Please ensure the export path is valid.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        # Get WSL image size using wsl command
        try {
            $wslSizeOutput = wsl.exe --system -d $global:SelectedImageForBackup df -h /mnt/wslg/distro
            $sizeInfo = $wslSizeOutput | Select-Object -Last 1
            if ($sizeInfo -match '\s(\S+)\s+(\S+)\s+(\S+)\s+(\S+)') {
                $usedSpace = $matches[2]
                if ($usedSpace -match '(\d+\.?\d*)([KMGT])') {
                    $size = [double]$matches[1]
                    $unit = $matches[2]
                    switch ($unit) {
                        'K' { $requiredSpace = $size * 1KB }
                        'M' { $requiredSpace = $size * 1MB }
                        'G' { $requiredSpace = $size * 1GB }
                        'T' { $requiredSpace = $size * 1TB }
                    }
                } else {
                    $outputTextBox.AppendText("Failed to parse WSL image size. Aborting export.`r`n")
                    return
                }
            } else {
                $outputTextBox.AppendText("Failed to get WSL image size. Aborting export.`r`n")
                return
            }
        } catch {
            $outputTextBox.AppendText("Error getting WSL image size: $_`r`n")
            return
        }

        if ($freeSpace -lt $requiredSpace) {
            $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
            $requiredSpaceGB = [math]::Round($requiredSpace / 1GB, 2)
            $outputTextBox.AppendText("Not enough disk space. Available: $freeSpaceGB GB, Required: $requiredSpaceGB GB`r`n")
            [System.Windows.Forms.MessageBox]::Show("Not enough disk space to export the WEnix image.`nAvailable: $freeSpaceGB GB`nRequired: $requiredSpaceGB GB", "Insufficient Disk Space", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        try {
            if (-not (Test-Path $exportLocation)) {
                New-Item -ItemType Directory -Path $exportLocation | Out-Null
                $outputTextBox.AppendText("Created directory: $exportLocation`r`n")
            }

            $command = "wsl.exe --export `"$global:SelectedImageForBackup`" `"$exportPath`""
            $outputTextBox.AppendText("Executing command: $command`r`n")
            Show-Notification -Title "Backup Started" -Message "WEnix Image $global:SelectedImageForBackup is currently being backed up. This Process can take up to 5 minutes." -Icon info

            # Show the spinner
            $spinner.Visible = $true

            $process = Start-Process -FilePath "
