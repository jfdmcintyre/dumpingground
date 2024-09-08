
function Get-WSLImages {
    $originalEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $wslOutput = wsl --list --quiet
    [Console]::OutputEncoding = $originalEncoding
    return ($wslOutput -split "`n" | Where-Object { $_.Trim() -ne "" })
}

$wslImages = Get-WSLImages

if ($wslImages.Count -eq 2) {
    # If only two WSL images exist, go directly to the WSL command
    $selectedImage = $wslImages[0]
    
    $command = "wsl -d $selectedImage -u root passwd wsl2user"
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $command
    
    [System.Windows.Forms.MessageBox]::Show("Password change command executed for $selectedImage. Please enter the new password in the Command Prompt window.", "Command Executed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}
else {

    $action1 = {
        function Get-WSLImages {
        $originalEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        $wslOutput = wsl --list --quiet
        [Console]::OutputEncoding = $originalEncoding
        return ($wslOutput -split "`n" | Where-Object { $_.Trim() -ne "" })
    }
    $wslImages = Get-WSLImages

    if ($wslImages.Count -le 2) {
        # If there are two or fewer WSL images, load the default one
        try {
            $process = Start-Process -FilePath "wsl" -PassThru
            Show-Notification -Title "WSL Loaded" -Message "Default WSL distribution has been loaded." -Icon Info
        } catch {
            Show-Notification -Title "Error" -Message "An error occurred while loading the default WSL distribution: $_" -Icon Error
        }
    }
    else {
        # If there are three or more WSL images, show the list
        $wslListForm = New-Object System.Windows.Forms.Form
        $wslListForm.Text = "WSL Distributions"
        $wslListForm.Size = New-Object System.Drawing.Size(400, 300)
        $wslListForm.StartPosition = "CenterScreen"
        $wslListForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(10, 10)
        $label.Size = New-Object System.Drawing.Size(380, 20)
        $label.Text = "Double-click a WSL distribution to load:"
        $label.ForeColor = [System.Drawing.Color]::White
        $wslListForm.Controls.Add($label)

        $listBox = New-Object System.Windows.Forms.ListBox
        $listBox.Location = New-Object System.Drawing.Point(10, 40)
        $listBox.Size = New-Object System.Drawing.Size(360, 200)
        $listBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
        $listBox.ForeColor = [System.Drawing.Color]::White
        $listBox.Font = New-Object System.Drawing.Font("Arial", 12)
        $wslListForm.Controls.Add($listBox)

        foreach ($image in $wslImages) {
            $listBox.Items.Add($image)
        }

        $listBox.Add_DoubleClick({
            $selectedImage = $listBox.SelectedItem
            if ($selectedImage) {
                $wslListForm.Close()
                try {
                    $process = Start-Process -FilePath "wsl" -ArgumentList "-d", $selectedImage  -PassThru
                    Show-Notification -Title "WSL Distribution Loaded" -Message "WSL distribution '$selectedImage' has been loaded." -Icon Info
                } catch {
                    Show-Notification -Title "Error" -Message "An error occurred while loading WSL distribution: $_" -Icon Error
                }
            }
        })

        $wslListForm.ShowDialog()
    }
}



































Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# main form of app
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "WEnix Companion"
$mainForm.Size = New-Object System.Drawing.Size(600, 700) # Increased height
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136) # Teal background
$mainForm.Icon = "C:\_WSL2\_SCRIPTS\WEnix.ico"

# Create menu strip
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(0, 130, 116)  # Slightly darker teal
$menuStrip.ForeColor = [System.Drawing.Color]::White

# File menu
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "File"

$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem.Text = "Exit"
$exitMenuItem.Add_Click({ $mainForm.Close() })

$fileMenu.DropDownItems.Add($exitMenuItem)

# Help menu
$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text = "Help"

$helpArticle = @"
## WEnix Companion Help

Welcome to the WEnix Companion help guide. This application assists you in managing your WEnix (WSL) environments.

### Main Features:

1. **Start/Stop WEnix**
   - Launch WEnix: Starts your WEnix environment.
   - Stop WEnix: Safely shuts down your WEnix environment.
   - Start VPNKIT: Initiates the VPNKIT service for network connectivity.

2. **Manage WEnix Images**
   - Backup Image: Create a backup of your WEnix image.
   - Restore Image: Restore a previously backed up WEnix image.
   - Remove Image: Uninstall a WEnix image from your system.

3. **Additional Tools**
   - Password Reset: Reset the password for your WEnix user account.
   - WEnix Website: Quick access to the WEnix documentation website.
   - About: Information about the WEnix Companion app.

### Using the Application:

1. Click on the desired action button on the main screen.
2. Follow the on-screen prompts for each action.
3. Check the output in the provided text boxes for operation results.

### Tips:

- Regularly backup your WEnix images to prevent data loss.
- Always use the 'Stop WEnix' button to safely shut down your environment.
- If you encounter issues, check the WEnix Website for troubleshooting guides.

For more detailed information, please visit the WEnix documentation website.
"@
function Show-HelpArticle {
    $helpForm = New-Object System.Windows.Forms.Form
    $helpForm.Text = "WEnix Companion Help"
    $helpForm.Size = New-Object System.Drawing.Size(600, 500)
    $helpForm.StartPosition = "CenterScreen"
    $helpForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $helpTextBox = New-Object System.Windows.Forms.RichTextBox
    $helpTextBox.Location = New-Object System.Drawing.Point(10, 10)
    $helpTextBox.Size = New-Object System.Drawing.Size(565, 440)
    $helpTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $helpTextBox.ForeColor = [System.Drawing.Color]::Black
    $helpTextBox.BackColor = [System.Drawing.Color]::White
    $helpTextBox.ReadOnly = $true
    $helpTextBox.Text = $helpArticle

    $helpForm.Controls.Add($helpTextBox)

    $helpForm.ShowDialog()
}

# Add this function to your help menu item
$helpMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenuItem.Text = "Help"
$helpMenuItem.Add_Click({ Show-HelpArticle })

# Add the help menu item to your menu strip
$helpMenu.DropDownItems.Add($helpMenuItem)

$aboutMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutMenuItem.Text = "About"
$aboutMenuItem.Add_Click($WEnixinfo)  # Assuming $action9 is your about page action

$helpMenu.DropDownItems.Add($aboutMenuItem)

# Add menus to menu strip
$menuStrip.Items.Add($fileMenu)
$menuStrip.Items.Add($helpMenu)

# Add menu strip to form
$mainForm.Controls.Add($menuStrip)

# Adjust other controls' positions
$title.Location = New-Object System.Drawing.Point(10, 40)  # Move title down to accommodate menu strip

# Add menu strip to form
$mainForm.MainMenuStrip = $menuStrip

# Function to create a button with an image - to set names and images of buttons, go to line 915 to input.
function New-Button {
    param ($x, $y, $text, $imagePath, $action)
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($x, $y)
    $button.Size = New-Object System.Drawing.Size(100, 100)
    $button.Text = ""
    $button.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136) # Teal button background
    $button.ForeColor = [System.Drawing.Color]::White # White button text
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderColor = [System.Drawing.Color]::White # White button border
    $button.FlatAppearance.BorderSize = 0
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold) # Button font and size
    $button.Add_Click($action)

    # Load and set the image for buttons
    if (Test-Path $imagePath) {
        $image = [System.Drawing.Image]::FromFile($imagePath)
    } elseif ($imagePath -match '^https?://') {
        $webClient = New-Object System.Net.WebClient
        $imageBytes = $webClient.DownloadData($imagePath)
       $memoryStream = New-Object System.IO.MemoryStream($imageBytes, 0, $imageBytes.Length)
        $image = [System.Drawing.Image]::FromStream($memoryStream)

    } else {
        Write-Warning "Image not found: $imagePath"
        return $button
    }

    # Button aligntment in main form

    $button.Image = $image
    $button.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $button.TextAlign = [System.Drawing.ContentAlignment]::BottomCenter
    $button.TextImageRelation = [System.Windows.Forms.TextImageRelation]::ImageAboveText

    return $button

}
#  Function to create a title label under a button
function New-ButtonTitle {
    param ($x, $y, $text)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.Size = New-Object System.Drawing.Size(100, 20)
    $label.Text = $text
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular) # Button title font
    $label.ForeColor = [System.Drawing.Color]::White # White title text
    $label.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136) # Teal title background
    $label.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
   return $label
}
# Function to have three category labels on main form.
function New-CategoryLabel {
    param ($x, $y, $text)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.Size = New-Object System.Drawing.Size(340, 30)
    $label.Text = $text
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::White # White category text
    $label.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136) # Teal category background
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    return $label
}
# Function for Windows Popup Notifications for action notifications. Used for quick information to the user that doesn't require confirmation. Automatically dismisses in 5 seconds.
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

    Start-Sleep -Seconds 5
    $balloon.Dispose()
}
# Function for watermark in textbox. Used in action 4 and 5 for inline infomation in textbox
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
# Function to List WEnix Images for action 1 & 7, these functions don't need special tweaks for any datalistiew, can be handled with this function
function Get-WSLImages {
    $originalEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $wslOutput = wsl --list --quiet
    [Console]::OutputEncoding = $originalEncoding
    $images = ($wslOutput -split "`n" | Where-Object { $_.Trim() -ne "" -and $_.Trim() -ne "wsl-vpnkit" }) # vpnkit is ignored, will not show in lists.
    return $images
}  


