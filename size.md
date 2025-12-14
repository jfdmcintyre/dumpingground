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

# Function to get WSL distro sizes from registry
function Get-WSLDistroSizes {
    $distros = @()
    
    $wslRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
    
    if (-not (Test-Path $wslRegPath)) {
        return $distros
    }
    
    # Get default distro GUID
    $defaultGuid = (Get-ItemProperty -Path $wslRegPath -Name DefaultDistribution -ErrorAction SilentlyContinue).DefaultDistribution
    
    $distroGuids = Get-ChildItem -Path $wslRegPath | Where-Object { $_.PSChildName -match '^{[A-F0-9-]+}$' }
    
    foreach ($guidKey in $distroGuids) {
        try {
            $distroName = (Get-ItemProperty -Path $guidKey.PSPath -Name DistributionName -ErrorAction SilentlyContinue).DistributionName
            $basePath = (Get-ItemProperty -Path $guidKey.PSPath -Name BasePath -ErrorAction SilentlyContinue).BasePath
            $isDefault = ($guidKey.PSChildName -eq $defaultGuid)
            
            if ($basePath) {
                $vhdxPath = Join-Path $basePath "ext4.vhdx"
                
                if (Test-Path $vhdxPath) {
                    $vhdxFile = Get-Item $vhdxPath
                    $logicalSize = $vhdxFile.Length
                    $physicalSize = [DiskSize]::GetSizeOnDisk($vhdxFile.FullName)
                    
                    $distros += [PSCustomObject]@{
                        Name         = if ($distroName) { $distroName } else { "Unknown" }
                        IsDefault    = $isDefault
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
$form.Size = New-Object System.Drawing.Size(900, 300)
$form.StartPosition = "CenterScreen"

# Create ListView
$listView = New-Object System.Windows.Forms.ListView
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Location = New-Object System.Drawing.Point(10, 10)
$listView.Size = New-Object System.Drawing.Size(860, 240)
$listView.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor 
                   [System.Windows.Forms.AnchorStyles]::Bottom -bor
                   [System.Windows.Forms.AnchorStyles]::Left -bor
                   [System.Windows.Forms.AnchorStyles]::Right

# Set font to support Unicode
$listView.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Add columns
[void]$listView.Columns.Add("Image Name", 150)
[void]$listView.Columns.Add("Default", 70)
[void]$listView.Columns.Add("Size / Size on Disk", 180)
[void]$listView.Columns.Add("Location", 430)

# Get distros and populate list
$distros = Get-WSLDistroSizes

foreach ($distro in $distros) {
    $logicalFormatted = Format-Bytes $distro.LogicalSize
    $physicalFormatted = Format-Bytes $distro.PhysicalSize
    $combinedSize = "{0} / {1}" -f $logicalFormatted, $physicalFormatted
    
    $item = New-Object System.Windows.Forms.ListViewItem($distro.Name)
    [void]$item.SubItems.Add($(if ($distro.IsDefault) { "\u2605" } else { "" }))
    [void]$item.SubItems.Add($combinedSize)
    [void]$item.SubItems.Add($distro.Location)
    
    [void]$listView.Items.Add($item)
}

# Add controls to form
$form.Controls.Add($listView)

# Show form
[void]$form.ShowDialog()
