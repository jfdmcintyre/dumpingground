Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Add the Win32 API for Size on Disk (only if not already loaded)
if (-not ([System.Management.Automation.PSTypeName]'DiskSize').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public class DiskSize {
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern uint GetCompressedFileSizeW(string lpFileName, out uint lpFileSizeHigh);
    
    public static long GetSizeOnDisk(string filename) {
        uint high;
        uint low = GetCompressedFileSizeW(filename, out high);
        if (low == 0xFFFFFFFF) {
            int error = Marshal.GetLastWin32Error();
            if (error != 0) return 0;
        }
        return ((long)high << 32) | low;
    }
}
"@
}

# Function to format bytes
function Format-Bytes {
    param([long]$Bytes)
    
    if ($Bytes -eq 0) { return "0 B" }
    
    $sizes = "B", "KB", "MB", "GB", "TB"
    $order = [Math]::Floor([Math]::Log($Bytes, 1024))
    $num = [Math]::Round($Bytes / [Math]::Pow(1024, $order), 2)
    
    return "{0:N2} {1}" -f $num, $sizes[$order]
}

# Function to get WSL running status
function Get-WSLStatus {
    $runningDistros = @{}
    
    try {
        $wslList = wsl --list --verbose 2>&1 | Out-String
        $lines = $wslList -split "`r?`n"
        
        foreach ($line in $lines) {
            # Skip header and empty lines
            if ($line -match '^\s*NAME\s+STATE' -or $line -match '^\s*$') {
                continue
            }
            
            # Parse the line - format is: * NAME    STATE    VERSION
            if ($line -match '^\s*[\*\s]\s*(\S+)\s+(Running|Stopped)') {
                $distroName = $matches[1]
                $state = $matches[2]
                $runningDistros[$distroName] = $state
            }
        }
    } catch {
        # If wsl command fails, return empty
    }
    
    return $runningDistros
}

# Function to get WSL distro sizes from registry
function Get-WSLDistroSizes {
    $distros = @()
    
    $wslRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
    
    if (-not (Test-Path $wslRegPath)) {
        return $distros
    }
    
    # Get default distro GUID
    $defaultGuid = (Get-ItemProperty -Path $wslRegPath -Name DefaultDistribution -ErrorAction SilentlyContinue).DefaultDistribution
    
    # Get running status for all distros
    $statusMap = Get-WSLStatus
    
    $distroGuids = Get-ChildItem -Path $wslRegPath | Where-Object { $_.PSChildName -match '^{[A-F0-9-]+}$' }
    
    foreach ($guidKey in $distroGuids) {
        try {
            $distroName = (Get-ItemProperty -Path $guidKey.PSPath -Name DistributionName -ErrorAction SilentlyContinue).DistributionName
            $basePath = (Get-ItemProperty -Path $guidKey.PSPath -Name BasePath -ErrorAction SilentlyContinue).BasePath
            $isDefault = ($guidKey.PSChildName -eq $defaultGuid)
            
            # Get status
            $status = "Stopped"
            if ($distroName -and $statusMap.ContainsKey($distroName)) {
                $status = $statusMap[$distroName]
            }
            
            if ($basePath) {
                $vhdxPath = Join-Path $basePath "ext4.vhdx"
                
                if (Test-Path $vhdxPath) {
                    $vhdxFile = Get-Item $vhdxPath
                    $logicalSize = $vhdxFile.Length
                    $physicalSize = [DiskSize]::GetSizeOnDisk($vhdxFile.FullName)
                    
                    $distros += [PSCustomObject]@{
                        Name         = if ($distroName) { $distroName } else { "Unknown" }
                        IsDefault    = $isDefault
                        Status       = $status
                        LogicalSize  = $logicalSize
                        PhysicalSize = $physicalSize
                        Location     = $vhdxFile.FullName
                    }
                }
            }
        } catch {
            # Skip errors
        }
    }
    
    return $distros
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WSL Distro Sizes"
$form.Size = New-Object System.Drawing.Size(1000, 300)
$form.StartPosition = "CenterScreen"

# Create ListView
$listView = New-Object System.Windows.Forms.ListView
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Location = New-Object System.Drawing.Point(10, 10)
$listView.Size = New-Object System.Drawing.Size(960, 240)
$listView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor 
                   [System.Windows.Forms.AnchorStyles]::Bottom -bor
                   [System.Windows.Forms.AnchorStyles]::Left -bor
                   [System.Windows.Forms.AnchorStyles]::Right

# Set font to support Unicode
$listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Add columns
[void]$listView.Columns.Add("Image Name", 150)
[void]$listView.Columns.Add("Status", 80)
[void]$listView.Columns.Add("Default", 70)
[void]$listView.Columns.Add("Size / Size on Disk", 180)
[void]$listView.Columns.Add("Location", 450)

# Get distros and populate list
$distros = Get-WSLDistroSizes

foreach ($distro in $distros) {
    $logicalFormatted = Format-Bytes $distro.LogicalSize
    $physicalFormatted = Format-Bytes $distro.PhysicalSize
    $combinedSize = "{0} / {1}" -f $logicalFormatted, $physicalFormatted
    
    $item = New-Object System.Windows.Forms.ListViewItem($distro.Name)
    [void]$item.SubItems.Add($distro.Status)
    [void]$item.SubItems.Add($(if ($distro.IsDefault) { "★" } else { "" }))
    [void]$item.SubItems.Add($combinedSize)
    [void]$item.SubItems.Add($distro.Location)
    
    # Color code based on status
    if ($distro.Status -eq "Running") {
        $item.ForeColor = [System.Drawing.Color]::Green
    } else {
        $item.ForeColor = [System.Drawing.Color]::Gray
    }
    
    [void]$listView.Items.Add($item)
}

# Add controls to form
$form.Controls.Add($listView)

# Show form
[void]$form.ShowDialog()
```

**Changes:**
1. Added new function `Get-WSLStatus` that runs `wsl --list --verbose` and parses the output
2. Added **Status** column showing "Running" or "Stopped"
3. Color codes entries:
   - **Green** for running distros
   - **Gray** for stopped distros
4. Increased form width to accommodate the new column

The status is determined by running `wsl --list --verbose` which outputs something like:
```
  NAME      STATE      VERSION
* Ubuntu    Running    2
  Debian    Stopped    2
