Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Auto-Refresh Image Form"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Create a PictureBox to hold the image
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
$pictureBox.Size = New-Object System.Drawing.Size(200, 200)
$pictureBox.Location = New-Object System.Drawing.Point(100, 50)
$form.Controls.Add($pictureBox)

# Array of images to toggle between for demonstration purposes
$images = @("C:\Users\shlum\dumpingground\messenger.png", "C:\Users\shlum\dumpingground\square.png")
$currentImageIndex = 0

# Timer to refresh the image every 5 seconds
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000  # 5 seconds

# Timer tick event to update the image
$timer.Add_Tick({
    # Toggle between the images
    $currentImageIndex = ($currentImageIndex + 1) % $images.Length
    $newImagePath = $images[$currentImageIndex]

    # Load the new image and set it to the PictureBox
    # Dispose of the current image if it exists
    if ($pictureBox.Image -ne $null) {
        $pictureBox.Image.Dispose()
    }

    # Create a new instance of the image
    $pictureBox.Image = [System.Drawing.Image]::FromFile($newImagePath)
})

# Start the timer
$timer.Start()

# Show the form
[void]$form.ShowDialog()
