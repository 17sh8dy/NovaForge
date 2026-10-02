# Controls.ps1
# Reusable, styled WPF control factories shared by every view (game-agnostic).
# Every factory returns a lightweight PSCustomObject with a .Root element plus
# handles to the interactive sub-controls, so views can read/wire without
# knowing the internal layout.

function Get-NFRes {
    param([Parameter(Mandatory)][string]$Key)
    return $Global:NF_Window.FindResource($Key)
}

function New-NFSectionHeader {
    param(
        [Parameter(Mandatory)][string]$Title,
        [string]$Subtitle = "",
        [switch]$NoMarginBottom
    )
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Margin = if ($NoMarginBottom) { "0" } else { "0,0,0,18" }

    $h1 = New-Object System.Windows.Controls.TextBlock
    $h1.Style = Get-NFRes 'Text.H1'
    $h1.Text = $Title
    $panel.Children.Add($h1) | Out-Null

    if ($Subtitle) {
        $sub = New-Object System.Windows.Controls.TextBlock
        $sub.Style = Get-NFRes 'Text.Secondary'
        $sub.Text = $Subtitle
        $sub.Margin = "0,4,0,0"
        $panel.Children.Add($sub) | Out-Null
    }
    return $panel
}

function New-NFCard {
    param(
        [string]$Margin = "0,0,0,16"
    )
    $border = New-Object System.Windows.Controls.Border
    $border.Style = Get-NFRes 'Panel.Card'
    $border.Margin = $Margin
    $stack = New-Object System.Windows.Controls.StackPanel
    $border.Child = $stack
    [PSCustomObject]@{ Root = $border; Body = $stack }
}

function New-NFBadge {
    param(
        [Parameter(Mandatory)][string]$Text,
        [ValidateSet('NotImplemented','Active','Warning')]
        [string]$Kind = 'NotImplemented'
    )
    $border = New-Object System.Windows.Controls.Border
    $border.Style = if ($Kind -eq 'Active') { Get-NFRes 'Badge.Active' } else { Get-NFRes 'Badge.NotImplemented' }
    $border.HorizontalAlignment = 'Left'
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.FontSize = 10
    $tb.FontWeight = 'SemiBold'
    $tb.Foreground = if ($Kind -eq 'Active') { Get-NFRes 'Brush.Accent' } else { Get-NFRes 'Brush.TextSecondary' }
    $border.Child = $tb
    return $border
}

function New-NFNotImplementedNote {
    param(
        [string]$Text = "This feature is not implemented yet. It is shown so you can see where it will live.",
        [string]$Icon = "$([char]0x2139)"
    )
    $border = New-Object System.Windows.Controls.Border
    $border.Style = Get-NFRes 'Panel.Banner.Info'
    $border.Margin = "0,0,0,16"

    $grid = New-Object System.Windows.Controls.Grid
    $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = 'Auto'
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = '*'
    $grid.ColumnDefinitions.Add($c0) | Out-Null
    $grid.ColumnDefinitions.Add($c1) | Out-Null

    $iconTb = New-Object System.Windows.Controls.TextBlock
    $iconTb.Text = $Icon
    $iconTb.FontSize = 14
    $iconTb.Foreground = Get-NFRes 'Brush.TextSecondary'
    $iconTb.Margin = "0,0,10,0"
    [System.Windows.Controls.Grid]::SetColumn($iconTb, 0)

    $textTb = New-Object System.Windows.Controls.TextBlock
    $textTb.Style = Get-NFRes 'Text.Secondary'
    $textTb.Text = $Text
    [System.Windows.Controls.Grid]::SetColumn($textTb, 1)

    $grid.Children.Add($iconTb) | Out-Null
    $grid.Children.Add($textTb) | Out-Null
    $border.Child = $grid
    return $border
}

