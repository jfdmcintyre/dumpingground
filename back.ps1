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

            # Check if the checkbox is checked to add the wnx_setup file
            if ($addSetupFileCheckbox.Checked) {
                $setupFilePath = "/home/wsl2user/wnx_setup"
                $outputTextBox.AppendText("Adding wnx_setup file to WSL image...`r`n")
                # Create the file in the WSL image
                wsl.exe --system -d $global:SelectedImageForBackup bash -c "echo 'Setup file for WEnix' > $setupFilePath"
            }

            $command = "wsl.exe --export `"$global:SelectedImageForBackup`" `"$exportPath`""
            $outputTextBox.AppendText("Executing command: $command`r`n")
            Show-Notification -Title "Backup Started" -Message "WEnix Image $global:SelectedImageForBackup is currently being backed up. This Process can take up to 5 minutes." -Icon info

            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", "`"$global:SelectedImageForBackup`"", "`"$exportPath`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\export_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\export_error.log"

            $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
            $stdout = Get-Content "C:\_WSL2\_APPLOG\export_output.log" -Raw
            $stderr = Get-Content "C:\_WSL2\_APPLOG\export_error.log" -Raw
            $outputTextBox.AppendText("Standard Output: $stdout`r`n")
            $outputTextBox.AppendText("Standard Error: $stderr`r`n")

            if ($process.ExitCode -eq 0) {
                $outputTextBox.AppendText("Export successful.`r`n")
                Show-Notification -Title "Success" -Message "WEnix Image $global:SelectedImageForBackup exported successfully to $exportPath" -icon info
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


# Add a checkbox for adding the wnx_setup file
$addSetupFileCheckbox = New-Object System.Windows.Forms.CheckBox
$addSetupFileCheckbox.Location = New-Object System.Drawing.Point(10, 360)
$addSetupFileCheckbox.Size = New-Object System.Drawing.Size(250, 20)
$addSetupFileCheckbox.Text = "Add wnx_setup file to WSL image"
$wslBackupForm.Controls.Add($addSetupFileCheckbox)