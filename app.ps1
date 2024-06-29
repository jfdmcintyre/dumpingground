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
