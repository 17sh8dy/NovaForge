# ModsView.ps1
# Real, local catalog of mods a user manages themselves. Nova Forge does NOT
# install, copy, inject, or patch any mod file into a game here -- this view
# only organizes metadata (name, notes, where you keep the files, enabled flag).

function New-NFModsView {
    $root = New-Object System.Windows.Controls.StackPanel
    $game = Get-NFGame -Id $Global:NF_State.CurrentGameId
    $profileId = $Global:NF_State.CurrentProfileId

    $root.Children.Add((New-NFSectionHeader -Title "Mods" -Subtitle "$($game.Name) - active profile only")) | Out-Null
    $root.Children.Add((New-NFNotImplementedNote -Text "This is a personal catalog only. Nova Forge does not install, inject, or patch mod files into your game yet. Track what you have and where it lives; apply it yourself for now.")) | Out-Null

    $legal = New-NFLegalBanner -Text "You are responsible for the legality of any file you catalog here. Nova Forge does not host, provide, or verify mod content." -WithLink
    $legal.LinkButton.Add_Click({ Show-NFView -Section 'Settings' -SettingsTab 'Legal' }) | Out-Null
    $root.Children.Add($legal.Root) | Out-Null

    # --- Trusted mod sites teaser: collapsed note, click to see the full list ---
    $sitesTeaser = New-Object System.Windows.Controls.Border
    $sitesTeaser.Style = Get-NFRes 'Panel.Banner.Info'
    $sitesTeaser.Margin = "0,0,0,16"
    $sitesTeaser.Cursor = [System.Windows.Input.Cursors]::Hand

    $teaserGrid = New-Object System.Windows.Controls.Grid
    $tc0 = New-Object System.Windows.Controls.ColumnDefinition; $tc0.Width = '*'
    $tc1 = New-Object System.Windows.Controls.ColumnDefinition; $tc1.Width = 'Auto'
    $teaserGrid.ColumnDefinitions.Add($tc0) | Out-Null
    $teaserGrid.ColumnDefinitions.Add($tc1) | Out-Null

    $teaserStack = New-Object System.Windows.Controls.StackPanel
    $teaserTitle = New-Object System.Windows.Controls.TextBlock
    $teaserTitle.Style = Get-NFRes 'Text.Body'
    $teaserTitle.FontWeight = 'SemiBold'
    $teaserTitle.Text = "Nova Forge hasn't added mod support for any game yet."
    $teaserStack.Children.Add($teaserTitle) | Out-Null
    $teaserSub = New-Object System.Windows.Controls.TextBlock
    $teaserSub.Style = Get-NFRes 'Text.Muted'
    $teaserSub.Text = "Until then, here are some of the safest, most reputable places to find mods."
    $teaserSub.Margin = "0,2,0,0"
    $teaserStack.Children.Add($teaserSub) | Out-Null
    $teaserGrid.Children.Add($teaserStack) | Out-Null

    $teaserLink = New-Object System.Windows.Controls.TextBlock
    $teaserLink.Style = Get-NFRes 'Text.Body'
    $teaserLink.Foreground = Get-NFRes 'Brush.Accent'
    $teaserLink.FontWeight = 'SemiBold'
    $teaserLink.Text = "View sites $([char]0x2192)"
    $teaserLink.VerticalAlignment = 'Center'
    $teaserLink.Margin = "10,0,0,0"
    [System.Windows.Controls.Grid]::SetColumn($teaserLink, 1)
    $teaserGrid.Children.Add($teaserLink) | Out-Null

    $sitesTeaser.Child = $teaserGrid
    $sitesTeaser.Add_MouseLeftButtonUp({ Show-NFModSitesDialog }.GetNewClosure()) | Out-Null
    $root.Children.Add($sitesTeaser) | Out-Null

    $mods = @(Get-NFMods -GameId $game.Id -ProfileId $profileId)

    $listCard = New-NFCard
    $listCard.Body.Children.Add((New-NFSectionHeader -Title "Cataloged Mods ($($mods.Count))" -NoMarginBottom)) | Out-Null
    $listCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 12 })) | Out-Null

    if ($mods.Count -eq 0) {
        $empty = New-Object System.Windows.Controls.TextBlock
        $empty.Style = Get-NFRes 'Text.Muted'
        $empty.Text = "No mods cataloged yet for this profile."
        $listCard.Body.Children.Add($empty) | Out-Null
    }

    foreach ($mod in $mods) {
        $row = New-Object System.Windows.Controls.Border
        $row.Background = Get-NFRes 'Brush.PanelBg'
        $row.CornerRadius = 6
        $row.Padding = "12,10"
        $row.Margin = "0,0,0,8"

        $grid = New-Object System.Windows.Controls.Grid
        $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = '*'
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = 'Auto'
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = 'Auto'
        $c3 = New-Object System.Windows.Controls.ColumnDefinition; $c3.Width = 'Auto'
        # columns: 0 text, 1 launcher button (optional), 2 enabled toggle, 3 remove
        $grid.ColumnDefinitions.Add($c0) | Out-Null
        $grid.ColumnDefinitions.Add($c1) | Out-Null
        $grid.ColumnDefinitions.Add($c2) | Out-Null
        $grid.ColumnDefinitions.Add($c3) | Out-Null

        $textStack = New-Object System.Windows.Controls.StackPanel
        [System.Windows.Controls.Grid]::SetColumn($textStack, 0)
        $nameTb = New-Object System.Windows.Controls.TextBlock
        $nameTb.Style = Get-NFRes 'Text.Body'
        $nameTb.FontWeight = 'SemiBold'
        $nameTb.Text = $mod.name
        $textStack.Children.Add($nameTb) | Out-Null
        if ($mod.notes) {
            $notesTb = New-Object System.Windows.Controls.TextBlock
            $notesTb.Style = Get-NFRes 'Text.Muted'
            $notesTb.Text = $mod.notes
            $notesTb.Margin = "0,2,0,0"
            $textStack.Children.Add($notesTb) | Out-Null
        }
        if ($mod.sourcePath) {
            $srcTb = New-Object System.Windows.Controls.TextBlock
            $srcTb.Style = Get-NFRes 'Text.Muted'
            $srcTb.Text = "Location: $($mod.sourcePath)"
            $srcTb.Margin = "0,2,0,0"
            $textStack.Children.Add($srcTb) | Out-Null
        }
        $grid.Children.Add($textStack) | Out-Null

        $toggle = New-Object System.Windows.Controls.CheckBox
        $toggle.Style = Get-NFRes 'ToggleSwitch'
        $toggle.IsChecked = [bool]$mod.enabled
        $toggle.VerticalAlignment = 'Center'
        $toggle.Margin = "10,0,10,0"
        [System.Windows.Controls.Grid]::SetColumn($toggle, 2)
        $capturedMod = $mod
        $toggle.Add_Click({
            $capturedMod.enabled = $toggle.IsChecked -eq $true
            $allMods = @(Get-NFMods -GameId $game.Id -ProfileId $profileId)
            foreach ($m in $allMods) { if ($m.id -eq $capturedMod.id) { $m.enabled = $capturedMod.enabled } }
            Save-NFMods -GameId $game.Id -ProfileId $profileId -Mods $allMods
        }.GetNewClosure()) | Out-Null
        $grid.Children.Add($toggle) | Out-Null

        # Optional: a mod that ships its own launcher/manager app gets an "Open launcher"
        # button. Nova Forge only starts that program; it never installs or patches anything.
        $launcherPath = if (Get-Member -InputObject $mod -Name 'launcherPath' -MemberType NoteProperty) { $mod.launcherPath } else { $null }
        if ($launcherPath) {
            $launchBtn = New-NFSecondaryButton -Text "Open launcher"
            $launchBtn.VerticalAlignment = 'Center'
            $launchBtn.Margin = "0,0,10,0"
            $launchBtn.IsEnabled = (Test-Path -LiteralPath $launcherPath -PathType Leaf)
            if (-not $launchBtn.IsEnabled) { $launchBtn.ToolTip = "Launcher not found at: $launcherPath" }
            $launchExe = $launcherPath
            $launchBtn.Add_Click({
                try { Start-Process -FilePath $launchExe -WorkingDirectory (Split-Path -Parent $launchExe) }
                catch { Show-NFMessage -Text "Couldn't start the launcher: $($_.Exception.Message)" -Kind 'Warning' }
            }.GetNewClosure()) | Out-Null
            [System.Windows.Controls.Grid]::SetColumn($launchBtn, 1)
            $grid.Children.Add($launchBtn) | Out-Null
        }

        $removeBtn = New-Object System.Windows.Controls.Button
        $removeBtn.Content = "Remove"
        $removeBtn.Style = Get-NFRes 'Btn.Danger'
        $removeBtn.VerticalAlignment = 'Center'
        [System.Windows.Controls.Grid]::SetColumn($removeBtn, 3)
        $removeBtn.Add_Click({
            Remove-NFModEntry -GameId $game.Id -ProfileId $profileId -ModId $capturedMod.id
            Show-NFView -Section 'Mods'
        }.GetNewClosure()) | Out-Null
        $grid.Children.Add($removeBtn) | Out-Null

        $row.Child = $grid
        $listCard.Body.Children.Add($row) | Out-Null
    }
    $root.Children.Add($listCard.Root) | Out-Null

    # --- Add mod form ---
    $addCard = New-NFCard
    $addCard.Body.Children.Add((New-NFSectionHeader -Title "Add a Mod Entry" -NoMarginBottom)) | Out-Null
    $addCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 10 })) | Out-Null

    $nameLabel = New-Object System.Windows.Controls.TextBlock
    $nameLabel.Style = Get-NFRes 'Text.Muted'
    $nameLabel.Text = "Name"
    $addCard.Body.Children.Add($nameLabel) | Out-Null
    $nameBox = New-Object System.Windows.Controls.TextBox
    $nameBox.Style = Get-NFRes 'Input.TextBox'
    $nameBox.Margin = "0,4,0,10"
    $addCard.Body.Children.Add($nameBox) | Out-Null

    $notesLabel = New-Object System.Windows.Controls.TextBlock
    $notesLabel.Style = Get-NFRes 'Text.Muted'
    $notesLabel.Text = "Notes (optional)"
    $addCard.Body.Children.Add($notesLabel) | Out-Null
    $notesBox = New-Object System.Windows.Controls.TextBox
    $notesBox.Style = Get-NFRes 'Input.TextBox'
    $notesBox.Margin = "0,4,0,10"
    $addCard.Body.Children.Add($notesBox) | Out-Null

    $srcPicker = New-NFPathPickerRow -Label "File location (optional)" -Description "Where you already keep this mod's files. Nova Forge will not move or copy them." -Value ""
    $addCard.Body.Children.Add($srcPicker.Root) | Out-Null
    $srcPicker.BrowseButton.Add_Click({
        $selected = Show-NFFolderBrowser -Description "Select the mod's folder"
        if ($selected) { $srcPicker.TextBox.Text = $selected }
    }.GetNewClosure()) | Out-Null

    $addBtn = New-NFPrimaryButton -Text "Add Mod Entry"
    $addBtn.Add_Click({
        if ([string]::IsNullOrWhiteSpace($nameBox.Text)) {
            Show-NFMessage -Text "Give the mod a name first." -Kind 'Warning'
            return
        }
        New-NFModEntry -GameId $game.Id -ProfileId $profileId -Name $nameBox.Text.Trim() -Notes $notesBox.Text.Trim() -SourcePath $(if ($srcPicker.TextBox.Text) { $srcPicker.TextBox.Text } else { $null }) | Out-Null
        Show-NFView -Section 'Mods'
    }.GetNewClosure()) | Out-Null
    $addCard.Body.Children.Add($addBtn) | Out-Null

    $root.Children.Add($addCard.Root) | Out-Null

    return $root
}
