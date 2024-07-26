function Get-WSLImageDetails {
    $details = @{}
    $lxssPath = "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
    
    # Get list of all distributions, including the default one
    $allDistros = wsl --list --verbose | Select-Object -Skip 1 | ForEach-Object {
        if ($_ -match '^\*?\s*(\S+.*)') {
            $matches[1].Trim()
        }
    }

    # Determine which distributions are running
    $runningDistros = $allDistros | Where-Object { $_ -match '^\*' } | ForEach-Object {
        $_ -replace '^\*\s*', '' -replace '\s+\(Default\)$', ''
    }

    if (Test-Path $lxssPath) {
        Get-ChildItem -Path $lxssPath | ForEach-Object {
            $distroName = $_.GetValue("DistributionName")
            $basePath = $_.GetValue("BasePath")
            if ($distroName -and $basePath) {
                try {
                    # Use the provided script to get the size
                    $distroDir = Switch ($PSVersionTable.PSEdition) {
                        "Core" {
                            $basePath -replace '^\\\\\?\\',''
                        }
                        "Desktop" {
                            if ($basePath.StartsWith('\\?\')) {
                                $basePath
                            } else {
                                '\\?\' + $basePath
                            }
                        }
                    }
                    if (Test-Path $distroDir) {
                        $distroSize = "{0:N0} MB" -f ((Get-ChildItem -Recurse -LiteralPath "$distroDir" | Measure-Object -Property Length -sum).sum / 1MB)
                    } else {
                        $distroSize = "Directory not found"
                    }
                } catch {
                    $distroSize = "Error: $($_.Exception.Message)"
                }
                $status = if ($runningDistros -contains $distroName) { "Running" } else { "Stopped" }
                $displayName = if ($allDistros -contains "$distroName (Default)") { "$distroName (Default)" } else { $distroName }
                $details[$displayName] = @{
                    Size = $distroSize
                    Location = New-LocationPath $basePath
                    Status = $status
                }
            }
        }
    }
    return $details
}

function New-LocationPath {
    param([string]$path)
    return $path -replace '^\\\\\?\\', ''
}