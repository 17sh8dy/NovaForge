# BotwModule.ps1
# Game-specific static content and feature flags for Breath of the Wild.
# Keeping this separate from src\App keeps the shared shell game-agnostic:
# supporting a new game means writing a module like this one, not touching
# the sidebar, navigation, or view shells.

$Global:NF_BotwInfo = [PSCustomObject]@{
    GameId       = 'botw'
    Description  = "Breath of the Wild is Nova Forge's first supported title. This prototype builds the interface and local storage foundation -- game-specific config editing, character customization, and mod installation are not implemented yet."
    EmulationNote = "Nova Forge is not an emulator and does not include or provide one. Running Breath of the Wild on PC requires your own legally obtained copy and a currently supported, actively maintained Switch emulator that you install and configure yourself. Discontinued projects (e.g. Yuzu) are not supported or recommended."
    SaveLocationNote = "Save data location depends on how you run the game (real hardware, or an emulator) and is not auto-detected. Point Nova Forge at the folder yourself in Save Management."
    Features = [PSCustomObject]@{
        GameSettings           = @{ Status = 'planned'; Note = 'In-game / config value editing is not implemented yet.' }
        CharacterCustomization = @{ Status = 'planned'; Note = 'No customization pipeline exists yet for this title.' }
        Mods                   = @{ Status = 'organize-only'; Note = 'You can catalog mods you manage yourself. Nova Forge does not install, inject, or patch files yet.' }
        SaveManagement         = @{ Status = 'backup-only'; Note = 'Backing up a save folder is implemented. Restoring is not implemented yet.' }
    }
}

# --- Folder validation ---
# Real Wii U game/update dumps (the layout Cemu expects) always have code/content/meta
# subfolders. DLC (add-on content) dumps have the same code/content/meta shape, but
# their content folder holds numbered pack folders (e.g. 0010, 0011) instead of the
# game's normal named content tree (Actor, Map, System, ...) -- that's what tells DLC
# apart from a base game or update dump here.

function Test-NFBotwGameFolder {
    param([Parameter(Mandatory)][string]$Path)
    foreach ($sub in @('code', 'content', 'meta')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $sub) -PathType Container)) {
            return [PSCustomObject]@{
                Valid  = $false
                Reason = "That doesn't look like a Breath of the Wild dump folder. Nova Forge expects to find 'code', 'content', and 'meta' subfolders here (the standard Wii U game-dump layout Cemu uses) -- '$sub' is missing."
            }
        }
    }
    return [PSCustomObject]@{ Valid = $true; Reason = "" }
}

function Test-NFBotwUpdateFolder {
    param([Parameter(Mandatory)][string]$Path)
    foreach ($sub in @('code', 'content', 'meta')) {
        if (-not (Test-Path -LiteralPath (Join-Path $Path $sub) -PathType Container)) {
            return [PSCustomObject]@{
                Valid  = $false
                Reason = "That doesn't look like a Breath of the Wild update dump. Nova Forge expects 'code', 'content', and 'meta' subfolders here, the same layout as the base game dump -- '$sub' is missing."
            }
        }
    }
    return [PSCustomObject]@{ Valid = $true; Reason = "" }
}

function Test-NFBotwDlcFolder {
    param([Parameter(Mandatory)][string]$Path)
    $contentDir = Join-Path $Path 'content'
    if (-not (Test-Path -LiteralPath $contentDir -PathType Container)) {
        return [PSCustomObject]@{
            Valid  = $false
            Reason = "That doesn't look like a Breath of the Wild DLC folder. Nova Forge expects a 'content' subfolder here (the standard Wii U add-on-content layout)."
        }
    }
    $hasNumberedPack = @(Get-ChildItem -LiteralPath $contentDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d+$' }).Count -gt 0
    if (-not $hasNumberedPack) {
        return [PSCustomObject]@{
            Valid  = $false
            Reason = "That 'content' folder doesn't look like DLC -- Nova Forge expects numbered pack subfolders inside it (e.g. 0010, 0011), not the base game's content tree."
        }
    }
    return [PSCustomObject]@{ Valid = $true; Reason = "" }
}
