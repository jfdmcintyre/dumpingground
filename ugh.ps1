Import-Module .\styles.ps1
Import-Module .\functions.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
function Show-Notification {
    param(
        [string]$title,
        [string]$Message,
        [System.Windows.Forms.ToolTipIcon]$Icon = [System.Windows.Forms.ToolTipIcon]::info
    )

    $balloon = New-Object System.Windows.Forms.NotifyIcon
    $balloon.Icon = [System.Drawing.SystemIcons]::Information
    $balloon.BalloonTipIcon = $Icon
    $balloon.BalloonTipTitle = $Title
    $balloon.BalloonTipText = $Message
    $balloon.Visible = $true
    $balloon.ShowBalloonTip(5000)

    #Start-Sleep -Seconds 5
    $balloon.Dispose()
}

# This gains the basic information about installed WSL images, used for simple lists. Mind the console encoding to unicode. this is required.
function Get-WSLImages {
    $originalEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $wslOutput = wsl --list --quiet
    [Console]::OutputEncoding = $originalEncoding
    $images = ($wslOutput -split "`n" | Where-Object { $_.Trim() -ne "" -and $_.Trim() -ne "wsl-vpnkit" }) # vpnkit is ignored, will not show in lists.
    return $images
}

# This gains information from Windows registry about WSL Images used for listview in action 9, refresh # This function is to gain information from Windows Registry target [Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss] for wsl images for: location of image on drive, full name.
function Get-WSLImageDetails {
    $details = @{}
    $lxssPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
    $runningDistros = (wsl --list --running).Split("`n") | Select-Object -Skip 1 | ForEach-Object { $_.Trim() }

    if (Test-Path $lxssPath) {
        Get-ChildItem -Path $lxssPath | ForEach-Object {
            $distroName = $_.GetValue("DistributionName")
            $basePath = $_.GetValue("BasePath")
            if ($distroName -and $basePath) {
                try {
                    $dfOutput = wsl.exe --system -d $distroName df -h /mnt/wslg/distro
                    $sizeInfo = $dfOutput | Select-Object -Last 1
                    if ($sizeInfo -match '\s(\S+)\s+(\S+)\s+(\S+)\s+(\S+)') {
                        $used = $matches[2]
                        $status = if ($runningDistros -contains $distroName) { "Running" } else { "Stopped" }
                        $details[$distroName] = @{
                            Size = $used
                            Location = New-LocationPath $basePath
                            Status = $status
                        }
                    } else {
                        $details[$distroName] = @{
                            Size = "Size unknown"
                            Location = New-LocationPath $basePath
                            Status = if ($runningDistros -contains $distroName) { "Running" } else { "Stopped" }
                        }
                    }
                } catch {
                    $details[$distroName] = @{
                        Size = "Error retrieving size"
                        Location = New-LocationPath $basePath
                        Status = if ($runningDistros -contains $distroName) { "Running" } else { "Stopped" }
                    }
                }
            }
        }
    }
    return $details
}


# This function is for the listing of wsl images saved outside of [user\appdata\local\packages]. cleans display and removes display junk \\?\^ at beginning of disk drive letter.
function New-LocationPath {
    param([string]$path)
    return $path -replace '^\\\\\?\\', ''
}

# This function is to gain drive(s) information of computer,
function Update-DiskSpaceInfo {
    $diskSpaceListView.Items.Clear()
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $drive = $_.Root
        $totalSpace = [math]::Round($_.Used / 1GB + $_.Free / 1GB, 2)
        $freeSpace = [math]::Round($_.Free / 1GB, 2)
        $freePercentage = [math]::Round(($_.Free / ($_.Used + $_.Free)) * 100, 2)

        $item = New-Object System.Windows.Forms.ListViewItem($drive)
        $item.SubItems.Add("$totalSpace GB")
        $item.SubItems.Add("$freeSpace GB")
        $item.SubItems.Add("$freePercentage%")
        $diskSpaceListView.Items.Add($item)
    }
}
function Set-Watermark {
    param (
        [System.Windows.Forms.TextBox]$TextBox,
        [string]$Watermark
    )

    $TextBox.ForeColor = [System.Drawing.Color]::Gray
    $TextBox.Text = $Watermark

    $TextBox.Add_GotFocus({
        if ($this.Text -eq $Watermark) {
            $this.Text = ""
            $this.ForeColor = [System.Drawing.Color]::Black
        }
    })


    $TextBox.Add_LostFocus({
        if ($this.Text -eq "") {
            $this.ForeColor = [System.Drawing.Color]::Gray
            $this.Text = $Watermark
        }
    })
}