function New-NFLegalBanner {
    param(
        [string]$Text = "Nova Forge does not own, sell, host, or distribute any third-party game files. You must provide your own legally obtained copies.",
        [switch]$WithLink
    )
    $border = New-Object System.Windows.Controls.Border
    $border.Style = Get-NFRes 'Panel.Banner.Legal'
    $border.Margin = "0,0,0,16"

    $stack = New-Object System.Windows.Controls.StackPanel

    $row = New-Object System.Windows.Controls.DockPanel
    $iconTb = New-Object System.Windows.Controls.TextBlock
    $iconTb.Text = "$([char]0x2696)"
    $iconTb.FontSize = 13
    $iconTb.Foreground = Get-NFRes 'Brush.Accent'
    $iconTb.Margin = "0,0,10,0"
    [System.Windows.Controls.DockPanel]::SetDock($iconTb, 'Left')
    $row.Children.Add($iconTb) | Out-Null

    $textTb = New-Object System.Windows.Controls.TextBlock
    $textTb.Style = Get-NFRes 'Text.Secondary'
    $textTb.Foreground = Get-NFRes 'Brush.TextPrimary'
    $textTb.Text = $Text
    $row.Children.Add($textTb) | Out-Null

    $stack.Children.Add($row) | Out-Null

    $link = $null
    if ($WithLink) {
        $link = New-Object System.Windows.Controls.Button
        $link.Content = "View full legal notice"
        $link.Style = Get-NFRes 'Btn.Ghost'
        $link.HorizontalAlignment = 'Left'
        $link.Margin = "24,6,0,0"
        $link.Padding = "0"
        $link.Foreground = Get-NFRes 'Brush.Accent'
        $stack.Children.Add($link) | Out-Null
    }

    $border.Child = $stack
    [PSCustomObject]@{ Root = $border; LinkButton = $link }
}

function New-NFToggleRow {
    param(
        [Parameter(Mandatory)][string]$Label,
        [string]$Description = "",
        [bool]$IsChecked = $false,
        [bool]$Enabled = $true
    )
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "0,0,0,14"
    $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = '*'
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = 'Auto'
    $grid.ColumnDefinitions.Add($c0) | Out-Null
    $grid.ColumnDefinitions.Add($c1) | Out-Null

    $textStack = New-Object System.Windows.Controls.StackPanel
    [System.Windows.Controls.Grid]::SetColumn($textStack, 0)
    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Style = Get-NFRes 'Text.Body'
    $lbl.Text = $Label
    $textStack.Children.Add($lbl) | Out-Null
    if ($Description) {
        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Style = Get-NFRes 'Text.Muted'
        $desc.Text = $Description
        $desc.Margin = "0,2,10,0"
        $textStack.Children.Add($desc) | Out-Null
    }

    $toggle = New-Object System.Windows.Controls.CheckBox
    $toggle.Style = Get-NFRes 'ToggleSwitch'
    $toggle.IsChecked = $IsChecked
    $toggle.IsEnabled = $Enabled
    $toggle.VerticalAlignment = 'Center'
    [System.Windows.Controls.Grid]::SetColumn($toggle, 1)

    $grid.Children.Add($textStack) | Out-Null
    $grid.Children.Add($toggle) | Out-Null

    [PSCustomObject]@{ Root = $grid; Toggle = $toggle }
}

