$action4 = {
    $wslBackupForm = New-Object System.Windows.Forms.Form
    $wslBackupForm.Text = "WEnix Image Backup"
    $wslBackupForm.Size = New-Object System.Drawing.Size(600, 430)
    $wslBackupForm.StartPosition = "CenterScreen"
    $wslBackupForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    # ... (previous code for labels, textboxes, and other controls remains the same)

    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Location = New-Object System.Drawing.Point(10, 515)
    $executeButton.Size = New-Object System.Drawing.Size(280, 30)
    $executeButton.Text = "Export WEnix Image"
    $executeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $executeButton.BackColor = [System.Drawing.Color]::White
    $executeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $executeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(295, 515)
    $closeButton.Size = New-Object System.Drawing.Size(280, 30)
    $closeButton.Text = "Close"
    $closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $closeButton.BackColor = [System.Drawing.Color]::White
    $closeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $closeButton.Add_Click({ $wslBackupForm.Close() })
    $wslBackupForm.Controls.Add($closeButton)

    $global:exportProcess = $null

    $executeButton.Add_Click({
        $selectedImage = $imageNameTextBox.Text.Trim()
        $exportName = $exportNameTextBox.Text.Trim()
        $exportLocation = $exportLocationTextBox.Text.Trim()
        $outputTextBox.Clear()
        $outputTextBox.AppendText("Selected Image: $selectedImage`r`nExport Name: $exportName`r`n")

        if ($selectedImage -and $exportName) {
            if (-not $exportName.EndsWith(".tar")) {
                $exportName += ".tar"
            }
            if ($exportLocation -eq "" -or $exportLocation -eq "Leave blank for default (C:\_WSL2)") {
                $exportLocation = "C:\_WSL2"
            }
            
            $exportPath = Join-Path $exportLocation $exportName
            $outputTextBox.AppendText("Export Path: $exportPath`r`n")

            try {
                if (-not (Test-Path $exportLocation)) {
                    New-Item -ItemType Directory -Path $exportLocation | Out-Null
                    $outputTextBox.AppendText("Created directory: $exportLocation`r`n")
                }

                $command = "wsl.exe --export `"$selectedImage`" `"$exportPath`""
                $outputTextBox.AppendText("Executing command: $command`r`n")

                Show-Notification -Title "Backup Started" -Message "WEnix Image $selectedImage is currently being backed up. This Process can take up to 5 minutes." -Icon info

                $global:exportProcess = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", "`"$selectedImage`"", "`"$exportPath`"" -NoNewWindow -PassThru

                # Create and show the cancel window
                $cancelForm = New-Object System.Windows.Forms.Form
                $cancelForm.Text = "Cancel Export"
                $cancelForm.Size = New-Object System.Drawing.Size(300, 150)
                $cancelForm.StartPosition = "CenterScreen"
                $cancelForm.TopMost = $true
                $cancelForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
                $cancelForm.MaximizeBox = $false
                $cancelForm.MinimizeBox = $false

                $cancelButton = New-Object System.Windows.Forms.Button
                $cancelButton.Location = New-Object System.Drawing.Point(75, 50)
                $cancelButton.Size = New-Object System.Drawing.Size(150, 30)
                $cancelButton.Text = "Cancel Export"
                $cancelButton.Add_Click({
                    if ($global:exportProcess -and -not $global:exportProcess.HasExited) {
                        $global:exportProcess.Kill()
                        $outputTextBox.AppendText("Export process cancelled by user.`r`n")
                    }
                    $cancelForm.Close()
                })
                $cancelForm.Controls.Add($cancelButton)

                $cancelForm.Show()

                $global:exportProcess.WaitForExit()

                $cancelForm.Close()

                $outputTextBox.AppendText("Process Exit Code: $($global:exportProcess.ExitCode)`r`n")
                $stdout = Get-Content "C:\_WSL2\_APPLOG\export_output.log" -Raw
                $stderr = Get-Content "C:\_WSL2\_APPLOG\export_error.log" -Raw
                $outputTextBox.AppendText("Standard Output: $stdout`r`n")
                $outputTextBox.AppendText("Standard Error: $stderr`r`n")

                if ($global:exportProcess.ExitCode -eq 0) {
                    $outputTextBox.AppendText("Export successful.`r`n")
                    Show-Notification -Title "Success" -Message "WEnix Image $selectedImage exported successfully to $exportPath" -icon info
                } else {
                    $outputTextBox.AppendText("Export failed.`r`n")
                    [System.Windows.Forms.MessageBox]::Show("Failed to export WEnix Image. Exit code: $($global:exportProcess.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            } catch {
                $outputTextBox.AppendText("Exception occurred: $_`r`n")
                [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            $outputTextBox.AppendText("Missing information. Please enter an image name and an export name.`r`n")
            [System.Windows.Forms.MessageBox]::Show("Please enter a WEnix image name and an export file name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    $wslBackupForm.Controls.Add($executeButton)

    $wslBackupForm.ShowDialog()
}
