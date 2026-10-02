# GameSelectorView.ps1 - pick which game to work with. Game-agnostic: reads the
# list from Core\GameRegistry.ps1, so a new game shows up here automatically.
# Games are grouped into big per-platform sections (Nintendo, PC/Linux, ...)
# read from each game's PlatformGroup -- add a new group by adding a game with
# that PlatformGroup value and listing it in $script:NF_PlatformGroups below.

function New-NFGameTile {
    param([Parameter(Mandatory)]$Game)

    $tile = New-Object System.Windows.Controls.Border
    $tile.Style = if ($Game.Supported) { Get-NFRes 'Panel.Card.Game' } else { Get-NFRes 'Panel.Card' }
    $tile.Width = 260
    $tile.Margin = "0,0,16,16"
    $tile.Cursor = if ($Game.Supported) { [System.Windows.Input.Cursors]::Hand } else { [System.Windows.Input.Cursors]::Arrow }

    $stack = New-Object System.Windows.Controls.StackPanel

    $topRow = New-Object System.Windows.Controls.DockPanel
    $iconBorder = New-Object System.Windows.Controls.Border
    $iconBorder.Width = 40; $iconBorder.Height = 40
    $iconBorder.CornerRadius = 8
    $iconBorder.Background = Get-NFRes 'Brush.PanelBg'
    $iconTb = New-Object System.Windows.Controls.TextBlock
    $iconTb.Text = $Game.Icon
    $iconTb.FontSize = 18
    $iconTb.HorizontalAlignment = 'Center'
    $iconTb.VerticalAlignment = 'Center'
    $iconBorder.Child = $iconTb
    [System.Windows.Controls.DockPanel]::SetDock($iconBorder, 'Left')
    $topRow.Children.Add($iconBorder) | Out-Null

    $badge = New-NFBadge -Text $(if ($Game.Supported) { "SUPPORTED" } else { "COMING SOON" }) -Kind $(if ($Game.Supported) { 'Active' } else { 'NotImplemented' })
    $badge.HorizontalAlignment = 'Right'
    $badge.VerticalAlignment = 'Center'
    $topRow.Children.Add($badge) | Out-Null

    $stack.Children.Add($topRow) | Out-Null

    $nameTb = New-Object System.Windows.Controls.TextBlock
    $nameTb.Style = Get-NFRes 'Text.H2'
    $nameTb.Text = $Game.Name
    $nameTb.Margin = "0,12,0,2"
    $nameTb.TextWrapping = 'Wrap'
    $stack.Children.Add($nameTb) | Out-Null

    $platTb = New-Object System.Windows.Controls.TextBlock
    $platTb.Style = Get-NFRes 'Text.Muted'
    $platTb.Text = $Game.Platform
    $stack.Children.Add($platTb) | Out-Null

    # Pick the profile right on the tile; clicking anywhere else on the tile opens the game.
    if ($Game.Supported) {
        $profiles = @(Get-NFProfiles -GameId $Game.Id)
        $profLabel = New-Object System.Windows.Controls.TextBlock
        $profLabel.Style = Get-NFRes 'Text.Muted'
        $profLabel.Text = "Profile"
        $profLabel.Margin = "0,14,0,4"
        $stack.Children.Add($profLabel) | Out-Null

        $combo = New-Object System.Windows.Controls.ComboBox
        $combo.Style = Get-NFRes 'Input.ComboBox'
        foreach ($pr in $profiles) { $combo.Items.Add($pr.name) | Out-Null }
        if ($profiles.Count -eq 0) { $combo.Items.Add("Default (created on first open)") | Out-Null }
        $activeId = Get-NFActiveProfileId -GameId $Game.Id
        $idx = 0
        for ($i = 0; $i -lt $profiles.Count; $i++) { if ($profiles[$i].id -eq $activeId) { $idx = $i } }
        $combo.SelectedIndex = $idx
        $combo.IsEnabled = ($profiles.Count -gt 0)
        $comboGameId = $Game.Id
        $comboProfiles = $profiles
        $combo.Add_SelectionChanged({
            if ($combo.SelectedIndex -ge 0 -and $combo.SelectedIndex -lt $comboProfiles.Count) {
                Set-NFActiveProfileId -GameId $comboGameId -ProfileId $comboProfiles[$combo.SelectedIndex].id
            }
        }.GetNewClosure()) | Out-Null
        $stack.Children.Add($combo) | Out-Null

        $openHint = New-Object System.Windows.Controls.TextBlock
        $openHint.Style = Get-NFRes 'Text.Body'
        $openHint.Foreground = Get-NFRes 'Brush.Accent'
        $openHint.FontWeight = 'SemiBold'
        $openHint.Text = "Open $([char]0x2192)"
        $openHint.Margin = "0,14,0,0"
        $stack.Children.Add($openHint) | Out-Null
    }

    $tile.Child = $stack

    if ($Game.Supported) {
        $capturedId = $Game.Id
        $tile.Add_MouseLeftButtonUp({
            # Ignore clicks that came from the profile dropdown (or its popup items).
            if ($_.Source -is [System.Windows.Controls.ComboBox] -or $_.Source -is [System.Windows.Controls.ComboBoxItem]) { return }
            Set-NFActiveGame -GameId $capturedId
        }.GetNewClosure()) | Out-Null
    } else {
        $tile.Opacity = 0.55
    }

    return $tile
}

