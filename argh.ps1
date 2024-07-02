Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function New-CustomButton {
    
    param (
        [Parameter(Mandatory=$true)]
        [string]$Text,
        
        [Parameter(Mandatory=$true)]
        [int]$X,
        
        [Parameter(Mandatory=$true)]
        [int]$Y,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$Action
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size(150, 50)
    $button.Text = $Text
    $button.BackColor = [System.Drawing.Color]::FromArgb(0, 150, 136)
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.Add_Click($Action)
    return $button
}

# Create the main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "WSL Management Tool"
$mainForm.Size = New-Object System.Drawing.Size(500, 400)
$mainForm.StartPosition = "CenterScreen"
$mainForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Define actions for each button
$actions = @(
    { Write-Host "Action 1 executed" },
    { Write-Host "Action 2 executed" },
    { Write-Host "Action 3 executed" },
    { Write-Host "Action 4 executed" },
    { Write-Host "Action 5 executed" },
    { Write-Host "Action 6 executed" },
    { Write-Host "Action 7 executed" },
    { Write-Host "Action 8 executed" },
    { Write-Host "Action 9 executed" }
)

# Create and add buttons to the form
for ($i = 0; $i -lt 9; $i++) {
    $row = [math]::Floor($i / 3)
    $col = $i % 3
    $x = 20 + ($col * 160)
    $y = 20 + ($row * 60)
    
    $button = New-CustomButton -Text "Action $($i+1)" -X $x -Y $y -Action $actions[$i]
    $mainForm.Controls.Add($button)
}

# Show the form
$mainForm.ShowDialog()
