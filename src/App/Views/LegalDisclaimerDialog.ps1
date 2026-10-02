# LegalDisclaimerDialog.ps1
# First-run acknowledgement. Must be accepted before the app is usable.

function Show-NFLegalDisclaimer {
    $win = New-Object System.Windows.Window
    $win.Title = "Nova Forge - Before You Continue"
    $win.Width = 620
    $win.Height = 640
    $win.MinWidth = 560
    $win.MinHeight = 520
    if ($Global:NF_Window -and $Global:NF_Window.IsVisible) {
        $win.Owner = $Global:NF_Window
        $win.WindowStartupLocation = 'CenterOwner'
    } else {
        $win.WindowStartupLocation = 'CenterScreen'
    }
    $win.ResizeMode = 'CanResizeWithGrip'
    $win.Background = Get-NFRes 'Brush.Bg'
    $win.FontFamily = 'Segoe UI'

    $outer = New-Object System.Windows.Controls.DockPanel
    $outer.Margin = 28

    # --- Brand header ---
    $brandRow = New-Object System.Windows.Controls.StackPanel
    $brandRow.Orientation = 'Horizontal'
    $brandRow.Margin = "0,0,0,4"
    [System.Windows.Controls.DockPanel]::SetDock($brandRow, 'Top')
    $novaTb = New-Object System.Windows.Controls.TextBlock
    $novaTb.Text = "NOVA"
    $novaTb.FontSize = 14
    $novaTb.FontWeight = 'Bold'
    $novaTb.Foreground = Get-NFRes 'Brush.TextPrimary'
    $brandRow.Children.Add($novaTb) | Out-Null
    $forgeTb = New-Object System.Windows.Controls.TextBlock
    $forgeTb.Text = "FORGE"
    $forgeTb.FontSize = 14
    $forgeTb.FontWeight = 'Bold'
    $forgeTb.Foreground = Get-NFRes 'Brush.Accent'
    $forgeTb.Margin = "4,0,0,0"
    $brandRow.Children.Add($forgeTb) | Out-Null
    $outer.Children.Add($brandRow) | Out-Null

    $header = New-Object System.Windows.Controls.TextBlock
    $header.Style = Get-NFRes 'Text.H1'
    $header.Text = "Before You Continue"
    $header.Margin = "0,4,0,4"
    [System.Windows.Controls.DockPanel]::SetDock($header, 'Top')
    $outer.Children.Add($header) | Out-Null

    $subHeader = New-Object System.Windows.Controls.TextBlock
    $subHeader.Style = Get-NFRes 'Text.Secondary'
    $subHeader.Text = "Nova Forge is a tool for organizing and customizing games you already own. Please read the following before using it."
    $subHeader.Margin = "0,0,0,16"
    [System.Windows.Controls.DockPanel]::SetDock($subHeader, 'Top')
    $outer.Children.Add($subHeader) | Out-Null

    $buttonRow = New-Object System.Windows.Controls.StackPanel
    $buttonRow.Orientation = 'Horizontal'
    $buttonRow.HorizontalAlignment = 'Right'
    $buttonRow.Margin = "0,16,0,0"
    [System.Windows.Controls.DockPanel]::SetDock($buttonRow, 'Bottom')

    $result = @{ Accepted = $false }

    $declineBtn = New-Object System.Windows.Controls.Button
    $declineBtn.Content = "Exit Nova Forge"
    $declineBtn.Style = Get-NFRes 'Btn.Secondary'
    $declineBtn.Margin = "0,0,10,0"
    $declineBtn.Add_Click({ $result.Accepted = $false; $win.Close() }.GetNewClosure()) | Out-Null
    $buttonRow.Children.Add($declineBtn) | Out-Null

    $acceptBtn = New-Object System.Windows.Controls.Button
    $acceptBtn.Content = "I Understand and Accept"
    $acceptBtn.Style = Get-NFRes 'Btn.Primary'
    $acceptBtn.Add_Click({ $result.Accepted = $true; $win.Close() }.GetNewClosure()) | Out-Null
    $buttonRow.Children.Add($acceptBtn) | Out-Null

    $outer.Children.Add($buttonRow) | Out-Null

    $scroll = New-Object System.Windows.Controls.ScrollViewer
    $scroll.VerticalScrollBarVisibility = 'Auto'

    $body = New-Object System.Windows.Controls.StackPanel

    $legalBanner = New-NFLegalBanner -Text "Nova Forge does not own, sell, license, host, provide, or distribute third-party games or copyrighted game materials, including ROMs, ISOs, disc images, extracted assets, or other proprietary content. You must supply your own legally obtained files."
    $body.Children.Add($legalBanner.Root) | Out-Null

    $sections = @(
        @{
            Heading = "What Nova Forge is"
            Body = "Nova Forge is an independent, local desktop application for organizing game configuration, modifications, tools, profiles, and other content that you manage yourself. Everything it stores lives on your PC. Nova Forge is independently developed and is not affiliated with, sponsored by, or endorsed by any third-party company, organization, or rights holder unless a separate written agreement says otherwise."
        }
        @{
            Heading = "Your game files are yours to provide"
            Body = "Nova Forge does not supply games, ROMs, ISOs, disc images, or any other copyrighted game material, and grants no license to any third-party game. By pointing Nova Forge at a game folder or importing a file, you are representing that you own it or are otherwise authorized to use it, and that you will follow the applicable game license, publisher terms, platform rules, and copyright law."
        }
        @{
            Heading = "Nova Forge is not an emulator"
            Body = "Nova Forge does not include, bundle, or distribute any emulator. Some supported games may require emulation to run on PC. Where that's the case, Nova Forge will point you toward actively maintained, legitimately supported emulator projects at the point of need -- never toward discontinued projects such as Yuzu."
        }
        @{
            Heading = "Nothing happens to your files until it's tested"
            Body = "Features that could change or damage your game or save files -- like restoring a backup, editing game settings, or installing a mod -- are only enabled once a real, tested implementation exists. Anything not implemented yet is clearly labeled in the app and will not silently pretend to work."
        }
        @{
            Heading = "Where to find this again"
            Body = "The full legal notice, including this text, is always available from Settings > Legal & Disclaimers inside Nova Forge, and in the LEGAL.md file in the Nova Forge installation folder."
        }
    )

    foreach ($s in $sections) {
        $h = New-Object System.Windows.Controls.TextBlock
        $h.Style = Get-NFRes 'Text.H2'
        $h.FontSize = 14
        $h.Text = $s.Heading
        $h.Margin = "0,14,0,4"
        $body.Children.Add($h) | Out-Null

        $b = New-Object System.Windows.Controls.TextBlock
        $b.Style = Get-NFRes 'Text.Secondary'
        $b.Text = $s.Body
        $body.Children.Add($b) | Out-Null
    }

    $scroll.Content = $body
    $outer.Children.Add($scroll) | Out-Null

    $win.Content = $outer
    $win.ShowDialog() | Out-Null

    return $result.Accepted
}
