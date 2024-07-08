$action9 = {
    $statusForm = New-Object System.Windows.Forms.Form
    $statusForm.Text = "WEnix Image Status"
    $statusForm.Size = New-Object System.Drawing.Size(800, 450)
    $statusForm.StartPosition = "CenterScreen"
    $statusForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(10, 10)
    $listView.Size = New-Object System.Drawing.Size(765, 180)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $listView.ForeColor = [System.Drawing.Color]::White
    $listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $listView.Columns.Add("Distribution", 150)
    $listView.Columns.Add("Size", 80)
    $listView.Columns.Add("Location", 520)

    $statusForm.Controls.Add($listView)

    # Function to get WSL image locations and sizes from registry
    function Get-WSLImageDetails {
        $details = @{}
        $lxssPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
        if (Test-Path $lxssPath) {
            Get-ChildItem -Path $lxssPath | ForEach-Object {
                try {
                    $distroName = $_.GetValue("DistributionName")
                    $basePath = $_.GetValue("BasePath")
                    
                    # Define potential VHDX locations
                    $potentialLocations = @(
                        (Join-Path -Path $basePath -ChildPath "ext4.vhdx"),
                        (Join-Path -Path "C:\_WSL2" -ChildPath "$distroName.vhdx"),
                        (Join-Path -Path $env:USERPROFILE -ChildPath "AppData\Local\Packages\$distroName\LocalState\ext4.vhdx"),
                        (Join-Path -Path "C:\_WSL2" -ChildPath "$distroName\ext4.vhdx")
                    )
                    
                    $vhdxPath = $null
                    foreach ($path in $potentialLocations) {
                        if (Test-Path $path) {
                            $vhdxPath = $path
                            break
                        }
                    }
                    
                    if ($vhdxPath) {
                        $size = (Get-Item $vhdxPath).length / 1GB
                        $details[$distroName] = @{
                            Location = $vhdxPath
                            Size = [math]::Round($size, 2)
                        }
                    } else {
                        $outputTextBox.AppendText("VHDX file not found for $distroName. Checked locations:`r`n")
                        $potentialLocations | ForEach-Object { $outputTextBox.AppendText("  $_`r`n") }
                    }
                } catch {
                    $outputTextBox.AppendText("Error processing $($_.Name): $_`r`n")
                }
            }
        } else {
            $outputTextBox.AppendText("LXSS registry path not found`r`n")
        }
        return $details
    }
    
    

    $wslImages = Get-WSLImages
    $wslDetails = Get-WSLImageDetails

    $outputTextBox.AppendText("WSL Images found: $($wslImages.Count)`r`n")
    $outputTextBox.AppendText("WSL Details retrieved: $($wslDetails.Count)`r`n")

foreach ($image in $wslImages) {
    $details = $wslDetails[$image]
    if ($details) {
        $location = $details.Location
        $size = if ($details.Size -gt 0) { "$($details.Size) GB" } else { "Size unknown" }
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


    $diskSpaceLabel = New-Object System.Windows.Forms.Label
    $diskSpaceLabel.Location = New-Object System.Drawing.Point(10, 200)
    $diskSpaceLabel.Size = New-Object System.Drawing.Size(765, 20)
    $diskSpaceLabel.ForeColor = [System.Drawing.Color]::White
    $diskSpaceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $diskSpace = Get-PSDrive C | Select-Object -ExpandProperty Free
    $diskSpaceGB = [math]::Round($diskSpace / 1GB, 2)
    $diskSpaceLabel.Text = "Available disk space: $diskSpaceGB GB"
    $statusForm.Controls.Add($diskSpaceLabel)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 230)
    $outputTextBox.Size = New-Object System.Drawing.Size(765, 150)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 89)
    $statusForm.Controls.Add($outputTextBox)

    $setSparseButton = New-Object System.Windows.Forms.Button
    $setSparseButton.Location = New-Object System.Drawing.Point(10, 390)
    $setSparseButton.Size = New-Object System.Drawing.Size(180, 30)
    $setSparseButton.Text = "Set Sparse VHD"
    $setSparseButton.BackColor = [System.Drawing.Color]::White
    $setSparseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $setSparseButton.Add_Click({
        $selectedItems = $listView.SelectedItems
        if ($selectedItems.Count -gt 0) {
            $distro = $selectedItems[0].Text
            
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Do you want to set Sparse VHD for $distro?",
                "Confirm Sparse VHD Change",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                $outputTextBox.AppendText("Shutting down WSL...`r`n")
                $shutdownProcess = Start-Process -FilePath "wsl.exe" -ArgumentList "--shutdown" -NoNewWindow -Wait -PassThru
                if ($shutdownProcess.ExitCode -eq 0) {
                    $outputTextBox.AppendText("WSL shut down successfully.`r`n")
                    $outputTextBox.AppendText("Setting Sparse VHD for $distro...`r`n")
                    $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--manage", $distro, "--set-sparse", "true" -NoNewWindow -Wait -PassThru
                    if ($process.ExitCode -eq 0) {
                        $outputTextBox.AppendText("Sparse VHD setting updated successfully.`r`n")
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

    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Location = New-Object System.Drawing.Point(200, 390)
    $refreshButton.Size = New-Object System.Drawing.Size(100, 30)
    $refreshButton.Text = "Refresh"
    $refreshButton.BackColor = [System.Drawing.Color]::White
    $refreshButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $refreshButton.Add_Click({
        $listView.Items.Clear()
        $outputTextBox.AppendText("Refreshing WEnix image list...`r`n")
        $wslImages = Get-WSLImages
        $wslDetails = Get-WSLImageDetails
        foreach ($image in $wslImages) {
            $details = $wslDetails[$image]
            $location = $details.Location ?? "Location not found"
            $size = $details.Size ?? "Size not found"
            $listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
            $listViewItem.SubItems.Add("$size GB")
            $listViewItem.SubItems.Add($location)
            $listView.Items.Add($listViewItem)
        }
        $diskSpace = Get-PSDrive C | Select-Object -ExpandProperty Free
        $diskSpaceGB = [math]::Round($diskSpace / 1GB, 2)
        $diskSpaceLabel.Text = "Available disk space: $diskSpaceGB GB"
        $outputTextBox.AppendText("Refresh complete.`r`n")
    })
    $statusForm.Controls.Add($refreshButton)

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(675, 390)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Text = "Close"
    $closeButton.BackColor = [System.Drawing.Color]::White
    $closeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $closeButton.Add_Click({ $statusForm.Close() })
    $statusForm.Controls.Add($closeButton)

    $statusForm.ShowDialog()
}

$action9 = {
    $statusForm = New-Object System.Windows.Forms.Form
    $statusForm.Text = "WEnix Image Status"
    $statusForm.Size = New-Object System.Drawing.Size(800, 500)
    $statusForm.StartPosition = "CenterScreen"
    $statusForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(10, 10)
    $listView.Size = New-Object System.Drawing.Size(765, 180)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $listView.ForeColor = [System.Drawing.Color]::White
    $listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $listView.Columns.Add("Distribution", 150)
    $listView.Columns.Add("Size", 80)
    $listView.Columns.Add("Location", 520)

    $statusForm.Controls.Add($listView)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 200)
    $outputTextBox.Size = New-Object System.Drawing.Size(765, 150)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 89)
    $statusForm.Controls.Add($outputTextBox)

    function Clean-LocationPath {
        param([string]$path)
        return $path -replace '^\\\\\?\\', ''
    }
    
    function Get-WSLImageDetails {
        $details = @{}
        $lxssPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
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
                            $details[$distroName] = @{
                                Size = $used
                                Location = Clean-LocationPath $basePath
                            }
                        } else {
                            $details[$distroName] = @{
                                Size = "Size unknown"
                                Location = Clean-LocationPath $basePath
                            }
                        }
                    } catch {
                        $details[$distroName] = @{
                            Size = "Error retrieving size"
                            Location = Clean-LocationPath $basePath
                        }
                    }
                }
            }
        }
        return $details
    }
    
    $wslImages = Get-WSLImages
    $wslDetails = Get-WSLImageDetails

    $outputTextBox.AppendText("WSL Images found: $($wslImages.Count)`r`n")
    $outputTextBox.AppendText("WSL Details retrieved: $($wslDetails.Count)`r`n")

    foreach ($image in $wslImages) {
        $details = $wslDetails[$image]
        if ($details) {
            $location = $details.Location  # This should now be the cleaned path
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
    

    $setSparseButton = New-Object System.Windows.Forms.Button
    $setSparseButton.Location = New-Object System.Drawing.Point(10, 360)
    $setSparseButton.Size = New-Object System.Drawing.Size(180, 30)
    $setSparseButton.Text = "Set Sparse VHD"
    $setSparseButton.BackColor = [System.Drawing.Color]::White
    $setSparseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $setSparseButton.Add_Click({
        $selectedItems = $listView.SelectedItems
        if ($selectedItems.Count -gt 0) {
            $distro = $selectedItems[0].Text
            
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Do you want to set Sparse VHD for $distro?",
                "Confirm Sparse VHD Change",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                $outputTextBox.AppendText("Shutting down WSL...`r`n")
                $shutdownProcess = Start-Process -FilePath "wsl.exe" -ArgumentList "--shutdown" -NoNewWindow -Wait -PassThru
                if ($shutdownProcess.ExitCode -eq 0) {
                    $outputTextBox.AppendText("WSL shut down successfully.`r`n")
                    $outputTextBox.AppendText("Setting Sparse VHD for $distro...`r`n")
                    $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--manage", $distro, "--set-sparse", "true" -NoNewWindow -Wait -PassThru
                    if ($process.ExitCode -eq 0) {
                        $outputTextBox.AppendText("Sparse VHD setting updated successfully.`r`n")
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

    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Location = New-Object System.Drawing.Point(200, 360)
    $refreshButton.Size = New-Object System.Drawing.Size(100, 30)
    $refreshButton.Text = "Refresh"
    $refreshButton.BackColor = [System.Drawing.Color]::White
    $refreshButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
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
    })
    $statusForm.Controls.Add($refreshButton)

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(675, 360)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Text = "Close"
    $closeButton.BackColor = [System.Drawing.Color]::White
    $closeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $closeButton.Add_Click({ $statusForm.Close() })
    $statusForm.Controls.Add($closeButton)

    $statusForm.ShowDialog()
}

$action9 = {
    $statusForm = New-Object System.Windows.Forms.Form
    $statusForm.Text = "WEnix Image Status and Disk Space"
    $statusForm.Size = New-Object System.Drawing.Size(800, 600)
    $statusForm.StartPosition = "CenterScreen"
    $statusForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(10, 10)
    $listView.Size = New-Object System.Drawing.Size(765, 180)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $listView.ForeColor = [System.Drawing.Color]::White
    $listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $listView.Columns.Add("Distribution", 150)
    $listView.Columns.Add("Size", 80)
    $listView.Columns.Add("Location", 520)

    $statusForm.Controls.Add($listView)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 200)
    $outputTextBox.Size = New-Object System.Drawing.Size(765, 150)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 89)
    $statusForm.Controls.Add($outputTextBox)

    $diskSpaceListView = New-Object System.Windows.Forms.ListView
    $diskSpaceListView.Location = New-Object System.Drawing.Point(10, 360)
    $diskSpaceListView.Size = New-Object System.Drawing.Size(765, 150)
    $diskSpaceListView.View = [System.Windows.Forms.View]::Details
    $diskSpaceListView.FullRowSelect = $true
    $diskSpaceListView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $diskSpaceListView.ForeColor = [System.Drawing.Color]::White
    $diskSpaceListView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $diskSpaceListView.Columns.Add("Drive", 100)
    $diskSpaceListView.Columns.Add("Total Space", 150)
    $diskSpaceListView.Columns.Add("Free Space", 150)
    $diskSpaceListView.Columns.Add("Free Space %", 150)

    $statusForm.Controls.Add($diskSpaceListView)

    function Clean-LocationPath {
        param([string]$path)
        return $path -replace '^\\\\\?\\', ''
    }

    function Get-WSLImageDetails {
        $details = @{}
        $lxssPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
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
                            $details[$distroName] = @{
                                Size = $used
                                Location = Clean-LocationPath $basePath
                            }
                        } else {
                            $details[$distroName] = @{
                                Size = "Size unknown"
                                Location = Clean-LocationPath $basePath
                            }
                        }
                    } catch {
                        $details[$distroName] = @{
                            Size = "Error retrieving size"
                            Location = Clean-LocationPath $basePath
                        }
                    }
                }
            }
        }
        return $details
    }

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

    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Location = New-Object System.Drawing.Point(10, 520)
    $refreshButton.Size = New-Object System.Drawing.Size(100, 30)
    $refreshButton.Text = "Refresh"
    $refreshButton.BackColor = [System.Drawing.Color]::White
    $refreshButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
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
    $closeButton.Location = New-Object System.Drawing.Point(675, 520)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Text = "Close"
    $closeButton.BackColor = [System.Drawing.Color]::White
    $closeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $closeButton.Add_Click({ $statusForm.Close() })
    $statusForm.Controls.Add($closeButton)

    $statusForm.ShowDialog()
}

