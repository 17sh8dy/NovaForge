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
        },
        [PSCustomObject]@{
            Id            = 'splatoon-3'
            Name          = 'Splatoon 3'
            ShortName     = 'Splatoon 3'
            Platform      = 'Nintendo Switch'
            PlatformGroup = 'Nintendo'
            Icon          = [System.Char]::ConvertFromUtf32(0x1F991)
            Supported     = $false
            ValidatorPrefix = $null
            Emulators     = @($script:NF_Emu.Ryubing)
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
