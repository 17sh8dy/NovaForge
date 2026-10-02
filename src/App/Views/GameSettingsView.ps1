# GameSettingsView.ps1
# Placeholder: demonstrates the reusable settings controls in a disabled preview
# state. No control here changes any real value yet -- config editing has not
# been implemented or tested for any game. What counts as "game settings" is
# different per game (servers/world rules for Minecraft, graphics/gameplay
# toggles for BOTW, ...), so the preview cards below are chosen per game.Id.

function New-NFGameSettingsView {
    $root = New-Object System.Windows.Controls.StackPanel
    $game = Get-NFGame -Id $Global:NF_State.CurrentGameId

    $root.Children.Add((New-NFSectionHeader -Title "Game Settings" -Subtitle "$($game.Name)")) | Out-Null
    $root.Children.Add((New-NFNotImplementedNote -Text "Game settings editing is not implemented yet for $($game.ShortName). The controls below are a disabled preview of the planned layout only -- nothing here reads or writes real game configuration.")) | Out-Null

    switch ($game.Id) {
        'minecraft' {
            $card = New-NFCard
            $card.Body.Children.Add((New-NFSectionHeader -Title "Servers" -NoMarginBottom)) | Out-Null
            $card.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 12 })) | Out-Null
            $card.Body.Children.Add((New-NFDropdownRow -Label "Default server" -Description "Planned. Not functional yet." -Items @("None added yet") -SelectedIndex 0 -Enabled $false).Root) | Out-Null
            $addServerBtn = New-NFSecondaryButton -Text "Add Server (planned)" -Enabled $false
            $card.Body.Children.Add($addServerBtn) | Out-Null
            $root.Children.Add($card.Root) | Out-Null

            $card2 = New-NFCard
            $card2.Body.Children.Add((New-NFSectionHeader -Title "World Options" -NoMarginBottom)) | Out-Null
            $card2.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 12 })) | Out-Null
            $card2.Body.Children.Add((New-NFDropdownRow -Label "Default difficulty" -Description "Planned. Not functional yet." -Items @("Peaceful","Easy","Normal","Hard") -SelectedIndex 2 -Enabled $false).Root) | Out-Null
            $card2.Body.Children.Add((New-NFToggleRow -Label "Keep inventory on death" -Description "Planned. Not functional yet." -Enabled $false).Root) | Out-Null
            $card2.Body.Children.Add((New-NFToggleRow -Label "Allow cheats / command blocks" -Description "Planned. Not functional yet." -Enabled $false).Root) | Out-Null
            $root.Children.Add($card2.Root) | Out-Null
        }
        'botw' {
            $card = New-NFCard
            $card.Body.Children.Add((New-NFSectionHeader -Title "Graphics & Performance" -NoMarginBottom)) | Out-Null
            $card.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 12 })) | Out-Null
            $card.Body.Children.Add((New-NFToggleRow -Label "Uncap frame rate" -Description "Planned. Not functional yet." -IsChecked $false -Enabled $false).Root) | Out-Null
            $card.Body.Children.Add((New-NFDropdownRow -Label "Resolution scale" -Description "Planned. Not functional yet." -Items @("Native","1.25x","1.5x","2x") -SelectedIndex 0 -Enabled $false).Root) | Out-Null
            $card.Body.Children.Add((New-NFToggleRow -Label "Disable motion blur" -Description "Planned. Not functional yet." -IsChecked $false -Enabled $false).Root) | Out-Null
            $root.Children.Add($card.Root) | Out-Null

            $card2 = New-NFCard
            $card2.Body.Children.Add((New-NFSectionHeader -Title "Gameplay" -NoMarginBottom)) | Out-Null
            $card2.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 12 })) | Out-Null
            $card2.Body.Children.Add((New-NFToggleRow -Label "Disable durability loss" -Description "Planned. Not functional yet." -IsChecked $false -Enabled $false).Root) | Out-Null
            $card2.Body.Children.Add((New-NFDropdownRow -Label "Difficulty preset" -Description "Planned. Not functional yet." -Items @("Default","Hard Mode") -SelectedIndex 0 -Enabled $false).Root) | Out-Null
            $root.Children.Add($card2.Root) | Out-Null
        }
        default {
            $card = New-NFCard
            $card.Body.Children.Add((New-NFSectionHeader -Title "Coming Later" -NoMarginBottom)) | Out-Null
            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.Style = Get-NFRes 'Text.Secondary'
            $tb.Margin = "0,8,0,0"
            $tb.Text = "Every game exposes different settings -- this screen exists to show where they'll live once a tested implementation exists for $($game.ShortName)."
            $card.Body.Children.Add($tb) | Out-Null
            $root.Children.Add($card.Root) | Out-Null
        }
    }

    return $root
}
