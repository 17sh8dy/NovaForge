# CharacterCustomizationView.ps1
# Placeholder only. No customization pipeline exists yet for any supported game.
# What "character customization" even means is different per game (skins for
# Minecraft, outfit/model swaps for BOTW, ...), so the preview layout below is
# chosen per game.Id rather than showing one generic mock-up for everything.

function New-NFCharacterCustomizationView {
    $root = New-Object System.Windows.Controls.StackPanel
    $game = Get-NFGame -Id $Global:NF_State.CurrentGameId

    $root.Children.Add((New-NFSectionHeader -Title "Character Customization" -Subtitle "$($game.Name)")) | Out-Null
    $root.Children.Add((New-NFNotImplementedNote -Text "Character customization is not implemented for any game yet, including $($game.ShortName). The controls below are a disabled preview of the planned layout only.")) | Out-Null

    $card = New-NFCard
    switch ($game.Id) {
        'minecraft' {
            $card.Body.Children.Add((New-NFSectionHeader -Title "Skin" -NoMarginBottom)) | Out-Null
            $card.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 12 })) | Out-Null
            $card.Body.Children.Add((New-NFPathPickerRow -Label "Skin file (.png)" -Description "Planned. Not functional yet." -Enabled $false).Root) | Out-Null
            $card.Body.Children.Add((New-NFDropdownRow -Label "Model" -Description "Planned. Not functional yet." -Items @("Classic (Steve)","Slim (Alex)") -SelectedIndex 0 -Enabled $false).Root) | Out-Null
            $card.Body.Children.Add((New-NFPathPickerRow -Label "Cape file (optional)" -Description "Planned. Not functional yet." -Enabled $false).Root) | Out-Null
        }
        'botw' {
            $card.Body.Children.Add((New-NFSectionHeader -Title "Outfits & Model" -NoMarginBottom)) | Out-Null
            $card.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 12 })) | Out-Null
            $card.Body.Children.Add((New-NFDropdownRow -Label "Equipped outfit" -Description "Planned. Not functional yet." -Items @("Default Tunic") -SelectedIndex 0 -Enabled $false).Root) | Out-Null
            $card.Body.Children.Add((New-NFToggleRow -Label "Unlock amiibo-linked costumes" -Description "Planned. Not functional yet." -Enabled $false).Root) | Out-Null
        }
        default {
            $card.Body.Children.Add((New-NFSectionHeader -Title "Coming Later" -NoMarginBottom)) | Out-Null
            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.Style = Get-NFRes 'Text.Secondary'
            $tb.Margin = "0,8,0,0"
            $tb.Text = "Depending on the game, this may include outfit/model swaps, skins, palette edits, or other costume data. Nothing is built here yet -- this screen exists to show where it will live."
            $card.Body.Children.Add($tb) | Out-Null
        }
    }
    $root.Children.Add($card.Root) | Out-Null

    return $root
}
