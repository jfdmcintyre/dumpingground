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
    $wslBackupForm.Text = "WSL Export"
    $wslBackupForm.Size = New-Object System.Drawing.Size(600, 600)
    $wslBackupForm.StartPosition = "CenterScreen"
    $wslBackupForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(580, 20)
    $label.Text = "Available WSL Images (double-click to select):"
    $label.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label)

    $dataGridView = New-Object System.Windows.Forms.DataGridView
    $dataGridView.Location = New-Object System.Drawing.Point(10, 50)
    $dataGridView.Size = New-Object System.Drawing.Size(580, 150)
    $dataGridView.ColumnCount = 1
    $dataGridView.Columns[0].Name = "WSL Image Name"
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
    $dataGridView.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
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

    # Add context menu for copying
    $contextMenu = New-Object System.Windows.Forms.ContextMenuStrip
    $copyMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $copyMenuItem.Text = "Copy"
    $copyMenuItem.Add_Click({
        if ($dataGridView.SelectedCells.Count -gt 0) {
            $cellValue = $dataGridView.SelectedCells[0].Value
            [System.Windows.Forms.Clipboard]::SetText($cellValue)
        }
    })
    $contextMenu.Items.Add($copyMenuItem)
    $dataGridView.ContextMenuStrip = $contextMenu

    $wslBackupForm.Controls.Add($dataGridView)

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 210)
    $label1.Size = New-Object System.Drawing.Size(580, 20)
    $label1.Text = "Enter the name of the WSL image to export:"
    $label1.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label1)

    $imageNameTextBox = New-Object System.Windows.Forms.TextBox
    $imageNameTextBox.Location = New-Object System.Drawing.Point(10, 240)
    $imageNameTextBox.Size = New-Object System.Drawing.Size(580, 20)
    $wslBackupForm.Controls.Add($imageNameTextBox)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 270)
    $label2.Size = New-Object System.Drawing.Size(580, 20)
    $label2.Text = "Enter export file name (will be saved in C:\_WSL2):"
    $label2.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label2)

    $exportNameTextBox = New-Object System.Windows.Forms.TextBox
    $exportNameTextBox.Location = New-Object System.Drawing.Point(10, 300)
    $exportNameTextBox.Size = New-Object System.Drawing.Size(580, 20)
    $wslBackupForm.Controls.Add($exportNameTextBox)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 360)
    $outputTextBox.Size = New-Object System.Drawing.Size(580, 180)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $wslBackupForm.Controls.Add($outputTextBox)

    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Location = New-Object System.Drawing.Point(10, 330)
    $executeButton.Size = New-Object System.Drawing.Size(580, 30)
    $executeButton.Text = "Export WSL Image"
    $executeButton.BackColor = [System.Drawing.Color]::White
    $executeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $executeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $executeButton.Add_Click({
        $selectedImage = $imageNameTextBox.Text.Trim()
        $exportName = $exportNameTextBox.Text.Trim()
        
        $outputTextBox.Clear()
        $outputTextBox.AppendText("Selected Image: $selectedImage`r`nExport Name: $exportName`r`n")
        
        if ($selectedImage -and $exportName) {
            if (-not $exportName.EndsWith(".tar")) {
                $exportName += ".tar"
            }
            $exportPath = "C:\_WSL2\$exportName"
            
            $outputTextBox.AppendText("Export Path: $exportPath`r`n")
            
            try {
                if (-not (Test-Path "C:\_WSL2")) {
                    New-Item -ItemType Directory -Path "C:\_WSL2" | Out-Null
                    $outputTextBox.AppendText("Created directory: C:\_WSL2`r`n")
                }

                $command = "wsl.exe --export `"$selectedImage`" `"$exportPath`""
                $outputTextBox.AppendText("Executing command: $command`r`n")

                $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--export", $selectedImage, $exportPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\export_output.log" -RedirectStandardError "C:\_WSL2\export_error.log"
                
                $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
                
                $stdout = Get-Content "C:\_WSL2\export_output.log" -Raw
                $stderr = Get-Content "C:\_WSL2\export_error.log" -Raw
                
                $outputTextBox.AppendText("Standard Output: $stdout`r`n")
                $outputTextBox.AppendText("Standard Error: $stderr`r`n")

                if ($process.ExitCode -eq 0) {
                    $outputTextBox.AppendText("Export successful.`r`n")
                    [System.Windows.Forms.MessageBox]::Show("WSL Image $selectedImage exported successfully to $exportPath", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                } else {
                    $outputTextBox.AppendText("Export failed.`r`n")
                    [System.Windows.Forms.MessageBox]::Show("Failed to export WSL Image. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            catch {
                $outputTextBox.AppendText("Exception occurred: $_`r`n")
                [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            $outputTextBox.AppendText("Missing information. Please enter an image name and an export name.`r`n")
            [System.Windows.Forms.MessageBox]::Show("Please enter a WSL image name and an export file name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    $wslBackupForm.Controls.Add($executeButton)

    $wslBackupForm.Add_Shown({
        try {
            $wslOutput = wsl --list --quiet 2>&1 | Where-Object { $_ -ne "" }
            if ($wslOutput) {
                $sortedImages = $wslOutput | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | Sort-Object
                foreach ($image in $sortedImages) {
                    $dataGridView.Rows.Add($image)
                }
            } else {
                $outputTextBox.AppendText("No WSL images found.`r`n")
                [System.Windows.Forms.MessageBox]::Show("No WSL images found.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            $outputTextBox.AppendText("Error retrieving WSL images: $errorMessage`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error retrieving WSL images: $errorMessage", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    $wslBackupForm.ShowDialog()
}





$action5 = {
    $wslBackupForm = New-Object System.Windows.Forms.Form
    $wslBackupForm.Text = "WSL Change Password"
    $wslBackupForm.Size = New-Object System.Drawing.Size(600, 650)
    $wslBackupForm.StartPosition = "CenterScreen"
    $wslBackupForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(580, 20)
    $label.Text = "Available WSL Images (double-click to select):"
    $label.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label)

    $dataGridView = New-Object System.Windows.Forms.DataGridView
    $dataGridView.Location = New-Object System.Drawing.Point(10, 50)
    $dataGridView.Size = New-Object System.Drawing.Size(580, 150)
    $dataGridView.ColumnCount = 1
    $dataGridView.Columns[0].Name = "WSL Image Name"
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
    $dataGridView.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
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
    $wslBackupForm.Controls.Add($dataGridView)

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 210)
    $label1.Size = New-Object System.Drawing.Size(580, 20)
    $label1.Text = "Enter the name of the WSL image to change password:"
    $label1.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label1)

    $imageNameTextBox = New-Object System.Windows.Forms.TextBox
    $imageNameTextBox.Location = New-Object System.Drawing.Point(10, 240)
    $imageNameTextBox.Size = New-Object System.Drawing.Size(580, 20)
    $wslBackupForm.Controls.Add($imageNameTextBox)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 270)
    $label2.Size = New-Object System.Drawing.Size(580, 20)
    $label2.Text = "Enter the new password for user 'wsl2user':"
    $label2.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label2)

    $passwordTextBox1 = New-Object System.Windows.Forms.TextBox
    $passwordTextBox1.Location = New-Object System.Drawing.Point(10, 300)
    $passwordTextBox1.Size = New-Object System.Drawing.Size(580, 20)
    $passwordTextBox1.UseSystemPasswordChar = $true
    $wslBackupForm.Controls.Add($passwordTextBox1)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Location = New-Object System.Drawing.Point(10, 330)
    $label3.Size = New-Object System.Drawing.Size(580, 20)
    $label3.Text = "Re-enter the new password for user 'wsl2user':"
    $label3.ForeColor = [System.Drawing.Color]::White
    $wslBackupForm.Controls.Add($label3)

    $passwordTextBox2 = New-Object System.Windows.Forms.TextBox
    $passwordTextBox2.Location = New-Object System.Drawing.Point(10, 360)
    $passwordTextBox2.Size = New-Object System.Drawing.Size(580, 20)
    $passwordTextBox2.UseSystemPasswordChar = $true
    $wslBackupForm.Controls.Add($passwordTextBox2)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 420)
    $outputTextBox.Size = New-Object System.Drawing.Size(580, 180)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $wslBackupForm.Controls.Add($outputTextBox)

    $executeButton = New-Object System.Windows.Forms.Button
    $executeButton.Location = New-Object System.Drawing.Point(10, 390)
    $executeButton.Size = New-Object System.Drawing.Size(580, 30)
    $executeButton.Text = "Change Password"
    $executeButton.BackColor = [System.Drawing.Color]::White
    $executeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $executeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $executeButton.Add_Click({
        $selectedImage = $imageNameTextBox.Text.Trim()
        $newPassword1 = $passwordTextBox1.Text
        $newPassword2 = $passwordTextBox2.Text
        
        $outputTextBox.Clear()
        $outputTextBox.AppendText("Selected Image: $selectedImage`r`n")
        
        if ($selectedImage -and $newPassword1 -and $newPassword2) {
            if ($newPassword1 -ne $newPassword2) {
                [System.Windows.Forms.MessageBox]::Show("Passwords do not match. Please enter the same password twice.", "Password Mismatch", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                return
            }

            $command = "echo wsl2user:$newPassword1 | wsl -d `"$selectedImage`" -u root chpasswd"
            $outputTextBox.AppendText("Executing command to change password...`r`n")
            
            try {
                $process = Start-Process -FilePath "powershell" -ArgumentList "-Command", $command -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\passwd_output.log" -RedirectStandardError "C:\_WSL2\passwd_error.log"
                
                $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
                
                $stdout = Get-Content "C:\_WSL2\passwd_output.log" -Raw
                $stderr = Get-Content "C:\_WSL2\passwd_error.log" -Raw
                
                $outputTextBox.AppendText("Standard Output: $stdout`r`n")
                $outputTextBox.AppendText("Standard Error: $stderr`r`n")

                if ($process.ExitCode -eq 0) {
                    $outputTextBox.AppendText("Password change successful.`r`n")
                    [System.Windows.Forms.MessageBox]::Show("Password for user 'wsl2user' in WSL Image $selectedImage changed successfully.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                } else {
                    $outputTextBox.AppendText("Password change failed.`r`n")
                    [System.Windows.Forms.MessageBox]::Show("Failed to change password for WSL user. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            catch {
                $outputTextBox.AppendText("Exception occurred: $_`r`n")
                [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            $outputTextBox.AppendText("Missing information. Please enter an image name and a new password.`r`n")
            [System.Windows.Forms.MessageBox]::Show("Please enter a WSL image name and a new password.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    $wslBackupForm.Controls.Add($executeButton)

    $wslBackupForm.Add_Shown({
        try {
            $wslOutput = wsl --list --quiet 2>&1
            $sortedImages = $wslOutput -split "`n" | Where-Object { $_.Trim() -ne "" } | Sort-Object
            foreach ($image in $sortedImages) {
                $dataGridView.Rows.Add($image.Trim())
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            $outputTextBox.AppendText("Error retrieving WSL images: $errorMessage`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error retrieving WSL images: $errorMessage", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    $wslBackupForm.ShowDialog()
}





$action6 = {
    $wslRemoveForm = New-Object System.Windows.Forms.Form
    $wslRemoveForm.Text = "WSL Image Removal"
    $wslRemoveForm.Size = New-Object System.Drawing.Size(600, 600)
    $wslRemoveForm.StartPosition = "CenterScreen"
    $wslRemoveForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(580, 20)
    $label.Text = "Available WSL Images (double-click to select):"
    $label.ForeColor = [System.Drawing.Color]::White
    $wslRemoveForm.Controls.Add($label)

    $dataGridView = New-Object System.Windows.Forms.DataGridView
    $dataGridView.Location = New-Object System.Drawing.Point(10, 50)
    $dataGridView.Size = New-Object System.Drawing.Size(580, 150)
    $dataGridView.ColumnCount = 1
    $dataGridView.Columns[0].Name = "WSL Image Name"
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
    $dataGridView.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
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
    $label1.Size = New-Object System.Drawing.Size(580, 20)
    $label1.Text = "Enter the name of the WSL image to remove:"
    $label1.ForeColor = [System.Drawing.Color]::White
    $wslRemoveForm.Controls.Add($label1)

    $imageNameTextBox = New-Object System.Windows.Forms.TextBox
    $imageNameTextBox.Location = New-Object System.Drawing.Point(10, 240)
    $imageNameTextBox.Size = New-Object System.Drawing.Size(580, 20)
    $wslRemoveForm.Controls.Add($imageNameTextBox)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 300)
    $outputTextBox.Size = New-Object System.Drawing.Size(580, 240)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $wslRemoveForm.Controls.Add($outputTextBox)

    $removeButton = New-Object System.Windows.Forms.Button
    $removeButton.Location = New-Object System.Drawing.Point(10, 270)
    $removeButton.Size = New-Object System.Drawing.Size(580, 30)
    $removeButton.Text = "Remove WSL Image"
    $removeButton.BackColor = [System.Drawing.Color]::White
    $removeButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $removeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $removeButton.Add_Click({
        $selectedImage = $imageNameTextBox.Text.Trim()
        
        if ($selectedImage) {
            $confirmForm = New-Object System.Windows.Forms.Form
            $confirmForm.Text = "Confirm WSL Image Removal"
            $confirmForm.Size = New-Object System.Drawing.Size(400, 200)
            $confirmForm.StartPosition = "CenterScreen"
            $confirmForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

            $warningLabel = New-Object System.Windows.Forms.Label
            $warningLabel.Location = New-Object System.Drawing.Point(10, 20)
            $warningLabel.Size = New-Object System.Drawing.Size(380, 40)
            $warningLabel.Text = "WARNING: There is no recovery from removal. To proceed, type 'DELETE' in the box below:"
            $warningLabel.ForeColor = [System.Drawing.Color]::White
            $confirmForm.Controls.Add($warningLabel)

            $confirmTextBox = New-Object System.Windows.Forms.TextBox
            $confirmTextBox.Location = New-Object System.Drawing.Point(10, 70)
            $confirmTextBox.Size = New-Object System.Drawing.Size(380, 20)
            $confirmForm.Controls.Add($confirmTextBox)

            $confirmButton = New-Object System.Windows.Forms.Button
            $confirmButton.Location = New-Object System.Drawing.Point(10, 100)
            $confirmButton.Size = New-Object System.Drawing.Size(380, 30)
            $confirmButton.Text = "Confirm Removal"
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
                $outputTextBox.AppendText("Removing WSL Image: $selectedImage`r`n")
                
                try {
                    $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--unregister", $selectedImage -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\remove_output.log" -RedirectStandardError "C:\_WSL2\remove_error.log"
                    
                    $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
                    
                    $stdout = Get-Content "C:\_WSL2\remove_output.log" -Raw
                    $stderr = Get-Content "C:\_WSL2\remove_error.log" -Raw
                    
                    $outputTextBox.AppendText("Standard Output: $stdout`r`n")
                    $outputTextBox.AppendText("Standard Error: $stderr`r`n")

                    if ($process.ExitCode -eq 0) {
                        $outputTextBox.AppendText("WSL Image removal successful.`r`n")
                        [System.Windows.Forms.MessageBox]::Show("WSL Image $selectedImage removed successfully.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                        # Refresh the DataGridView
                        $dataGridView.Rows.Clear()
                        $wslOutput = wsl --list --quiet 2>&1
                        $sortedImages = $wslOutput -split "`n" | Where-Object { $_.Trim() -ne "" } | Sort-Object
                        foreach ($image in $sortedImages) {
                            $dataGridView.Rows.Add($image.Trim())
                        }
                    } else {
                        $outputTextBox.AppendText("WSL Image removal failed.`r`n")
                        [System.Windows.Forms.MessageBox]::Show("Failed to remove WSL Image. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                }
                catch {
                    $outputTextBox.AppendText("Exception occurred: $_`r`n")
                    [System.Windows.Forms.MessageBox]::Show("Error executing command: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
        } else {
            $outputTextBox.AppendText("Missing information. Please enter an image name.`r`n")
            [System.Windows.Forms.MessageBox]::Show("Please enter a WSL image name.", "Missing Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    $wslRemoveForm.Controls.Add($removeButton)

    $wslRemoveForm.Add_Shown({
        try {
            $wslOutput = wsl --list --quiet 2>&1
            $sortedImages = $wslOutput -split "`n" | Where-Object { $_.Trim() -ne "" } | Sort-Object
            foreach ($image in $sortedImages) {
                $dataGridView.Rows.Add($image.Trim())
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            $outputTextBox.AppendText("Error retrieving WSL images: $errorMessage`r`n")
            [System.Windows.Forms.MessageBox]::Show("Error retrieving WSL images: $errorMessage", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    $wslRemoveForm.ShowDialog()
}


$action7 = {
    $url = "https://wenix.dx.dev.td.com"
    
    try {
        Start-Process $url
        [System.Windows.Forms.MessageBox]::Show("Opening $url in your default browser.", "Website Opened", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $errorMessage = $_.Exception.Message
        [System.Windows.Forms.MessageBox]::Show("Error opening the website: $errorMessage", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing



function Set-Watermark {
    param (
        [System.Windows.Forms.TextBox]$TextBox,
        [string]$Watermark
    )
    $TextBox.ForeColor = [System.Drawing.Color]::Gray
    $TextBox.Text = $Watermark
    $TextBox.GotFocus.Add({
        if ($TextBox.Text -eq $Watermark) {
            $TextBox.Text = ""
            $TextBox.ForeColor = [System.Drawing.Color]::Black
        }
    })
    $TextBox.LostFocus.Add({
        if ($TextBox.Text -eq "") {
            $TextBox.ForeColor = [System.Drawing.Color]::Gray
            $TextBox.Text = $Watermark
        }
    })
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

$action8 = {
    $wslInstallForm = New-Object System.Windows.Forms.Form
    $wslInstallForm.Text = "WSL Image Installation"
    $wslInstallForm.Size = New-Object System.Drawing.Size(600, 500)
    $wslInstallForm.StartPosition = "CenterScreen"
    $wslInstallForm.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)

    $label1 = New-Object System.Windows.Forms.Label
    $label1.Location = New-Object System.Drawing.Point(10, 20)
    $label1.Size = New-Object System.Drawing.Size(580, 20)
    $label1.Text = "Select the .tar file for WSL image installation:"
    $label1.ForeColor = [System.Drawing.Color]::White
    $wslInstallForm.Controls.Add($label1)

    $tarFileTextBox = New-Object System.Windows.Forms.TextBox
    $tarFileTextBox.Location = New-Object System.Drawing.Point(10, 50)
    $tarFileTextBox.Size = New-Object System.Drawing.Size(460, 20)
    $tarFileTextBox.ReadOnly = $true
    $wslInstallForm.Controls.Add($tarFileTextBox)

    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Location = New-Object System.Drawing.Point(480, 48)
    $browseButton.Size = New-Object System.Drawing.Size(100, 25)
    $browseButton.Text = "Browse"
    $browseButton.BackColor = [System.Drawing.Color]::White
    $browseButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $browseButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $browseButton.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "TAR files (*.tar)|*.tar"
        $openFileDialog.Title = "Select WSL Image TAR File"
        if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $tarFileTextBox.Text = $openFileDialog.FileName
        }
    })
    $wslInstallForm.Controls.Add($browseButton)

    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10, 90)
    $label2.Size = New-Object System.Drawing.Size(580, 20)
    $label2.Text = "Enter the desired WSL image name:"
    $label2.ForeColor = [System.Drawing.Color]::White
    $wslInstallForm.Controls.Add($label2)

    $imageNameTextBox = New-Object System.Windows.Forms.TextBox
    $imageNameTextBox.Location = New-Object System.Drawing.Point(10, 120)
    $imageNameTextBox.Size = New-Object System.Drawing.Size(580, 20)
    $wslInstallForm.Controls.Add($imageNameTextBox)

    $label3 = New-Object System.Windows.Forms.Label
    $label3.Location = New-Object System.Drawing.Point(10, 160)
    $label3.Size = New-Object System.Drawing.Size(580, 20)
    $label3.Text = "Select the import location (leave blank for default):"
    $label3.ForeColor = [System.Drawing.Color]::White
    $wslInstallForm.Controls.Add($label3)

    $importLocationTextBox = New-Object System.Windows.Forms.TextBox
    $importLocationTextBox.Location = New-Object System.Drawing.Point(10, 190)
    $importLocationTextBox.Size = New-Object System.Drawing.Size(460, 20)
    $wslInstallForm.Controls.Add($importLocationTextBox)

    Set-Watermark -TextBox $importLocationTextBox -Watermark "Leave blank for default (C:\_WSL2\<image_name>)"

    $browseLocationButton = New-Object System.Windows.Forms.Button
    $browseLocationButton.Location = New-Object System.Drawing.Point(480, 188)
    $browseLocationButton.Size = New-Object System.Drawing.Size(100, 25)
    $browseLocationButton.Text = "Browse"
    $browseLocationButton.BackColor = [System.Drawing.Color]::White
    $browseLocationButton.ForeColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $browseLocationButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $browseLocationButton.Add_Click({
        $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowserDialog.Description = "Select WSL Image Import Location"
        if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $importLocationTextBox.ForeColor = [System.Drawing.Color]::Black
            $importLocationTextBox.Text = $folderBrowserDialog.SelectedPath
        }
    })
    $wslInstallForm.Controls.Add($browseLocationButton)

    $outputTextBox = New-Object System.Windows.Forms.TextBox
    $outputTextBox.Location = New-Object System.Drawing.Point(10, 230)
    $outputTextBox.Size = New-Object System.Drawing.Size(580, 180)
    $outputTextBox.Multiline = $true
    $outputTextBox.ScrollBars = "Vertical"
    $outputTextBox.ReadOnly = $true
    $outputTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $outputTextBox.ForeColor = [System.Drawing.Color]::White
    $outputTextBox.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 109)
    $wslInstallForm.Controls.Add($outputTextBox)

    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Location = New-Object System.Drawing.Point(10, 420)
    $installButton.Size = New-Object System.Drawing.Size(580, 30)
    $installButton.Text = "Install WSL Image"
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

        if ($importLocation -eq "" -or $importLocation -eq "Leave blank for default (C:\_WSL2\<image_name>)") {
            $importLocation = "C:\_WSL2\$imageName"
        }
        
        $outputTextBox.Clear()
        $outputTextBox.AppendText("Installing WSL Image:`r`n")
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
            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "--import", $imageName, $importLocation, $tarFile, "--version", "2" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "C:\_WSL2\install_output.log" -RedirectStandardError "C:\_WSL2\install_error.log"
            
            $outputTextBox.AppendText("Process Exit Code: $($process.ExitCode)`r`n")
            
            $stdout = Get-Content "C:\_WSL2\install_output.log" -Raw
            $stderr = Get-Content "C:\_WSL2\install_error.log" -Raw
            
            $outputTextBox.AppendText("Standard Output: $stdout`r`n")
            $outputTextBox.AppendText("Standard Error: $stderr`r`n")

            if ($process.ExitCode -eq 0) {
                $outputTextBox.AppendText("WSL Image installation successful.`r`n")
                [System.Windows.Forms.MessageBox]::Show("WSL Image $imageName installed successfully as WSL 2.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                $outputTextBox.AppendText("WSL Image installation failed.`r`n")
                [System.Windows.Forms.MessageBox]::Show("Failed to install WSL Image. Exit code: $($process.ExitCode)`r`nError: $stderr", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
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