function New-NFPathPickerRow {
    param(
        [Parameter(Mandatory)][string]$Label,
        [string]$Description = "",
        [string]$Value = "",
        [string]$Placeholder = "Not set",
        [bool]$Enabled = $true,
        [bool]$HasPrevious = $false
    )
    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.Margin = "0,0,0,14"

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Style = Get-NFRes 'Text.Body'
    $lbl.Text = $Label
    $stack.Children.Add($lbl) | Out-Null

    if ($Description) {
        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Style = Get-NFRes 'Text.Muted'
        $desc.Text = $Description
        $desc.Margin = "0,2,0,8"
        $stack.Children.Add($desc) | Out-Null
    }

    $row = New-Object System.Windows.Controls.Grid
    $row.Margin = "0,6,0,0"
    $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = '*'
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = 'Auto'
    $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = 'Auto'
    $row.ColumnDefinitions.Add($c0) | Out-Null
    $row.ColumnDefinitions.Add($c1) | Out-Null
    $row.ColumnDefinitions.Add($c2) | Out-Null

    $tb = New-Object System.Windows.Controls.TextBox
    $tb.Style = Get-NFRes 'Input.TextBox'
    $tb.Text = $Value
    $tb.IsReadOnly = $true
    $tb.IsEnabled = $Enabled
    $tb.Margin = "0,0,10,0"
    [System.Windows.Controls.Grid]::SetColumn($tb, 0)

    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = "Browse..."
    $btn.Style = Get-NFRes 'Btn.Secondary'
    $btn.IsEnabled = $Enabled
    $btn.Margin = "0,0,8,0"
    [System.Windows.Controls.Grid]::SetColumn($btn, 1)

    $revertBtn = New-Object System.Windows.Controls.Button
    $revertBtn.Content = "$([char]0x21A9)"
    $revertBtn.Style = Get-NFRes 'Btn.Secondary'
    $revertBtn.ToolTip = "Restore the previous folder you had set here"
    $revertBtn.IsEnabled = ($Enabled -and $HasPrevious)
    $revertBtn.Visibility = if ($HasPrevious) { 'Visible' } else { 'Collapsed' }
    $revertBtn.Padding = "10,9"
    [System.Windows.Controls.Grid]::SetColumn($revertBtn, 2)

    $row.Children.Add($tb) | Out-Null
    $row.Children.Add($btn) | Out-Null
    $row.Children.Add($revertBtn) | Out-Null
    $stack.Children.Add($row) | Out-Null

    [PSCustomObject]@{ Root = $stack; TextBox = $tb; BrowseButton = $btn; RevertButton = $revertBtn }
}

function New-NFDropdownRow {
    param(
        [Parameter(Mandatory)][string]$Label,
        [string]$Description = "",
        [string[]]$Items = @(),
        [int]$SelectedIndex = 0,
        [bool]$Enabled = $true
    )
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "0,0,0,14"
    $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = '*'
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = '220'
    $grid.ColumnDefinitions.Add($c0) | Out-Null
    $grid.ColumnDefinitions.Add($c1) | Out-Null

    $textStack = New-Object System.Windows.Controls.StackPanel
    [System.Windows.Controls.Grid]::SetColumn($textStack, 0)
    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Style = Get-NFRes 'Text.Body'
    $lbl.Text = $Label
    $textStack.Children.Add($lbl) | Out-Null
    if ($Description) {
        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Style = Get-NFRes 'Text.Muted'
        $desc.Text = $Description
        $desc.Margin = "0,2,10,0"
        $textStack.Children.Add($desc) | Out-Null
    }

    $combo = New-Object System.Windows.Controls.ComboBox
    $combo.Style = Get-NFRes 'Input.ComboBox'
    foreach ($item in $Items) { $combo.Items.Add($item) | Out-Null }
    if ($Items.Count -gt 0) { $combo.SelectedIndex = [Math]::Min($SelectedIndex, $Items.Count - 1) }
    $combo.IsEnabled = $Enabled
    $combo.VerticalAlignment = 'Center'
    [System.Windows.Controls.Grid]::SetColumn($combo, 1)

    $grid.Children.Add($textStack) | Out-Null
    $grid.Children.Add($combo) | Out-Null

    [PSCustomObject]@{ Root = $grid; ComboBox = $combo }
}

function New-NFPrimaryButton {
    param([Parameter(Mandatory)][string]$Text, [bool]$Enabled = $true)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = $Text
    $btn.Style = Get-NFRes 'Btn.Primary'
    $btn.IsEnabled = $Enabled
    $btn.HorizontalAlignment = 'Left'
    return $btn
}

function New-NFSecondaryButton {
    param([Parameter(Mandatory)][string]$Text, [bool]$Enabled = $true)
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = $Text
    $btn.Style = Get-NFRes 'Btn.Secondary'
    $btn.IsEnabled = $Enabled
    $btn.HorizontalAlignment = 'Left'
    return $btn
}

