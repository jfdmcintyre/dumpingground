$listView.Columns.Clear()
$listView.Columns.Add("WEnix Image", 150)
$listView.Columns.Add("Status", 80)
$listView.Columns.Add("VHD Size", 80)
$listView.Columns.Add("Location", 440)


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
