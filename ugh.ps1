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

                $executeButton.Enabled = $true
                $global:exportProcess = $null
                $global:exportCancelled = $false
            }
        })
        $timer.Start()

        $executeButton.Enabled = $false
    } catch {
        $outputTextBox.AppendText("Exception occurred: $_`r`n")
        [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

Now, let's modify the cancel button to work with this new asynchronous process:
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
                $executeButton.Enabled = $true
            } catch {
                $outputTextBox.AppendText("Failed to cancel the export process: $_`r`n")
            }
        }
    } else {
        $wslBackupForm.Close()
    }
})

Finally, let's modify the form closing event:
powershell
$wslBackupForm.Add_FormClosing({
    param($sender, $e)
    if ($global:exportProcess -and -not $global:exportProcess.HasExited) {
        $result = [System.Windows.Forms.MessageBox]::Show(
            "An export process is still running. Are you sure you want to close the window and terminate the process?",
            "Confirm Close",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                $global:exportProcess.Kill()
                $global:exportCancelled = $true
            } catch {
                # Process may have exited already, ignore any errors
            }
        } else {
            $e.Cancel = $true
        }
    }
})