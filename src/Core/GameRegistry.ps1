# GameRegistry.ps1
# The single list of games Nova Forge knows about. Adding a new game means adding
# an entry here (and, once real functionality exists for it, a module under
# src\Games\<id>\) -- the shared shell and views never hardcode a game name.
#
# The game selector groups games into big per-platform sections using
# `PlatformGroup` below. GameSelectorView.ps1's platform list must include a
# matching entry for a new group to show up (e.g. adding a PC game with
# PlatformGroup 'PC/Linux' will populate the existing PC/Linux section).

# Suggested emulators, per system. Nova Forge is not an emulator and bundles none -- these
# are links to actively maintained projects only. Discontinued projects (e.g. Yuzu, the
# original Ryujinx) are deliberately NOT listed. Re-check each entry before a release.
$script:NF_Emu = @{
    Cemu = [PSCustomObject]@{
        Name = 'Cemu'; System = 'Wii U'; Url = 'https://cemu.info/'
        Note = 'Actively maintained open-source Wii U emulator.'
    }
    Ryubing = [PSCustomObject]@{
        Name = 'Ryubing (Ryujinx)'; System = 'Switch'; Url = 'https://ryujinx.app/'
        Note = 'The actively maintained continuation of Ryujinx. The original Ryujinx project was discontinued.'
    }
}

# "Don't have the game yet?" -- shown per game. Nova Forge never sells, provides or hosts game copies
# (not even free ones); these are official stores and, for Nintendo titles, guides for dumping a copy
# you own from your own console. Re-check every link before a release.
$script:NF_NoCopiesNote = "Nova Forge does not sell or provide copies of any third-party game -- not even free ones. You need your own legally obtained copy."
$script:NF_NintendoNote = "Nintendo games can only be used on PC from a dump of a copy you own, made from your own console. Nova Forge does not provide dumps, keys, or firmware."
$script:NF_Get = @{
    BotwStore = @{ Label = 'Buy Breath of the Wild (Nintendo)'; Url = 'https://www.nintendo.com/us/store/products/the-legend-of-zelda-breath-of-the-wild-switch/' }
    SmoStore  = @{ Label = 'Buy Super Mario Odyssey (Nintendo)'; Url = 'https://www.nintendo.com/us/store/products/super-mario-odyssey-switch/' }
    SwitchDump = @{ Label = 'Guide: dumping Switch games (GameBanana tutorial)'; Url = 'https://gamebanana.com/tuts/19858' }
    WiiUDump  = @{ Label = 'Guide: dumping Wii U games for Cemu (Dumpling)'; Url = 'https://cemu.cfw.guide/using-dumpling.html' }
    McDownload = @{ Label = 'Minecraft: Java Edition - download / buy (minecraft.net)'; Url = 'https://www.minecraft.net/en-us/download' }
    McStore   = @{ Label = 'Minecraft: Java Edition - Microsoft Store'; Url = 'https://apps.microsoft.com/detail/9pj8266bhfwn?hl=en-US&gl=US' }
}

function Get-NFGames {
    return @(
        [PSCustomObject]@{
            Id            = 'botw'
            Name          = 'The Legend of Zelda: Breath of the Wild'
            ShortName     = 'BOTW'
            Platform      = 'Nintendo Switch / Wii U'
            PlatformGroup = 'Nintendo'
            Icon          = [System.Char]::ConvertFromUtf32(0x1F5E1)
            Supported     = $true
            ValidatorPrefix = 'Botw'
            Emulators     = @($script:NF_Emu.Cemu, $script:NF_Emu.Ryubing)
            # Sections shown in this game's own sidebar (Overview and Profiles always show).
            Sections      = @('GameSettings', 'Character', 'Mods', 'SaveManagement')
            GetGameNote   = "$($script:NF_NoCopiesNote) $($script:NF_NintendoNote)"
            GetGameLinks  = @($script:NF_Get.BotwStore, $script:NF_Get.WiiUDump, $script:NF_Get.SwitchDump)
        },
        [PSCustomObject]@{
            Id            = 'totk'
            Name          = 'The Legend of Zelda: Tears of the Kingdom'
            ShortName     = 'TOTK'
            Platform      = 'Nintendo Switch'
            PlatformGroup = 'Nintendo'
            Icon          = [System.Char]::ConvertFromUtf32(0x1F3DD)
            Supported     = $false
            ValidatorPrefix = $null
            Emulators     = @($script:NF_Emu.Ryubing)
            Sections      = @()
            GetGameNote   = "$($script:NF_NoCopiesNote) $($script:NF_NintendoNote)"
            GetGameLinks  = @($script:NF_Get.SwitchDump)
        },
        [PSCustomObject]@{
            Id            = 'mario-odyssey'
            Name          = 'Super Mario Odyssey'
            ShortName     = 'Odyssey'
            Platform      = 'Nintendo Switch'
            PlatformGroup = 'Nintendo'
            Icon          = [System.Char]::ConvertFromUtf32(0x1F344)
            Supported     = $true
            ValidatorPrefix = $null
            Emulators     = @($script:NF_Emu.Ryubing)
            # No Game Settings / Character Customization: Odyssey has none planned yet (Moonrush is cataloged under Mods).
            Sections      = @('Mods', 'SaveManagement')
            GetGameNote   = "$($script:NF_NoCopiesNote) $($script:NF_NintendoNote)"
            GetGameLinks  = @($script:NF_Get.SmoStore, $script:NF_Get.SwitchDump)
        },
        [PSCustomObject]@{
            Id            = 'minecraft'
            Name          = 'Minecraft: Java Edition'
            ShortName     = 'Minecraft'
            Platform      = 'PC / Linux (Java Edition)'
            PlatformGroup = 'PC/Linux'
            Icon          = [System.Char]::ConvertFromUtf32(0x26CF)
            Supported     = $true
            ValidatorPrefix = 'Minecraft'
            Emulators     = @()
            Sections      = @('GameSettings', 'Character', 'Mods', 'SaveManagement')
            GetGameNote   = $script:NF_NoCopiesNote
            GetGameLinks  = @($script:NF_Get.McDownload, $script:NF_Get.McStore)
        }
    )
}

function Get-NFGame {
    param([Parameter(Mandatory)][string]$Id)
    return (Get-NFGames | Where-Object { $_.Id -eq $Id } | Select-Object -First 1)
}

# Dispatches to a game module's Test-NF<Prefix><Kind>Folder function (resolved by
# name so GameRegistry never has to load-order-depend on any specific game module).
# Games without a ValidatorPrefix, or without that particular Kind implemented,
# fall back to "the folder exists" -- honest rather than pretending to validate.
function Test-NFGameFolder {
    param(
        [Parameter(Mandatory)]$Game,
        [Parameter(Mandatory)][ValidateSet('Game', 'Update', 'Dlc')][string]$Kind,
        [Parameter(Mandatory)][string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return [PSCustomObject]@{ Valid = $false; Reason = "That folder doesn't exist." }
    }
    if ($Game.ValidatorPrefix) {
        $fnName = "Test-NF$($Game.ValidatorPrefix)$($Kind)Folder"
        $cmd = Get-Command $fnName -ErrorAction SilentlyContinue
        if ($cmd) { return (& $cmd -Path $Path) }
    }
    return [PSCustomObject]@{ Valid = $true; Reason = "" }
}
