# OverviewView.ps1

function Add-NFDirectoryPickerRow {
    param(
        [Parameter(Mandatory)]$Card,
        [Parameter(Mandatory)]$Profile,
        [Parameter(Mandatory)]$Game,
        [Parameter(Mandatory)][ValidateSet('Game', 'Update', 'Dlc')][string]$Kind,
        [Parameter(Mandatory)][string]$FieldName,
        [Parameter(Mandatory)][string]$PreviousFieldName,
        [Parameter(Mandatory)][string]$Label,
        [string]$Description = ""
    )
    $currentValue = $Profile.$FieldName
    $previousValue = $Profile.$PreviousFieldName

    $picker = New-NFPathPickerRow -Label $Label -Description $Description `
        -Value $(if ($currentValue) { $currentValue } else { "" }) `
        -HasPrevious ([bool]$previousValue)

    $picker.BrowseButton.Add_Click({
        $selected = Show-NFFolderBrowser -Description "Select your $Label"
        if (-not $selected) { return }
        $result = Test-NFGameFolder -Game $Game -Kind $Kind -Path $selected
        if (-not $result.Valid) {
            Show-NFMessage -Kind 'Error' -Text $result.Reason
            return
        }
        $freshProfile = Get-NFProfile -GameId $Game.Id -ProfileId $Profile.id
        if ($freshProfile.$FieldName -and $freshProfile.$FieldName -ne $selected) {
            $freshProfile.$PreviousFieldName = $freshProfile.$FieldName
        }
        $freshProfile.$FieldName = $selected
        Save-NFProfile -Profile $freshProfile
        Show-NFView -Section 'Overview'
    }.GetNewClosure()) | Out-Null

    $picker.RevertButton.Add_Click({
        $freshProfile = Get-NFProfile -GameId $Game.Id -ProfileId $Profile.id
        if (-not $freshProfile.$PreviousFieldName) { return }
        $swap = $freshProfile.$FieldName
        $freshProfile.$FieldName = $freshProfile.$PreviousFieldName
        $freshProfile.$PreviousFieldName = $swap
        Save-NFProfile -Profile $freshProfile
        Show-NFView -Section 'Overview'
    }.GetNewClosure()) | Out-Null

    $Card.Body.Children.Add($picker.Root) | Out-Null
}

