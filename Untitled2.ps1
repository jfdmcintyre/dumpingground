Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WSL Export Tool"
$form.Size = New-Object System.Drawing.Size(600, 400)

# Create a RichTextBox to display output
$rTextBox = New-Object System.Windows.Forms.RichTextBox
$rTextBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$form.Controls.Add($rTextBox)

# Create a button to trigger the export
$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Text = "Export WSL Image"
$exportButton.Dock = [System.Windows.Forms.DockStyle]::Top
$form.Controls.Add($exportButton)

# Define the export function
$exportFunction = {
    param($imageName, $tarGzFileName)

    # Ensure the tar.gz file ends with the correct extension
    if (-Not ($tarGzFileName.EndsWith(".tar.gz"))) {
        $tarGzFileName += ".tar.gz"
    }

    # Check if 7-Zip is installed and the path is correct
    $sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
    if (-Not (Test-Path $sevenZipPath)) {
        $rTextBox.AppendText("7-Zip not found at $sevenZipPath. Please check the installation path.`n")
        return
    }

    # Create the CMD command string
    $cmdCommand = "wsl --export $imageName - | `"$sevenZipPath`" a -tgzip `"$tarGzFileName`" -si"

    # Start the process and capture output
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmdCommand" -NoNewWindow -RedirectStandardOutput "output.txt" -RedirectStandardError "error.txt" -PassThru -Wait

    # Read the output in real-time
    $reader = [System.IO.StreamReader]::new("output.txt")
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 100
    $timer.Add_Tick({
        if (!$reader.EndOfStream) {
            $line = $reader.ReadLine()
            $rTextBox.AppendText("$line`n")
            $rTextBox.ScrollToCaret()  # Scroll to the bottom
        } else {
            $timer.Stop()
            $reader.Close()
            if ($process.ExitCode -eq 0) {
                $rTextBox.AppendText("Successfully exported and compressed the WSL image '$imageName' to '$tarGzFileName'.`n")
            } else {
                $rTextBox.AppendText("Failed to export and compress the WSL image. Exit code: $($process.ExitCode)`n")
            }
        }
    })

    # Start the timer to read output
    $timer.Start()
}

# Add the click event for the export button
$exportButton.Add_Click({
    $imageName = [System.Windows.Forms.MessageBox]::Show("Enter the name of the WSL distribution to export:", "Input", [System.Windows.Forms.MessageBoxButtons]::OKCancel)
    $tarGzFileName = [System.Windows.Forms.MessageBox]::Show("Enter the full path and name for the output tar.gz file (e.g., C:\Backups\MyBackup.tar.gz):", "Input", [System.Windows.Forms.MessageBoxButtons]::OKCancel)

    if ($imageName -ne [System.Windows.Forms.DialogResult]::Cancel -and $tarGzFileName -ne [System.Windows.Forms.DialogResult]::Cancel) {
        $exportFunction.Invoke($imageName, $tarGzFileName)
    }
})

# Show the form
[void]$form.ShowDialog()
