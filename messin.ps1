$action9 = {
    $wslManagerForm = New-Object System.Windows.Forms.Form
    $wslManagerForm.Text = "WEnix Image Manager"
    $wslManagerForm.Size = New-Object System.Drawing.Size(600, 600)
    $wslManagerForm.StartPosition = "CenterScreen"
    $wslManagerForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(10, 10)
    $listView.Size = New-Object System.Drawing.Size(565, 400)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.Columns.Add("WEnix Images", 565)
    $wslManagerForm.Controls.Add($listView)

    # Add other existing buttons here...

    $backupButton = New-Object System.Windows.Forms.Button
    $backupButton.Location = New-Object System.Drawing.Point(10, 520)
    $backupButton.Size = New-Object System.Drawing.Size(565, 30)
    $backupButton.Text = "Backup Selected Image"
    $backupButton.BackColor = [System.Drawing.Color]::White
    $backupButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $backupButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $backupButton.Add_Click({
        if ($listView.SelectedItems.Count -eq 1) {
            $selectedImage = $listView.SelectedItems[0].Text
            Show-BackupWindow -SelectedImage $selectedImage
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please select a WEnix image to backup.", "No Image Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    $wslManagerForm.Controls.Add($backupButton)

    # Populate the ListView
    $wslOutput = wsl --list --quiet
    $wslLines = $wslOutput -split "`n" | Where-Object { $_.Trim() -ne "" -and $_.Trim() -ne "wsl-vpnkit" }
    foreach ($image in $wslLines) {
        $listView.Items.Add($image.Trim())
    }

    $wslManagerForm.ShowDialog()
}


function Show-BackupWindow {
    param ($SelectedImage)

    $backupForm = New-Object System.Windows.Forms.Form
    $backupForm.Text = "Backup WEnix Image"
    $backupForm.Size = New-Object System.Drawing.Size(600, 400)
    $backupForm.StartPosition = "CenterScreen"
    $backupForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $label1.Size = New-Object System.Drawing.Size(565, 20)
    $label1.Text = "Selected Image: $SelectedImage"
    $label1.ForeColor = [System.Drawing.Color]::White
    $backupForm.Controls.Add($label1)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 50)
    $label2.Size = New-Object System.Drawing.Size(565, 20)
    $label2.Text = "Enter export file name: (don't use spaces or special characters)"
    $label2.ForeColor = [System.Drawing.Color]::White
    $backupForm.Controls.Add($label2)

    $exportNameTextBox = New-Object System.Windows.Forms.TextBox
    $exportNameTextBox.Location = New-Object System.Drawing.Point(10, 80)
    $exportNameTextBox.Size = New-Object System.Drawing.Size(565, 20)
    $backupForm.Controls.Add($exportNameTextBox)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Location = New-Object System.Drawing.Point(10, 110)
    $label3.Size = New-Object System.Drawing.Size(565, 20)
    $label3.Text = "Select export location (leave blank for default C:\_WSL2):"
    $label3.ForeColor = [System.Drawing.Color]::White
    $backupForm.Controls.Add($label3)

    $exportLocationTextBox = New-Object System.Windows.Forms.TextBox
    $exportLocationTextBox.Location = New-Object System.Drawing.Point(10, 140)
    $exportLocationTextBox.Size = New-Object System.Drawing.Size(450, 20)
    $backupForm.Controls.Add($exportLocationTextBox)

    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(465, 138)
    $browseButton.Size = New-Object System.Drawing.Size(110, 25)
    $browseButton.Text = "Browse"
    $browseButton.BackColor = [System.Drawing.Color]::White
    $browseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $browseButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select export location"
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $exportLocationTextBox.Text = $folderBrowser.SelectedPath
        }
    })
    $backupForm.Controls.Add($browseButton)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 180)
    $outputTextBox.Size = New-Object System.Drawing.Size(565, 100)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $backupForm.Controls.Add($outputTextBox)

    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Location = New-Object System.Drawing.Point(10, 290)
    $executeButton.Size = New-Object System.Drawing.Size(565, 30)
    $executeButton.Text = "Export WEnix Image"
    $executeButton.BackColor = [System.Drawing.Color]::White
    $executeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $executeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $executeButton.Add_Click({
        $exportName = $exportNameTextBox.Text.Trim()
        $exportLocation = $exportLocationTextBox.Text.Trim()

        if (-not $exportName) {
            [System.Windows.Forms.MessageBox]::Show("Please enter an export file name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        if ($exportName -match '[^a-zA-Z0-9-]') {
            [System.Windows.Forms.MessageBox]::Show("Export file name should only contain letters, numbers, and hyphens.", "Invalid File Name", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        if (-not $exportName.EndsWith(".tar")) {
            $exportName += ".tar"
        }

        if (-not $exportLocation) {
            $exportLocation = "C:\_WSL2"
        }

        $exportPath = Join-Path $exportLocation $exportName
        $outputTextBox.AppendText("Exporting $SelectedImage to $exportPath`r`n")

        try {
            if (-not (Test-Path $exportLocation)) {
                New-Item -ItemType Directory -Path $exportLocation | Out-Null
                $outputTextBox.AppendText("Created directory: $exportLocation`r`n")
            }

            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", $SelectedImage, $exportPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\export_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\export_error.log"

            $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
            $stdout = Get-Content "C:\_WSL2\_APPLOG\export_output.log" -Raw
            $stderr = Get-Content "C:\_WSL2\_APPLOG\export_error.log" -Raw
            $outputTextBox.AppendText("Standard Output: $stdout`r`n")
            $outputTextBox.AppendText("Standard Error: $stderr`r`n")

            if ($process.ExitCode -eq 0) {
                $outputTextBox.AppendText("Export successful.`r`n")
                [System.Windows.Forms.MessageBox]::Show("WEnix Image $SelectedImage exported successfully to $exportPath", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                $outputTextBox.AppendText("Export failed.`r`n")
                [System.Windows.Forms.MessageBox]::Show("Failed to export WEnix Image. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } catch {
            $outputTextBox.AppendText("Exception occurred: $_`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $backupForm.Controls.Add($executeButton)

    $backupForm.ShowDialog()
}


function Show-BackupWindow {
    param ($SelectedImage)

    $backupForm = New-Object System.Windows.Forms.Form
    $backupForm.Text = "Backup WEnix Image"
    $backupForm.Size = New-Object System.Drawing.Size(600, 400)
    $backupForm.StartPosition = "CenterScreen"
    $backupForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $label1.Size = New-Object System.Drawing.Size(565, 20)
    $label1.Text = "Selected Image: $SelectedImage"
    $label1.ForeColor = [System.Drawing.Color]::White
    $backupForm.Controls.Add($label1)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 50)
    $label2.Size = New-Object System.Drawing.Size(565, 20)
    $label2.Text = "Enter export file name: (don't use spaces or special characters)"
    $label2.ForeColor = [System.Drawing.Color]::White
    $backupForm.Controls.Add($label2)

    $exportNameTextBox = New-Object System.Windows.Forms.TextBox
    $exportNameTextBox.Location = New-Object System.Drawing.Point(10, 80)
    $exportNameTextBox.Size = New-Object System.Drawing.Size(565, 20)
    $backupForm.Controls.Add($exportNameTextBox)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Location = New-Object System.Drawing.Point(10, 110)
    $label3.Size = New-Object System.Drawing.Size(565, 20)
    $label3.Text = "Select export location (leave blank for default C:\_WSL2):"
    $label3.ForeColor = [System.Drawing.Color]::White
    $backupForm.Controls.Add($label3)

    $exportLocationTextBox = New-Object System.Windows.Forms.TextBox
    $exportLocationTextBox.Location = New-Object System.Drawing.Point(10, 140)
    $exportLocationTextBox.Size = New-Object System.Drawing.Size(450, 20)
    $backupForm.Controls.Add($exportLocationTextBox)

    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(465, 138)
    $browseButton.Size = New-Object System.Drawing.Size(110, 25)
    $browseButton.Text = "Browse"
    $browseButton.BackColor = [System.Drawing.Color]::White
    $browseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $browseButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select export location"
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $exportLocationTextBox.Text = $folderBrowser.SelectedPath
        }
    })
    $backupForm.Controls.Add($browseButton)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 180)
    $outputTextBox.Size = New-Object System.Drawing.Size(565, 100)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $backupForm.Controls.Add($outputTextBox)

    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Location = New-Object System.Drawing.Point(10, 290)
    $executeButton.Size = New-Object System.Drawing.Size(565, 30)
    $executeButton.Text = "Export WEnix Image"
    $executeButton.BackColor = [System.Drawing.Color]::White
    $executeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $executeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $executeButton.Add_Click({
        $exportName = $exportNameTextBox.Text.Trim()
        $exportLocation = $exportLocationTextBox.Text.Trim()

        if (-not $exportName) {
            [System.Windows.Forms.MessageBox]::Show("Please enter an export file name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        if ($exportName -match '[^a-zA-Z0-9-]') {
            [System.Windows.Forms.MessageBox]::Show("Export file name should only contain letters, numbers, and hyphens.", "Invalid File Name", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        if (-not $exportName.EndsWith(".tar")) {
            $exportName += ".tar"
        }

        if (-not $exportLocation) {
            $exportLocation = "C:\_WSL2"
        }

        $exportPath = Join-Path $exportLocation $exportName
        $outputTextBox.AppendText("Exporting $SelectedImage to $exportPath`r`n")

        try {
            if (-not (Test-Path $exportLocation)) {
                New-Item -ItemType Directory -Path $exportLocation | Out-Null
                $outputTextBox.AppendText("Created directory: $exportLocation`r`n")
            }

            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", $SelectedImage, $exportPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\export_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\export_error.log"

            $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
            $stdout = Get-Content "C:\_WSL2\_APPLOG\export_output.log" -Raw
            $stderr = Get-Content "C:\_WSL2\_APPLOG\export_error.log" -Raw
            $outputTextBox.AppendText("Standard Output: $stdout`r`n")
            $outputTextBox.AppendText("Standard Error: $stderr`r`n")

            if ($process.ExitCode -eq 0) {
                $outputTextBox.AppendText("Export successful.`r`n")
                [System.Windows.Forms.MessageBox]::Show("WEnix Image $SelectedImage exported successfully to $exportPath", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                $outputTextBox.AppendText("Export failed.`r`n")
                [System.Windows.Forms.MessageBox]::Show("Failed to export WEnix Image. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } catch {
            $outputTextBox.AppendText("Exception occurred: $_`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $backupForm.Controls.Add($executeButton)

    $backupForm.ShowDialog()
}
