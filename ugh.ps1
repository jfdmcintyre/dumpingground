# Define the action for installing a WSL image
$action5 = {
    # Create and configure the form
    $wslInstallForm = New-Object System.Windows.Forms.Form
    $wslInstallForm.Text = "Install WSL Image"
    $wslInstallForm.Size = New-Object System.Drawing.Size(600, 400)
    $wslInstallForm.StartPosition = "CenterScreen"
    $wslInstallForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $wslInstallForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $wslInstallForm.MaximizeBox = $false

    # Label for WSL Image Name
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $label1.Size = New-Object System.Drawing.Size(565, 20)
    $label1.Text = "Enter WSL Image Name:"
    $wslInstallForm.Controls.Add($label1)

    # TextBox for WSL Image Name
    $imageNameTextBox = New-Object System.Windows.Forms.TextBox
    $imageNameTextBox.Location = New-Object System.Drawing.Point(10, 50)
    $imageNameTextBox.Size = New-Object System.Drawing.Size(450, 20)
    $wslInstallForm.Controls.Add($imageNameTextBox)

    # Label for Installation Location
    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 80)
    $label2.Size = New-Object System.Drawing.Size(565, 20)
    $label2.Text = "Select Installation Location:"
    $wslInstallForm.Controls.Add($label2)

    # TextBox for Installation Location
    $installLocationTextBox = New-Object System.Windows.Forms.TextBox
    $installLocationTextBox.Location = New-Object System.Drawing.Point(10, 110)
    $installLocationTextBox.Size = New-Object System.Drawing.Size(450, 20)
    $installLocationTextBox.Text = "C:\_WSL2"  # Default value
    $wslInstallForm.Controls.Add($installLocationTextBox)

    # Browse Button
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(465, 108)
    $browseButton.Size = New-Object System.Drawing.Size(110, 25)
    $browseButton.Text = "Browse"
    $browseButton.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select installation location"
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $installLocationTextBox.Text = $folderBrowser.SelectedPath
        }
    })
    $wslInstallForm.Controls.Add($browseButton)

    # Install Button
    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Location = New-Object System.Drawing.Point(10, 320)
    $installButton.Size = New-Object System.Drawing.Size(280, 30)
    $installButton.Text = "Install WSL Image"
    $installButton.Add_Click({
        $imageName = $imageNameTextBox.Text.Trim()
        $installLocation = $installLocationTextBox.Text.Trim()

        if (-not $imageName) {
            [System.Windows.Forms.MessageBox]::Show("Please enter a WSL image name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        # Validate and adjust installation location
        if (-not $installLocation -or $installLocation -eq "Leave blank for default (C:\_WSL2)") {
            $installLocation = "C:\_WSL2"
        }
        
        # Ensure the installation location path is valid
        $installLocation = [System.IO.Path]::GetFullPath($installLocation)
        if (-not (Test-Path $installLocation)) {
            try {
                New-Item -ItemType Directory -Path $installLocation | Out-Null
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to create installation directory. Error: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
        }

        # Create a wait form with a progress bar for the installation
        $waitForm = New-Object System.Windows.Forms.Form
        $waitForm.Text = "Installing WSL Image..."
        $waitForm.Size = New-Object System.Drawing.Size(300, 100)
        $waitForm.StartPosition = "CenterScreen"
        $waitForm.TopMost = $true

        $progressBar = New-Object System.Windows.Forms.ProgressBar
        $progressBar.Location = New-Object System.Drawing.Point(20, 20)
        $progressBar.Size = New-Object System.Drawing.Size(250, 30)
        $progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
        $waitForm.Controls.Add($progressBar)

        # Show the wait form
        $waitForm.Show()

        # Logic to install WSL image
        try {
            $tarFilePath = "<path_to_tar_file>"  # Replace with actual path or file selection logic
            if (-not (Test-Path $tarFilePath)) {
                [System.Windows.Forms.MessageBox]::Show("The specified tar file does not exist.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $waitForm.Close()
                return
            }
            
            # Start the export process
            $exportWaitForm = New-Object System.Windows.Forms.Form
            $exportWaitForm.Text = "Exporting WSL Image..."
            $exportWaitForm.Size = New-Object System.Drawing.Size(300, 100)
            $exportWaitForm.StartPosition = "CenterScreen"
            $exportWaitForm.TopMost = $true

            $exportProgressBar = New-Object System.Windows.Forms.ProgressBar
            $exportProgressBar.Location = New-Object System.Drawing.Point(20, 20)
            $exportProgressBar.Size = New-Object System.Drawing.Size(250, 30)
            $exportProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
            $exportWaitForm.Controls.Add($exportProgressBar)

            # Show the export wait form
            $exportWaitForm.Show()

            # Perform the export operation
            $command = "wsl.exe --import `"$imageName`" `"$installLocation`" `"$tarFilePath`""
            Start-Process -FilePath "wsl.exe" -ArgumentList "--import", $imageName, $installLocation, $tarFilePath -NoNewWindow -Wait

            # Close the export wait form
            $exportWaitForm.Close()

            # Show success message
            [System.Windows.Forms.MessageBox]::Show("WSL Image $imageName installed successfully at $installLocation.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to install WSL Image $imageName. Error: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }

        # Close the installation wait form
        $waitForm.Close()

        # Set the global variable to refresh action9
        $global:Action9NeedsRefresh = $true

        # Close the main form
        $wslInstallForm.Close()
    })
    $wslInstallForm.Controls.Add($installButton)

    # Show the form
    $wslInstallForm.ShowDialog()
}