function New-NFOverviewView {
    $root = New-Object System.Windows.Controls.StackPanel

    if (-not $Global:NF_State.CurrentGameId) {
        $root.Children.Add((New-NFSectionHeader -Title "Overview" -Subtitle "No game selected yet.")) | Out-Null
        $note = New-NFNotImplementedNote -Text "Choose a game from the sidebar to see its overview, settings, mods, and save tools."
        $root.Children.Add($note) | Out-Null
        $btn = New-NFPrimaryButton -Text "Choose a Game"
        $btn.Add_Click({ Show-NFGameSelector }) | Out-Null
        $root.Children.Add($btn) | Out-Null
        return $root
    }

    $game = Get-NFGame -Id $Global:NF_State.CurrentGameId
    $profile = Get-NFProfile -GameId $game.Id -ProfileId $Global:NF_State.CurrentProfileId

    $root.Children.Add((New-NFSectionHeader -Title $game.Name -Subtitle "$($game.Platform) - Active profile: $($profile.name)")) | Out-Null

    if ($game.Id -eq 'botw') {
        $root.Children.Add((New-NFNotImplementedNote -Text $Global:NF_BotwInfo.Description -Icon ([System.Char]::ConvertFromUtf32(0x1F5E1)))) | Out-Null
    } elseif ($game.Id -eq 'minecraft') {
        $root.Children.Add((New-NFNotImplementedNote -Text $Global:NF_MinecraftInfo.Description -Icon ([System.Char]::ConvertFromUtf32(0x26CF)))) | Out-Null
    }

    $legal = New-NFLegalBanner -WithLink
    $legal.LinkButton.Add_Click({ Show-NFView -Section 'Settings' -SettingsTab 'Legal' }) | Out-Null
    $root.Children.Add($legal.Root) | Out-Null

    # --- Game / update / DLC directory card ---
    $dirCard = New-NFCard
    $dirCard.Body.Children.Add((New-NFSectionHeader -Title "Game Directory" -Subtitle "Point Nova Forge at your own legally obtained files. Each folder is checked for the layout this title expects before it's accepted -- nothing is copied, moved, or uploaded." -NoMarginBottom)) | Out-Null
    $dirCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 14 })) | Out-Null

    $gameFolderDesc = switch ($game.Id) {
        'botw'      { "The base game dump. Must contain 'code', 'content', and 'meta' subfolders." }
        'minecraft' { "Your .minecraft folder. Must contain a 'versions' subfolder." }
        default     { "Your base game install." }
    }
    Add-NFDirectoryPickerRow -Card $dirCard -Profile $profile -Game $game -Kind 'Game' `
        -FieldName 'gameDirectory' -PreviousFieldName 'previousGameDirectory' `
        -Label "Game folder" `
        -Description $gameFolderDesc

    # Update/DLC only mean something for titles whose module actually validates
    # them -- showing the picker for a game with no such concept (e.g. Minecraft
    # has no "DLC dump") would be misleading, not just unimplemented.
    if ($game.ValidatorPrefix -and (Get-Command "Test-NF$($game.ValidatorPrefix)UpdateFolder" -ErrorAction SilentlyContinue)) {
        Add-NFDirectoryPickerRow -Card $dirCard -Profile $profile -Game $game -Kind 'Update' `
            -FieldName 'updateDirectory' -PreviousFieldName 'previousUpdateDirectory' `
            -Label "Update folder" `
            -Description "Optional. Your update/patch dump, if you have one installed separately from the base game."
    }

    if ($game.ValidatorPrefix -and (Get-Command "Test-NF$($game.ValidatorPrefix)DlcFolder" -ErrorAction SilentlyContinue)) {
        Add-NFDirectoryPickerRow -Card $dirCard -Profile $profile -Game $game -Kind 'Dlc' `
            -FieldName 'dlcDirectory' -PreviousFieldName 'previousDlcDirectory' `
            -Label "DLC folder" `
            -Description "Optional. Your add-on content dump, if you own it."
    }

    $tip = New-NFNotImplementedNote -Icon ([System.Char]::ConvertFromUtf32(0x1F4A1)) `
        -Text "Tip: if you already have mods, save backups, or DLC/update files somewhere else on this PC, use the Browse buttons above to point Nova Forge at those existing folders directly -- nothing needs to be re-downloaded or re-imported."
    $tip.Margin = "0,4,0,0"
    $dirCard.Body.Children.Add($tip) | Out-Null

    $root.Children.Add($dirCard.Root) | Out-Null

    if ($game.Id -eq 'botw') {
        $emuNote = New-NFCard
        $emuNote.Body.Children.Add((New-NFSectionHeader -Title "Running on PC" -NoMarginBottom)) | Out-Null
        $emuTb = New-Object System.Windows.Controls.TextBlock
        $emuTb.Style = Get-NFRes 'Text.Secondary'
        $emuTb.Margin = "0,8,0,0"
        $emuTb.Text = $Global:NF_BotwInfo.EmulationNote
        $emuNote.Body.Children.Add($emuTb) | Out-Null
        $root.Children.Add($emuNote.Root) | Out-Null
    }

    # --- Don't have the game yet? (shown until a game folder is set for this profile) ---
    if (-not $profile.gameDirectory -and (Get-Member -InputObject $game -Name 'GetGameNote' -MemberType NoteProperty)) {
        $getCard = New-NFCard
        $getCard.Body.Children.Add((New-NFSectionHeader -Title "Don't have the game yet?" -NoMarginBottom)) | Out-Null
        $getNote = New-Object System.Windows.Controls.TextBlock
        $getNote.Style = Get-NFRes 'Text.Secondary'
        $getNote.TextWrapping = 'Wrap'
        $getNote.Margin = "0,8,0,12"
        $getNote.Text = $game.GetGameNote
        $getCard.Body.Children.Add($getNote) | Out-Null
        foreach ($link in @($game.GetGameLinks)) {
            $linkBtn = New-NFSecondaryButton -Text $link.Label
            $linkBtn.HorizontalAlignment = 'Left'
            $linkBtn.Margin = "0,0,0,8"
            $linkUrl = $link.Url
            $linkBtn.Add_Click({ Start-Process $linkUrl }.GetNewClosure()) | Out-Null
            $getCard.Body.Children.Add($linkBtn) | Out-Null
        }
        $root.Children.Add($getCard.Root) | Out-Null
    }

    # --- Suggested emulators (links only; Nova Forge bundles none) ---
    $emus = @()
    if (Get-Member -InputObject $game -Name 'Emulators' -MemberType NoteProperty) { $emus = @($game.Emulators) }
    if ($emus.Count -gt 0) {
        $emuCard = New-NFCard
        $emuCard.Body.Children.Add((New-NFSectionHeader -Title "Suggested Emulators" -Subtitle "Nova Forge is not an emulator and includes none. These are actively maintained projects you install yourself, with your own legally obtained game files. Discontinued projects (e.g. Yuzu) are not listed." -NoMarginBottom)) | Out-Null
        $emuCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 12 })) | Out-Null
        foreach ($emu in $emus) {
            $emuRow = New-Object System.Windows.Controls.DockPanel
            $emuRow.Margin = "0,0,0,10"
            $emuBtn = New-NFSecondaryButton -Text "Open site"
            $emuBtn.VerticalAlignment = 'Center'
            [System.Windows.Controls.DockPanel]::SetDock($emuBtn, 'Right')
            $emuUrl = $emu.Url
            $emuBtn.Add_Click({ Start-Process $emuUrl }.GetNewClosure()) | Out-Null
            $emuRow.Children.Add($emuBtn) | Out-Null
            $emuText = New-Object System.Windows.Controls.StackPanel
            $emuName = New-Object System.Windows.Controls.TextBlock
            $emuName.Style = Get-NFRes 'Text.Body'
            $emuName.FontWeight = 'SemiBold'
            $emuName.Text = "$($emu.Name)  -  $($emu.System)"
            $emuText.Children.Add($emuName) | Out-Null
            $emuNote2 = New-Object System.Windows.Controls.TextBlock
            $emuNote2.Style = Get-NFRes 'Text.Muted'
            $emuNote2.TextWrapping = 'Wrap'
            $emuNote2.Text = $emu.Note
            $emuText.Children.Add($emuNote2) | Out-Null
            $emuRow.Children.Add($emuText) | Out-Null
            $emuCard.Body.Children.Add($emuRow) | Out-Null
        }
        $root.Children.Add($emuCard.Root) | Out-Null
    }

    # --- Feature status card ---
    $featCard = New-NFCard
    $featCard.Body.Children.Add((New-NFSectionHeader -Title "Feature Status" -Subtitle "What's real in this prototype vs. planned." -NoMarginBottom)) | Out-Null
    $featCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 10 })) | Out-Null

    $features = @(
        @{ Name = "Profiles & local config storage"; Status = "Implemented"; Kind = "Active" }
        @{ Name = "Game/update/DLC directory selection"; Status = "Implemented"; Kind = "Active" }
        @{ Name = "Mod cataloging (no installation)"; Status = "Organize only"; Kind = "NotImplemented" }
        @{ Name = "Save backup"; Status = "Implemented"; Kind = "Active" }
        @{ Name = "Save restore"; Status = "Not implemented"; Kind = "NotImplemented" }
        @{ Name = "Game settings editing"; Status = "Planned"; Kind = "NotImplemented" }
        @{ Name = "Character customization"; Status = "Planned"; Kind = "NotImplemented" }
    )
    foreach ($f in $features) {
        $row = New-Object System.Windows.Controls.DockPanel
        $row.Margin = "0,0,0,10"
        $nameTb = New-Object System.Windows.Controls.TextBlock
        $nameTb.Style = Get-NFRes 'Text.Body'
        $nameTb.Text = $f.Name
        $row.Children.Add($nameTb) | Out-Null
        $badge = New-NFBadge -Text $f.Status.ToUpper() -Kind $f.Kind
        $badge.HorizontalAlignment = 'Right'
        $row.Children.Add($badge) | Out-Null
        $featCard.Body.Children.Add($row) | Out-Null
    }
    $root.Children.Add($featCard.Root) | Out-Null

    return $root
}
