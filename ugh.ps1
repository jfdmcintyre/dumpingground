Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "Multi-Function Tool"
$mainForm.Size = New-Object System.Drawing.Size(600, 600)
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Function to create a button with an image
function New-Button {
    param ($x, $y, $text, $imagePath)
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($x, $y)
    $button.Size = New-Object System.Drawing.Size(100, 100)
    $button.Text = $text
    $button.BackColor = [System.Drawing.Color]::White
    $button.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $button.Add_Click({ Open-FunctionWindow $text })

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
    $button.ImageAlign = [System.Drawing.ContentAlignment]::TopCenter
    $button.TextAlign = [System.Drawing.ContentAlignment]::BottomCenter
    $button.TextImageRelation = [System.Windows.Forms.TextImageRelation]::ImageAboveText

    return $button
}

# Function to create a category label
function New-CategoryLabel {
    param ($x, $y, $text)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.Size = New-Object System.Drawing.Size(340, 30)
    $label.Text = $text
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $label.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    return $label
}

# Create 9 buttons with specified images, separated into 3 categories
$buttons = @(
    # Category 1
    (Create-Button 50 50 "Function 1" "C:\path\to\image1.jpg"),
    (Create-Button 170 50 "Function 2" "C:\path\to\image2.jpg"),
    (Create-Button 290 50 "Function 3" "C:\path\to\image3.jpg"),
    # Category 2
    (Create-Button 50 200 "Function 4" "C:\path\to\image4.jpg"),
    (Create-Button 170 200 "Function 5" "C:\path\to\image5.jpg"),
    (Create-Button 290 200 "Function 6" "C:\path\to\image6.jpg"),
    # Category 3
    (Create-Button 50 350 "Function 7" "C:\path\to\image7.jpg"),
    (Create-Button 170 350 "Function 8" "C:\path\to\image8.jpg"),
    (Create-Button 290 350 "Function 9" "C:\path\to\image9.jpg")
)

# Create category labels
$categoryLabels = @(
    (Create-CategoryLabel 50 10 "Category 1"),
    (Create-CategoryLabel 50 160 "Category 2"),
    (Create-CategoryLabel 50 310 "Category 3")
)

# Add buttons and labels to the main form
foreach ($button in $buttons) {
    $mainForm.Controls.Add($button)
}
foreach ($label in $categoryLabels) {
    $mainForm.Controls.Add($label)
}

# Function to open a new window for each function
function Open-FunctionWindow {
    param ($functionName)
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $functionName
    $form.Size = New-Object System.Drawing.Size(300, 200)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(280, 40)
    $label.Text = "This is the window for $functionName"
    $label.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($label)

    # Add specific functionality for each function here
    # For example:
    switch ($functionName) {
        "Function 1" { Function1 $form }
        "Function 2" { Function2 $form }
        # ... Add cases for Functions 3-9
    }

    $form.ShowDialog()
}

# Example functions for each button
function Function1 {
    param ($form)
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(10, 70)
    $button.Size = New-Object System.Drawing.Size(100, 30)
    $button.Text = "Get Date"
    $button.BackColor = [System.Drawing.Color]::White
    $button.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $button.Add_Click({
        [System.Windows.Forms.MessageBox]::Show((Get-Date), "Current Date and Time")
    })
    $form.Controls.Add($button)
}

function Function2 {
    param ($form)
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10, 70)
    $textBox.Size = New-Object System.Drawing.Size(200, 20)
    $form.Controls.Add($textBox)

    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(10, 100)
    $button.Size = New-Object System.Drawing.Size(100, 30)
    $button.Text = "Uppercase"
    $button.BackColor = [System.Drawing.Color]::White
    $button.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $button.Add_Click({
        $textBox.Text = $textBox.Text.ToUpper()
    })
    $form.Controls.Add($button)
}

# Add more functions for buttons 3-9 here

# Show the main form
$mainForm.ShowDialog()





$action9 = {
    Write-DebugLog "Executing Action 9: Show About Page" "INFO"

    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "About WSL Management Tool"
    $aboutForm.Size = New-Object System.Drawing.Size(400, 300)
    $aboutForm.StartPosition = "CenterScreen"
    $aboutForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $aboutForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Location = New-Object System.Drawing.Point(10, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(380, 30)
    $titleLabel.Text = "WSL Management Tool"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $aboutForm.Controls.Add($titleLabel)

    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Location = New-Object System.Drawing.Point(10, 60)
    $versionLabel.Size = New-Object System.Drawing.Size(380, 20)
    $versionLabel.Text = "Version 1.0"
    $versionLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $versionLabel.ForeColor = [System.Drawing.Color]::White
    $versionLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $aboutForm.Controls.Add($versionLabel)

    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Location = New-Object System.Drawing.Point(10, 100)
    $descriptionLabel.Size = New-Object System.Drawing.Size(360, 100)
    $descriptionLabel.Text = "This tool provides a user-friendly interface for managing Windows Subsystem for Linux (WSL) distributions. It allows you to install, remove, and manage your WSL environments with ease."
    $descriptionLabel.Font = New-Object System.Drawing.Font("Arial", 10)
    $descriptionLabel.ForeColor = [System.Drawing.Color]::White
    $descriptionLabel.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
    $aboutForm.Controls.Add($descriptionLabel)

    $copyrightLabel = New-Object System.Windows.Forms.Label
    $copyrightLabel.Location = New-Object System.Drawing.Point(10, 210)
    $copyrightLabel.Size = New-Object System.Drawing.Size(380, 20)
    $copyrightLabel.Text = "© 2024 Your Company Name"
    $copyrightLabel.Font = New-Object System.Drawing.Font("Arial", 8)
    $copyrightLabel.ForeColor = [System.Drawing.Color]::White
    $copyrightLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $aboutForm.Controls.Add($copyrightLabel)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(150, 240)
    $okButton.Size = New-Object System.Drawing.Size(100, 30)
    $okButton.Text = "OK"
    $okButton.BackColor = [System.Drawing.Color]::White
    $okButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $okButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $okButton.Add_Click({ $aboutForm.Close() })
    $aboutForm.Controls.Add($okButton)

    Write-DebugLog "Showing About page" "INFO"
    $aboutForm.ShowDialog()
}