# Action for Button 9, This is a section for WSL Image status, Computer disk(s) storage and Sparse VHD option for wsl images.
$statusForm = New-Object System.Windows.Forms.Form # this is the main window for action 9, called $statusform
$statusForm.Text = "WEnix Image Status and Disk Space"
$statusForm.Size = New-Object System.Drawing.Size(800, 700)  # Increased height for new labels
$statusForm.StartPosition = "CenterScreen"
New-FormStyle -form $statusForm
Show-Notification -Title "WEnix Image Status Loading" -Message "WEnix Image status is currently loading information from WIndows Registry, Please wait." -Icon info


$InstructionLabel = New-Object System.Windows.Forms.Label
$InstructionLabel.Location = New-Object System.Drawing.Point(10, 10)
$InstructionLabel.Size = New-Object System.Drawing.Size(765, 20)
$InstructionLabel.Text = "Highlight the image you want to interact with. Right click for options, Double click to load"
New-LabelStyle -label $InstructionLabel
$statusForm.Controls.Add($InstructionLabel)

# This is the display list of all wsl images registered on computer. (excluding wsl-vpnkit)
$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10, 35)
$listView.Size = New-Object System.Drawing.Size(765, 180)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
New-outputStyle -outputTextBox $listView

$listView.Columns.Clear()
$listView.Columns.Add("WEnix Image", 150)
$listView.Columns.Add("Status", 80)
$listView.Columns.Add("VHD Size", 80)
$listView.Columns.Add("Location", 440)

$statusForm.Controls.Add($listView)

# This adds a WEnix image loader in the listview. No need to leave the window to turn on any WEnix image.
$listView.Add_DoubleClick({
    if ($listView.SelectedItems.Count -eq 1) {
        $selectedImage = $listView.SelectedItems[0].Text
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Do you want to load $selectedImage ?",
            "Load WEnix Image",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                Start-Process -FilePath "wsl.exe" -ArgumentList "-d", $selectedImage -PassThru
                Show-Notification -Title "WEnix Image Loaded" -Message "WEnix Image '$selectedImage' has been loaded." -Icon Info # Windows popup notification or success
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to load WEnix Image $selectedImage. Error: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    }
})

# Disk space information label
$diskSpaceLabel = New-Object System.Windows.Forms.Label
$diskSpaceLabel.Location = New-Object System.Drawing.Point(10, 220)
$diskSpaceLabel.Size = New-Object System.Drawing.Size(765, 20)
$diskSpaceLabel.Text = "Disk space available:"
$diskSpaceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$diskSpaceLabel.ForeColor = [System.Drawing.Color]::FromArgb(3, 130 ,3)
$statusForm.Controls.Add($diskSpaceLabel)

$diskSpaceListView = New-Object System.Windows.Forms.ListView
$diskSpaceListView.Location = New-Object System.Drawing.Point(10, 245)
$diskSpaceListView.Size = New-Object System.Drawing.Size(765, 150)
$diskSpaceListView.View = [System.Windows.Forms.View]::Details
$diskSpaceListView.FullRowSelect = $true
$diskSpaceListView.BackColor = [System.Drawing.Color]::FromArgb(236, 246, 233)
$diskSpaceListView.ForeColor = [System.Drawing.Color]::Black
$diskSpaceListView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(10, 410)
$outputTextBox.Size = New-Object System.Drawing.Size(765, 150)
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = "Vertical"
$outputTextBox.ReadOnly = $true
$outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$outputTextBox.ForeColor = [System.Drawing.Color]::Black
$outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(236, 246, 233)
$statusForm.Controls.Add($outputTextBox)

$diskSpaceListView.Columns.Add("Drive", 100)
$diskSpaceListView.Columns.Add("Total Space", 150)
$diskSpaceListView.Columns.Add("Free Space", 150)
$diskSpaceListView.Columns.Add("Free Space %", 150)

$statusForm.Controls.Add($diskSpaceListView)


