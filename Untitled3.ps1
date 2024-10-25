# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "WSL VPN Status"
$mainForm.Size = New-Object System.Drawing.Size(300, 150)
$mainForm.StartPosition = "CenterScreen"

# Create label to display VPN status
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Size = New-Object System.Drawing.Size(250, 50)
$statusLabel.Location = New-Object System.Drawing.Point(25, 30)
$statusLabel.Font = New-Object System.Drawing.Font("Arial", 16)
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$mainForm.Controls.Add($statusLabel)

# Function to check running WSL images and update status
function Update-VPNStatus {
    $originalEncoding = [Console]::OutputEncoding
  [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
  $wslOutput = wsl --list --running
  [Console]::OutputEncoding = $originalEncoding
  $runningDistros = ($wslOutput -split "`n" )
    # Get the list of running WSL distributions
   

    # Check if 'wsl-vpnkit' is runnings
    if ($runningDistros -match "wsl-vpnkit") {
        $statusLabel.Text = "VPN ON"
    } elseif ($runningDistros.Count -gt 0) {
        $statusLabel.Text = "VPN OFF"
    } else {
        $statusLabel.Text = "No WSL Images Running"
    }
}

# Create a timer to refresh status every 5 seconds
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000 # 5000 milliseconds = 5 seconds
$timer.Add_Tick({ Update-VPNStatus })
$timer.Start()

# Initial status check
Update-VPNStatus

# Show the main form
$mainForm.Add_Shown({ $mainForm.Activate() })
[void]$mainForm.ShowDialog()
