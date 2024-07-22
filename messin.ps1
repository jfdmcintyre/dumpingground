$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(10, 515)
$cancelButton.Size = New-Object System.Drawing.Size(565, 30)
$cancelButton.Text = "Cancel Export"
$cancelButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$cancelButton.BackColor = [System.Drawing.Color]::White
$cancelButton.ForeColor = [System.Drawing.Color]::Red
$cancelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$cancelButton.Visible = $false
$wslBackupForm.Controls.Add($cancelButton)

Now, let's modify the execute button click event to show the cancel button and start the export process asynchronously:
powershell
$global:exportProcess = $null
$global:exportCancelled = $false

$executeButton.Add_Click({
    # ... (previous code remains the same)

    try {
        if (-not (Test-Path $exportLocation)) {
            New-Item -ItemType Directory -Path $exportLocation | Out-Null
            $outputTextBox.AppendText("Created directory: $exportLocation`r`n")
        }

        $command = "wsl.exe --export `"$selectedImage`" `"$exportPath`""
        $outputTextBox.AppendText("Executing command: $command`r`n")

        Show-Notification -Title "Backup Started" -Message "WEnix Image $selectedImage is currently being backed up. This Process can take up to 5 minutes." -Icon info

        $global:exportProcess = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", "`"$selectedImage`"", "`"$exportPath`"" -NoNewWindow -PassThru

        $executeButton.Visible = $false
        $cancelButton.Visible = $true

        # Start an asynchronous job to monitor the export process
        $job = Start-Job -ScriptBlock {
            param($process, $outputPath, $errorPath)
            $process | Wait-Process
            $stdout = Get-Content $outputPath -Raw
            $stderr = Get-Content $errorPath -Raw
            return @{
                ExitCode = $process.ExitCode
                StdOut = $stdout
                StdErr = $stderr
            }
        } -ArgumentList $global:exportProcess, "C:\_WSL2\_APPLOG\export_output.log", "C:\_WSL2\_APPLOG\export_error.log"

        # Start a timer to check the job status
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 1000 # Check every second
        $timer.Add_Tick({
            if ($job.State -eq 'Completed') {
                $timer.Stop()
                $result = Receive-Job $job
                $outputTextBox.AppendText("Process Exit Code: $($result.ExitCode)`r`n")
                $outputTextBox.AppendText("Standard Output: $($result.StdOut)`r`n")
                $outputTextBox.AppendText("Standard Error: $($result.StdErr)`r`n")

                if ($result.ExitCode -eq 0 -and -not $global:exportCancelled) {
                    $outputTextBox.AppendText("Export successful.`r`n")
                    Show-Notification -Title "Success" -Message "WEnix Image $selectedImage exported successfully to $exportPath" -icon info
                } elseif ($global:exportCancelled) {
                    $outputTextBox.AppendText("Export cancelled by user.`r`n")
                } else {
                    $outputTextBox.AppendText("Export failed.`r`n")
                    [System.Windows.Forms.MessageBox]::Show("Failed to export WEnix Image. Exit code: $($result.ExitCode)`r`nError: $($result.StdErr)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }

                $executeButton.Visible = $true
                $cancelButton.Visible = $false
                $global:exportProcess = $null
                $global:exportCancelled = $false
            }
        })
        $timer.Start()
    } catch {
        $outputTextBox.AppendText("Exception occurred: $_`r`n")
        [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

Finally, let's implement the cancel button functionality:
powershell
$cancelButton.Add_Click({
    if ($global:exportProcess -and -not $global:exportProcess.HasExited) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Are you sure you want to cancel the export process?",
            "Confirm Cancel",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                $global:exportProcess.Kill()
                $global:exportCancelled = $true
                $outputTextBox.AppendText("Export process cancelled by user.`r`n")
                $executeButton.Visible = $true
                $cancelButton.Visible = $false
            } catch {
                $outputTextBox.AppendText("Failed to cancel the export process: $_`r`n")
            }
        }
    }
})

