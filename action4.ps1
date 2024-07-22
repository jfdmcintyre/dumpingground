Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing



    $wslBackupForm = New-Object System.Windows.Forms.Form
    $wslBackupForm.Text = "WEnix Image Backup"
    $wslBackupForm.Size = New-Object System.Drawing.Size(600, 600)
    $wslBackupForm.StartPosition = "CenterScreen"
    $wslBackupForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $label1.Size = New-Object System.Drawing.Size(565, 20)
    $label1.Text = "Selected Image: $global:SelectedImageForBackup"
    $label1.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label1.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label1)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 50)
    $label2.Size = New-Object System.Drawing.Size(565, 20)
    $label2.Text = "Enter export file name: (don't use spaces)"
    $label2.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label2.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label2)

    $exportNameTextBox = New-Object System.Windows.Forms.TextBox
    $exportNameTextBox.Location = New-Object System.Drawing.Point(10, 80)
    $exportNameTextBox.Size = New-Object System.Drawing.Size(565, 20)
    $wslBackupForm.Controls.Add($exportNameTextBox)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Location = New-Object System.Drawing.Point(10, 110)
    $label3.Size = New-Object System.Drawing.Size(565, 20)
    $label3.Text = "Select export location (leave blank for default C:\_WSL2):"
    $label3.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label3.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label3)

    $exportLocationTextBox = New-Object System.Windows.Forms.TextBox
    $exportLocationTextBox.Location = New-Object System.Drawing.Point(10, 140)
    $exportLocationTextBox.Size = New-Object System.Drawing.Size(450, 20)
    $wslBackupForm.Controls.Add($exportLocationTextBox)

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
    $wslBackupForm.Controls.Add($browseButton)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 180)
    $outputTextBox.Size = New-Object System.Drawing.Size(565, 130)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $wslBackupForm.Controls.Add($outputTextBox)

    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Location = New-Object System.Drawing.Point(10, 320)
    $executeButton.Size = New-Object System.Drawing.Size(565, 30)
    $executeButton.Text = "Export WEnix Image"
    $executeButton.BackColor = [System.Drawing.Color]::White
    $executeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $executeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $executeButton.Add_Click({
        $exportName = $exportNameTextBox.Text.Trim()
        $exportLocation = $exportLocationTextBox.Text.Trim()
        $outputTextBox.Clear()
        $outputTextBox.AppendText("Selected Image: $global:SelectedImageForBackup`r`nExport Name: $exportName`r`n")

        if ($exportName) {
            if (-not $exportName.EndsWith(".tar")) {
                $exportName += ".tar"
            }
            if ($exportLocation -eq "") {
                $exportLocation = "C:\_WSL2"
            }
            
            $exportPath = Join-Path $exportLocation $exportName
            $outputTextBox.AppendText("Export Path: $exportPath`r`n")

            try {
                if (-not (Test-Path $exportLocation)) {
                    New-Item -ItemType Directory -Path $exportLocation | Out-Null
                    $outputTextBox.AppendText("Created directory: $exportLocation`r`n")
                }

                $command = "wsl.exe --export `"$global:SelectedImageForBackup`" `"$exportPath`""
                $outputTextBox.AppendText("Executing command: $command`r`n")

                #Show-Notification -Title "Backup Started" -Message "WEnix Image $global:SelectedImageForBackup is currently being backed up. This Process can take up to 5 minutes." -Icon info

                $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", "`"$global:SelectedImageForBackup`"", "`"$exportPath`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\export_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\export_error.log"

                $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
                $stdout = Get-Content "C:\_WSL2\_APPLOG\export_output.log" -Raw
                $stderr = Get-Content "C:\_WSL2\_APPLOG\export_error.log" -Raw
                $outputTextBox.AppendText("Standard Output: $stdout`r`n")
                $outputTextBox.AppendText("Standard Error: $stderr`r`n")

                if ($process.ExitCode -eq 0) {
                    $outputTextBox.AppendText("Export successful.`r`n")
                    #Show-Notification -Title "Success" -Message "WEnix Image $global:SelectedImageForBackup exported successfully to $exportPath" -icon info
                } else {
                    $outputTextBox.AppendText("Export failed.`r`n")
                    [System.Windows.Forms.MessageBox]::Show("Failed to export WEnix Image. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            } catch {
                $outputTextBox.AppendText("Exception occurred: $_`r`n")
                [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            $outputTextBox.AppendText("Missing information. Please enter an export name.`r`n")
            [System.Windows.Forms.MessageBox]::Show("Please enter an export file name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    $wslBackupForm.Controls.Add($executeButton)

    $wslBackupForm.ShowDialog()

