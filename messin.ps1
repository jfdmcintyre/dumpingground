$global:RefreshAction9ListView = {
    if ($listView -and $listView.InvokeRequired) {
        $listView.Invoke($global:RefreshAction9ListView)
    } else {
        # Your existing refresh logic here
        $listView.Items.Clear()
        $wslOutput = wsl --list --verbose
        $wslLines = $wslOutput -split "`n" | Select-Object -Skip 1 | Where-Object { $_.Trim() -ne "" -and $_.Trim() -notmatch "wsl-vpnkit" }
        foreach ($line in $wslLines) {
            $parts = $line -split '\s+', 3
            if ($parts.Count -ge 3) {
                $name = $parts[2].Trim()
                $status = $parts[1].Trim()
                $item = New-Object System.Windows.Forms.ListViewItem($name)
                $item.SubItems.Add($status)
                $listView.Items.Add($item)
            }
        }
    }
}



if ($global:RefreshAction9ListView) {
    & $global:RefreshAction9ListView
}


if ($wslManagerForm.InvokeRequired) {
    $wslManagerForm.Invoke($global:RefreshAction9ListView)
} else {
    & $global:RefreshAction9ListView
}