# Define actions for each button, buttons 1 thorugh 9
# Action for Button 1, for launching WEnix Default Image, or select from list if more are installed.
$action1 = {
     
    $wslImages = Get-WSLImages # This is the function that gets the list of wsl images on computer, the 'if' determins next action.

    if ($wslImages.Count -le 1) {
        # If there is only one WSL image, load the default image. wsl-vpnkit is ignored.
        try {
            Start-Process -FilePath "wsl.exe" -PassThru
           Show-Notification -Title "WEnix Loaded" -Message "Default WEinx distribution has been loaded." -Icon Info
        } catch {
            Show-Notification -Title "Error" -Message "An error occurred while loading the default WEnix distribution: $_" -Icon Error
        }
    }
    else {
        # If there is one or more WSL images, show the list of wsl images available.
        $wslListForm = New-Object System.Windows.Forms.Form # this is the main form for wsl loading. sets size, position, name, colour, font
        $wslListForm.Text = "WEnix Distributions"
        $wslListForm.Size = New-Object System.Drawing.Size(400, 300)
        $wslListForm.StartPosition = "CenterScreen"
        $wslListForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
 
        $label = New-Object System.Windows.Forms.Label #This is the text intruction line on form, positioning, size, name and colour, font
        $label.Location = New-Object System.Drawing.Point(10, 10)
        $label.Size = New-Object System.Drawing.Size(380, 20)
        $label.Text = "Double-click a WEnix Image to load:"
        $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $label.ForeColor = [System.Drawing.Color]::White
        $wslListForm.Controls.Add($label)

        $listBox = New-Object System.Windows.Forms.ListBox # This is the list box that contains the wsl images on computer. positioning, size, name, colour, font
        $listBox.Location = New-Object System.Drawing.Point(10, 40)
        $listBox.Size = New-Object System.Drawing.Size(360, 200)
        $listBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
        $listBox.ForeColor = [System.Drawing.Color]::White
        $listBox.Font = New-Object System.Drawing.Font("Arial", 12)
        $wslListForm.Controls.Add($listBox)

        foreach ($image in $wslImages) { #This is telling the list to show all wsl images from the function $wslimages to display in the list.
            $listBox.Items.Add($image)
        }

        $listBox.Add_DoubleClick({ # on double clicking on a image in the list, it will continue with loading the image with wsl command and the $selected image.
            $selectedImage = $listBox.SelectedItem
            if ($selectedImage) {
                $wslListForm.Close()
                try {
                    Start-Process -FilePath "wsl" -ArgumentList "-d", $selectedImage -PassThru # command for starting wsl eith desired image
                    Show-Notification -Title "WEnix Image Loaded" -Message "WEnix Image '$selectedImage' has been loaded." -Icon Info # Windows popup notification or success
                } catch {
                    Show-Notification -Title "Error" -Message "An error occurred while loading WEnix Image: $_" -Icon Error # Windows popup of failure
                }
            }
        })
        $wslListForm.ShowDialog() # Closing form tag. Required for all forms, will not display form unless finished with wrapping all contents within
    }
}

