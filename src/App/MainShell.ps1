# MainShell.ps1
# Wires the static shell (MainWindow.xaml) to state + views. Keeps the shell
# itself game-agnostic: it only knows "there is a current game/profile or not".

$Global:NF_State = [PSCustomObject]@{
    CurrentGameId    = $null
    CurrentProfileId = $null
    CurrentSection   = 'Overview'
    CurrentSettingsTab = 'General'
}

function Initialize-NFShell {
    $Global:NF_Nav = @{
        Overview  = $Global:NF_Window.FindName('NavOverview')
        GameSettings = $Global:NF_Window.FindName('NavGameSettings')
        Character = $Global:NF_Window.FindName('NavCharacter')
        Mods      = $Global:NF_Window.FindName('NavMods')
        Saves     = $Global:NF_Window.FindName('NavSaves')
        Profiles  = $Global:NF_Window.FindName('NavProfiles')
        Settings  = $Global:NF_Window.FindName('NavSettings')
    }
    $Global:NF_Content = $Global:NF_Window.FindName('MainContent')
    $Global:NF_ActiveProfileText = $Global:NF_Window.FindName('ActiveProfileText')
    $Global:NF_StatusText = $Global:NF_Window.FindName('StatusText')

    $Global:NF_Window.FindName('BrandHomeButton').Add_Click({ Show-NFGameSelector }) | Out-Null
    $Global:NF_Window.FindName('LegalHeaderButton').Add_Click({ Show-NFView -Section 'Settings' -SettingsTab 'Legal' }) | Out-Null

    $Global:NF_Nav.Overview.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Overview' } }) | Out-Null
    $Global:NF_Nav.GameSettings.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'GameSettings' } }) | Out-Null
    $Global:NF_Nav.Character.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Character' } }) | Out-Null
    $Global:NF_Nav.Mods.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Mods' } }) | Out-Null
    $Global:NF_Nav.Saves.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'SaveManagement' } }) | Out-Null
    $Global:NF_Nav.Profiles.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Profiles' } }) | Out-Null
    $Global:NF_Nav.Settings.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Settings' } }) | Out-Null

    # --- Restore last session state ---
    $cfg = Get-NFConfig
    if ($cfg.activeGameId) {
        $game = Get-NFGame -Id $cfg.activeGameId
        if ($game -and $game.Supported) {
            Set-NFActiveGame -GameId $game.Id -Silent
        }
    }

    Update-NFChrome
    Show-NFView -Section $Global:NF_State.CurrentSection
}

function Update-NFChrome {
    if ($Global:NF_State.CurrentGameId) {
        $game = Get-NFGame -Id $Global:NF_State.CurrentGameId
        $profile = if ($Global:NF_State.CurrentProfileId) { Get-NFProfile -GameId $game.Id -ProfileId $Global:NF_State.CurrentProfileId } else { $null }
        $Global:NF_ActiveProfileText.Text = if ($profile) { "Profile: $($profile.name)" } else { "No profile selected" }

        foreach ($key in @('GameSettings','Character','Mods','Saves','Profiles')) {
            $Global:NF_Nav[$key].IsEnabled = $true
        }
        # Character Customization and Game Settings don't mean anything without an
        # active game, so they're hidden (not just grayed out) until one is chosen.
        $Global:NF_Nav.GameSettings.Visibility = 'Visible'
        $Global:NF_Nav.Character.Visibility = 'Visible'
    } else {
        $Global:NF_ActiveProfileText.Text = "No game selected"

        foreach ($key in @('GameSettings','Character','Mods','Saves','Profiles')) {
            $Global:NF_Nav[$key].IsEnabled = $false
        }
        $Global:NF_Nav.GameSettings.Visibility = 'Collapsed'
        $Global:NF_Nav.Character.Visibility = 'Collapsed'
    }
}

function Set-NFActiveGame {
    param([Parameter(Mandatory)][string]$GameId, [switch]$Silent)

    $Global:NF_State.CurrentGameId = $GameId

    $profiles = @(Get-NFProfiles -GameId $GameId)
    if ($profiles.Count -eq 0) {
        $profiles = @(New-NFProfile -GameId $GameId -Name "Default")
    }

    $activeId = Get-NFActiveProfileId -GameId $GameId
    $activeProfile = $null
    if ($activeId) { $activeProfile = $profiles | Where-Object { $_.id -eq $activeId } | Select-Object -First 1 }
    if (-not $activeProfile) { $activeProfile = $profiles[0] }

    $Global:NF_State.CurrentProfileId = $activeProfile.id

    $cfg = Get-NFConfig
    $cfg.activeGameId = $GameId
    Save-NFConfig -Config $cfg
    Set-NFActiveProfileId -GameId $GameId -ProfileId $activeProfile.id

    Update-NFChrome
    if (-not $Silent) {
        Show-NFView -Section 'Overview'
    }
}

function Set-NFActiveProfile {
    param([Parameter(Mandatory)][string]$ProfileId)
    $Global:NF_State.CurrentProfileId = $ProfileId
    Set-NFActiveProfileId -GameId $Global:NF_State.CurrentGameId -ProfileId $ProfileId
    Update-NFChrome
}

function Show-NFGameSelector {
    $Global:NF_SuppressNav = $true
    foreach ($nav in $Global:NF_Nav.Values) { $nav.IsChecked = $false }
    $Global:NF_SuppressNav = $false
    $Global:NF_Content.Content = New-NFGameSelectorView
    $Global:NF_StatusText.Text = "Choose a game to begin."
}

function Show-NFView {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Overview','GameSettings','Character','Mods','SaveManagement','Profiles','Settings')]
        [string]$Section,
        [string]$SettingsTab = 'General'
    )

    $Global:NF_State.CurrentSection = $Section
    $Global:NF_State.CurrentSettingsTab = $SettingsTab

    $Global:NF_SuppressNav = $true
    foreach ($nav in $Global:NF_Nav.Values) { $nav.IsChecked = $false }
    switch ($Section) {
        'Overview'       { $Global:NF_Nav.Overview.IsChecked = $true }
        'GameSettings'   { $Global:NF_Nav.GameSettings.IsChecked = $true }
        'Character'      { $Global:NF_Nav.Character.IsChecked = $true }
        'Mods'           { $Global:NF_Nav.Mods.IsChecked = $true }
        'SaveManagement' { $Global:NF_Nav.Saves.IsChecked = $true }
        'Profiles'       { $Global:NF_Nav.Profiles.IsChecked = $true }
        'Settings'       { $Global:NF_Nav.Settings.IsChecked = $true }
    }
    $Global:NF_SuppressNav = $false

    $needsGame = $Section -in @('GameSettings','Character','Mods','SaveManagement','Profiles')
    if ($needsGame -and -not $Global:NF_State.CurrentGameId) {
        $Global:NF_Content.Content = New-NFOverviewView
        return
    }

    $Global:NF_Content.Content = switch ($Section) {
        'Overview'       { New-NFOverviewView }
        'GameSettings'   { New-NFGameSettingsView }
        'Character'      { New-NFCharacterCustomizationView }
        'Mods'           { New-NFModsView }
        'SaveManagement' { New-NFSaveManagementView }
        'Profiles'       { New-NFProfilesView }
        'Settings'       { New-NFSettingsView -Tab $SettingsTab }
    }

    $Global:NF_StatusText.Text = "Ready."
}
