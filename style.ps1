Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll", CharSet=CharSet.Auto)]
        public static extern int SendMessage(IntPtr hWnd, int wMsg, IntPtr wParam, IntPtr lParam);
        [DllImport("user32.dll", CharSet=CharSet.Auto)]
        public static extern bool LockWindowUpdate(IntPtr hWnd);
    }
"@

function Add-FormattedText {
    param (
        [System.Windows.Forms.RichTextBox]$RichTextBox,
        [string]$Text,
        [System.Drawing.Font]$Font = $RichTextBox.Font,
        [System.Drawing.Color]$Color = [System.Drawing.Color]::Black,
        [bool]$Bold = $false,
        [bool]$Italic = $false,
        [bool]$Underline = $false
    )

    # Lock the window to prevent redraw during update
    [Win32]::LockWindowUpdate($RichTextBox.Handle)

    # Temporarily disable read-only to allow adding text
    $wasReadOnly = $RichTextBox.ReadOnly
    $RichTextBox.ReadOnly = $false

    # Append the new text
    $startIndex = $RichTextBox.TextLength
    $RichTextBox.AppendText($Text + "`r`n")
    $endIndex = $RichTextBox.TextLength

    # Apply formatting
    $RichTextBox.Select($startIndex, $endIndex - $startIndex)
    $style = [System.Drawing.FontStyle]::Regular
    if ($Bold) { $style = $style -bor [System.Drawing.FontStyle]::Bold }
    if ($Italic) { $style = $style -bor [System.Drawing.FontStyle]::Italic }
    if ($Underline) { $style = $style -bor [System.Drawing.FontStyle]::Underline }

    $RichTextBox.SelectionFont = New-Object System.Drawing.Font($Font.FontFamily, $Font.Size, $style)
    $RichTextBox.SelectionColor = $Color

    # Deselect all text
    $RichTextBox.DeselectAll()

    # Set the caret to the end and scroll to it
    $RichTextBox.SelectionStart = $RichTextBox.Text.Length
    $RichTextBox.ScrollToCaret()

    # Unlock the window update to allow redraw
    [Win32]::LockWindowUpdate([IntPtr]::Zero)

    # Restore read-only state
    $RichTextBox.ReadOnly = $wasReadOnly

    # Force the RichTextBox to refresh after the scroll
    $RichTextBox.Refresh()
}
