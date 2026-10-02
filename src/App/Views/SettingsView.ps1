# SettingsView.ps1
# App-level settings: general, legal & disclaimers, and data locations.
# This view is game-agnostic and always reachable, even before a game is chosen.

function New-NFSettingsView {
    param([string]$Tab = 'General')

    $root = New-Object System.Windows.Controls.StackPanel
    $root.Children.Add((New-NFSectionHeader -Title "Settings")) | Out-Null

    # --- Tab strip ---
    $tabs = @('General', 'Legal', 'Data')
    $tabLabels = @{ General = 'General'; Legal = 'Legal & Disclaimers'; Data = 'About & Data' }
    $tabStrip = New-Object System.Windows.Controls.StackPanel
    $tabStrip.Orientation = 'Horizontal'
    $tabStrip.Margin = "0,0,0,16"
    foreach ($t in $tabs) {
        $b = New-Object System.Windows.Controls.Button
        $b.Content = $tabLabels[$t]
        $b.Margin = "0,0,8,0"
        $b.Style = if ($t -eq $Tab) { Get-NFRes 'Btn.Primary' } else { Get-NFRes 'Btn.Secondary' }
        $capturedTab = $t
        $b.Add_Click({ Show-NFView -Section 'Settings' -SettingsTab $capturedTab }.GetNewClosure()) | Out-Null
        $tabStrip.Children.Add($b) | Out-Null
    }
    $root.Children.Add($tabStrip) | Out-Null

    switch ($Tab) {
        'Legal' {
            $card = New-NFCard
            $card.Body.Children.Add((New-NFSectionHeader -Title "Legal & Disclaimers" -Subtitle "Full text also available at LEGAL.md in the Nova Forge folder." -NoMarginBottom)) | Out-Null
            $card.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 10 })) | Out-Null

            $legalPath = Join-Path $Global:NF_Root 'LEGAL.md'
            $legalText = if (Test-Path -LiteralPath $legalPath) { Get-Content -LiteralPath $legalPath -Raw -Encoding UTF8 } else { "Legal notice file not found." }

            $tb = New-Object System.Windows.Controls.TextBox
            $tb.Text = $legalText
            $tb.IsReadOnly = $true
            $tb.TextWrapping = 'Wrap'
            $tb.AcceptsReturn = $true
            $tb.Background = Get-NFRes 'Brush.PanelBg'
            $tb.Foreground = Get-NFRes 'Brush.TextSecondary'
            $tb.BorderThickness = 0
            $tb.FontSize = 12
            $tb.Padding = 12
            $tb.MaxHeight = 420
            $tb.VerticalScrollBarVisibility = 'Auto'
            $card.Body.Children.Add($tb) | Out-Null
            $root.Children.Add($card.Root) | Out-Null
        }
        'Data' {
            $card = New-NFCard
            $card.Body.Children.Add((New-NFSectionHeader -Title "About" -NoMarginBottom)) | Out-Null
            $aboutTb = New-Object System.Windows.Controls.TextBlock
            $aboutTb.Style = Get-NFRes 'Text.Secondary'
            $aboutTb.Margin = "0,8,0,0"
            $aboutTb.Text = "Nova Forge $($Global:NF_Version) - Prototype build. Independent game customization and mod management toolkit. Nova Forge is independently developed and is not affiliated with, sponsored by, or endorsed by any third-party company, organization, or rights holder."
            $card.Body.Children.Add($aboutTb) | Out-Null
            $root.Children.Add($card.Root) | Out-Null

            $dataCard = New-NFCard
            $dataCard.Body.Children.Add((New-NFSectionHeader -Title "Local Data Locations" -Subtitle "Everything Nova Forge stores lives on this PC, under the app folder." -NoMarginBottom)) | Out-Null
            $dataCard.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 10 })) | Out-Null

            $paths = @(
                @{ Label = "Profiles"; Path = $Global:NF_ProfilesDir }
                @{ Label = "Mod catalog"; Path = $Global:NF_ModsDir }
                @{ Label = "Backups"; Path = $Global:NF_BackupsDir }
            )
            foreach ($p in $paths) {
                $row = New-Object System.Windows.Controls.Grid
                $row.Margin = "0,0,0,10"
                $c0 = New-Object System.Windows.Controls.ColumnDefinition; $c0.Width = '*'
                $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = 'Auto'
                $row.ColumnDefinitions.Add($c0) | Out-Null
                $row.ColumnDefinitions.Add($c1) | Out-Null

                $stack = New-Object System.Windows.Controls.StackPanel
                $lbl = New-Object System.Windows.Controls.TextBlock
                $lbl.Style = Get-NFRes 'Text.Body'
                $lbl.Text = $p.Label
                $stack.Children.Add($lbl) | Out-Null
                $pathTb = New-Object System.Windows.Controls.TextBlock
                $pathTb.Style = Get-NFRes 'Text.Muted'
                $pathTb.Text = $p.Path
                $stack.Children.Add($pathTb) | Out-Null
                $row.Children.Add($stack) | Out-Null

                $openBtn = New-Object System.Windows.Controls.Button
                $openBtn.Content = "Open"
                $openBtn.Style = Get-NFRes 'Btn.Secondary'
                [System.Windows.Controls.Grid]::SetColumn($openBtn, 1)
                $capturedPath = $p.Path
                $openBtn.Add_Click({ Start-Process explorer.exe $capturedPath }.GetNewClosure()) | Out-Null
                $row.Children.Add($openBtn) | Out-Null

                $dataCard.Body.Children.Add($row) | Out-Null
            }
            $root.Children.Add($dataCard.Root) | Out-Null
        }
        default {
            $card = New-NFCard
            $card.Body.Children.Add((New-NFSectionHeader -Title "Appearance" -NoMarginBottom)) | Out-Null
            $card.Body.Children.Add((New-Object System.Windows.Controls.Border -Property @{ Height = 10 })) | Out-Null
            $card.Body.Children.Add((New-NFDropdownRow -Label "Theme" -Description "Light mode is not implemented yet." -Items @("Dark","Light (coming soon)") -SelectedIndex 0 -Enabled $false).Root) | Out-Null

            $accentPresets = @(Get-NFAccentPresets)
            $accentNames = @($accentPresets | ForEach-Object { $_.Name })
            $settingsCfg = Get-NFConfig
            $currentAccentIndex = [Math]::Max(0, [array]::IndexOf($accentNames, $settingsCfg.accentColor))
            $accentRow = New-NFDropdownRow -Label "Accent Color" -Description "Changes Nova Forge's highlight color throughout the app." -Items $accentNames -SelectedIndex $currentAccentIndex -Enabled $true
            $accentRow.ComboBox.Add_SelectionChanged({
                $selectedName = $accentRow.ComboBox.SelectedItem
                if ($selectedName -and $selectedName -ne $settingsCfg.accentColor) {
                    Set-NFAccentColor -Name $selectedName
                    $c = Get-NFConfig
                    $c.accentColor = $selectedName
                    Save-NFConfig -Config $c
                    Show-NFView -Section 'Settings' -SettingsTab 'General'
                }
            }.GetNewClosure()) | Out-Null
            $card.Body.Children.Add($accentRow.Root) | Out-Null
            $root.Children.Add($card.Root) | Out-Null

            $resetCard = New-NFCard
            $resetCard.Body.Children.Add((New-NFSectionHeader -Title "Reset" -NoMarginBottom)) | Out-Null
            $resetTb = New-Object System.Windows.Controls.TextBlock
            $resetTb.Style = Get-NFRes 'Text.Secondary'
            $resetTb.Margin = "0,8,0,10"
            $resetTb.Text = "Clearing Nova Forge's local data (profiles, mod catalog entries, backup index) is not implemented yet in this prototype."
            $resetCard.Body.Children.Add($resetTb) | Out-Null
            $resetBtn = New-Object System.Windows.Controls.Button
            $resetBtn.Content = "Reset Local Data (not implemented)"
            $resetBtn.Style = Get-NFRes 'Btn.Secondary'
            $resetBtn.IsEnabled = $false
            $resetCard.Body.Children.Add($resetBtn) | Out-Null
            $root.Children.Add($resetCard.Root) | Out-Null
        }
    }

    return $root
}
