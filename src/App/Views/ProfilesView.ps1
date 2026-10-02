# ProfilesView.ps1
# Local, per-game profiles: each stores its own game directory, save directory,
# and mod catalog. Real local JSON storage under profiles\<gameId>\.

function New-NFProfilesView {
    $root = New-Object System.Windows.Controls.StackPanel
    $game = Get-NFGame -Id $Global:NF_State.CurrentGameId

    $root.Children.Add((New-NFSectionHeader -Title "Profiles" -Subtitle "$($game.Name) - switch between separate setups (e.g. different mod lists or save sets).")) | Out-Null

    $profiles = @(Get-NFProfiles -GameId $game.Id)

    $listCard = New-NFCard
    $listCard.Body.Children.Add((New-NFSectionHeader -Title "Your Profiles ($($profiles.Count))" -NoMarginBottom)) | Out-Null
    $listCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 10 })) | Out-Null

    foreach ($p in $profiles) {
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
        $grid.ColumnDefinitions.Add($c0) | Out-Null
        $grid.ColumnDefinitions.Add($c1) | Out-Null
        $grid.ColumnDefinitions.Add($c2) | Out-Null
        $grid.ColumnDefinitions.Add($c3) | Out-Null

        $isActive = ($p.id -eq $Global:NF_State.CurrentProfileId)

        $textStack = New-Object System.Windows.Controls.StackPanel
        $nameRow = New-Object System.Windows.Controls.StackPanel
        $nameRow.Orientation = 'Horizontal'
        $nameTb = New-Object System.Windows.Controls.TextBlock
        $nameTb.Style = Get-NFRes 'Text.Body'
        $nameTb.FontWeight = 'SemiBold'
        $nameTb.Text = $p.name
        $nameRow.Children.Add($nameTb) | Out-Null
        if ($isActive) {
            $activeBadge = New-NFBadge -Text "ACTIVE" -Kind 'Active'
            $activeBadge.Margin = "10,0,0,0"
            $nameRow.Children.Add($activeBadge) | Out-Null
        }
        $textStack.Children.Add($nameRow) | Out-Null
        $subTb = New-Object System.Windows.Controls.TextBlock
        $subTb.Style = Get-NFRes 'Text.Muted'
        $dirText = if ($p.gameDirectory) { $p.gameDirectory } else { "No game folder set" }
        $subTb.Text = $dirText
        $subTb.Margin = "0,2,0,0"
        $textStack.Children.Add($subTb) | Out-Null
        $grid.Children.Add($textStack) | Out-Null

        $activateBtn = New-Object System.Windows.Controls.Button
        $activateBtn.Content = if ($isActive) { "Active" } else { "Set Active" }
        $activateBtn.Style = Get-NFRes 'Btn.Secondary'
        $activateBtn.IsEnabled = -not $isActive
        $activateBtn.Margin = "10,0,10,0"
        [System.Windows.Controls.Grid]::SetColumn($activateBtn, 1)
        $capturedProfile = $p
        $activateBtn.Add_Click({
            Set-NFActiveProfile -ProfileId $capturedProfile.id
            Show-NFView -Section 'Profiles'
        }.GetNewClosure()) | Out-Null
        $grid.Children.Add($activateBtn) | Out-Null

        $renameBtn = New-Object System.Windows.Controls.Button
        $renameBtn.Content = "Rename"
        $renameBtn.Style = Get-NFRes 'Btn.Secondary'
        $renameBtn.Margin = "0,0,10,0"
        [System.Windows.Controls.Grid]::SetColumn($renameBtn, 2)
        $renameBtn.Add_Click({
            $newName = Show-NFInputDialog -Title "Rename Profile" -Label "Profile name" -DefaultValue $capturedProfile.name
            if ($newName -and $newName -ne $capturedProfile.name) {
                Rename-NFProfile -GameId $game.Id -ProfileId $capturedProfile.id -NewName $newName
                if ($Global:NF_State.CurrentProfileId -eq $capturedProfile.id) { Update-NFChrome }
                Show-NFView -Section 'Profiles'
            }
        }.GetNewClosure()) | Out-Null
        $grid.Children.Add($renameBtn) | Out-Null

        $deleteBtn = New-Object System.Windows.Controls.Button
        $deleteBtn.Content = "Delete"
        $deleteBtn.Style = Get-NFRes 'Btn.Danger'
        $deleteBtn.IsEnabled = ($profiles.Count -gt 1)
        [System.Windows.Controls.Grid]::SetColumn($deleteBtn, 3)
        $deleteBtn.Add_Click({
            $confirm = Show-NFMessage -Text "Delete profile '$($capturedProfile.name)'? This does not touch your game or save files -- only Nova Forge's local record of this profile." -Kind 'YesNo'
            if ($confirm -eq 'Yes') {
                Remove-NFProfile -GameId $game.Id -ProfileId $capturedProfile.id
                if ($Global:NF_State.CurrentProfileId -eq $capturedProfile.id) {
                    $remaining = @(Get-NFProfiles -GameId $game.Id)
                    if ($remaining.Count -gt 0) { Set-NFActiveProfile -ProfileId $remaining[0].id }
                }
                Show-NFView -Section 'Profiles'
            }
        }.GetNewClosure()) | Out-Null
        $grid.Children.Add($deleteBtn) | Out-Null

        $row.Child = $grid
        $listCard.Body.Children.Add($row) | Out-Null
    }
    $root.Children.Add($listCard.Root) | Out-Null

    # --- New profile ---
    $newCard = New-NFCard
    $newCard.Body.Children.Add((New-NFSectionHeader -Title "Create a New Profile" -NoMarginBottom)) | Out-Null
    $newCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 10 })) | Out-Null

    $row2 = New-Object System.Windows.Controls.Grid
    $rc0 = New-Object System.Windows.Controls.ColumnDefinition; $rc0.Width = '*'
    $rc1 = New-Object System.Windows.Controls.ColumnDefinition; $rc1.Width = 'Auto'
    $row2.ColumnDefinitions.Add($rc0) | Out-Null
    $row2.ColumnDefinitions.Add($rc1) | Out-Null

    $nameBox = New-Object System.Windows.Controls.TextBox
    $nameBox.Style = Get-NFRes 'Input.TextBox'
    $nameBox.Margin = "0,0,10,0"
    [System.Windows.Controls.Grid]::SetColumn($nameBox, 0)
    $row2.Children.Add($nameBox) | Out-Null

    $createBtn = New-Object System.Windows.Controls.Button
    $createBtn.Content = "Create Profile"
    $createBtn.Style = Get-NFRes 'Btn.Primary'
    [System.Windows.Controls.Grid]::SetColumn($createBtn, 1)
    $createBtn.Add_Click({
        $name = $nameBox.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($name)) { $name = "Profile $((Get-NFProfiles -GameId $game.Id).Count + 1)" }
        $newProfile = New-NFProfile -GameId $game.Id -Name $name
        Set-NFActiveProfile -ProfileId $newProfile.id
        Show-NFView -Section 'Profiles'
    }.GetNewClosure()) | Out-Null
    $row2.Children.Add($createBtn) | Out-Null

    $newCard.Body.Children.Add($row2) | Out-Null
    $root.Children.Add($newCard.Root) | Out-Null

    return $root
}
