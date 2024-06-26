Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Multi-Function Tool"
$mainForm.Size = New-Object System.Drawing.Size(600, 700)  # Increased height
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)  # Teal background

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
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    return $label
}

# Define actions for each button
$action1 = {
    try {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c start wsl"
        [System.Windows.Forms.MessageBox]::Show("WSL has been launched in a new Command Prompt window.", "WSL Launched")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error launching WSL: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

$action2 = {
    try {
        $result = Start-Process -FilePath "wsl.exe" -ArgumentList "--shutdown" -NoNewWindow -Wait -PassThru
        if ($result.ExitCode -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("WSL has been shut down successfully.", "WSL Shutdown")
        } else {
            [System.Windows.Forms.MessageBox]::Show("WSL shutdown completed with exit code: " + $result.ExitCode, "WSL Shutdown")
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error shutting down WSL: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

$action3 = {
    try {
        $result = Start-Process -FilePath "wsl.exe" -ArgumentList "-d", "wsl-vpnkit", "service", "wsl-vpnkit", "start" -NoNewWindow -Wait -PassThru
        if ($result.ExitCode -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("wsl-vpnkit service started successfully.", "Function 3")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to start wsl-vpnkit service. Exit code: " + $result.ExitCode, "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

$action4 = {
    $wslBackupForm = New-Object System.Windows.Forms.Form
    $wslBackupForm.Text = "WSL Backup"
    $wslBackupForm.Size = New-Object System.Drawing.Size(400, 300)
    $wslBackupForm.StartPosition = "CenterScreen"
    $wslBackupForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(380, 20)
    $label.Text = "Select WSL Image to Backup:"
    $label.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label)

    $dropdown = New-Object System.Windows.Forms.ComboBox
    $dropdown.Location = New-Object System.Drawing.Point(10, 50)
    $dropdown.Size = New-Object System.Drawing.Size(360, 20)
    $wslBackupForm.Controls.Add($dropdown)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 90)
    $label2.Size = New-Object System.Drawing.Size(380, 20)
    $label2.Text = "Backup Name:"
    $label2.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label2)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 120)
    $textBox.Size = New-Object System.Drawing.Size(360, 20)
    $textBox.Text = "Enter backup name here"
    $wslBackupForm.Controls.Add($textBox)

    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Location = New-Object System.Drawing.Point(10, 160)
    $executeButton.Size = New-Object System.Drawing.Size(360, 30)
    $executeButton.Text = "Backup WSL Image"
    $executeButton.BackColor = [System.Drawing.Color]::White
    $executeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $executeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $executeButton.Add_Click({
        $selectedImage = $dropdown.SelectedItem
        $backupName = $textBox.Text
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
            [System.Windows.Forms.MessageBox]::Show("Please select a WSL image and enter a backup name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    $wslBackupForm.Controls.Add($executeButton)

    $wslBackupForm.Add_Shown({
        try {
            $wslOutput = wsl --list --verbose | Out-String
            $wslImages = $wslOutput -split "`r`n" | Select-Object -Skip 1 | Where-Object { $_.Trim() -ne "" }
            foreach ($image in $wslImages) {
                $dropdown.Items.Add($image)
            }
            if ($dropdown.Items.Count -gt 0) {
                $dropdown.SelectedIndex = 0
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Error retrieving WSL images: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    $wslBackupForm.ShowDialog()
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

# Calculate centered positions
$centerX = ($mainForm.ClientSize.Width - 340) / 2
$startY = 50

# Create 9 buttons with specified images, separated into 3 categories
$buttons = @(
    # Category 1
    (Create-Button ($centerX + 0) ($startY + 50) "Launch WSL" "C:\path\to\wsl_icon.png" $action1),
    (Create-Button ($centerX + 120) ($startY + 50) "Shutdown WSL" "C:\path\to\image2.jpg" $action2),
    (Create-Button ($centerX + 240) ($startY + 50) "Function 3" "C:\path\to\image3.jpg" $action3),
    # Category 2
    (Create-Button ($centerX + 0) ($startY + 220) "Function 4" "C:\path\to\image4.jpg" $action4),
    (Create-Button ($centerX + 120) ($startY + 220) "Function 5" "C:\path\to\image5.jpg" $action5),
    (Create-Button ($centerX + 240) ($startY + 220) "Function 6" "C:\path\to\image6.jpg" $action6),
    # Category 3
    (Create-Button ($centerX + 0) ($startY + 390) "Function 7" "C:\path\to\image7.jpg" $action7),
    (Create-Button ($centerX + 120) ($startY + 390) "Function 8" "C:\path\to\image8.jpg" $action8),
    (Create-Button ($centerX + 240) ($startY + 390) "Function 9" "C:\path\to\image9.jpg" $action9)
)

# Create titles for buttons
$titles = @(
    (Create-ButtonTitle ($centerX + 0) ($startY + 155) "Launch WSL"),
    (Create-ButtonTitle ($centerX + 120) ($startY + 155) "Shutdown WSL"),
    (Create-ButtonTitle ($centerX + 240) ($startY + 155) "Function 3"),
    (Create-ButtonTitle ($centerX + 0) ($startY + 325) "Function 4"),
    (Create-ButtonTitle ($centerX + 120) ($startY + 325) "Function 5"),
    (Create-ButtonTitle ($centerX + 240) ($startY + 325) "Function 6"),
    (Create-ButtonTitle ($centerX + 0) ($startY + 495) "Function 7"),
    (Create-ButtonTitle ($centerX + 120) ($startY + 495) "Function 8"),
    (Create-ButtonTitle ($centerX + 240) ($startY + 495) "Function 9")
)

# Create category labels
$categoryLabels = @(
    (Create-CategoryLabel $centerX ($startY + 10) "Category 1"),
    (Create-CategoryLabel $centerX ($startY + 180) "Category 2"),
    (Create-CategoryLabel $centerX ($startY + 350) "Category 3")
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
