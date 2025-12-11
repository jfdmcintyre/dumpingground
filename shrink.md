# WSL Shrink Image GUI - Standalone with Parameter Support

param(
    [Parameter(Mandatory=$false)]
    [string]$DistroName
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to get human-readable file size
function Get-FormattedSize {
    param([int64]$Bytes)
    
    if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
    elseif ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    elseif ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    else { return "{0} Bytes" -f $Bytes }
}

# Function to get WSL distribution actual used space
function Get-WSLDistributionSize {
    param([string]$DistroName)
    
    try {
        $dfOutput = wsl --system -d $DistroName df -h /mnt/wslg/distro 2>&1
        $lines = $dfOutput -split "`n" | Where-Object { $_ -and $_.Trim() -ne "" }
        
        foreach ($line in $lines) {
            if ($line -match "Filesystem|^$") { continue }
            
            if ($line -match '\s+(\d+\.?\d*[KMGT]?)\s+(\d+\.?\d*[KMGT]?)\s+(\d+\.?\d*[KMGT]?)\s+(\d+)%') {
                $usedStr = $matches[2]
                
                if ($usedStr -match '(\d+\.?\d*)([KMGT]?)') {
                    $value = [double]$matches[1]
                    $unit = $matches[2]
                    
                    $bytes = switch ($unit) {
                        'T' { [int64]($value * 1TB) }
                        'G' { [int64]($value * 1GB) }
                        'M' { [int64]($value * 1MB) }
                        'K' { [int64]($value * 1KB) }
                        default { [int64]$value }
                    }
                    
                    return $bytes
                }
            }
        }
        
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
        $distros = Get-ChildItem $regPath -ErrorAction SilentlyContinue
        
        foreach ($distro in $distros) {
            $distroProps = Get-ItemProperty $distro.PSPath
            if ($distroProps.DistributionName -eq $DistroName) {
                $basePath = $distroProps.BasePath
                $vhdxPath = Join-Path $basePath "ext4.vhdx"
                
                if (Test-Path $vhdxPath) {
                    $file = Get-Item $vhdxPath
                    return [int64]$file.Length
                }
            }
        }
        
        return 0
    }
    catch {
        return 0
    }
}

# Function to get VHDX file size
function Get-WSLVHDXFileSize {
    param([string]$DistroName)
    
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
        $distros = Get-ChildItem $regPath -ErrorAction SilentlyContinue
        
        foreach ($distro in $distros) {
            $distroProps = Get-ItemProperty $distro.PSPath
            if ($distroProps.DistributionName -eq $DistroName) {
                $basePath = $distroProps.BasePath
                $vhdxPath = Join-Path $basePath "ext4.vhdx"
                
                if (Test-Path $vhdxPath) {
                    $file = Get-Item $vhdxPath
                    return @{
                        Size = [int64]$file.Length
                        Path = $vhdxPath
                        BasePath = $basePath
                    }
                }
            }
        }
        return @{ Size = 0; Path = ""; BasePath = "" }
    }
    catch {
        return @{ Size = 0; Path = ""; BasePath = "" }
    }
}

# Function to get available disk space
function Get-AvailableDiskSpace {
    param([string]$Path)
    
    $drive = Split-Path -Path $Path -Qualifier
    if (-not $drive) {
        $drive = $env:SystemDrive
    }
    
    $disk = Get-PSDrive -Name $drive.TrimEnd(':')
    return $disk.Free
}

# Function to get distribution info
function Get-WSLDistributionInfo {
    param([string]$DistroName)
    
    $wslPath = (Get-Command wsl.exe).Source
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $wslPath
    $psi.Arguments = "--list --verbose"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.StandardOutputEncoding = [System.Text.Encoding]::Unicode

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $null = $process.Start()

    $outputString = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()

    $lines = $outputString -split "`r`n|`n" | Where-Object { $_ -and $_.Trim() -ne "" }

    foreach ($line in $lines) {
        if ($line -match "NAME|^\s*-+\s*$|Windows Subsystem") { 
            continue 
        }
        
        $cleanLine = $line.Trim()
        
        if ($cleanLine -match '^\*?\s*([^\s]+.*?)\s+(Stopped|Running)\s+(\d+)\s*$') {
            $distroNameParsed = $matches[1].Trim() -replace '^\*\s*', ''
            
            if ($distroNameParsed -eq $DistroName) {
                return [PSCustomObject]@{
                    Name    = $distroNameParsed
                    State   = $matches[2]
                    Version = $matches[3]
                }
            }
        }
    }
    
    return $null
}

