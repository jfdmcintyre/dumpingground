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
    $drive = Split-Path -Qualifier $exportPath
    $driveInfo = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'"
    if ($driveInfo) {
        $freeSpace = $driveInfo.FreeSpace
    } else {
        $outputTextBox.AppendText("Failed to get drive information. Aborting export.`r`n")
        return
    }

    # Get WSL image size using wsl command
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

    $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
    $requiredSpaceGB = [math]::Round($requiredSpace / 1GB, 2)

    $outputTextBox.AppendText("Available disk space: $freeSpaceGB GB`r`n")
    $outputTextBox.AppendText("Required disk space: $requiredSpaceGB GB`r`n")

    if ($freeSpace -lt $requiredSpace) {
        $outputTextBox.AppendText("Not enough disk space. Available: $freeSpaceGB GB, Required: $requiredSpaceGB GB`r`n")
        [System.Windows.Forms.MessageBox]::Show("Not enough disk space to export the WEnix image.`nAvailable: $freeSpaceGB GB`nRequired: $requiredSpaceGB GB", "Insufficient Disk Space", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    # Continue with the export process...
}