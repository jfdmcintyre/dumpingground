# Import the required namespaces
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to get WSL images details
function Get-WSLImageDetails {
    $details = @{}
    $originalEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $lxssPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"

    # Get list of all distributions from "wsl -l"
    $allDistros = wsl --list | Select-Object -Skip 1 | ForEach-Object { $_.Trim() }

    # Identify the default distribution by checking for "(Default)" in the line
    $defaultDistro = $allDistros | Where-Object { $_ -match '\(Default\)$' }

    # Remove the "(Default)" suffix to get the actual distribution name
    $defaultDistro = $defaultDistro -replace '\s+\(Default\)$', ''

    # Get list of all running distributions
    $runningImages = wsl -l --running | Select-Object -Skip 1 | ForEach-Object {
        $_.Trim() -replace ' \(Default\)$', ''
    }

    [Console]::OutputEncoding = $originalEncoding

    if (Test-Path $lxssPath) {
        Get-ChildItem -Path $lxssPath | ForEach-Object {
            $distroName = $_.GetValue("DistributionName")
            $basePath = $_.GetValue("BasePath")

            if ($distroName -and $basePath) {
                try {
                    # Get the size of the distribution
                    $distroDir = Switch ($PSVersionTable.PSEdition) {
                        "Core" { $basePath -replace '^\\\\\?\\','' }
                        "Desktop" {
                            if ($basePath.StartsWith('\\?\')) { $basePath } else { '\\?\' + $basePath }
                        }
                    }

                    if (Test-Path $distroDir) {
                        $distroSize = "{0:N2} GB" -f ((Get-ChildItem -Recurse -LiteralPath "$distroDir" | Measure-Object -Property Length -sum).sum / 1GB)
                    } else {
                        $distroSize = "Directory not found"
                    }
                } catch {
                    $distroSize = "Error: $($_.Exception.Message)"
                }

                $status = if ($runningImages -contains $distroName) { "Running" } else { "Stopped" }
                $isDefault = $distroName -eq $defaultDistro
                $displayName = if ($isDefault) { "* $distroName" } else { $distroName }

                $details[$displayName] = @{
                    Size      = $distroSize
                    Location  = $basePath
                    Status    = $status
                    IsDefault = $isDefault
                }
            }
        }
    }

    [Console]::OutputEncoding = $originalEncoding
    return $details
}

# Create the form
$form = New-Object Windows.Forms.Form
$form.Text = "WSL Distributions"
$form.Size = New-Object Drawing.Size(600, 400)

# Create the ListView
$listView = New-Object Windows.Forms.ListView
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Dock = [System.Windows.Forms.DockStyle]::Fill

# Create columns
$listView.Columns.Add("Name", 150)
$listView.Columns.Add("Size", 100)
$listView.Columns.Add("Location", 200)
$listView.Columns.Add("Status", 80)
$listView.Columns.Add("Default", 60)

# Get the WSL image details
$wslDetails = Get-WSLImageDetails

# Add items to the ListView
foreach ($key in $wslDetails.Keys) {
    $details = $wslDetails[$key]
    $item = New-Object Windows.Forms.ListViewItem $key
    $item.SubItems.Add($details.Size)
    $item.SubItems.Add($details.Location)
    $item.SubItems.Add($details.Status)

    # Check if the distribution is the default
    $defaultText = if ($details.IsDefault) { "*" } else { "" }

    # Add the default indicator to the sub-items
    $item.SubItems.Add($defaultText)

    # Add the item to the ListView
    $listView.Items.Add($item)
}

# Add the ListView to the form
$form.Controls.Add($listView)

# Show the form
[void]$form.ShowDialog()
