# Add a progress indicator Label
$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Size = New-Object System.Drawing.Size(30, 30)
$progressLabel.Location = New-Object System.Drawing.Point(530, 440)
$progressLabel.Font = New-Object System.Drawing.Font("Consolas", 16)
$progressLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$progressLabel.ForeColor = [System.Drawing.Color]::White
$progressLabel.Visible = $false
$wslImportForm.Controls.Add($progressLabel)

# Create a timer for updating the progress indicator
$progressTimer = New-Object System.Windows.Forms.Timer
$progressTimer.Interval = 100
$progressIndex = 0
$progressChars = @('|', '/', '-', '\')
$progressTimer.Add_Tick({
    $progressLabel.Text = $progressChars[$progressIndex]
    $progressIndex = ($progressIndex + 1) % 4
})