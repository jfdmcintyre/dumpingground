Import-Module .\styles.ps1
Import-Module .\functions.ps1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


# This gains the basic information about installed WSL images, used for simple lists. Mind the console encoding to unicode. this is required.


# This gains information from Windows registry about WSL Images used for listview in action 9, refresh # This function is to gain information from Windows Registry target [Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss] for wsl images for: location of image on drive, full name.
function Get-WSLImageDetails {
    $details = @{}
    $originalEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode

    $lxssPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"

    # Get list of all distributions, including the default one
    $allDistros = @(wsl --list --verbose | Select-Object -Skip 1 | ForEach-Object {
        if ($_ -match '^\*?\s*(\S+.*)') {
            $matches[1].Trim()
        }
    })

    # Get list of all running distros. This includes default
    $runningImages = @(wsl -l --running | Select-Object -Skip 1 | ForEach-Object {
        $_.Trim() -replace ' \(Default\)$', ''
    })

    [Console]::OutputEncoding = $originalEncoding

    if (Test-Path $lxssPath) {
        Get-ChildItem -Path $lxssPath | ForEach-Object {
            $distroName = $_.GetValue("DistributionName")
            $basePath = $_.GetValue("BasePath")
            if ($distroName -and $basePath) {
                try {
                    $distroDir = Switch ($PSVersionTable.PSEdition) {
                        "Core" {
                            $basePath -replace '^\\\\\?\\',''
                        }
                        "Desktop" {
                            if ($basePath.StartsWith('\\?\')) {
                                $basePath
                            } else {
                                '\\?\' + $basePath
                            }
                        }
                    }

                    if (Test-Path $distroDir) {
                        # Get size on disk using robocopy
                        $robocopyOutput = robocopy $distroDir NULL /L /XJ /R:0 /W:0 /NDL /NJH /NJS /NC /NS /MT:64 /E /BYTES
                    
                        Write-Host "`n---Robocopy Output for $distroName---"
                        Write-Host $robocopyOutput
                        Write-Host "---End of Robocopy Output---`n"
                    
                        # Extract the size from robocopy output
                        $sizeLine = $robocopyOutput | Select-String -Pattern '^\s*(\d+)\s+.*\.vhdx'
                        if ($sizeLine -and $sizeLine.Matches.Groups.Count -gt 1) {
                            $sizeInBytes = [long]$sizeLine.Matches.Groups[1].Value
                            $sizeInGB = $sizeInBytes / 1GB
                            $distroSize = "{0:N2} GB" -f $sizeInGB
                            Write-Host "Size on disk for $distroName : $distroSize"
                        } else {
                            Write-Host "Error: Could not find size in robocopy output for $distroName."
                            $distroSize = "Size unknown"
                        }
                    } else {
                        Write-Host "Directory not found: $distroDir"
                        $distroSize = "Directory not found"
                    }
                    
                    $status = if ($runningImages -contains $distroName) { "Running" } else { "Stopped" }
                    $displayName = if ($allDistros -contains "$distroName (Default)") { "$distroName (Default)" } else { $distroName }
                    
                    $details[$displayName] = @{
                        Size = $distroSize
                        Location = New-LocationPath $basePath
                        Status = $status
                    }
                } catch {
                    Write-Host "Error processing $distroName $($_.Exception.Message)"
                    $logicalSizeGB = "Error"
                    $sizeOnDiskGB = "Error"
                }

                $status = if ($runningImages -contains $distroName) { "Running" } else { "Stopped" }
                $displayName = if ($allDistros -contains "$distroName (Default)") { "$distroName (Default)" } else { $distroName }

                $details[$displayName] = @{
                    #LogicalSize = $logicalSizeGB
                    Size = $distroSize
                    Location = New-LocationPath $basePath
                    Status = $status
                }
            }
        }
    }

    [Console]::OutputEncoding = $originalEncoding
    return $details
}
function Get-SizeOnDisk {
    param(
        [string]$path
    )

    # Get all files under the provided path
    $files = Get-ChildItem -Recurse -LiteralPath $path -File -ErrorAction SilentlyContinue

    # This will store the total size on disk
    $totalSizeOnDisk = 0

    foreach ($file in $files) {
        # Get the size on disk using COM object
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace($file.DirectoryName)
        $item = $folder.ParseName($file.Name)
        
        # The index 12 corresponds to the size on disk
        $sizeOnDisk = $folder.GetDetailsOf($item, 12)
        
        # Convert size string to bytes
        if ($sizeOnDisk -match '([\d\.]+)\s*([KMGT]B)') {
            $size = [double]$matches[1]
            $unit = $matches[2]
            
            switch ($unit) {
                'KB' { $size *= 1KB }
                'MB' { $size *= 1MB }
                'GB' { $size *= 1GB }
                'TB' { $size *= 1TB }
            }
            
            $totalSizeOnDisk += $size
        }
    }

    # Release COM object
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null

    # Return the size in human-readable format
    $totalSizeGB = "{0:N2} GB" -f ($totalSizeOnDisk / 1GB)
    return $totalSizeGB
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

# This is the listview column and category
$listView.Columns.Add("WEnix Image", 150)
$listView.Columns.Add("VHD Size", 80)
$listView.Columns.Add("Location", 520)

$statusForm.Controls.Add($listView)


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



$statusForm.Controls.Add($closeButton)
$statusForm.Add_FormClosed({ $refreshTimer.Stop()})
$statusForm.ShowDialog()
