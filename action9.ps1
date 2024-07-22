Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

    function Get-WSLImages {
        $originalEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        $wslOutput = wsl --list --quiet
        [Console]::OutputEncoding = $originalEncoding
        return ($wslOutput -split "`n" | Where-Object { $_.Trim() -ne "" })
    }

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
    if ($listView.SelectedItems.Count -eq 1) {
        $selectedImage = $listView.SelectedItems[0].Text
        $global:SelectedImageForBackup = $selectedImage
        .\action4.ps1
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a WEnix image to backup.", "No Image Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
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
