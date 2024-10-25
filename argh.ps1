mport-Module .\styles.ps1
Import-Module .\functions.ps1

# main form of app
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Whoosh - WEnix Companion"
$mainForm.Size = New-Object System.Drawing.Size(450, 475) # Increased height
$mainForm.Icon = "C:\_WSL2\_SCRIPTS\WEnix.ico"
$mainForm.MaximumSize = $mainForm.Size
$mainForm.MinimumSize = $mainForm.Size
New-FormStyle -form $mainForm

$toolTip = New-Object System.Windows.Forms.ToolTip

$originalEncoding = [Console]::OutputEncoding
  [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
  $wslOutput = wsl --list --running
  [Console]::OutputEncoding = $originalEncoding
  $runningDistros = ($wslOutput -split "`n" )

# Create menu strip
$menuStrip = New-Object System.Windows.Forms.MenuStrip
New-MenuStyle -form $menu

 

# File menu
$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "File"

$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem.Text = "Exit"
$exitMenuItem.Add_Click({ $mainForm.Close() })

$fileMenu.DropDownItems.Add($exitMenuItem)

$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text = "Help"

# Function to open a URL in the default browser
function Open-URL {
  param ($url)
  try {
  # Use Start-Process to open the URL in the default browser
  Start-Process $url
  } catch {
  [System.Windows.Forms.MessageBox]::Show("Unable to open the URL: $url", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
  }
}

 

# Add multiple help menu items that link to websites
$helpTopics = @(
  @{ Text = "Whoosh Help"; URL = https://www.example.com/general_help },
  @{ Text = "WEnix Help"; URL = https://www.example.com/wenix_usage },
  @{ Text = "About"; URL = https://www.example.com/vpnkit_help }
)

foreach ($topic in $helpTopics) {
  $menuItem = New-Object System.Windows.Forms.ToolStripMenuItem
  $menuItem.Text = $topic.Text
  $menuItem.Add_Click({ Open-URL $topic.URL })
  $helpMenu.DropDownItems.Add($menuItem)
}

 
$aboutMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutMenuItem.Text = "About"
$aboutMenuItem.Add_Click({
  $aboutForm = New-Object System.Windows.Forms.Form
  $aboutForm.Text = "About Whoosh - WEnix Companion"
  $aboutForm.Size = New-Object System.Drawing.Size(400, 300)
  $aboutForm.StartPosition = "CenterScreen"
  $aboutForm.BackColor = [System.Drawing.Color]::FromArgb(246, 250, 240)

  $titleLabel = New-Object System.Windows.Forms.Label
  $titleLabel.Location = New-Object System.Drawing.Point(10, 20)
  $titleLabel.Size = New-Object System.Drawing.Size(380, 30)
  $titleLabel.Text = "Whoosh - WEnix Companion"
  $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
  $titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(3, 130, 3)
  $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
  $aboutForm.Controls.Add($titleLabel)
 

  $versionLabel = New-Object System.Windows.Forms.Label
  $versionLabel.Location = New-Object System.Drawing.Point(10, 60)
  $versionLabel.Size = New-Object System.Drawing.Size(380, 20)
  $versionLabel.Text = "Version 0.3"
  $versionLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Regular)
  $versionLabel.ForeColor = [System.Drawing.Color]::FromArgb(3, 130, 3)
  $versionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
  $aboutForm.Controls.Add($versionLabel)

  $descriptionLabel = New-Object System.Windows.Forms.Label
  $descriptionLabel.Location = New-Object System.Drawing.Point(10, 100)
  $descriptionLabel.Size = New-Object System.Drawing.Size(360, 90)
  $descriptionLabel.Text = "This tool provides a user-friendly interface for managing Windows Subsystem for Linux (WSL) WEnix Image. It allows you to install, remove, and manage your WSL WEnix environments with ease."
  $descriptionLabel.Font = New-Object System.Drawing.Font("Arial", 10)
  $descriptionLabel.ForeColor = [System.Drawing.Color]::Black
  $descriptionLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
  $aboutForm.Controls.Add($descriptionLabel)

  $copyrightLabel = New-Object System.Windows.Forms.Label
  $copyrightLabel.Location = New-Object System.Drawing.Point(10, 190)
  $copyrightLabel.Size = New-Object System.Drawing.Size(380, 20)
  $copyrightLabel.Text = "© 2024 Toronto Dominion DX Team"
  $copyrightLabel.Font = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
  $copyrightLabel.ForeColor = [System.Drawing.Color]::FromArgb(3, 130, 3)
  $copyrightLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
  $aboutForm.Controls.Add($copyrightLabel)

  $okButton = New-Object System.Windows.Forms.Button
  $okButton.Location = New-Object System.Drawing.Point(150, 220)
  $okButton.Size = New-Object System.Drawing.Size(100, 30)
  $okButton.Text = "OK"
  $okButton.BackColor = [System.Drawing.Color]::White
  $okButton.ForeColor = [System.Drawing.Color]::FromArgb(3, 130, 3)
  $okButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
  $okButton.Add_Click({ $aboutForm.Close() })
  $aboutForm.Controls.Add($okButton)

  $aboutForm.ShowDialog()

})

 

$helpMenu.DropDownItems.Add($aboutMenuItem)

# Add menus to menu strip
$menuStrip.Items.Add($fileMenu)
$menuStrip.Items.Add($helpMenu)

# Add menu strip to form
$mainForm.Controls.Add($menuStrip)

# Add menu strip to form
$mainForm.MainMenuStrip = $menuStrip

# Define actions for each button, buttons 1 thorugh 9

# Action for Button 1, for launching WEnix Default Image, or select from list if more are installed.

$action1 = {
  Start-Process -FilePath "powershell" "actions/launch-image.ps1" -NoNewWindow
}

# Action for Button 2, Complete WSL shutdown
$action2 = {
  Start-Process -FilePath "powershell" "actions/stop-wenix.ps1" -NoNewWindow
}

# Action for Button 3, Launch WEnix VPNKIT

$action3 = {
  Start-Process -FilePath "powershell" "actions/launch-vpnkit.ps1" -NoNewWindow
  if ($runningDistros -match "wsl-vpnkit" -and $runningDistros -notmatch "\n"){
  Start-Sleep -Seconds 6
  (New-Button ($centerX + 240) ($startY + 50) "Start VPNKIT" "icons/Leash-vpnkit.ico" $action3 "This will turn on if you WEnix gets a NetWork Error on startup`n or no internet conneciton.")
  } else {
  Start-Sleep -Seconds 6
  (New-Button ($centerX + 240) ($startY + 50) "Start VPNKIT" "icons/Leash-vpnkit-sad.png" $action3 "This will turn on if you WEnix gets a NetWork Error on startup`n or no internet conneciton.")
  }
}

# Action for Button 8, Launch of WEnix Pages Site

$action8 = {
  Start-Process -FilePath "powershell" "actions/wenix-site.ps1" -NoNewWindow
}

# Action for Button 9, not filled with a feature yet, coming soon. used as about page for now.
$action9 = {
  Start-Process -FilePath "powershell" "actions/wenix-toolbox.ps1" -NoNewWindow
}

# Calculate centered positions
$centerX = ($mainForm.ClientSize.Width - 340) / 2
$startY = 50
 
# 9 buttons with specified images, separated into 3 categories

$buttons = @(
  # Category 1
  (New-Button ($centerX + 0) ($startY + 50) "Start WEnix" "icons/WEnix.ico" $action1 "This Will start WEnix.`n If you have 2 or more installed, select from the list"),
  (New-Button ($centerX + 120) ($startY + 50) "Stop WEnix" "icons/WEnix_stop.ico" $action2 "This will close all WEnix WSL services")
 

  if ($runningDistros -match "wsl-vpnkit" -and $runningDistros -notmatch "\n"){
  (New-Button ($centerX + 240) ($startY + 50) "Start VPNKIT" "icons/Leash-vpnkit.ico" $action3 "This will turn on if you WEnix gets a NetWork Error on startup`n or no internet conneciton.")
  } else {
  (New-Button ($centerX + 240) ($startY + 50) "Start VPNKIT" "icons/Leash-vpnkit-sad.png" $action3 "This will turn on if you WEnix gets a NetWork Error on startup`n or no internet conneciton.")
  }

  # Category 2
  (New-Button ($centerX + 60) ($startY + 220) "WEnix Website" "icons/About_the_App.ico" $action8 "Click here to access WEnix Pages Site`n For tips, walkthroughs, News & more!"),
  (New-Button ($centerX + 180) ($startY + 220) "Image Status" "icons/Launch_Website.ico" $action9 "Whoosh Toolbox will help you with WEnix Image tools:`n install, remove, password reset & more!")
)




# titles for buttons

$titles = @(
  (New-ButtonTitle ($centerX + 0) ($startY + 155) "Launch WEnix"),
  (New-ButtonTitle ($centerX + 120) ($startY + 155) "Stop WEnix"),
  (New-ButtonTitle ($centerX + 240) ($startY + 155) "Start VPNKIT"),
  (New-ButtonTitle ($centerX + 60) ($startY + 325) "WEnix Website"),
  (New-ButtonTitle ($centerX + 180) ($startY + 325) "WEnix Toolbox")
  )

 

# App category labels

$categoryLabels = @(
  (New-CategoryLabel $centerX ($startY + 10) "Start / Stop WEnix"),
  (New-CategoryLabel $centerX ($startY + 180) "Manage WEnix Images")
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