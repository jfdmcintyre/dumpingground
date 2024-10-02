function Compress-TarFile {
    param (
        [string]$tarFilePath
    )

    $tarExePath = "C:\Windows\System32\tar.exe"
    if (-not (Test-Path $tarExePath)) {
        Write-Host "tar.exe not found at $tarExePath. Compression skipped."
        return
    }

    $compressedFilePath = $tarFilePath + ".gz"
    $compressionCommand = "& '$tarExePath' -czf '$compressedFilePath' -C '$([System.IO.Path]::GetDirectoryName($tarFilePath))' '$([System.IO.Path]::GetFileName($tarFilePath))'"
    
    Invoke-Expression $compressionCommand

    if (Test-Path $compressedFilePath) {
        Remove-Item $tarFilePath
        Write-Host "Tar file compressed and original removed: $compressedFilePath"
    } else {
        Write-Host "Compression failed."
    }
}


# Action 4: Export and Compress WSL Image
$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Location = New-Object System.Drawing.Point(10, 130)
$exportButton.Size = New-Object System.Drawing.Size(200, 30)
$exportButton.Text = "Export and Compress WSL Image"
New-ButtonStyle -button $exportButton
$exportButton.Add_Click({
    $selectedImage = $imageComboBox.SelectedItem
    if ($selectedImage) {
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveFileDialog.Filter = "Tar Files (*.tar)|*.tar"
        $saveFileDialog.Title = "Export WSL Image"
        $saveFileDialog.ShowDialog()

        if ($saveFileDialog.FileName -ne "") {
            $exportPath = $saveFileDialog.FileName
            $exportCommand = "wsl --export $selectedImage `"$exportPath`""
            
            try {
                Invoke-Expression $exportCommand
                if (Test-Path $exportPath) {
                    Write-Host "WSL image exported successfully to: $exportPath"
                    Compress-TarFile -tarFilePath $exportPath
                } else {
                    Write-Host "Export failed. File not found: $exportPath"
                }
            } catch {
                Write-Host "An error occurred during export: $_"
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a WSL image to export.", "No Image Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$form.Controls.Add($exportButton)






$exportButton.Add_Click({
    $selectedImage = $imageComboBox.SelectedItem
    if ($selectedImage) {
        $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveFileDialog.Filter = "Tar.gz Files (*.tar.gz)|*.tar.gz"
        $saveFileDialog.Title = "Export WSL Image"
        $saveFileDialog.ShowDialog()

        if ($saveFileDialog.FileName -ne "") {
            $compressedPath = $saveFileDialog.FileName

            # Export and compress the WSL image
            $exportProcess = StartProcess -FilePath "wsl.exe" -ArgumentList @("--export", $selectedImage, "-")
            $compressProcess = StartProcess -FilePath "tar.exe" -ArgumentList @("-czf", $compressedPath, "-")

            # Pipe the output of wsl.exe to tar.exe
            $exportProcess.StandardOutput.BaseStream.CopyTo($compressProcess.StandardInput.BaseStream)
            $compressProcess.StandardInput.Close()

            # Wait for both processes to complete
            $exportProcess.WaitForExit()
            $compressProcess.WaitForExit()

            if (($exportProcess.ExitCode -eq 0) -and ($compressProcess.ExitCode -eq 0)) {
                Write-Host "WSL image exported and compressed successfully to: $compressedPath"
            } else {
                Write-Host "Export or compression failed. Export exit code: $($exportProcess.ExitCode), Compress exit code: $($compressProcess.ExitCode)"
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a WSL image to export.", "No Image Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})




$wslProcess = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", $wslDistroName, "-" -NoNewWindow -PassThru -RedirectStandardOutput "NUL"
$sevenZipProcess = Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "a", "-tgzip", $tarGzFileName, "-si" -NoNewWindow -Wait -PassThru -RedirectStandardInput $wslProcess.StandardOutput -RedirectStandardOutput "NUL"