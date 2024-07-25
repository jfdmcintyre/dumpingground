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

        # Create a folder with the same name as the image
        $imageFolderName = $global:SelectedImageForBackup
        $imageFolderPath = Join-Path $exportLocation $imageFolderName
        if (-not (Test-Path $imageFolderPath)) {
            New-Item -ItemType Directory -Path $imageFolderPath | Out-Null
            $outputTextBox.AppendText("Created directory: $imageFolderPath`r`n")
        }

        $exportPath = Join-Path $imageFolderPath $exportName
        $outputTextBox.AppendText("Export Path: $exportPath`r`n")

        # Check available disk space
        $drive = Split-Path -Qualifier $exportPath
        $freeSpace = (Get-PSDrive $drive.TrimEnd(":")).Free

        # Rest of the disk space check and export logic...
        # ...

        try {
            $command = "wsl.exe --export `"$global:SelectedImageForBackup`" `"$exportPath`""
            $outputTextBox.AppendText("Executing command: $command`r`n")
            Show-Notification -Title "Backup Started" -Message "WEnix Image $global:SelectedImageForBackup is currently being backed up. This Process can take up to 5 minutes." -Icon info

            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", "`"$global:SelectedImageForBackup`"", "`"$exportPath`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\export_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\export_error.log"

            # Rest of the process handling code...
            # ...
        }
        catch {
            $outputTextBox.AppendText("Exception occurred: $_`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    else {
        $outputTextBox.AppendText("Missing information. Please enter an export name.`r`n")
        [System.Windows.Forms.MessageBox]::Show("Please enter an export file name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