# Function to add log entry
function Add-LogEntry {
    param([string]$Message, [string]$Color = "Black")
    
    $script:logBox.SelectionStart = $script:logBox.TextLength
    $script:logBox.SelectionLength = 0
    $script:logBox.SelectionColor = [System.Drawing.Color]::FromName($Color)
    $script:logBox.AppendText("$Message`r`n")
    $script:logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# Validate distribution name was provided
if (-not $DistroName) {
    [System.Windows.Forms.MessageBox]::Show(
        "No distribution name provided. This script should be launched from WSL-Manager.ps1",
        "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

# Get distribution info
$distroInfo = Get-WSLDistributionInfo -DistroName $DistroName

if (-not $distroInfo) {
    [System.Windows.Forms.MessageBox]::Show(
        "Distribution '$DistroName' not found.",
        "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Shrink WSL Image: $DistroName"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Create title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.Size = New-Object System.Drawing.Size(760, 40)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.Text = "WSL Distribution Size Optimizer"
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)

# Create distribution name label
$distroNameLabel = New-Object System.Windows.Forms.Label
$distroNameLabel.Location = New-Object System.Drawing.Point(10, 50)
$distroNameLabel.Size = New-Object System.Drawing.Size(760, 30)
$distroNameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$distroNameLabel.Text = $DistroName
$distroNameLabel.TextAlign = "MiddleCenter"
$distroNameLabel.ForeColor = [System.Drawing.Color]::DarkBlue
$form.Controls.Add($distroNameLabel)

# Create info group
$infoGroupBox = New-Object System.Windows.Forms.GroupBox
$infoGroupBox.Location = New-Object System.Drawing.Point(10, 90)
$infoGroupBox.Size = New-Object System.Drawing.Size(760, 180)
$infoGroupBox.Text = "Distribution Information"
$form.Controls.Add($infoGroupBox)

# Create info labels
$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Location = New-Object System.Drawing.Point(10, 25)
$infoLabel.Size = New-Object System.Drawing.Size(740, 145)
$infoLabel.Font = New-Object System.Drawing.Font("Consolas", 9)
$infoLabel.Text = "Analyzing..."
$infoGroupBox.Controls.Add($infoLabel)

# Create action buttons
$shrinkButton = New-Object System.Windows.Forms.Button
$shrinkButton.Location = New-Object System.Drawing.Point(10, 280)
$shrinkButton.Size = New-Object System.Drawing.Size(150, 40)
$shrinkButton.Text = "Shrink Image"
$shrinkButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$shrinkButton.BackColor = [System.Drawing.Color]::LightGreen
$shrinkButton.Enabled = $false
$form.Controls.Add($shrinkButton)

# Create progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 325)
$progressBar.Size = New-Object System.Drawing.Size(760, 25)
$progressBar.Style = "Continuous"
$form.Controls.Add($progressBar)

# Create log group
$logGroupBox = New-Object System.Windows.Forms.GroupBox
$logGroupBox.Location = New-Object System.Drawing.Point(10, 360)
$logGroupBox.Size = New-Object System.Drawing.Size(760, 190)
$logGroupBox.Text = "Operation Log"
$form.Controls.Add($logGroupBox)

# Create log box
$script:logBox = New-Object System.Windows.Forms.RichTextBox
$script:logBox.Location = New-Object System.Drawing.Point(10, 25)
$script:logBox.Size = New-Object System.Drawing.Size(740, 155)
$script:logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$script:logBox.ReadOnly = $true
$script:logBox.BackColor = [System.Drawing.Color]::White
$logGroupBox.Controls.Add($script:logBox)

# Script-level variables
$script:selectedDistro = $distroInfo
$script:distroSize = 0
$script:vhdxFileSize = 0
$script:vhdxPath = ""
$script:basePath = ""

# Shrink button click event
$shrinkButton.Add_Click({
    try {
        if (-not $script:selectedDistro) {
            return
        }
        
        # Check if running and offer to stop
        if ($script:selectedDistro.State -eq "Running") {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Distribution '$($script:selectedDistro.Name)' is currently running.`r`n`r`n" +
                "For the best results, it must be stopped before shrinking.`r`n`r`n" +
                "Would you like to stop it now and continue?",
                "Distribution Running",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Add-LogEntry "Stopping distribution..." "Blue"
                try {
                    wsl --terminate $script:selectedDistro.Name
                    Start-Sleep -Seconds 2
                    Add-LogEntry "Distribution stopped successfully." "Green"
                    $script:selectedDistro.State = "Stopped"
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Error stopping distribution: $_`r`n`r`nShrink operation cancelled.",
                        "Error",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                    Add-LogEntry "Error stopping distribution: $_" "Red"
                    return
                }
            }
            else {
                Add-LogEntry "Operation cancelled by user." "Blue"
                return
            }
        }
        
        # Check disk space
        $tempPath = $env:TEMP
        $requiredSpace = [int64]($script:distroSize * 1.5)
        $availableSpace = Get-AvailableDiskSpace -Path $tempPath
        
        if ($availableSpace -lt $requiredSpace) {
            [System.Windows.Forms.MessageBox]::Show(
                "Insufficient disk space!`r`n`r`n" +
                "Available: $(Get-FormattedSize $availableSpace)`r`n" +
                "Required: $(Get-FormattedSize $requiredSpace)`r`n`r`n" +
                "Please free up disk space and try again.",
                "Insufficient Space",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            Add-LogEntry "Error: Insufficient disk space" "Red"
            return
        }
        
        # Confirm operation
        $wastedSpace = $script:vhdxFileSize - $script:distroSize
        $confirmText = "SHRINK WSL IMAGE`r`n`r`n" +
                      "Distribution: $($script:selectedDistro.Name)`r`n" +
                      "Actual data used: $(Get-FormattedSize $script:distroSize)`r`n" +
                      "Current VHDX size: $(Get-FormattedSize $script:vhdxFileSize)`r`n" +
                      "Wasted space: $(Get-FormattedSize $wastedSpace)`r`n`r`n" +
                      "This will:`r`n" +
                      "1. Export only the actual data ($(Get-FormattedSize $script:distroSize))`r`n" +
                      "2. Remove the old bloated VHDX file`r`n" +
                      "3. Create a fresh, compact VHDX`r`n" +
                      "4. Your files and settings will be preserved`r`n`r`n" +
                      "Proceed with operation?"
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            $confirmText,
            "Confirm Shrink Operation",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
            Add-LogEntry "Operation cancelled by user." "Blue"
            return
        }
        
        # Disable controls
        $shrinkButton.Enabled = $false
        
        # Start operation
        $progressBar.Style = "Marquee"
        
        # Export
        Add-LogEntry "========================================" "Blue"
        Add-LogEntry "[1/3] Exporting distribution..." "Blue"
        Add-LogEntry "This may take several minutes..." "DarkGray"
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $exportFileName = "$($script:selectedDistro.Name)_backup_$timestamp.tar"
        $exportPath = Join-Path $tempPath $exportFileName
        
        Add-LogEntry "Export location: $exportPath" "DarkGray"
        
        $exportStart = Get-Date
        
        # Start export process asynchronously so we can show progress
        $exportJob = Start-Job -ScriptBlock {
            param($distroName, $exportPath)
            wsl --export $distroName $exportPath 2>&1
        } -ArgumentList $script:selectedDistro.Name, $exportPath
        
        # Monitor progress
        $lastSize = 0
        $dots = 0
        while ($exportJob.State -eq 'Running') {
            Start-Sleep -Milliseconds 500
            
            if (Test-Path $exportPath) {
                $currentSize = (Get-Item $exportPath).Length
                if ($currentSize -ne $lastSize) {
                    $dots = ($dots + 1) % 4
                    $dotString = "." * $dots + " " * (3 - $dots)
                    Add-LogEntry "  Exporting$dotString $(Get-FormattedSize $currentSize)" "DarkGray"
                    $lastSize = $currentSize
                }
            }
            else {
                $dots = ($dots + 1) % 4
                $dotString = "." * $dots + " " * (3 - $dots)
                Add-LogEntry "  Preparing export$dotString" "DarkGray"
            }
            
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        $exportOutput = Receive-Job -Job $exportJob
        Remove-Job -Job $exportJob
        
        $exportEnd = Get-Date
        $exportDuration = ($exportEnd - $exportStart).TotalSeconds
        
        if (Test-Path $exportPath) {
            $exportSize = (Get-Item $exportPath).Length
            Add-LogEntry "Export completed in $([math]::Round($exportDuration, 2)) seconds" "Green"
            Add-LogEntry "Export file size: $(Get-FormattedSize $exportSize)" "Green"
        }
        else {
            throw "Export file was not created"
        }
        
        # Unregister
        Add-LogEntry "`r`n[2/3] Unregistering distribution..." "Blue"
        wsl --unregister $script:selectedDistro.Name
        Add-LogEntry "Distribution unregistered successfully" "Green"
        
        # Import
        Add-LogEntry "`r`n[3/3] Importing distribution..." "Blue"
        Add-LogEntry "This may take several minutes..." "DarkGray"
        
        $importStart = Get-Date
        
        if (-not (Test-Path $script:basePath)) {
            New-Item -Path $script:basePath -ItemType Directory -Force | Out-Null
        }
        
        # Start import process asynchronously so we can show progress
        $importJob = Start-Job -ScriptBlock {
            param($distroName, $basePath, $exportPath, $version)
            wsl --import $distroName $basePath $exportPath --version $version 2>&1
        } -ArgumentList $script:selectedDistro.Name, $script:basePath, $exportPath, $script:selectedDistro.Version
        
        # Monitor progress by checking VHDX file creation/growth
        $vhdxTargetPath = Join-Path $script:basePath "ext4.vhdx"
        $lastSize = 0
        $dots = 0
        
        while ($importJob.State -eq 'Running') {
            Start-Sleep -Milliseconds 500
            
            if (Test-Path $vhdxTargetPath) {
                try {
                    $currentSize = (Get-Item $vhdxTargetPath).Length
                    if ($currentSize -ne $lastSize) {
                        $dots = ($dots + 1) % 4
                        $dotString = "." * $dots + " " * (3 - $dots)
                        $percentComplete = if ($exportSize -gt 0) { [math]::Round(($currentSize / $exportSize) * 100, 0) } else { 0 }
                        Add-LogEntry "  Importing$dotString $(Get-FormattedSize $currentSize) ($percentComplete%)" "DarkGray"
                        $lastSize = $currentSize
                    }
                }
                catch {
                    # File might be locked, just show activity
                    $dots = ($dots + 1) % 4
                    $dotString = "." * $dots + " " * (3 - $dots)
                    Add-LogEntry "  Importing$dotString" "DarkGray"
                }
            }
            else {
                $dots = ($dots + 1) % 4
                $dotString = "." * $dots + " " * (3 - $dots)
                Add-LogEntry "  Preparing import$dotString" "DarkGray"
            }
            
            [System.Windows.Forms.Application]::DoEvents()
        }
        
        $importOutput = Receive-Job -Job $importJob
        Remove-Job -Job $importJob
        
        $importEnd = Get-Date
        $importDuration = ($importEnd - $importStart).TotalSeconds
        
        Add-LogEntry "Import completed in $([math]::Round($importDuration, 2)) seconds" "Green"
        
        # Verify
        Add-LogEntry "`r`nVerifying installation..." "Blue"
        Start-Sleep -Seconds 2
        
        $wslPath = (Get-Command wsl.exe).Source
        $psiVerify = New-Object System.Diagnostics.ProcessStartInfo
        $psiVerify.FileName = $wslPath
        $psiVerify.Arguments = "--list --verbose"
        $psiVerify.RedirectStandardOutput = $true
        $psiVerify.RedirectStandardError = $true
        $psiVerify.UseShellExecute = $false
        $psiVerify.StandardOutputEncoding = [System.Text.Encoding]::Unicode

        $processVerify = New-Object System.Diagnostics.Process
        $processVerify.StartInfo = $psiVerify
        $null = $processVerify.Start()

        $verifyOutput = $processVerify.StandardOutput.ReadToEnd()
        $processVerify.WaitForExit()
        
        if ($verifyOutput -match [regex]::Escape($script:selectedDistro.Name)) {
            Add-LogEntry "SUCCESS: Distribution has been restored!" "Green"
            
            # Calculate savings
            $newDistroSize = Get-WSLDistributionSize -DistroName $script:selectedDistro.Name
            $newVhdxFileSize = (Get-WSLVHDXFileSize -DistroName $script:selectedDistro.Name).Size
            
            $vhdxSpaceSaved = $script:vhdxFileSize - $newVhdxFileSize
            $percentSaved = if ($script:vhdxFileSize -gt 0) { ($vhdxSpaceSaved / $script:vhdxFileSize) * 100 } else { 0 }
            
            Add-LogEntry "`r`n========================================" "Green"
            Add-LogEntry "DISK SPACE RECLAIMED!" "Green"
            Add-LogEntry "========================================" "Green"
            Add-LogEntry "VHDX File Size:" "Blue"
            Add-LogEntry "  Before:       $(Get-FormattedSize $script:vhdxFileSize)" "DarkGray"
            Add-LogEntry "  After:        $(Get-FormattedSize $newVhdxFileSize)" "Green"
            Add-LogEntry "  Space Saved:  $(Get-FormattedSize $vhdxSpaceSaved) ($([math]::Round($percentSaved, 1))%)" "DarkCyan"
            Add-LogEntry "" "Black"
            Add-LogEntry "Actual Data Used:" "Blue"
            Add-LogEntry "  Before:       $(Get-FormattedSize $script:distroSize)" "DarkGray"
            Add-LogEntry "  After:        $(Get-FormattedSize $newDistroSize)" "DarkGray"
            Add-LogEntry "========================================" "Green"
            
            [System.Windows.Forms.MessageBox]::Show(
                "WSL image successfully shrunk!`r`n`r`n" +
                "VHDX space saved: $(Get-FormattedSize $vhdxSpaceSaved) ($([math]::Round($percentSaved, 1))%)`r`n`r`n" +
                "The VHDX file is now compact and matches your actual data usage.",
                "Success",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
        else {
            Add-LogEntry "WARNING: Could not verify restoration." "Red"
        }
        
        # Cleanup
        Add-LogEntry "`r`nCleaning up temporary files..." "Blue"
        $cleanupResult = [System.Windows.Forms.MessageBox]::Show(
            "Delete the temporary export file?`r`n`r`n$exportPath",
            "Cleanup",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        
        if ($cleanupResult -eq [System.Windows.Forms.DialogResult]::Yes) {
            Remove-Item $exportPath -Force
            Add-LogEntry "Temporary file deleted" "Green"
        }
        else {
            Add-LogEntry "Export file preserved at: $exportPath" "Blue"
        }
        
        Add-LogEntry "`r`nOperation complete!" "Green"
        
        # Re-enable controls
        $progressBar.Style = "Continuous"
        $shrinkButton.Enabled = $true
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error during shrink operation: $_",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        Add-LogEntry "ERROR: $_" "Red"
        
        $progressBar.Style = "Continuous"
        $shrinkButton.Enabled = $true
    }
})

# Analyze on form load
$form.Add_Shown({
    $form.Activate()
    
    Add-LogEntry "WSL Distribution Size Optimizer" "Blue"
    Add-LogEntry "Distribution: $($script:selectedDistro.Name)" "Blue"
    Add-LogEntry "Analyzing..." "Blue"
    
    try {
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        # Get VHDX info
        $vhdxInfo = Get-WSLVHDXFileSize -DistroName $script:selectedDistro.Name
        $script:vhdxFileSize = $vhdxInfo.Size
        $script:vhdxPath = $vhdxInfo.Path
        $script:basePath = $vhdxInfo.BasePath
        
        # Get actual used space
        $script:distroSize = Get-WSLDistributionSize -DistroName $script:selectedDistro.Name
        
        if ($script:vhdxFileSize -eq 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "Could not find VHDX file for this distribution.",
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            $form.Close()
            return
        }
        
        # Build info text
        $wastedSpace = $script:vhdxFileSize - $script:distroSize
        $infoText = "Distribution: $($script:selectedDistro.Name)`r`n"
        $infoText += "State: $($script:selectedDistro.State)`r`n"
        $infoText += "Version: WSL $($script:selectedDistro.Version)`r`n"
        $infoText += "`r`n"
        $infoText += "VHDX Location:`r`n$($script:vhdxPath)`r`n"
        $infoText += "`r`n"
        $infoText += "Actual data used:  $(Get-FormattedSize $script:distroSize)`r`n"
        $infoText += "VHDX file size:    $(Get-FormattedSize $script:vhdxFileSize)`r`n"
        
        if ($wastedSpace -gt 0) {
            $infoText += "Wasted space:      $(Get-FormattedSize $wastedSpace)`r`n"
            $infoText += "`r`n"
            $infoText += "This wasted space can be reclaimed!"
        }
        else {
            $infoText += "`r`n"
            $infoText += "Distribution is already fairly optimized."
        }
        
        $infoLabel.Text = $infoText
        
        # Enable buttons
        $shrinkButton.Enabled = $true
        
        Add-LogEntry "Analysis complete." "Green"
        Add-LogEntry "Actual data used: $(Get-FormattedSize $script:distroSize)" "Green"
        Add-LogEntry "VHDX file size: $(Get-FormattedSize $script:vhdxFileSize)" "Green"
        Add-LogEntry "Wasted space: $(Get-FormattedSize $wastedSpace)" "DarkCyan"
        
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Error analyzing distribution: $_",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        Add-LogEntry "Error: $_" "Red"
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        $form.Close()
    }
})

# Show form
[void]$form.ShowDialog()
