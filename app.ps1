Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Multi-Function Tool"
$mainForm.Size = New-Object System.Drawing.Size(600, 650)
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)  # Teal background

# Function to create a rounded rectangle shape
function Create-RoundedRectangle {
    param (
        [int]$width,
        [int]$height,
        [int]$radius
    )
    
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc(0, 0, $radius * 2, $radius * 2, 180, 90)
    $path.AddArc($width - $radius * 2, 0, $radius * 2, $radius * 2, 270, 90)
    $path.AddArc($width - $radius * 2, $height - $radius * 2, $radius * 2, $radius * 2, 0, 90)
    $path.AddArc(0, $height - $radius * 2, $radius * 2, $radius * 2, 90, 90)
    $path.CloseFigure()
    
    return $path
}

# Function to create a button with an image
function Create-Button {
    param ($x, $y, $text, $imagePath, $action)
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($x, $y)
    $button.Size = New-Object System.Drawing.Size(100, 100)
    $button.Text = ""
    $button.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)  # Teal button background
    $button.ForeColor = [System.Drawing.Color]::White  # White button text
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderColor = [System.Drawing.Color]::White  # White button border
    $button.FlatAppearance.BorderSize = 2
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $button.Region = New-Object System.Drawing.Region($(Create-RoundedRectangle $button.Width $button.Height 20))
    $button.Add_Click($action)

    # Load and set the image
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

    $button.Image = $image
    $button.ImageAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $button.TextAlign = [System.Drawing.ContentAlignment]::BottomCenter
    $button.TextImageRelation = [System.Windows.Forms.TextImageRelation]::ImageAboveText

    return $button
}

# Function to create a title label under a button
function Create-ButtonTitle {
    param ($x, $y, $text)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.Size = New-Object System.Drawing.Size(100, 20)
    $label.Text = $text
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $label.ForeColor = [System.Drawing.Color]::White  # White title text
    $label.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)  # Teal title background
    $label.TextAlign = [System.Drawing.ContentAlignment]::TopCenter
    return $label
}

# Function to create a category label
function Create-CategoryLabel {
    param ($x, $y, $text)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.Size = New-Object System.Drawing.Size(340, 30)
    $label.Text = $text
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::White  # White category text
    $label.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)  # Teal category background
    return $label
}