function Show-NFFolderBrowser {
    param([string]$Description = "Select a folder", [string]$InitialPath = "")
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $Description
    $dlg.ShowNewFolderButton = $false
    if ($InitialPath -and (Test-Path -LiteralPath $InitialPath)) {
        $dlg.SelectedPath = $InitialPath
    }
    $result = $dlg.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dlg.SelectedPath
    }
    return $null
}

function Show-NFInputDialog {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Label,
        [string]$DefaultValue = ""
    )
    $win = New-Object System.Windows.Window
    $win.Title = $Title
    $win.Width = 420
    $win.SizeToContent = 'Height'
    $win.ResizeMode = 'NoResize'
    $win.WindowStyle = 'ToolWindow'
    if ($Global:NF_Window -and $Global:NF_Window.IsVisible) {
        $win.Owner = $Global:NF_Window
        $win.WindowStartupLocation = 'CenterOwner'
    } else {
        $win.WindowStartupLocation = 'CenterScreen'
    }
    $win.Background = Get-NFRes 'Brush.Bg'
    $win.FontFamily = 'Segoe UI'

    $outer = New-Object System.Windows.Controls.StackPanel
    $outer.Margin = 20

    $lbl = New-Object System.Windows.Controls.TextBlock
    $lbl.Style = Get-NFRes 'Text.Body'
    $lbl.Text = $Label
    $lbl.Margin = "0,0,0,8"
    $outer.Children.Add($lbl) | Out-Null

    $tb = New-Object System.Windows.Controls.TextBox
    $tb.Style = Get-NFRes 'Input.TextBox'
    $tb.Text = $DefaultValue
    $tb.Margin = "0,0,0,16"
    $outer.Children.Add($tb) | Out-Null

    $result = @{ Value = $null }

    $btnRow = New-Object System.Windows.Controls.StackPanel
    $btnRow.Orientation = 'Horizontal'
    $btnRow.HorizontalAlignment = 'Right'

    $cancelBtn = New-Object System.Windows.Controls.Button
    $cancelBtn.Content = "Cancel"
    $cancelBtn.Style = Get-NFRes 'Btn.Secondary'
    $cancelBtn.Margin = "0,0,10,0"
    $cancelBtn.Add_Click({ $result.Value = $null; $win.Close() }.GetNewClosure()) | Out-Null
    $btnRow.Children.Add($cancelBtn) | Out-Null

    $okBtn = New-Object System.Windows.Controls.Button
    $okBtn.Content = "Save"
    $okBtn.Style = Get-NFRes 'Btn.Primary'
    $okBtn.Add_Click({ $result.Value = $tb.Text.Trim(); $win.Close() }.GetNewClosure()) | Out-Null
    $btnRow.Children.Add($okBtn) | Out-Null

    $outer.Children.Add($btnRow) | Out-Null
    $win.Content = $outer

    $tb.Add_KeyDown({
        if ($_.Key -eq 'Enter') { $result.Value = $tb.Text.Trim(); $win.Close() }
        elseif ($_.Key -eq 'Escape') { $result.Value = $null; $win.Close() }
    }.GetNewClosure()) | Out-Null
    $win.Add_ContentRendered({ $tb.Focus() | Out-Null; $tb.SelectAll() }.GetNewClosure()) | Out-Null

    $win.ShowDialog() | Out-Null
    return $result.Value
}

