$removeButton.Add_Click({
    if ($listView.SelectedItems.Count -eq 1) {
        $selectedImage = $listView.SelectedItems[0].Text
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Are you sure you want to remove $selectedImage?`nThis action cannot be undone.",
            "Confirm Removal",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                # Get the path to the VHDX file before unregistering
                $vhdxPath = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss\*" | 
                    Where-Object { $_.DistributionName -eq $selectedImage }).BasePath

                # Unregister the WSL distribution
                $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--unregister", $selectedImage -NoNewWindow -Wait -PassThru
                if ($process.ExitCode -eq 0) {
                    $outputTextBox.AppendText("$selectedImage has been successfully removed.`r`n")

                    # Remove the VHDX file
                    if ($vhdxPath) {
                        $vhdxFile = Join-Path $vhdxPath "ext4.vhdx"
                        if (Test-Path $vhdxFile) {
                            Remove-Item $vhdxFile -Force
                            $outputTextBox.AppendText("VHDX file removed: $vhdxFile`r`n")

                            # Check if the parent folder is empty
                            $parentFolder = Split-Path $vhdxFile -Parent
                            if ((Get-ChildItem $parentFolder -Force | Measure-Object).Count -eq 0) {
                                Remove-Item $parentFolder -Force -Recurse
                                $outputTextBox.AppendText("Empty parent folder removed: $parentFolder`r`n")
                            } else {
                                $outputTextBox.AppendText("Parent folder not empty, skipping removal: $parentFolder`r`n")
                            }
                        } else {
                            $outputTextBox.AppendText("VHDX file not found: $vhdxFile`r`n")
                        }
                    } else {
                        $outputTextBox.AppendText("VHDX path not found for $selectedImage`r`n")
                    }

                    # Refresh the ListView
                    $listView.Items.Clear()
                    $wslImages = Get-WSLImages
                    $wslDetails = Get-WSLImageDetails
                    foreach ($image in $wslImages) {
                        $details = $wslDetails[$image]
                        if ($details) {
                            $location = $details.Location
                            $size = $details.Size
                        } else {
                            $location = "Location not found"
                            $size = "Size unknown"
                        }
                        $listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
                        $listViewItem.SubItems.Add($size)
                        $listViewItem.SubItems.Add($location)
                        $listView.Items.Add($listViewItem)
                    }
                } else {
                    $outputTextBox.AppendText("Failed to remove $selectedImage. Exit code: $($process.ExitCode)`r`n")
                }
            } catch {
                $outputTextBox.AppendText("An error occurred: $_`r`n")
            }
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a WEnix image to remove.", "No Image Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
})