# Action for Button 2, Complete WSL shutdown
$action2 = {

    try { #upon press of button, command to stop wsl will start.
        $result = Start-Process -FilePath "wsl.exe" -ArgumentList "--shutdown" -NoNewWindow -Wait -PassThru # command to shutdown wsl, no cmd window, app stops until complete
        if ($result.ExitCode -eq 0) {
            Show-Notification -Title "WSL Shutdown" -Message "WSL has been shut down successfully." -Icon Info #Windows pop success notification
        } else {
            [System.Windows.Forms.MessageBox]::Show("WSL shutdown completed with exit code: " + $result.ExitCode, "WSL Shutdown") # Windows failure popup notification.
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error shutting down WSL: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    } # Secondary failure notification.
}

# Action for Button 3, Launch WEnix VPNKIT
$action3 = {
    try { # Identical to action 2, the command is different to start wsl-vpnkit, the rest is the same.
        $result = Start-Process -FilePath "wsl.exe" -ArgumentList "-d", "wsl-vpnkit", "service", "wsl-vpnkit", "start" -NoNewWindow -Wait -PassThru
        if ($result.ExitCode -eq 0) {
            Show-Notification -Title "WEnix-VPNKIT" -Message "WEnix-VPNKIT service started successfully."
        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to start wsl-vpnkit service. Exit code: " + $result.ExitCode, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }

    catch {
        [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Action for Button 4, Backup WEnix Image
$action4 = {
    $wslBackupForm = New-Object System.Windows.Forms.Form
    $wslBackupForm.Text = "WEnix Image Backup"
    $wslBackupForm.Size = New-Object System.Drawing.Size(600, 600)
    $wslBackupForm.StartPosition = "CenterScreen"
    $wslBackupForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(565, 20)
    $label.Text = "Available WEnix Images (double-click to select):"
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label)

    $dataGridView = New-Object System.Windows.Forms.DataGridView
    $dataGridView.Location = New-Object System.Drawing.Point(10, 50)
    $dataGridView.Size = New-Object System.Drawing.Size(565, 150)
    $dataGridView.ColumnCount = 1
    $dataGridView.Columns[0].Name = "WEnix Images"
    $dataGridView.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $dataGridView.ReadOnly = $true
    $dataGridView.AllowUserToAddRows = $false
    $dataGridView.AllowUserToDeleteRows = $false
    $dataGridView.AllowUserToResizeRows = $false
    $dataGridView.RowHeadersVisible = $false
    $dataGridView.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $dataGridView.MultiSelect = $false
    $dataGridView.BackgroundColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $dataGridView.ForeColor = [System.Drawing.Color]::White
    $dataGridView.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(0, 0, 0)
    $dataGridView.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $dataGridView.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0, 100, 89)
    $dataGridView.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $dataGridView.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 89)
    $dataGridView.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $dataGridView.Font = New-Object System.Drawing.Font("Consolas", 10)
    $dataGridView.EnableHeadersVisualStyles = $false
    $dataGridView.Add_CellMouseDoubleClick({
        if ($_.RowIndex -ge 0) {
            $selectedImageName = $dataGridView.Rows[$_.RowIndex].Cells[0].Value
            $imageNameTextBox.Text = $selectedImageName
        }
    })
    $wslBackupForm.Controls.Add($dataGridView)

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 210)
    $label1.Size = New-Object System.Drawing.Size(565, 20)
    $label1.Text = "Enter the name of the WEnix image to export:"
    $label1.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label1.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label1)

    $imageNameTextBox = New-Object System.Windows.Forms.TextBox
    $imageNameTextBox.Location = New-Object System.Drawing.Point(10, 240)
    $imageNameTextBox.Size = New-Object System.Drawing.Size(565, 20)
    $wslBackupForm.Controls.Add($imageNameTextBox)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 270)
    $label2.Size = New-Object System.Drawing.Size(565, 20)
    $label2.Text = "Enter export file name: (don't use spaces)"
    $label2.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label2.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label2)

    $exportNameTextBox = New-Object System.Windows.Forms.TextBox
    $exportNameTextBox.Location = New-Object System.Drawing.Point(10, 300)
    $exportNameTextBox.Size = New-Object System.Drawing.Size(565, 20)
    $wslBackupForm.Controls.Add($exportNameTextBox)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Location = New-Object System.Drawing.Point(10, 330)
    $label3.Size = New-Object System.Drawing.Size(565, 20)
    $label3.Text = "Select export location (leave blank for default C:\_WSL2):"
    $label3.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label3.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label3)

    $exportLocationTextBox = New-Object System.Windows.Forms.TextBox
    $exportLocationTextBox.Location = New-Object System.Drawing.Point(10, 360)
    $exportLocationTextBox.Size = New-Object System.Drawing.Size(450, 20)
    $wslBackupForm.Controls.Add($exportLocationTextBox)

    Set-Watermark -TextBox $exportLocationTextBox -Watermark "Leave blank for default (C:\_WSL2)"

 

    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(465, 358)
    $browseButton.Size = New-Object System.Drawing.Size(110, 25)
    $browseButton.Text = "Browse"

    $browseButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $browseButton.BackColor = [System.Drawing.Color]::White
    $browseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $browseButton.Add_Click({

        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select export location"
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $exportLocationTextBox.Text = $folderBrowser.SelectedPath
            $exportLocationTextBox.ForeColor = [System.Drawing.Color]::Black
        }

    })

    $wslBackupForm.Controls.Add($browseButton)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 400)
    $outputTextBox.Size = New-Object System.Drawing.Size(565, 100)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $wslBackupForm.Controls.Add($outputTextBox)

    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Location = New-Object System.Drawing.Point(10, 515)
    $executeButton.Size = New-Object System.Drawing.Size(565, 30)
    $executeButton.Text = "Export WEnix Image"
    $executeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $executeButton.BackColor = [System.Drawing.Color]::White
    $executeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $executeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
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

            if ($exportNameTextBox -notmatch '[^a-zA-Z0-9-]'){
                $outputTextBox.AppendText("Missing information. Please dont us special chare dffff   ort name.`r`n")
                    [System.Windows.Forms.MessageBox]::Show("Please enter a WEnix image name and an export file name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    return
                }
       
            $exportPath = Join-Path $exportLocation $exportName
    
            $outputTextBox.AppendText("Export Path: $exportPath`r`n")
         
            try {
                if (-not (Test-Path $exportLocation)) {
                    New-Item -ItemType Directory -Path $exportLocation | Out-Null
                    $outputTextBox.AppendText("Created directory: $exportLocation`r`n")
                }

            
                $command = "wsl.exe --export `"$selectedImage`" `"$exportPath`""
                $outputTextBox.AppendText("Executing command: $command`r`n")
                Show-Notification -Title "Backup Started" -Message "WEnix Image $selectedImage is currently being backed up. This Process can take up to 5 minutes." -Icon info
                $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", $selectedImage, $exportPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\export_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\export_error.log"
        
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
            }

            catch {
                $outputTextBox.AppendText("Exception occurred: $_`r`n")
                [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }

        } else {
            $outputTextBox.AppendText("Missing information. Please enter an image name and an export name.`r`n")
            [System.Windows.Forms.MessageBox]::Show("Please enter a WEnix image name and an export file name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }

    })

    $wslBackupForm.Controls.Add($executeButton)

    $wslBackupForm.Add_Shown({
        try {
            $originalEncoding = [Console]::OutputEncoding
            [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
            $wslOutput = wsl --list --quiet
           [Console]::OutputEncoding = $originalEncoding
            $wslLines = $wslOutput -split "`n" | Where-Object { $_.Trim() -ne "wsl-vpnkit"}
            foreach ($image in $wslLines) {
                $dataGridView.Rows.Add($image.Trim())
            }
        }

        catch {
            $errorMessage = $_.Exception.Message
            $outputTextBox.AppendText("Error retrieving WEnix images: $errorMessage`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error retrieving WEnix images: $errorMessage", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    $wslBackupForm.ShowDialog()
}
# Action for Button 5, Restore or Import WEnix Image
$action5 = {
    $wslInstallForm = New-Object System.Windows.Forms.Form
    $wslInstallForm.Text = "WEnix Image Installation"
    $wslInstallForm.Size = New-Object System.Drawing.Size(600, 440)
    $wslInstallForm.StartPosition = "CenterScreen"
    $wslInstallForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $label1.Size = New-Object System.Drawing.Size(580, 20)
    $label1.Text = "Select the .tar file for WEnix image installation:"
    $label1.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label1.ForeColor = [System.Drawing.Color]::White
    $wslInstallForm.Controls.Add($label1)

    $tarFileTextBox = New-Object System.Windows.Forms.TextBox
    $tarFileTextBox.Location = New-Object System.Drawing.Point(10, 50)
    $tarFileTextBox.Size = New-Object System.Drawing.Size(460, 20)
    $tarFileTextBox.ReadOnly = $true
    $wslInstallForm.Controls.Add($tarFileTextBox)

    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(475, 48)
    $browseButton.Size = New-Object System.Drawing.Size(100, 25)
    $browseButton.Text = "Browse"
    $browseButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $browseButton.BackColor = [System.Drawing.Color]::White
    $browseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $browseButton.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "TAR files (*.tar; *tar.gz)|*.tar; *tar.gz"
        $openFileDialog.Title = "Select WEnix Image TAR File"
        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $tarFileTextBox.Text = $openFileDialog.FileName
        }
    })

    $wslInstallForm.Controls.Add($browseButton)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 90)
    $label2.Size = New-Object System.Drawing.Size(565, 20)
    $label2.Text = "Enter the desired WEnix image name:"
    $label2.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label2.ForeColor = [System.Drawing.Color]::White
    $wslInstallForm.Controls.Add($label2)

    $imageNameTextBox = New-Object System.Windows.Forms.TextBox
    $imageNameTextBox.Location = New-Object System.Drawing.Point(10, 120)
    $imageNameTextBox.Size = New-Object System.Drawing.Size(565, 20)
    $wslInstallForm.Controls.Add($imageNameTextBox)
 
    $label3 = New-Object System.Windows.Forms.Label
    $label3.Location = New-Object System.Drawing.Point(10, 160)
    $label3.Size = New-Object System.Drawing.Size(580, 20)
    $label3.Text = "Select the import location (leave blank for default):"
    $label3.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label3.ForeColor = [System.Drawing.Color]::White

    $wslInstallForm.Controls.Add($label3)

    $importLocationTextBox = New-Object System.Windows.Forms.TextBox
    $importLocationTextBox.Location = New-Object System.Drawing.Point(10, 190)
    $importLocationTextBox.Size = New-Object System.Drawing.Size(460, 20)

    $wslInstallForm.Controls.Add($importLocationTextBox)

    Set-Watermark -TextBox $importLocationTextBox -Watermark "Leave blank for default (C:\_WSL2\<image_name>)"
 
    $browseLocationButton = New-Object System.Windows.Forms.Button
    $browseLocationButton.Location = New-Object System.Drawing.Point(475, 188)
    $browseLocationButton.Size = New-Object System.Drawing.Size(100, 25)
    $browseLocationButton.Text = "Browse"
    $browseLocationButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $browseLocationButton.BackColor = [System.Drawing.Color]::White
    $browseLocationButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $browseLocationButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $browseLocationButton.Add_Click({

        $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowserDialog.Description = "Select WEnix Image Import Location"
        if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $importLocationTextBox.ForeColor = [System.Drawing.Color]::Black
            $importLocationTextBox.Text = $folderBrowserDialog.SelectedPath
        }
    })

    $wslInstallForm.Controls.Add($browseLocationButton)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 230)
    $outputTextBox.Size = New-Object System.Drawing.Size(565, 100)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $wslInstallForm.Controls.Add($outputTextBox)

    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Location = New-Object System.Drawing.Point(10, 350)
    $installButton.Size = New-Object System.Drawing.Size(565, 30)
    $installButton.Text = "Install WEnix Image"
    $installButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $installButton.BackColor = [System.Drawing.Color]::White
    $installButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $installButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $installButton.Add_Click({
        $tarFile = $tarFileTextBox.Text
        $imageName = $imageNameTextBox.Text.Trim()
        $importLocation = $importLocationTextBox.Text.Trim()
   
        if (-not $tarFile -or -not $imageName) {
            [System.Windows.Forms.MessageBox]::Show("Please select a TAR file and enter an image name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        if ($imageName -notmatch "^[a-zA-Z0-9_-]+$") {
            [System.Windows.Forms.MessageBox]::Show("Please do not use special characters or spaces in name.", "Invalid Image Name", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        if ($importLocation -eq "" -or $importLocation -eq "Leave blank for default (C:\_WSL2\<image_name>)") {
            $importLocation = "C:\_WSL2\$imageName"
        }
 
        $outputTextBox.Clear()
        $outputTextBox.AppendText("Installing WEnix Image:`r`n")
        $outputTextBox.AppendText("TAR File: $tarFile`r`n")
        $outputTextBox.AppendText("Image Name: $imageName`r`n")
        $outputTextBox.AppendText("Import Location: $importLocation`r`n")
        $outputTextBox.AppendText("WSL Version: 2`r`n`r`n")
     
        try {
            # Create the installation directory if it doesn't exist
            if (-not (Test-Path $importLocation)) {
                New-Item -ItemType Directory -Path $importLocation | Out-Null
                $outputTextBox.AppendText("Created directory: $importLocation`r`n")
            }

            # Install the WSL image
            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--import", $imageName, $importLocation, $tarFile, "--version", "2" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\_APPLOG\install_output.log" -RedirectStandardError "C:\_WSL2\_APPLOG\install_error.log"
         
            $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
       
            $stdout = Get-Content "C:\_WSL2\_APPLOG\install_output.log" -Raw
            $stderr = Get-Content "C:\_WSL2\_APPLOG\install_error.log" -Raw
     
            $outputTextBox.AppendText("Standard Output: $stdout`r`n")
            $outputTextBox.AppendText("Standard Error: $stderr`r`n")

           if ($process.ExitCode -eq 0) {
                $outputTextBox.AppendText("WEnix Image installation successful.`r`n")
                Show-Notification -Title "Success" -Message "WEnix Image $imageName installed successfully into WSL 2." -Icon info
           } else {
                $outputTextBox.AppendText("WEnix Image installation failed.`r`n")
                [System.Windows.Forms.MessageBox]::Show("Failed to install WEnix Image. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
        catch {
            $outputTextBox.AppendText("Exception occurred: $_`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    $wslInstallForm.Controls.Add($installButton)
    $wslInstallForm.ShowDialog()
}

# Action for Button 6, Removal of WEnix Image
$action6 = {
    $wslRemoveForm = New-Object System.Windows.Forms.Form
    $wslRemoveForm.Text = "WEnix Image Removal"
    $wslRemoveForm.Size = New-Object System.Drawing.Size(600, 465)
    $wslRemoveForm.StartPosition = "CenterScreen"
    $wslRemoveForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(565, 20)
    $label.Text = "Available WEnix Images (double-click to select):"
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::White
    $wslRemoveForm.Controls.Add($label)

    $dataGridView = New-Object System.Windows.Forms.DataGridView
    $dataGridView.Location = New-Object System.Drawing.Point(10, 50)
    $dataGridView.Size = New-Object System.Drawing.Size(565, 150)
    $dataGridView.ColumnCount = 1
    $dataGridView.Columns[0].Name = "WEnix Image Name"
    $dataGridView.Font = New-Object System.Drawing.Font("Consolas", 10)
    $dataGridView.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $dataGridView.ReadOnly = $true
    $dataGridView.AllowUserToAddRows = $false
    $dataGridView.AllowUserToDeleteRows = $false
    $dataGridView.AllowUserToResizeRows = $false
    $dataGridView.RowHeadersVisible = $false
    $dataGridView.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
    $dataGridView.MultiSelect = $false
    $dataGridView.BackgroundColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $dataGridView.ForeColor = [System.Drawing.Color]::White
    $dataGridView.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(0, 0, 0)
    $dataGridView.DefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $dataGridView.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(0, 100, 89)
    $dataGridView.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $dataGridView.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 89)
    $dataGridView.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::White
    $dataGridView.EnableHeadersVisualStyles = $false
    $dataGridView.Add_CellMouseDoubleClick({
        if ($_.RowIndex -ge 0) {
            $selectedImageName = $dataGridView.Rows[$_.RowIndex].Cells[0].Value
            $imageNameTextBox.Text = $selectedImageName
        }
    })
    $wslRemoveForm.Controls.Add($dataGridView)
 
    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 210)
    $label1.Size = New-Object System.Drawing.Size(565, 20)
    $label1.Text = "Enter the name of the WEnix image to remove:"
    $label1.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $label1.ForeColor = [System.Drawing.Color]::White
    $wslRemoveForm.Controls.Add($label1)

    $imageNameTextBox = New-Object System.Windows.Forms.TextBox
    $imageNameTextBox.Location = New-Object System.Drawing.Point(10, 240)
    $imageNameTextBox.Size = New-Object System.Drawing.Size(565, 20)
    $wslRemoveForm.Controls.Add($imageNameTextBox)
 
    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 270)
    $outputTextBox.Size = New-Object System.Drawing.Size(565, 100)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $wslRemoveForm.Controls.Add($outputTextBox)
 
    $removeButton = New-Object System.Windows.Forms.Button
    $removeButton.Location = New-Object System.Drawing.Point(10, 380)
    $removeButton.Size = New-Object System.Drawing.Size(565, 30)
    $removeButton.Text = "Remove WEnix Image"
    $removeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $removeButton.BackColor = [System.Drawing.Color]::White
    $removeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $removeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $removeButton.Add_Click({
       $selectedImage = $imageNameTextBox.Text.Trim()
        [System.Windows.Forms.MessageBox]::Show(
                "Make sure you have made a full backup of this Image before deleting! Use Backup WEnix feature for image : $selectedImage",
               "Remove WEnix Image, $selectedImage",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
                )      
        if ($selectedImage) {       
            $confirmForm = New-Object System.Windows.Forms.Form
            $confirmForm.Text = "Confirm WEnix Image Removal"
            $confirmForm.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $confirmForm.Size = New-Object System.Drawing.Size(400, 200)
            $confirmForm.StartPosition = "CenterScreen"
            $confirmForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

            $warningLabel = New-Object System.Windows.Forms.Label
            $warningLabel.Location = New-Object System.Drawing.Point(10, 20)
            $warningLabel.Size = New-Object System.Drawing.Size(385, 40)
            $warningLabel.Text = "WARNING: There is no recovery from removal. To proceed, type 'DELETE' in the box below:"
            $warningLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $warningLabel.ForeColor = [System.Drawing.Color]::White
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
            $confirmButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
            $confirmButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
            $confirmButton.Add_Click({
                if ($confirmTextBox.Text -eq "DELETE") {
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
                        # Refresh the DataGridView
                        $dataGridView.Rows.Clear()
                        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
                        $wslOutput = wsl --list --quiet 2>&1
                        $sortedImages = $wslOutput -split "`n" | Where-Object { $_.Trim() -ne "wsl-vpnkit"} | Sort-Object
                        foreach ($image in $sortedImages) {
                            $dataGridView.Rows.Add($image.Trim())
                        }
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
    })
    $wslRemoveForm.Controls.Add($removeButton)

    $wslRemoveForm.Add_Shown({
       try {
            $originalEncoding = [Console]::OutputEncoding
            [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
            $wslOutput = wsl --list --quiet 2>&1
            [Console]::OutputEncoding = $originalEncoding
            $sortedImages = $wslOutput -split "`n" | Where-Object { $_.Trim() -ne "wsl-vpnkit" } | Sort-Object
            foreach ($image in $sortedImages) {
                $dataGridView.Rows.Add($image.Trim())
            }
        }

        catch {
            $errorMessage = $_.Exception.Message
            $outputTextBox.AppendText("Error retrieving WEnix images: $errorMessage`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error retrieving WEnix images: $errorMessage", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    $wslRemoveForm.ShowDialog()
}

# Action for Button 7, WEnix Image Password reset for user: wsl2user
$action7 = {
  
    $wslImages = Get-WSLImages
    if ($wslImages.Count -le 1) {
        # If there are two or fewer WSL images, load the default one
        try {
            Start-Process -FilePath "wsl.exe" -ArgumentList "-u", "root", "passwd", "wsl2user"  -PassThru
            Show-Notification -Title "WEnix Loaded" -Message "Default WEinx distribution Password Change Window Loaded." -Icon Info
        } catch {
            Show-Notification -Title "Error" -Message "An error occurred while loading the default WEnix distribution: $_" -Icon Error
        }
    }

    else {
        # If there are three or more WSL images, show the list
        $wslListForm = New-Object System.Windows.Forms.Form
        $wslListForm.Text = "WEnix Distributions"
        $wslListForm.Size = New-Object System.Drawing.Size(400, 300)
        $wslListForm.StartPosition = "CenterScreen"
        $wslListForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
 
        $label = New-Object System.Windows.Forms.Label
        $label.Location = New-Object System.Drawing.Point(10, 10)
        $label.Size = New-Object System.Drawing.Size(380, 20)
        $label.Text = "Double-click a WEnix Image to load:"
        $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $label.ForeColor = [System.Drawing.Color]::White
        $wslListForm.Controls.Add($label)
 
        $listBox = New-Object System.Windows.Forms.ListBox
        $listBox.Location = New-Object System.Drawing.Point(10, 40)
        $listBox.Size = New-Object System.Drawing.Size(360, 200)
        $listBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
        $listBox.ForeColor = [System.Drawing.Color]::White
        $listBox.Font = New-Object System.Drawing.Font("Arial", 12)
        $wslListForm.Controls.Add($listBox)
 
        foreach ($image in $wslImages) {
            $listBox.Items.Add($image)
       }

        $listBox.Add_DoubleClick({
            $selectedImage = $listBox.SelectedItem
            if ($selectedImage) {
                $wslListForm.Close()
                try {
                    Start-Process -FilePath "wsl" -ArgumentList "-d", $selectedImage,"-u", "root", "passwd", "wsl2user" -PassThru
                    Show-Notification -Title "WEnix Image Loaded" -Message "WEnix Image '$selectedImage' Password Windows has been loaded." -Icon Info
                } catch {
                    Show-Notification -Title "Error" -Message "An error occurred while loading WEnix Image: $_" -Icon Error
                }
            }
        })

        $wslListForm.ShowDialog()
   }
}

# Action for Button 8, Launch of WEnix Pages Site
$action8 = {
    $url = https://wenix.dx.dev.td.com
   
    try {
        Start-Process $url
        Show-Notification -Title "WEnix Website" -Message "Opening $url in your default browser." -Icon Info
    }
    catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Error opening the website: $errorMessage", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Action for Button 9, not filled with a feature yet, coming soon. used as about page for now.

$action9 = {
    $statusForm = New-Object System.Windows.Forms.Form
    $statusForm.Text = "WEnix Image Status"
    $statusForm.Size = New-Object System.Drawing.Size(600, 480)
    $statusForm.StartPosition = "CenterScreen"
    $statusForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 145)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(10, 10)
    $listView.Size = New-Object System.Drawing.Size(565, 180)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $listView.ForeColor = [System.Drawing.Color]::White
    $listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $listView.Columns.Add("Distribution", 300)
    $listView.Columns.Add("Size", 100)

    $statusForm.Controls.Add($listView)

    $wslImages = Get-WSLImages

    foreach ($image in $wslImages) {
        $size = wsl -d $image -- df -h / | Select-Object -Last 1 | ForEach-Object { ($_ -split '\s+')[2] }
        $listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
        $listViewItem.SubItems.Add($size)
        $listView.Items.Add($listViewItem)
    }

    $diskSpaceLabel = New-Object System.Windows.Forms.Label
    $diskSpaceLabel.Location = New-Object System.Drawing.Point(10, 200)
    $diskSpaceLabel.Size = New-Object System.Drawing.Size(565, 20)
    $diskSpaceLabel.ForeColor = [System.Drawing.Color]::White
    $diskSpaceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $diskSpace = Get-PSDrive C | Select-Object -ExpandProperty Free
    $diskSpaceGB = [math]::Round($diskSpace / 1GB, 2)
    $diskSpaceLabel.Text = "Available disk space: $diskSpaceGB GB"
    $statusForm.Controls.Add($diskSpaceLabel)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 230)
    $outputTextBox.Size = New-Object System.Drawing.Size(565, 150)
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
        foreach ($image in $wslImages) {
            $size = wsl -d $image -- df -h / | Select-Object -Last 1 | ForEach-Object { ($_ -split '\s+')[2] }
            $listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
            $listViewItem.SubItems.Add($size)
            $listView.Items.Add($listViewItem)
        }
        $diskSpace = Get-PSDrive C | Select-Object -ExpandProperty Free
        $diskSpaceGB = [math]::Round($diskSpace / 1GB, 2)
        $diskSpaceLabel.Text = "Available disk space: $diskSpaceGB GB"
        $outputTextBox.AppendText("Refresh complete.`r`n")
    })
    $statusForm.Controls.Add($refreshButton)

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(475, 390)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Text = "Close"
    $closeButton.BackColor = [System.Drawing.Color]::White
    $closeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $closeButton.Add_Click({ $statusForm.Close() })
    $statusForm.Controls.Add($closeButton)

    $statusForm.ShowDialog()
}



$WEnixinfo = {
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "About WEnix Companion"
    $aboutForm.Size = New-Object System.Drawing.Size(400, 300)
    $aboutForm.StartPosition = "CenterScreen"
    $aboutForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $aboutForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false
 
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(10, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(380, 30)
    $titleLabel.Text = "WEnix Companion"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $aboutForm.Controls.Add($titleLabel)
 
    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Location = New-Object System.Drawing.Point(10, 60)
    $versionLabel.Size = New-Object System.Drawing.Size(380, 20)
    $versionLabel.Text = "Version 1.0"
    $versionLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Regular)
    $versionLabel.ForeColor = [System.Drawing.Color]::White
    $versionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $aboutForm.Controls.Add($versionLabel)

    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Location = New-Object System.Drawing.Point(10, 100)
    $descriptionLabel.Size = New-Object System.Drawing.Size(360, 90)
    $descriptionLabel.Text = "This tool provides a user-friendly interface for managing Windows Subsystem for Linux (WSL) WEnix Image. It allows you to install, remove, and manage your WSL WEnix environments with ease."
    $descriptionLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $descriptionLabel.ForeColor = [System.Drawing.Color]::White
    $descriptionLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
    $aboutForm.Controls.Add($descriptionLabel)

    $copyrightLabel = New-Object System.Windows.Forms.Label
    $copyrightLabel.Location = New-Object System.Drawing.Point(10, 190)
    $copyrightLabel.Size = New-Object System.Drawing.Size(380, 20)
    $copyrightLabel.Text = "© 2024 Toronto Dominion DX Team"
    $copyrightLabel.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
    $copyrightLabel.ForeColor = [System.Drawing.Color]::White
    $copyrightLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $aboutForm.Controls.Add($copyrightLabel)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(150, 220)
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Text = "OK"
    $okButton.BackColor = [System.Drawing.Color]::White
    $okButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $okButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $okButton.Add_Click({ $aboutForm.Close() })
    $aboutForm.Controls.Add($okButton)

    $aboutForm.ShowDialog()

    # Show-Notification -Title "Coming Soon" -Message "New Feature Coming Soon to this Button" -Icon Info
}
# Calculate centered positions
$centerX = ($mainForm.ClientSize.Width - 340) / 2
$startY = 50

# 9 buttons with specified images, separated into 3 categories
$buttons = @(
    # Category 1
    (New-Button ($centerX + 0) ($startY + 50) "Start WEnix" "C:\_WSL2\_SCRIPTS\WEnix.ico" $action1),
    (New-Button ($centerX + 120) ($startY + 50) "Stop WEnix" "C:\_WSL2\_SCRIPTS\WEnix_stop.ico" $action2),
    (New-Button ($centerX + 240) ($startY + 50) "Start VPNKIT" "C:\_WSL2\_SCRIPTS\Leash-03-02_1.ico" $action3),
    # Category 2
    (New-Button ($centerX + 0) ($startY + 220) "Backup Image" "C:\path\to\image4.jpg" $action4),
    (New-Button ($centerX + 120) ($startY + 220) "Restore Iamge" "C:\path\to\image5.jpg" $action5),
    (New-Button ($centerX + 240) ($startY + 220) "Remvoe Image" "C:\path\to\image6.jpg" $action6),
    # Category 3
    (New-Button ($centerX + 0) ($startY + 390) "Password Reset" "C:\path\to\image7.jpg" $action7),
    (New-Button ($centerX + 120) ($startY + 390) "WEnix Website" "c:\path\to\image8.jpg" $action8),
    (New-Button ($centerX + 240) ($startY + 390) "Shrink WEnix" "C:\path\to\image9.jpg" $action9)
)
 
# titles for buttons
$titles = @(
    (New-ButtonTitle ($centerX + 0) ($startY + 155) "Launch WEnix"),
    (New-ButtonTitle ($centerX + 120) ($startY + 155) "Stop WEnix"),
    (New-ButtonTitle ($centerX + 240) ($startY + 155) "Start VPNKIT"),
    (New-ButtonTitle ($centerX + 0) ($startY + 325) "Backup Image"),
    (New-ButtonTitle ($centerX + 120) ($startY + 325) "Restore Image"),
    (New-ButtonTitle ($centerX + 240) ($startY + 325) "Remove Image"),
    (New-ButtonTitle ($centerX + 0) ($startY + 495) "Password Reset"),
    (New-ButtonTitle ($centerX + 120) ($startY + 495) "WEnix Website"),
    (New-ButtonTitle ($centerX + 240) ($startY + 495) "Shrink WEnix")
)

# App category labels
$categoryLabels = @(
    (New-CategoryLabel $centerX ($startY + 10) "Start / Stop WEnix"),
    (New-CategoryLabel $centerX ($startY + 180) "Manage WEnix Images"),
    (New-CategoryLabel $centerX ($startY + 350) "Password and WEnix Documentation")
)

# Add buttons, titles, and labels to the main form
foreach ($button in $buttons) {
    $mainForm.Controls.Add($button)
}
foreach ($title in $titles) {
    $mainForm.Controls.Add($title)
}
foreach ($label in $categoryLabels) {
    $mainForm.Controls.Add($label)
}

 # Show the main form
$mainForm.ShowDialog()



$aboutMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutMenuItem.Text = "About"
$aboutMenuItem.Add_Click({
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "About WEnix Companion"
    $aboutForm.Size = New-Object System.Drawing.Size(400, 300)
    $aboutForm.StartPosition = "CenterScreen"
    $aboutForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(10, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(380, 30)
    $titleLabel.Text = "WEnix Companion"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $aboutForm.Controls.Add($titleLabel)

    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Location = New-Object System.Drawing.Point(10, 60)
    $versionLabel.Size = New-Object System.Drawing.Size(380, 20)
    $versionLabel.Text = "Version 1.0.0.0.0"
    $versionLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Regular)
    $versionLabel.ForeColor = [System.Drawing.Color]::White
    $versionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $aboutForm.Controls.Add($versionLabel)

    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Location = New-Object System.Drawing.Point(10, 100)
    $descriptionLabel.Size = New-Object System.Drawing.Size(360, 90)
    $descriptionLabel.Text = "This tool provides a user-friendly interface for managing Windows Subsystem for Linux (WSL) WEnix Image. It allows you to install, remove, and manage your WSL WEnix environments with ease."
    $descriptionLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $descriptionLabel.ForeColor = [System.Drawing.Color]::White
    $descriptionLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
    $aboutForm.Controls.Add($descriptionLabel)

    $copyrightLabel = New-Object System.Windows.Forms.Label
    $copyrightLabel.Location = New-Object System.Drawing.Point(10, 190)
    $copyrightLabel.Size = New-Object System.Drawing.Size(380, 20)
    $copyrightLabel.Text = "© 2024 Toronto Dominion DX Team"
    $copyrightLabel.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
    $copyrightLabel.ForeColor = [System.Drawing.Color]::White
    $copyrightLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $aboutForm.Controls.Add($copyrightLabel)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(150, 220)
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Text = "OK"
    $okButton.BackColor = [System.Drawing.Color]::White
    $okButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $okButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $okButton.Add_Click({ $aboutForm.Close() })
    $aboutForm.Controls.Add($okButton)

    $aboutForm.ShowDialog()
})


# Action for Button 3, Launch WEnix VPNKIT
$action3 = {
    try {
        # Check if wsl-vpnkit is already running
        $runningDistros = wsl --list --verbose
        if ($runningDistros -match "wsl-vpnkit") {
            Show-Notification -Title "WEnix-VPNKIT" -Message "WEnix-VPNKIT is already running." -Icon Info
        } else {
            # Start wsl-vpnkit in the background
            Start-Process -FilePath "wsl.exe" -ArgumentList "-d", "wsl-vpnkit", "service", "wsl-vpnkit", "start" -NoNewWindow -PassThru

            # Show notification immediately
            Show-Notification -Title "WEnix-VPNKIT" -Message "WEnix-VPNKIT service start initiated. It may take a moment to fully start." -Icon Info
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}
 


# Action for Button 3, Launch WEnix VPNKIT
$action3 = {
    try {
        # Check if wsl-vpnkit is already running
        $runningDistros = wsl --list --verbose | Select-String "Running"
        if ($runningDistros -match "wsl-vpnkit") {
            Show-Notification -Title "WEnix-VPNKIT" -Message "WEnix-VPNKIT is already running." -Icon Info
        } else {
            # Start wsl-vpnkit
            $result = Start-Process -FilePath "wsl.exe" -ArgumentList "-d", "wsl-vpnkit", "service", "wsl-vpnkit", "start" -NoNewWindow -Wait -PassThru
            if ($result.ExitCode -eq 0) {
                Show-Notification -Title "WEnix-VPNKIT" -Message "WEnix-VPNKIT service started successfully." -Icon Info
            } else {
                [System.Windows.Forms.MessageBox]::Show("Failed to start wsl-vpnkit service. Exit code: " + $result.ExitCode, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}




$action9 = {
    $statusForm = New-Object System.Windows.Forms.Form
    $statusForm.Text = "WEnix Image Status"
    $statusForm.Size = New-Object System.Drawing.Size(600, 480)
    $statusForm.StartPosition = "CenterScreen"
    $statusForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 145)

    $listView = New-Object System.Windows.Forms.ListView
    $listView.Location = New-Object System.Drawing.Point(10, 10)
    $listView.Size = New-Object System.Drawing.Size(565, 180)
    $listView.View = [System.Windows.Forms.View]::Details
    $listView.FullRowSelect = $true
    $listView.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $listView.ForeColor = [System.Drawing.Color]::White
    $listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

    $listView.Columns.Add("Distribution", 300)
    $listView.Columns.Add("Size", 100)

    $statusForm.Controls.Add($listView)

    $wslImages = Get-WSLImages

    foreach ($image in $wslImages) {
        $size = wsl -d $image -- df -h / | Select-Object -Last 1 | ForEach-Object { ($_ -split '\s+')[2] }
        $listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
        $listViewItem.SubItems.Add($size)
        $listView.Items.Add($listViewItem)
    }

    $diskSpaceLabel = New-Object System.Windows.Forms.Label
    $diskSpaceLabel.Location = New-Object System.Drawing.Point(10, 200)
    $diskSpaceLabel.Size = New-Object System.Drawing.Size(565, 20)
    $diskSpaceLabel.ForeColor = [System.Drawing.Color]::White
    $diskSpaceLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $diskSpace = Get-PSDrive C | Select-Object -ExpandProperty Free
    $diskSpaceGB = [math]::Round($diskSpace / 1GB, 2)
    $diskSpaceLabel.Text = "Available disk space: $diskSpaceGB GB"
    $statusForm.Controls.Add($diskSpaceLabel)

    $outputTextBox = New-Object System.Windows.Forms.RichTextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 230)
    $outputTextBox.Size = New-Object System.Drawing.Size(565, 150)
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
        foreach ($image in $wslImages) {
            $size = wsl -d $image -- df -h / | Select-Object -Last 1 | ForEach-Object { ($_ -split '\s+')[2] }
            $listViewItem = New-Object System.Windows.Forms.ListViewItem($image)
            $listViewItem.SubItems.Add($size)
            $listView.Items.Add($listViewItem)
        }
        $diskSpace = Get-PSDrive C | Select-Object -ExpandProperty Free
        $diskSpaceGB = [math]::Round($diskSpace / 1GB, 2)
        $diskSpaceLabel.Text = "Available disk space: $diskSpaceGB GB"
        $outputTextBox.AppendText("Refresh complete.`r`n")
    })
    $statusForm.Controls.Add($refreshButton)

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Location = New-Object System.Drawing.Point(475, 390)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Text = "Close"
    $closeButton.BackColor = [System.Drawing.Color]::White
    $closeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $closeButton.Add_Click({ $statusForm.Close() })
    $statusForm.Controls.Add($closeButton)

    $statusForm.ShowDialog()
}


function Add-FormattedText{
    param (
        [System.Windows.Form.RichTextBox]$RichTextBox,
        [string]$text,
        [System.Drawing.Font]$Font = $RichTextBox.Font,
        [System.Drawing.Color]$Color = [System.Drawing.Color]::Black,
        [bool]$bold = $false,
        [bool]$Italic = $false,
        [bool]$Underline = $false
    )

$startIndex = $RichTextBox.TextLength
$RichTextBox.AppendText($text)
$endIndex = $RichTextBox.TextLength

$RichTextBox.Select($startIndex, $endIndex - $startIndex)

$Style = [System.Drawing.FontStyle]::Regular
if ($Bold) {$style = $style -bor [System.Drawing.FontStyle]::Bold}
if ($Italic) {$style = $style -bor [System.Drawing.FontStyle]::Italic}
if ($Underline) {$style = $style -bor [System.Drawing.FontStyle]::Underline}

$RichTextBox.SelectionFont = New-Object System.Drawing.Font($Font.FontFamily, $Font.Size, $style)
$RichTextBox.SelectionColor = $Color
$RichTextBox.DeselectAll()
}