# Define actions for each button
$action1 = {
    try {
        Start-Process -FilePath "wsl.exe" -NoNewWindow
        [System.Windows.Forms.MessageBox]::Show("WSL has been launched.", "WSL Launched")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error launching WSL: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

$action2 = {
    [System.Windows.Forms.MessageBox]::Show("Function 2 executed.", "Function 2")
}

$action3 = {
    [System.Windows.Forms.MessageBox]::Show("Function 3 executed.", "Function 3")
}

$action4 = {
    [System.Windows.Forms.MessageBox]::Show("Function 4 executed.", "Function 4")
}

$action5 = {
    [System.Windows.Forms.MessageBox]::Show("Function 5 executed.", "Function 5")
}

$action6 = {
    [System.Windows.Forms.MessageBox]::Show("Function 6 executed.", "Function 6")
}

$action7 = {
    [System.Windows.Forms.MessageBox]::Show("Function 7 executed.", "Function 7")
}

$action8 = {
    [System.Windows.Forms.MessageBox]::Show("Function 8 executed.", "Function 8")
}

$action9 = {
    [System.Windows.Forms.MessageBox]::Show("Function 9 executed.", "Function 9")
}

# Create 9 buttons with specified images, separated into 3 categories
$buttons = @(
    # Category 1
    (Create-Button 50 50 "Launch WSL" "C:\path\to\wsl_icon.png" $action1),
    (Create-Button 170 50 "Function 2" "C:\path\to\image2.jpg" $action2),
    (Create-Button 290 50 "Function 3" "C:\path\to\image3.jpg" $action3),
    # Category 2
    (Create-Button 50 220 "Function 4" "C:\path\to\image4.jpg" $action4),
    (Create-Button 170 220 "Function 5" "C:\path\to\image5.jpg" $action5),
    (Create-Button 290 220 "Function 6" "C:\path\to\image6.jpg" $action6),
    # Category 3
    (Create-Button 50 390 "Function 7" "C:\path\to\image7.jpg" $action7),
    (Create-Button 170 390 "Function 8" "C:\path\to\image8.jpg" $action8),
    (Create-Button 290 390 "Function 9" "C:\path\to\image9.jpg" $action9)
)

# Create titles for buttons
$titles = @(
    (Create-ButtonTitle 50 155 "Launch WSL"),
    (Create-ButtonTitle 170 155 "Function 2"),
    (Create-ButtonTitle 290 155 "Function 3"),
    (Create-ButtonTitle 50 325 "Function 4"),
    (Create-ButtonTitle 170 325 "Function 5"),
    (Create-ButtonTitle 290 325 "Function 6"),
    (Create-ButtonTitle 50 495 "Function 7"),
    (Create-ButtonTitle 170 495 "Function 8"),
    (Create-ButtonTitle 290 495 "Function 9")
)

# Create category labels
$categoryLabels = @(
    (Create-CategoryLabel 50 10 "WEnix On / OFF"),
    (Create-CategoryLabel 50 180 "Category 2"),
    (Create-CategoryLabel 50 350 "Category 3")
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


$action4 = {
    $passwordChangeForm = New-Object System.Windows.Forms.Form
    $passwordChangeForm.Text = "Password Change"
    $passwordChangeForm.Size = New-Object System.Drawing.Size(300, 150)
    $passwordChangeForm.StartPosition = "CenterScreen"
    $passwordChangeForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(280, 40)
    $label.Text = "Click the button below to reset the password for 'wsl2user' in the default WSL distribution."
    $label.ForeColor = [System.Drawing.Color]::White
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $passwordChangeForm.Controls.Add($label)

    $resetButton = New-Object System.Windows.Forms.Button
    $resetButton.Location = New-Object System.Drawing.Point(75, 70)
    $resetButton.Size = New-Object System.Drawing.Size(150, 30)
    $resetButton.Text = "Reset Password"
    $resetButton.BackColor = [System.Drawing.Color]::White
    $resetButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $resetButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $resetButton.Add_Click({
        try {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c wsl -u root passwd wsl2user" -NoNewWindow
            [System.Windows.Forms.MessageBox]::Show("Password reset process started. Please follow the prompts in the new command window.", "Password Reset", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error starting password reset process: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $passwordChangeForm.Controls.Add($resetButton)

    $passwordChangeForm.ShowDialog()
}






$action4 = {
    $wslBackupForm = New-Object System.Windows.Forms.Form
    $wslBackupForm.Text = "WSL Backup"
    $wslBackupForm.Size = New-Object System.Drawing.Size(500, 400)
    $wslBackupForm.StartPosition = "CenterScreen"
    $wslBackupForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(480, 20)
    $label.Text = "Available WSL Images:"
    $label.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 50)
    $textBox.Size = New-Object System.Drawing.Size(480, 150)
    $textBox.Multiline = $true
    $textBox.ScrollBars = "Vertical"
    $textBox.ReadOnly = $true
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textBox.ForeColor = [System.Drawing.Color]::White
    $textBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $wslBackupForm.Controls.Add($textBox)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 210)
    $label2.Size = New-Object System.Drawing.Size(480, 20)
    $label2.Text = "Enter the name of the WSL image to backup:"
    $label2.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label2)

    $imageNameTextBox = New-Object System.Windows.Forms.TextBox
    $imageNameTextBox.Location = New-Object System.Drawing.Point(10, 240)
    $imageNameTextBox.Size = New-Object System.Drawing.Size(480, 20)
    $wslBackupForm.Controls.Add($imageNameTextBox)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Location = New-Object System.Drawing.Point(10, 270)
    $label3.Size = New-Object System.Drawing.Size(480, 20)
    $label3.Text = "Enter backup name:"
    $label3.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label3)

    $backupNameTextBox = New-Object System.Windows.Forms.TextBox
    $backupNameTextBox.Location = New-Object System.Drawing.Point(10, 300)
    $backupNameTextBox.Size = New-Object System.Drawing.Size(480, 20)
    $wslBackupForm.Controls.Add($backupNameTextBox)

    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Location = New-Object System.Drawing.Point(10, 330)
    $executeButton.Size = New-Object System.Drawing.Size(480, 30)
    $executeButton.Text = "Backup WSL Image"
    $executeButton.BackColor = [System.Drawing.Color]::White
    $executeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $executeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $executeButton.Add_Click({
        $selectedImage = $imageNameTextBox.Text.Trim()
        $backupName = $backupNameTextBox.Text.Trim()
        if ($selectedImage -and $backupName) {
            try {
                $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", $selectedImage, "C:\_WSL2\$backupName.tar" -NoNewWindow -PassThru -Wait
                if ($process.ExitCode -eq 0) {
                    [System.Windows.Forms.MessageBox]::Show("WSL Image $selectedImage backed up successfully to C:\_WSL2\$backupName.tar.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                } else {
                    [System.Windows.Forms.MessageBox]::Show("Failed to backup WSL Image. Exit code: " + $process.ExitCode, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("Please enter a WSL image name and a backup name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    $wslBackupForm.Controls.Add($executeButton)

    $wslBackupForm.Add_Shown({
        try {
            $wslOutput = wsl --list --verbose | Out-String
            $textBox.Text = $wslOutput
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error retrieving WSL images: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    $wslBackupForm.ShowDialog()
}
