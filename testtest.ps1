$wsl_user = get-item 'hkcu:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss'

$def_distro_guid = $wsl_user.GetValue('DefaultDistribution')
$def_vers        = $wsl_user.GetValue('DefaultVersion')

"Default version: $def_vers"

foreach ($distro_guid in $wsl_user.GetSubKeyNames()) {

   ''

   $distro = $wsl_user.OpenSubKey($distro_guid)

   $distro.GetValue('DistributionName')   

   if ($distro_guid -eq $def_distro_guid) {
     "  This is the default distribution"
   }

   "  Version:        $($distro.GetValue('Version'          ))"
   "  Base Path:      $($distro.GetValue('BasePath'         ))"
   "  Package Family: $($distro.GetValue('PackageFamilyName'))"
   "  State:          $($distro.GetValue('State'            ))"
   "  Default UID:    $($distro.GetValue('DefaultUid'       ))"
   "  Flags:          $($distro.GetValue('Flags'            ))"

   $def_env = $distro.GetValue('DefaultEnvironment')
   "  Default Environment:"
   foreach ($env in $def_env.Split()) {
   '    {0,-10} = {1}' -f ($env.Split('='))
   }

   $distro.Close()
}

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

        # Check available disk space
        $drive = Split-Path -Qualifier $exportPath
        $freeSpace = (Get-PSDrive $drive.TrimEnd(":")).Free
        $requiredSpace = (Get-ChildItem "\\wsl$\$selectedImage" -Recurse | Measure-Object -Property Length -Sum).Sum

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

            $command = "wsl.exe --export `"$selectedImage`" `"$exportPath`""
            $outputTextBox.AppendText("Executing command: $command`r`n")

            Show-Notification -Title "Backup Started" -Message "WEnix Image $selectedImage is currently being backed up. This Process can take up to 5 minutes." -Icon info

            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", "`"$selectedImage`"", "`"$exportPath`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\export_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\export_error.log"

            $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
            $stdout = Get-Content "C:\_WSL2\_APPLOG\export_output.log" -Raw
            $stderr = Get-Content "C:\_WSL2\_APPLOG\export_error.log" -Raw
            $outputTextBox.AppendText("Standard Output: $stdout`r`n")
            $outputTextBox.AppendText("Standard Error: $stderr`r`n")

            if ($process.ExitCode -eq 0) {
                $outputTextBox.AppendText("Export successful.`r`n")
                Show-Notification -Title "Success" -Message "WEnix Image $selectedImage exported successfully to $exportPath" -icon info
            } else {
                $outputTextBox.AppendText("Export failed.`r`n")
                [System.Windows.Forms.MessageBox]::Show("Failed to export WEnix Image. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
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

        # Check available disk space
        $drive = Split-Path -Qualifier $exportPath
        $freeSpace = (Get-PSDrive $drive.TrimEnd(":")).Free

        # Get WSL image size using wsl command
        $wslSizeOutput = wsl -d $selectedImage -e du -sb /
        if ($wslSizeOutput -match '(\d+)') {
            $requiredSpace = [long]$matches[1]
        } else {
            $outputTextBox.AppendText("Failed to get WSL image size. Aborting export.`r`n")
            return
        }

        if ($freeSpace -lt $requiredSpace) {
            $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
            $requiredSpaceGB = [math]::Round($requiredSpace / 1GB, 2)
            $outputTextBox.AppendText("Not enough disk space. Available: $freeSpaceGB GB, Required: $requiredSpaceGB GB`r`n")
            [System.Windows.Forms.MessageBox]::Show("Not enough disk space to export the WEnix image.`nAvailable: $freeSpaceGB GB`nRequired: $requiredSpaceGB GB", "Insufficient Disk Space", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        # Rest of the export process remains the same
        try {
            if (-not (Test-Path $exportLocation)) {
                New-Item -ItemType Directory -Path $exportLocation | Out-Null
                $outputTextBox.AppendText("Created directory: $exportLocation`r`n")
            }

            $command = "wsl.exe --export `"$selectedImage`" `"$exportPath`""
            $outputTextBox.AppendText("Executing command: $command`r`n")

            Show-Notification -Title "Backup Started" -Message "WEnix Image $selectedImage is currently being backed up. This Process can take up to 5 minutes." -Icon info

            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", "`"$selectedImage`"", "`"$exportPath`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\export_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\export_error.log"

            # Rest of the process handling remains the same
        }
        catch {
            # Error handling remains the same
        }
    }
    else {
        # Handling for missing information remains the same
    }
})







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

        # Check available disk space
        $drive = Split-Path -Qualifier $exportPath
        $freeSpace = (Get-PSDrive $drive.TrimEnd(":")).Free

        # Get WSL image size using wsl command
        $wslSizeOutput = wsl.exe --system -d $selectedImage df -h /mnt/wslg/distro
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

        if ($freeSpace -lt $requiredSpace) {
            $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
            $requiredSpaceGB = [math]::Round($requiredSpace / 1GB, 2)
            $outputTextBox.AppendText("Not enough disk space. Available: $freeSpaceGB GB, Required: $requiredSpaceGB GB`r`n")
            [System.Windows.Forms.MessageBox]::Show("Not enough disk space to export the WEnix image.`nAvailable: $freeSpaceGB GB`nRequired: $requiredSpaceGB GB", "Insufficient Disk Space", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        # Rest of the export process remains the same
        try {
            if (-not (Test-Path $exportLocation)) {
                New-Item -ItemType Directory -Path $exportLocation | Out-Null
                $outputTextBox.AppendText("Created directory: $exportLocation`r`n")
            }

            $command = "wsl.exe --export `"$selectedImage`" `"$exportPath`""
            $outputTextBox.AppendText("Executing command: $command`r`n")

            Show-Notification -Title "Backup Started" -Message "WEnix Image $selectedImage is currently being backed up. This Process can take up to 5 minutes." -Icon info

            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", "`"$selectedImage`"", "`"$exportPath`"" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\export_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\export_error.log"

            # Rest of the process handling remains the same
        }
        catch {
            # Error handling remains the same
        }
    }
    else {
        # Handling for missing information remains the same
    }
})








# Check available disk space
$drive = Split-Path -Qualifier $installLocation
$freeSpace = (Get-PSDrive $drive.TrimEnd(":")).Free
$requiredSpace = (Get-Item $importPath).Length

if ($freeSpace -lt $requiredSpace) {
    $freeSpaceGB = [math]::Round($freeSpace / 1GB, 2)
    $requiredSpaceGB = [math]::Round($requiredSpace / 1GB, 2)
    $outputTextBox.AppendText("Not enough disk space. Available: $freeSpaceGB GB, Required: $requiredSpaceGB GB`r`n")
    [System.Windows.Forms.MessageBox]::Show("Not enough disk space to import the WEnix image.`nAvailable: $freeSpaceGB GB`nRequired: $requiredSpaceGB GB", "Insufficient Disk Space", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    return
}