# This is a fix to update the list in action 9 after installing an image. This is done with a timer looking for a trigger file. When file is found, turn on the action to refresh. action 5 uses this after install is complete.
$refreshTimer = New-Object System.Windows.Forms.Timer
$refreshTimer.Interval = 1000
$refreshTimer.Add_Tick({
    $triggerFile = ".\refresh_action9.trigger"
    if (Test-Path $triggerFile) {
        $listView.Items.Clear()
$outputTextBox.Clear()
$wslImages = Get-WSLImages
$wslDetails = Get-WSLImageDetails
$outputTextBox.AppendText("WSL Images found: $($wslImages.Count)`r`n")
$outputTextBox.AppendText("WSL Details retrieved: $($wslDetails.Count)`r`n")
foreach ($image in $wslImages) {
    $details = $wslDetails[$image]
        if ($details) {
            $location = $details.Location
            $size = $details.Size
        } else {
            $location = "Location not found"
            $size = "Size unknown"
        }
$outputTextBox.AppendText("Image: $image, Size: $size, Location: $location`r`n")
$listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
$listViewItem.SubItems.Add($size)
$listViewItem.SubItems.Add($location)
$listView.Items.Add($listViewItem)
}
Update-DiskSpaceInfo
    }
    Remove-Item $triggerFile -Force
})
$refreshTimer.Start()

$wslImages = Get-WSLImages
$wslDetails = Get-WSLImageDetails
$outputTextBox.AppendText("WSL Images found: $($wslImages.Count)`r`n")
$outputTextBox.AppendText("WSL Details retrieved: $($wslDetails.Count)`r`n")

foreach ($image in $wslImages) {
    $details = $wslDetails[$image]
    if ($details) {
        $location = $details.Location
        $size = $details.Size
        $status = $details.Status
    } else {
        $location = "Location not found"
        $size = "Size unknown"
        $status = "Unknown"
    }
    $outputTextBox.AppendText("Image: $image, Status: $status, Size: $size, Location: $location`r`n")
    $listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
    $listViewItem.SubItems.Add($status)
    $listViewItem.SubItems.Add($size)
    $listViewItem.SubItems.Add($location)
    $listView.Items.Add($listViewItem)
}



Update-DiskSpaceInfo

$setSparseButton = New-Object System.Windows.Forms.Button
$setSparseButton.Location = New-Object System.Drawing.Point(10, 570)
$setSparseButton.Size = New-Object System.Drawing.Size(180, 30)
$setSparseButton.Text = "Set Sparse VHD"
$setSparseButton.BackColor = [System.Drawing.Color]::White
$setSparseButton.ForeColor = [System.Drawing.Color]::FromArgb(03, 130 ,3)
$setSparseButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$setSparseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$setSparseButton.Add_Click({
    $selectedItems = $listView.SelectedItems
    if ($selectedItems.Count -gt 0) {
        $distro = $selectedItems[0].Text

        $result = [System.Windows.Forms.MessageBox]::Show(
            "Do you want to set Sparse VHD for $distro ? Make sure to save your work on all images, this process shuts down WSL",
            "Confirm Sparse VHD Change",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )

        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            Show-Notification -Title "WSL Shutdown and Sparse VHD started" -Message "WSL is currently being shut down to apply VHD changes for selected image: $distro " -Icon info
            $outputTextBox.AppendText("Shutting down WSL...`r`n")
            $shutdownProcess = Start-Process -FilePath "wsl.exe" -ArgumentList "--shutdown" -NoNewWindow -Wait -PassThru
            if ($shutdownProcess.ExitCode -eq 0) {
                $outputTextBox.AppendText("WSL shut down successfully.`r`n")
                $outputTextBox.AppendText("Setting Sparse VHD for $distro...`r`n")
                $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--manage", $distro, "--set-sparse", "true" -NoNewWindow -Wait -PassThru
                if ($process.ExitCode -eq 0) {
                    $outputTextBox.AppendText("Sparse VHD setting updated successfully.`r`n")
                    Show-Notification -Title "Sparse VHD Complete." -Message "Sparse VHD setting updated for $distro successfully." -Icon info
                } else {
                    $outputTextBox.AppendText("Failed to update Sparse VHD setting.`r`n")
                }
            } else {
                $outputTextBox.AppendText("Failed to shut down WSL.`r`n")
            }
        }
    } else {
        $outputTextBox.AppendText("Please select a WEnix image first.`r`n")
    }
})
$statusForm.Controls.Add($setSparseButton)