function New-NFPlatformSection {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Icon,
        [array]$Games = @()
    )

    $section = New-Object System.Windows.Controls.Border
    $section.Style = Get-NFRes 'Panel.Platform'
    $section.Margin = "0,0,0,20"

    $stack = New-Object System.Windows.Controls.StackPanel

    $header = New-Object System.Windows.Controls.StackPanel
    $header.Orientation = 'Horizontal'
    $header.Margin = "0,0,0,16"

    $iconBorder = New-Object System.Windows.Controls.Border
    $iconBorder.Width = 44; $iconBorder.Height = 44
    $iconBorder.CornerRadius = 10
    $iconBorder.Background = Get-NFRes 'Brush.CardBg'
    $iconTb = New-Object System.Windows.Controls.TextBlock
    $iconTb.Text = $Icon
    $iconTb.FontSize = 20
    $iconTb.HorizontalAlignment = 'Center'
    $iconTb.VerticalAlignment = 'Center'
    $iconBorder.Child = $iconTb
    $header.Children.Add($iconBorder) | Out-Null

    $titleStack = New-Object System.Windows.Controls.StackPanel
    $titleStack.Margin = "12,0,0,0"
    $titleStack.VerticalAlignment = 'Center'
    $titleTb = New-Object System.Windows.Controls.TextBlock
    $titleTb.Style = Get-NFRes 'Text.H1'
    $titleTb.FontSize = 18
    $titleTb.Text = $Title
    $titleStack.Children.Add($titleTb) | Out-Null
    $countTb = New-Object System.Windows.Controls.TextBlock
    $countTb.Style = Get-NFRes 'Text.Muted'
    $countTb.Text = if ($Games.Count -eq 1) { "1 game" } else { "$($Games.Count) games" }
    $titleStack.Children.Add($countTb) | Out-Null
    $header.Children.Add($titleStack) | Out-Null

    $stack.Children.Add($header) | Out-Null

    if ($Games.Count -eq 0) {
        $placeholder = New-Object System.Windows.Controls.TextBlock
        $placeholder.Style = Get-NFRes 'Text.Muted'
        $placeholder.Text = "No $Title games added yet."
        $stack.Children.Add($placeholder) | Out-Null
    } else {
        $wrap = New-Object System.Windows.Controls.WrapPanel
        foreach ($game in $Games) {
            $wrap.Children.Add((New-NFGameTile -Game $game)) | Out-Null
        }
        $stack.Children.Add($wrap) | Out-Null
    }

    $section.Child = $stack
    return $section
}

function New-NFGameSelectorView {
    $root = New-Object System.Windows.Controls.StackPanel

    $root.Children.Add((New-NFSectionHeader -Title "Choose a Game" -Subtitle "Nova Forge organizes configuration, mods, and saves per game, grouped by platform.")) | Out-Null

    $legal = New-NFLegalBanner -WithLink
    $legal.LinkButton.Add_Click({ Show-NFView -Section 'Settings' -SettingsTab 'Legal' }) | Out-Null
    $root.Children.Add($legal.Root) | Out-Null

    $allGames = @(Get-NFGames)

    $platformGroups = @(
        @{ Title = 'Nintendo';   Filter = 'Nintendo';   Icon = [System.Char]::ConvertFromUtf32(0x1F3AE) }
        @{ Title = 'PC / Linux'; Filter = 'PC/Linux';   Icon = [System.Char]::ConvertFromUtf32(0x1F5A5) }
    )

    foreach ($group in $platformGroups) {
        $gamesInGroup = @($allGames | Where-Object { $_.PlatformGroup -eq $group.Filter })
        $root.Children.Add((New-NFPlatformSection -Title $group.Title -Icon $group.Icon -Games $gamesInGroup)) | Out-Null
    }

    return $root
}
