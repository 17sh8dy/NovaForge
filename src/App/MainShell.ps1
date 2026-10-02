# MainShell.ps1
# Wires the static shell (MainWindow.xaml) to state + views. Keeps the shell
# itself game-agnostic: it only knows "there is a current game/profile or not".

$Global:NF_State = [PSCustomObject]@{
    CurrentGameId    = $null
    CurrentProfileId = $null
    CurrentSection   = 'Overview'
    InGame           = $false
    CurrentSettingsTab = 'General'
}

function Initialize-NFShell {
    $Global:NF_Nav = @{
        Home      = $Global:NF_Window.FindName('NavHome')
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

    $Global:NF_GameNavHeader = $Global:NF_Window.FindName('GameNavHeader')
    $Global:NF_NavGameTitle = $Global:NF_Window.FindName('NavGameTitle')
    $Global:NF_Window.FindName('NavBack').Add_Click({ Show-NFGameSelector }) | Out-Null
    $Global:NF_Nav.Home.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFGameSelector } }) | Out-Null
    $Global:NF_Window.FindName('BrandHomeButton').Add_Click({ Show-NFGameSelector }) | Out-Null
    $Global:NF_Window.FindName('LegalHeaderButton').Add_Click({ Show-NFView -Section 'Settings' -SettingsTab 'Legal' }) | Out-Null

    $Global:NF_Nav.Overview.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Overview' } }) | Out-Null
    $Global:NF_Nav.GameSettings.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'GameSettings' } }) | Out-Null
    $Global:NF_Nav.Character.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Character' } }) | Out-Null
    $Global:NF_Nav.Mods.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Mods' } }) | Out-Null
    $Global:NF_Nav.Saves.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'SaveManagement' } }) | Out-Null
    $Global:NF_Nav.Profiles.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Profiles' } }) | Out-Null
    $Global:NF_Nav.Settings.Add_Checked({ if ($Global:NF_SuppressNav -ne $true) { Show-NFView -Section 'Settings' } }) | Out-Null

    # Always start at Home: pick a game and a profile there. (Each game then has its own sidebar.)
    Show-NFGameSelector
}

function Update-NFChrome {
    # Home shows only Home + Settings. Inside a game, the sidebar shows that game's own
    # sections (Game.Sections in Core\GameRegistry.ps1) plus Overview and Profiles.
    $nav = $Global:NF_Nav
    $inGame = ($Global:NF_State.InGame -and $Global:NF_State.CurrentGameId)
    $gameKeys = @{ GameSettings = 'GameSettings'; Character = 'Character'; Mods = 'Mods'; Saves = 'SaveManagement' }

    if ($inGame) {
        $game = Get-NFGame -Id $Global:NF_State.CurrentGameId
        $profile = if ($Global:NF_State.CurrentProfileId) { Get-NFProfile -GameId $game.Id -ProfileId $Global:NF_State.CurrentProfileId } else { $null }
        $Global:NF_ActiveProfileText.Text = if ($profile) { "$($game.ShortName)  -  Profile: $($profile.name)" } else { "No profile selected" }
        $sections = if (Get-Member -InputObject $game -Name 'Sections' -MemberType NoteProperty) { @($game.Sections) } else { @() }

        $Global:NF_GameNavHeader.Visibility = 'Visible'
        $Global:NF_NavGameTitle.Text = $game.Name
        $nav.Home.Visibility = 'Collapsed'
        $nav.Overview.Visibility = 'Visible'
        $nav.Profiles.Visibility = 'Visible'
        foreach ($key in $gameKeys.Keys) {
            $nav[$key].Visibility = if ($sections -contains $gameKeys[$key]) { 'Visible' } else { 'Collapsed' }
        }
    } else {
        $Global:NF_ActiveProfileText.Text = ""
        $Global:NF_GameNavHeader.Visibility = 'Collapsed'
        $nav.Home.Visibility = 'Visible'
        foreach ($key in @('Overview', 'Profiles') + @($gameKeys.Keys)) { $nav[$key].Visibility = 'Collapsed' }
    }
}

function Set-NFActiveGame {
    param([Parameter(Mandatory)][string]$GameId, [switch]$Silent)

    $Global:NF_State.CurrentGameId = $GameId
    $Global:NF_State.InGame = $true

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
    $Global:NF_State.InGame = $false
    $Global:NF_State.CurrentSection = 'Overview'
    $Global:NF_SuppressNav = $true
    foreach ($nav in $Global:NF_Nav.Values) { $nav.IsChecked = $false }
    $Global:NF_Nav.Home.IsChecked = $true
    $Global:NF_SuppressNav = $false
    Update-NFChrome
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

    $needsGame = $Section -in @('Overview','GameSettings','Character','Mods','SaveManagement','Profiles')
    if ($needsGame -and -not $Global:NF_State.InGame) {
        Show-NFGameSelector
        return
    }
    # A game only has the sections it declares; anything else falls back to its Overview.
    if ($Global:NF_State.InGame -and $Section -in @('GameSettings','Character','Mods','SaveManagement')) {
        $g = Get-NFGame -Id $Global:NF_State.CurrentGameId
        $gs = if (Get-Member -InputObject $g -Name 'Sections' -MemberType NoteProperty) { @($g.Sections) } else { @() }
        if ($gs -notcontains $Section) { $Section = 'Overview' }
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
