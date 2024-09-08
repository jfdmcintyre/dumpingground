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


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "WEnix Companion"
$mainForm.Size = New-Object System.Drawing.Size(600, 700)
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
$mainForm.Icon = "C:\_WSL2\_SCRIPTS\WEnix.ico"

# Menu strip
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(0, 130, 116)
$menuStrip.ForeColor = [System.Drawing.Color]::White

$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "File"

$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem.Text = "Exit"
$exitMenuItem.Add_Click({ $mainForm.Close() })

$fileMenu.DropDownItems.Add($exitMenuItem)

$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text = "Help"

$helpMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenuItem.Text = "Help"

# Define the help file path
$helpFilePath = "C:\path\to\help.txt"  # Replace with the correct path to your help file

# Function to show help text in a new form
function Show-Help {
    # Load help text from external file
    if (Test-Path $helpFilePath) {
        $helpText = Get-Content -Path $helpFilePath -Raw
    } else {
        $helpText = "Help file not found."
    }

    # Create a new form for the help content
    $helpForm = New-Object System.Windows.Forms.Form
    $helpForm.Text = "Help"
    $helpForm.Size = New-Object System.Drawing.Size(400, 400)
    $helpForm.StartPosition = "CenterParent"
    $helpForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    # Add a RichTextBox to display the help text
    $helpTextBox = New-Object System.Windows.Forms.RichTextBox
    $helpTextBox.Size = New-Object System.Drawing.Size(380, 360)
    $helpTextBox.Location = New-Object System.Drawing.Point(10, 10)
    $helpTextBox.Text = $helpText
    $helpTextBox.ReadOnly = $true
    $helpTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $helpTextBox.ForeColor = [System.Drawing.Color]::White
    $helpTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    # Add the help text box to the form
    $helpForm.Controls.Add($helpTextBox)

    # Show the help form as a modal dialog
    $helpForm.ShowDialog()
}

# Add the help click event
$helpMenuItem.Add_Click({ Show-Help })

$aboutMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutMenuItem.Text = "About"
$aboutMenuItem.Add_Click($WEnixinfo)

$helpMenu.DropDownItems.Add($helpMenuItem)
$helpMenu.DropDownItems.Add($aboutMenuItem)

$menuStrip.Items.Add($fileMenu)
$menuStrip.Items.Add($helpMenu)

# Add menu strip to form
$mainForm.Controls.Add($menuStrip)
$mainForm.MainMenuStrip = $menuStrip

# Create buttons and add other controls as before...

# Show the main form
$mainForm.ShowDialog()
