class CustomMessageBox {
    [System.Windows.Forms.Form]$form
    [System.Windows.Forms.RichTextBox]$richTextBox
    [System.Windows.Forms.Button]$okButton

    CustomMessageBox([string]$title, [string]$message) {
        $this.form = New-Object System.Windows.Forms.Form
        $this.form.Text = $title
        $this.form.Size = New-Object System.Drawing.Size(400, 200)
        $this.form.StartPosition = "CenterScreen"
        $this.form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        $this.form.MaximizeBox = $false
        $this.form.MinimizeBox = $false
        $this.form.ShowInTaskbar = $false

        $this.richTextBox = New-Object System.Windows.Forms.RichTextBox
        $this.richTextBox.Location = New-Object System.Drawing.Point(10, 10)
        $this.richTextBox.Size = New-Object System.Drawing.Size(360, 100)
        $this.richTextBox.ReadOnly = $true
        $this.richTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $this.richTextBox.BackColor = $this.form.BackColor
        $this.richTextBox.Text = $message
        $this.form.Controls.Add($this.richTextBox)

        $this.okButton = New-Object System.Windows.Forms.Button
        $this.okButton.Text = "OK"
        $this.okButton.Location = New-Object System.Drawing.Point(150, 120)
        $this.okButton.Size = New-Object System.Drawing.Size(100, 30)
        $this.okButton.Add_Click({ $this.form.DialogResult = [System.Windows.Forms.DialogResult]::OK; $this.form.Close() })
        $this.form.Controls.Add($this.okButton)
    }

    [System.Windows.Forms.DialogResult] ShowDialog() {
        return $this.form.ShowDialog()
    }

    [void] AddFormattedText([string]$text, [bool]$bold = $false, [bool]$underline = $false) {
        $startIndex = $this.richTextBox.TextLength
        $this.richTextBox.AppendText($text)
        $endIndex = $this.richTextBox.TextLength

        $this.richTextBox.Select($startIndex, $endIndex - $startIndex)
        
        $style = [System.Drawing.FontStyle]::Regular
        if ($bold) { $style = $style -bor [System.Drawing.FontStyle]::Bold }
        if ($underline) { $style = $style -bor [System.Drawing.FontStyle]::Underline }
        
        $this.richTextBox.SelectionFont = New-Object System.Drawing.Font($this.richTextBox.Font, $style)
        $this.richTextBox.DeselectAll()
    }
}

# Create and show the custom message box
$messageBox = [CustomMessageBox]::new("Custom Message Box", "")
$messageBox.AddFormattedText("This is a ", $false, $false)
$messageBox.AddFormattedText("bold", $true, $false)
$messageBox.AddFormattedText(" and ", $false, $false)
$messageBox.AddFormattedText("underlined", $false, $true)
$messageBox.AddFormattedText(" message.", $false, $false)
$messageBox.ShowDialog()
