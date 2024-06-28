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

