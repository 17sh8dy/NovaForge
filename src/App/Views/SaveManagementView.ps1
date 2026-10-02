# SaveManagementView.ps1
# Backup is real: it copies from your save folder into Nova Forge's own backups\
# folder and never writes back. Restore is intentionally disabled -- writing
# into a live save folder needs a tested, explicit implementation first.

function New-NFSaveManagementView {
    $root = New-Object System.Windows.Controls.StackPanel
    $game = Get-NFGame -Id $Global:NF_State.CurrentGameId
    $profileId = $Global:NF_State.CurrentProfileId
    $profile = Get-NFProfile -GameId $game.Id -ProfileId $profileId

    $root.Children.Add((New-NFSectionHeader -Title "Save Management" -Subtitle "$($game.Name) - active profile only")) | Out-Null

    if ($game.Id -eq 'botw') {
        $root.Children.Add((New-NFNotImplementedNote -Text $Global:NF_BotwInfo.SaveLocationNote)) | Out-Null
    }

    $dirCard = New-NFCard
    $dirCard.Body.Children.Add((New-NFSectionHeader -Title "Save Location" -NoMarginBottom)) | Out-Null
    $dirCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 10 })) | Out-Null
    $picker = New-NFPathPickerRow -Label "Save folder" -Description "Backups only ever read from this folder." -Value $(if ($profile.saveDirectory) { $profile.saveDirectory } else { "" })
    $dirCard.Body.Children.Add($picker.Root) | Out-Null

    $backupBtn = New-NFPrimaryButton -Text "Back Up Now" -Enabled ([bool]$profile.saveDirectory)
    $dirCard.Body.Children.Add($backupBtn) | Out-Null

    $picker.BrowseButton.Add_Click({
        $selected = Show-NFFolderBrowser -Description "Select your $($game.ShortName) save folder"
        if ($selected) {
            $picker.TextBox.Text = $selected
            $profile.saveDirectory = $selected
            Save-NFProfile -Profile $profile
            $backupBtn.IsEnabled = $true
        }
    }.GetNewClosure()) | Out-Null

    $backupBtn.Add_Click({
        try {
            $record = New-NFBackup -GameId $game.Id -ProfileId $profileId -SourcePath $profile.saveDirectory
            Show-NFMessage -Text "Backup created:`n$($record.folder)"
            Show-NFView -Section 'SaveManagement'
        } catch {
            Show-NFMessage -Text "Backup failed: $($_.Exception.Message)" -Kind 'Error'
        }
    }.GetNewClosure()) | Out-Null

    $root.Children.Add($dirCard.Root) | Out-Null

    # --- Backup history ---
    $backups = @(Get-NFBackups -GameId $game.Id -ProfileId $profileId | Sort-Object -Property createdUtc -Descending)
    $histCard = New-NFCard
    $histCard.Body.Children.Add((New-NFSectionHeader -Title "Backup History ($($backups.Count))" -NoMarginBottom)) | Out-Null
    $histCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 10 })) | Out-Null

    if ($backups.Count -eq 0) {
        $empty = New-Object System.Windows.Controls.TextBlock
        $empty.Style = Get-NFRes 'Text.Muted'
        $empty.Text = "No backups yet."
        $histCard.Body.Children.Add($empty) | Out-Null
    }

    foreach ($b in $backups) {
        $row = New-Object System.Windows.Controls.Border
        $row.Background = Get-NFRes 'Brush.PanelBg'
        $row.CornerRadius = 6
        $row.Padding = "12,10"
        $row.Margin = "0,0,0,8"

        $grid = New-Object System.Windows.Controls.Grid
        $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = '*'
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = 'Auto'
        $grid.ColumnDefinitions.Add($c0) | Out-Null
        $grid.ColumnDefinitions.Add($c1) | Out-Null

        $textStack = New-Object System.Windows.Controls.StackPanel
        $nameTb = New-Object System.Windows.Controls.TextBlock
        $nameTb.Style = Get-NFRes 'Text.Body'
        $nameTb.Text = $b.timestamp
        $textStack.Children.Add($nameTb) | Out-Null
        $sizeMb = [Math]::Round($b.sizeBytes / 1MB, 2)
        $subTb = New-Object System.Windows.Controls.TextBlock
        $subTb.Style = Get-NFRes 'Text.Muted'
        $subTb.Text = "$sizeMb MB - $($b.folder)"
        $textStack.Children.Add($subTb) | Out-Null
        $grid.Children.Add($textStack) | Out-Null

        $restoreBtn = New-Object System.Windows.Controls.Button
        $restoreBtn.Content = "Restore (not implemented)"
        $restoreBtn.Style = Get-NFRes 'Btn.Secondary'
        $restoreBtn.IsEnabled = $false
        $restoreBtn.ToolTip = "Restoring would overwrite live save files. Not implemented until a tested, safe implementation exists."
        [System.Windows.Controls.Grid]::SetColumn($restoreBtn, 1)
        $grid.Children.Add($restoreBtn) | Out-Null

        $row.Child = $grid
        $histCard.Body.Children.Add($row) | Out-Null
    }
    $root.Children.Add($histCard.Root) | Out-Null

    $openBtn = New-NFSecondaryButton -Text "Open Backups Folder"
    $openBtn.Add_Click({
        $dir = Get-NFBackupDir -GameId $game.Id -ProfileId $profileId
        Start-Process explorer.exe $dir
    }.GetNewClosure()) | Out-Null
    $root.Children.Add($openBtn) | Out-Null

    return $root
}