$action9 = {
    $statusForm = New-Object System.Windows.Forms.Form
    $statusForm.Text = "WEnix Image Status and Disk Space"
    $statusForm.Size = New-Object System.Drawing.Size(800, 650)  # Increased height for sparse VHD button
    $statusForm.StartPosition = "CenterScreen"
    $statusForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(10, 10)
    $listView.Size = New-Object System.Drawing.Size(765, 180)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $listView.ForeColor = [System.Drawing.Color]::White
    $listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $listView.Columns.Add("Distribution", 150)
    $listView.Columns.Add("Size", 80)
    $listView.Columns.Add("Location", 520)

    $statusForm.Controls.Add($listView)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 200)
    $outputTextBox.Size = New-Object System.Drawing.Size(765, 150)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 89)
    $statusForm.Controls.Add($outputTextBox)

    $diskSpaceListView = New-Object System.Windows.Forms.ListView
    $diskSpaceListView.Location = New-Object System.Drawing.Point(10, 360)
    $diskSpaceListView.Size = New-Object System.Drawing.Size(765, 150)
    $diskSpaceListView.View = [System.Windows.Forms.View]::Details
    $diskSpaceListView.FullRowSelect = $true
    $diskSpaceListView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $diskSpaceListView.ForeColor = [System.Drawing.Color]::White
    $diskSpaceListView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $diskSpaceListView.Columns.Add("Drive", 100)
    $diskSpaceListView.Columns.Add("Total Space", 150)
    $diskSpaceListView.Columns.Add("Free Space", 150)
    $diskSpaceListView.Columns.Add("Free Space %", 150)

    $statusForm.Controls.Add($diskSpaceListView)

    function Clean-LocationPath {
        param([string]$path)
        return $path -replace '^\\\\\?\\', ''
    }

    function Get-WSLImageDetails {
        $details = @{}
        $lxssPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
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
                            $details[$distroName] = @{
                                Size = $used
                                Location = Clean-LocationPath $basePath
                            }
                        } else {
                            $details[$distroName] = @{
                                Size = "Size unknown"
                                Location = Clean-LocationPath $basePath
                            }
                        }
                    } catch {
                        $details[$distroName] = @{
                            Size = "Error retrieving size"
                            Location = Clean-LocationPath $basePath
                        }
                    }
                }
            }
        }
        return $details
    }

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

    $setSparseButton = New-Object System.Windows.Forms.Button
    $setSparseButton.Location = New-Object System.Drawing.Point(10, 520)
    $setSparseButton.Size = New-Object System.Drawing.Size(180, 30)
    $setSparseButton.Text = "Set Sparse VHD"
    $setSparseButton.BackColor = [System.Drawing.Color]::White
    $setSparseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $setSparseButton.Add_Click({
        $selectedItems = $listView.SelectedItems
        if ($selectedItems.Count -gt 0) {
            $distro = $selectedItems[0].Text
            
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Do you want to set Sparse VHD for $distro?",
                "Confirm Sparse VHD Change",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            
            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                $outputTextBox.AppendText("Shutting down WSL...`r`n")
                $shutdownProcess = Start-Process -FilePath "wsl.exe" -ArgumentList "--shutdown" -NoNewWindow -Wait -PassThru
                if ($shutdownProcess.ExitCode -eq 0) {
                    $outputTextBox.AppendText("WSL shut down successfully.`r`n")
                    $outputTextBox.AppendText("Setting Sparse VHD for $distro...`r`n")
                    $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--manage", $distro, "--set-sparse", "true" -NoNewWindow -Wait -PassThru
                    if ($process.ExitCode -eq 0) {
                        $outputTextBox.AppendText("Sparse VHD setting updated successfully.`r`n")
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

    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Location = New-Object System.Drawing.Point(200, 520)
    $refreshButton.Size = New-Object System.Drawing.Size(100, 30)
    $refreshButton.Text = "Refresh"
    $refreshButton.BackColor = [System.Drawing.Color]::White
    $refreshButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
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
    $closeButton.Location = New-Object System.Drawing.Point(675, 520)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Text = "Close"
    $closeButton.BackColor = [System.Drawing.Color]::White
    $closeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $closeButton.Add_Click({ $statusForm.Close() })
    $statusForm.Controls.Add($closeButton)

    $statusForm.ShowDialog()
}


$action9 = {
    $statusForm = New-Object System.Windows.Forms.Form
    $statusForm.Text = "WEnix Image Status and Disk Space"
    $statusForm.Size = New-Object System.Drawing.Size(800, 700)  # Increased height for new labels
    $statusForm.StartPosition = "CenterScreen"
    $statusForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    # Instruction label for sparse VHD
    $sparseInstructionLabel = New-Object System.Windows.Forms.Label
    $sparseInstructionLabel.Location = New-Object System.Drawing.Point(10, 10)
    $sparseInstructionLabel.Size = New-Object System.Drawing.Size(765, 20)
    $sparseInstructionLabel.Text = "Click on the image you want to shrink with sparse VHD, then click the 'Set Sparse VHD' button:"
    $sparseInstructionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $sparseInstructionLabel.ForeColor = [System.Drawing.Color]::White
    $statusForm.Controls.Add($sparseInstructionLabel)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(10, 35)  # Moved down to accommodate new label
    $listView.Size = New-Object System.Drawing.Size(765, 180)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $listView.ForeColor = [System.Drawing.Color]::White
    $listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $listView.Columns.Add("Distribution", 150)
    $listView.Columns.Add("Size", 80)
    $listView.Columns.Add("Location", 520)

    $statusForm.Controls.Add($listView)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 225)
    $outputTextBox.Size = New-Object System.Drawing.Size(765, 150)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 89)
    $statusForm.Controls.Add($outputTextBox)

    # Disk space information label
    $diskSpaceLabel = New-Object System.Windows.Forms.Label
    $diskSpaceLabel.Location = New-Object System.Drawing.Point(10, 385)
    $diskSpaceLabel.Size = New-Object System.Drawing.Size(765, 20)
    $diskSpaceLabel.Text = "Disk space available:"
    $diskSpaceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $diskSpaceLabel.ForeColor = [System.Drawing.Color]::White
    $statusForm.Controls.Add($diskSpaceLabel)

    $diskSpaceListView = New-Object System.Windows.Forms.ListView
    $diskSpaceListView.Location = New-Object System.Drawing.Point(10, 410)
    $diskSpaceListView.Size = New-Object System.Drawing.Size(765, 150)
    $diskSpaceListView.View = [System.Windows.Forms.View]::Details
    $diskSpaceListView.FullRowSelect = $true
    $diskSpaceListView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $diskSpaceListView.ForeColor = [System.Drawing.Color]::White
    $diskSpaceListView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $diskSpaceListView.Columns.Add("Drive", 100)
    $diskSpaceListView.Columns.Add("Total Space", 150)
    $diskSpaceListView.Columns.Add("Free Space", 150)
    $diskSpaceListView.Columns.Add("Free Space %", 150)

    $statusForm.Controls.Add($diskSpaceListView)



    $setSparseButton = New-Object System.Windows.Forms.Button
    $setSparseButton.Location = New-Object System.Drawing.Point(10, 570)
    $setSparseButton.Size = New-Object System.Drawing.Size(180, 30)
    $setSparseButton.Text = "Set Sparse VHD"
    $setSparseButton.BackColor = [System.Drawing.Color]::White
    $setSparseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    # ... (rest of the button setup remains the same)

    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Location = New-Object System.Drawing.Point(200, 570)
    $refreshButton.Size = New-Object System.Drawing.Size(100, 30)
    $refreshButton.Text = "Refresh"
    $refreshButton.BackColor = [System.Drawing.Color]::White
    $refreshButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $setSparseButton = New-Object System.Windows.Forms.Button
    $setSparseButton.Location = New-Object System.Drawing.Point(10, 570)
    $setSparseButton.Size = New-Object System.Drawing.Size(180, 30)
    $setSparseButton.Text = "Set Sparse VHD"
    $setSparseButton.BackColor = [System.Drawing.Color]::White
    $setSparseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    # ... (rest of the button setup remains the same)

    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Location = New-Object System.Drawing.Point(200, 570)
    $refreshButton.Size = New-Object System.Drawing.Size(100, 30)
    $refreshButton.Text = "Refresh"
    $refreshButton.BackColor = [System.Drawing.Color]::White
    $refreshButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    # ... (rest of the button setup remains the same)

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(675, 570)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Text = "Close"
    $closeButton.BackColor = [System.Drawing.Color]::White
    $closeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $closeButton.Add_Click({ $statusForm.Close() })
    $statusForm.Controls.Add($closeButton)

    $statusForm.ShowDialog()