$backupButton = New-Object System.Windows.Forms.Button
$backupButton.Location = New-Object System.Drawing.Point(10, 610)
$backupButton.Size = New-Object System.Drawing.Size(180, 30)
$backupButton.Text = "Backup"
$backupButton.BackColor = [System.Drawing.Color]::White
$backupButton.ForeColor = [System.Drawing.Color]::FromArgb(03, 130 ,3)
$backupButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$backupButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$backupButton.Add_Click({
    if ($listView.SelectedItems.Count -eq 1) {
        $selectedImage = $listView.SelectedItems[0].Text
        $global:SelectedImageForBackup = $selectedImage
        ./actions/action4.ps1
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a WEnix image to backup.", "No Image Selected",
        [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
$statusForm.Controls.Add($backupButton)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Location = New-Object System.Drawing.Point(200, 610)
$removeButton.Size = New-Object System.Drawing.Size(180, 30)
$removeButton.Text = "Remove"
$removeButton.BackColor = [System.Drawing.Color]::White
$removeButton.ForeColor = [System.Drawing.Color]::FromArgb(03, 130 ,3)
$removeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$removeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$removeButton.Add_Click(({
    if ($listView.SelectedItems.Count -eq 1) {
        $selectedImage = $listView.SelectedItems[0].Text

    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a WEnix image to backup.", "No Image Selected",
        [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

        $result = [System.Windows.Forms.MessageBox]::Show(
            "Make sure you have made a full backup of this Image before deleting! Use Backup WEnix feature for image : $selectedImage",
            "Remove WEnix Image, $selectedImage",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
            )
        if ($result -eq [System.Windows.Forms.DialogResult]::No){
            return
        }
    if ($selectedImage) {
        $confirmForm = New-Object System.Windows.Forms.Form
        $confirmForm.Text = "Confirm WEnix Image Removal"
        $confirmForm.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $confirmForm.Size = New-Object System.Drawing.Size(400, 200)
        $confirmForm.StartPosition = "CenterScreen"
        $confirmForm.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)

        $warningLabel = New-Object System.Windows.Forms.Label
        $warningLabel.Location = New-Object System.Drawing.Point(10, 20)
        $warningLabel.Size = New-Object System.Drawing.Size(385, 40)
        $warningLabel.Text = "WARNING: There is no recovery from removal. To proceed, type 'DELETE' in the box below:"
        $warningLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $warningLabel.ForeColor = [System.Drawing.Color]::FromArgb(3, 130 ,3)
        $confirmForm.Controls.Add($warningLabel)

        $confirmTextBox = New-Object System.Windows.Forms.TextBox
        $confirmTextBox.Location = New-Object System.Drawing.Point(10, 70)
        $confirmTextBox.Size = New-Object System.Drawing.Size(360, 20)
        $confirmForm.Controls.Add($confirmTextBox)

        $confirmButton = New-Object System.Windows.Forms.Button
        $confirmButton.Location = New-Object System.Drawing.Point(10, 115)
        $confirmButton.Size = New-Object System.Drawing.Size(360, 40)
        $confirmButton.Text = "Confirm Removal"
        $confirmButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $confirmButton.BackColor = [System.Drawing.Color]::White
        $confirmButton.ForeColor = [System.Drawing.Color]::FromArgb(3, 130, 3)
        $confirmButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $confirmButton.Add_Click({
            if ($confirmTextBox.Text -ceq "DELETE") {
                $confirmForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $confirmForm.Close()
            } else {
                [System.Windows.Forms.MessageBox]::Show("Please type 'DELETE' to confirm.", "Invalid Confirmation", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
        })
        $confirmForm.Controls.Add($confirmButton)

        $confirmResult = $confirmForm.ShowDialog()

        if ($confirmResult -eq [System.Windows.Forms.DialogResult]::OK) {
            $outputTextBox.Clear()
            $outputTextBox.AppendText("Removing WEnix Image: $selectedImage`r`n")

            try {
                $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--unregister", $selectedImage -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\remove_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\remove_error.log"

                $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")

                $stdout = Get-Content "C:\_WSL2\_APPLOG\remove_output.log" -Raw
                $stderr = Get-Content "C:\_WSL2\_APPLOG\remove_error.log" -Raw

                $outputTextBox.AppendText("Standard Output: $stdout`r`n")
                $outputTextBox.AppendText("Standard Error: $stderr`r`n")

                if ($process.ExitCode -eq 0) {
                    $outputTextBox.AppendText("WEnix Image removal successful.`r`n")
                    Show-Notification -Title "Success" -Message "WEnix Image $selectedImage removed successfully." -Icon Info
                    $listView.Items.Clear()
$outputTextBox.Clear()
$wslImages = Get-WSLImages
$wslDetails = Get-WSLImageDetails
$outputTextBox.AppendText("WSL Images found: $($wslImages.Count)`r`n")
$outputTextBox.AppendText("WSL Details retrieved: $($wslDetails.Count)`r`n")
foreach ($image in $wslImages) {
    $details = $wslDetails[$image]
        if ($details) {
            $location = $details.Location
            $size = $details.Size
        } else {
            $location = "Location not found"
            $size = "Size unknown"
        }
$outputTextBox.AppendText("Image: $image, Size: $size, Location: $location`r`n")
$listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
$listViewItem.SubItems.Add($size)
$listViewItem.SubItems.Add($location)
$listView.Items.Add($listViewItem)
}
Update-DiskSpaceInfo
                } else {
                    $outputTextBox.AppendText("WEnix Image removal failed.`r`n")
                    [System.Windows.Forms.MessageBox]::Show("Failed to remove WEnix Image. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            catch {
                $outputTextBox.AppendText("Exception occurred: $_`r`n")
                [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    } else {
        $outputTextBox.AppendText("Missing information. Please enter an image name.`r`n")
        [System.Windows.Forms.MessageBox]::Show("Please enter a WEnix image name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
}))
$statusForm.Controls.Add($removeButton)

$installButton = New-Object System.Windows.Forms.Button
$installButton.Location = New-Object System.Drawing.Point(400, 610)
$installButton.Size = New-Object System.Drawing.Size(180, 30)
$installButton.Text = "Install"
$installButton.BackColor = [System.Drawing.Color]::White
$installButton.ForeColor = [System.Drawing.Color]::FromArgb(03, 130 ,3)
$installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$installButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$installButton.Add_Click({
    ./actions/action5.ps1
})
$statusForm.Controls.Add($installButton)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Location = New-Object System.Drawing.Point(200, 570)
$refreshButton.Size = New-Object System.Drawing.Size(100, 30)
$refreshButton.Text = "Refresh"
$refreshButton.BackColor = [System.Drawing.Color]::White
$refreshButton.ForeColor = [System.Drawing.Color]::FromArgb(3, 130, 3)
$refreshButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$refreshButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$refreshButton.Add_Click({
$listView.Items.Clear()
$outputTextBox.Clear()
$wslImages = Get-WSLImages
$wslDetails = Get-WSLImageDetails
$outputTextBox.AppendText("WSL Images found: $($wslImages.Count)`r`n")
$outputTextBox.AppendText("WSL Details retrieved: $($wslDetails.Count)`r`n")
foreach ($image in $wslImages) {
    $details = $wslDetails[$image]
        if ($details) {
            $location = $details.Location
            $size = $details.Size
        } else {
            $location = "Location not found"
            $size = "Size unknown"
        }
$outputTextBox.AppendText("Image: $image, Size: $size, Location: $location`r`n")
$listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
$listViewItem.SubItems.Add($size)
$listViewItem.SubItems.Add($location)
$listView.Items.Add($listViewItem)
}
Update-DiskSpaceInfo
})
$statusForm.Controls.Add($refreshButton)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Point(675, 570)
$closeButton.Size = New-Object System.Drawing.Size(100, 30)
$closeButton.Text = "Close"
$closeButton.BackColor = [System.Drawing.Color]::White
$closeButton.ForeColor = [System.Drawing.Color]::FromArgb(3, 130, 3)
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$closeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$closeButton.Add_Click({ $statusForm.Close()

})
$statusForm.Controls.Add($closeButton)
$statusForm.Add_FormClosed({ $refreshTimer.Stop()})
$statusForm.ShowDialog()








function Get-WSLImageDetails {
    $details = @{}
    $lxssPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
    $runningImages = wsl --list --running | Select-Object -Skip 1 | ForEach-Object { $_.Trim() }

    if (Test-Path $lxssPath) {
        Get-ChildItem -Path $lxssPath | ForEach-Object {
            $distroName = $_.GetValue("DistributionName")
            $basePath = $_.GetValue("BasePath")
            if ($distroName -and $basePath) {
                try {
                    $vhdPath = Join-Path $basePath "ext4.vhdx"
                    $vhdSize = (Get-Item $vhdPath).Length / 1GB
                    $vhdSizeFormatted = "{0:N2} GB" -f $vhdSize
                } catch {
                    $vhdSizeFormatted = "Error retrieving size"
                }
                $status = if ($runningImages -contains $distroName) { "Running" } else { "Stopped" }
                $details[$distroName] = @{
                    Size = $vhdSizeFormatted
                    Location = New-LocationPath $basePath
                    Status = $status
                }
            }
        }
    }
    return $details
}