function Show-NFModSitesDialog {
    param(
        [string]$Title = "Trusted Mod Sites",
        [string]$Subtitle = "Nova Forge doesn't host or vet any of these -- they're just some of the most established, reputable places people share mods. Always read a mod's page before installing it.",
        [array]$Sites = @(
            @{ Name = 'Nexus Mods'; Url = 'https://www.nexusmods.com/' }
            @{ Name = 'GameBanana'; Url = 'https://gamebanana.com/' }
            @{ Name = 'Modrinth'; Url = 'https://modrinth.com/' }
            @{ Name = 'CurseForge'; Url = 'https://www.curseforge.com/' }
            @{ Name = 'ModsHost'; Url = 'https://modshost.co/' }
        )
    )

    $win = New-Object System.Windows.Window
    $win.Title = $Title
    $win.Width = 460
    $win.SizeToContent = 'Height'
    $win.WindowStyle = 'None'
    $win.AllowsTransparency = $true
    $win.Background = [System.Windows.Media.Brushes]::Transparent
    $win.ResizeMode = 'NoResize'
    $win.ShowInTaskbar = $false
    if ($Global:NF_Window -and $Global:NF_Window.IsVisible) {
        $win.Owner = $Global:NF_Window
        $win.WindowStartupLocation = 'CenterOwner'
    } else {
        $win.WindowStartupLocation = 'CenterScreen'
    }

    # --- Glassy frosted card: translucent gradient + soft shadow + accent border ---
    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = 14
    $card.Padding = 26
    $card.BorderThickness = 1
    $card.BorderBrush = Get-NFRes 'Brush.Accent'
    $card.Cursor = [System.Windows.Input.Cursors]::Arrow

    $glassBrush = New-Object System.Windows.Media.LinearGradientBrush
    $glassBrush.StartPoint = New-Object System.Windows.Point(0, 0)
    $glassBrush.EndPoint = New-Object System.Windows.Point(1, 1)
    $glassBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromArgb(238, 14, 19, 28), 0))) | Out-Null
    $glassBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop([System.Windows.Media.Color]::FromArgb(238, 18, 24, 34), 1))) | Out-Null
    $card.Background = $glassBrush

    $cardGlow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $cardGlow.Color = [System.Windows.Media.Colors]::Black
    $cardGlow.BlurRadius = 34
    $cardGlow.ShadowDepth = 0
    $cardGlow.Opacity = 0.65
    $card.Effect = $cardGlow

    $scale = New-Object System.Windows.Media.ScaleTransform(0.92, 0.92)
    $card.RenderTransform = $scale
    $card.RenderTransformOrigin = New-Object System.Windows.Point(0.5, 0.5)
    $card.Opacity = 0

    $stack = New-Object System.Windows.Controls.StackPanel

    $headerRow = New-Object System.Windows.Controls.DockPanel
    # Drag-to-move is wired on the header only, not the whole card -- attaching it to
    # $card swallowed clicks on the link rows below, since DragMove() captures the
    # mouse on ButtonDown and the rows' own Click handler (on ButtonUp) never fired.
    $headerRow.Background = [System.Windows.Media.Brushes]::Transparent
    $headerRow.Cursor = [System.Windows.Input.Cursors]::SizeAll
    $headerRow.Add_MouseLeftButtonDown({ $win.DragMove() }.GetNewClosure()) | Out-Null
    $headerTb = New-Object System.Windows.Controls.TextBlock
    $headerTb.Style = Get-NFRes 'Text.H1'
    $headerTb.Text = $Title
    $headerRow.Children.Add($headerTb) | Out-Null
    $closeX = New-Object System.Windows.Controls.Button
    $closeX.Content = "$([char]0x2715)"
    $closeX.Style = Get-NFRes 'Btn.Ghost'
    $closeX.HorizontalAlignment = 'Right'
    [System.Windows.Controls.DockPanel]::SetDock($closeX, 'Right')
    $closeX.Add_Click({ $win.Close() }.GetNewClosure()) | Out-Null
    $headerRow.Children.Add($closeX) | Out-Null
    $stack.Children.Add($headerRow) | Out-Null

    $subTb = New-Object System.Windows.Controls.TextBlock
    $subTb.Style = Get-NFRes 'Text.Secondary'
    $subTb.Text = $Subtitle
    $subTb.Margin = "0,8,0,18"
    $stack.Children.Add($subTb) | Out-Null

    foreach ($site in $Sites) {
        $linkRow = New-Object System.Windows.Controls.Border
        $linkRow.Background = Get-NFRes 'Brush.CardBg'
        $linkRow.CornerRadius = 8
        $linkRow.Padding = "14,12"
        $linkRow.Margin = "0,0,0,8"
        $linkRow.Cursor = [System.Windows.Input.Cursors]::Hand

        $linkGrid = New-Object System.Windows.Controls.Grid
        $lc0 = New-Object System.Windows.Controls.ColumnDefinition; $lc0.Width = '*'
        $lc1 = New-Object System.Windows.Controls.ColumnDefinition; $lc1.Width = 'Auto'
        $linkGrid.ColumnDefinitions.Add($lc0) | Out-Null
        $linkGrid.ColumnDefinitions.Add($lc1) | Out-Null

        $siteStack = New-Object System.Windows.Controls.StackPanel
        $nameTb = New-Object System.Windows.Controls.TextBlock
        $nameTb.Style = Get-NFRes 'Text.Body'
        $nameTb.FontWeight = 'SemiBold'
        $nameTb.Text = $site.Name
        $siteStack.Children.Add($nameTb) | Out-Null
        $urlTb = New-Object System.Windows.Controls.TextBlock
        $urlTb.Style = Get-NFRes 'Text.Muted'
        $urlTb.Text = $site.Url
        $siteStack.Children.Add($urlTb) | Out-Null
        $linkGrid.Children.Add($siteStack) | Out-Null

        $arrowTb = New-Object System.Windows.Controls.TextBlock
        $arrowTb.Text = "$([char]0x2197)"
        $arrowTb.FontSize = 16
        $arrowTb.Foreground = Get-NFRes 'Brush.Accent'
        $arrowTb.VerticalAlignment = 'Center'
        [System.Windows.Controls.Grid]::SetColumn($arrowTb, 1)
        $linkGrid.Children.Add($arrowTb) | Out-Null

        $linkRow.Child = $linkGrid
        $capturedUrl = $site.Url
        $linkRow.Add_MouseLeftButtonUp({ Start-Process $capturedUrl; [System.Windows.Input.Mouse]::Capture($null) }.GetNewClosure()) | Out-Null
        $linkRow.Add_MouseEnter({ $linkRow.Background = Get-NFRes 'Brush.CardHover'; $linkRow.BorderBrush = Get-NFRes 'Brush.Accent'; $linkRow.BorderThickness = 1 }.GetNewClosure()) | Out-Null
        $linkRow.Add_MouseLeave({ $linkRow.Background = Get-NFRes 'Brush.CardBg'; $linkRow.BorderThickness = 0 }.GetNewClosure()) | Out-Null

        $stack.Children.Add($linkRow) | Out-Null
    }

    $card.Child = $stack
    $win.Content = $card

    $win.Add_ContentRendered({
        $ease = New-Object System.Windows.Media.Animation.CubicEase
        $ease.EasingMode = 'EaseOut'

        $fadeIn = [System.Windows.Media.Animation.DoubleAnimation]::new(0, 1, [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(200)))
        $fadeIn.EasingFunction = $ease
        $scaleAnim = [System.Windows.Media.Animation.DoubleAnimation]::new(0.92, 1.0, [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(200)))
        $scaleAnim.EasingFunction = $ease

        $card.BeginAnimation([System.Windows.Controls.Border]::OpacityProperty, $fadeIn)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleXProperty, $scaleAnim)
        $scale.BeginAnimation([System.Windows.Media.ScaleTransform]::ScaleYProperty, $scaleAnim)
    }.GetNewClosure()) | Out-Null

    $win.ShowDialog() | Out-Null
}

function Show-NFMessage {
    param(
        [Parameter(Mandatory)][string]$Text,
        [string]$Title = "Nova Forge",
        [ValidateSet('Info','Warning','Error','YesNo')]
        [string]$Kind = 'Info'
    )
    switch ($Kind) {
        'Warning' { [System.Windows.MessageBox]::Show($Text, $Title, 'OK', 'Warning') | Out-Null }
        'Error'   { [System.Windows.MessageBox]::Show($Text, $Title, 'OK', 'Error') | Out-Null }
        'YesNo'   { return [System.Windows.MessageBox]::Show($Text, $Title, 'YesNo', 'Question') }
        default   { [System.Windows.MessageBox]::Show($Text, $Title, 'OK', 'Information') | Out-Null }
    }
}
