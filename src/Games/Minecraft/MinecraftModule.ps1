# MinecraftModule.ps1
# Game-specific static content and feature flags for Minecraft: Java Edition.
# Keeping this separate from src\App keeps the shared shell game-agnostic --
# supporting a new game means writing a module like this one, not touching the
# sidebar, navigation, or view shells.

$Global:NF_MinecraftInfo = [PSCustomObject]@{
    GameId       = 'minecraft'
    Description  = "Minecraft: Java Edition is Nova Forge's first supported PC/Linux title. This prototype builds the interface and local storage foundation -- mod loader integration and world/save editing are not implemented yet."
    Features = [PSCustomObject]@{
        GameSettings           = @{ Status = 'planned'; Note = 'Options/config editing is not implemented yet for this title.' }
        CharacterCustomization = @{ Status = 'planned'; Note = 'Skin management is not implemented yet.' }
        Mods                   = @{ Status = 'organize-only'; Note = 'You can catalog mods you manage yourself. Nova Forge does not install a mod loader (Forge/Fabric/Quilt) or download mods for you.' }
        SaveManagement         = @{ Status = 'backup-only'; Note = 'Backing up a world/save folder is implemented. Restoring is not implemented yet.' }
    }
}

# --- Folder validation ---
# A real .minecraft install always has a 'versions' folder (created the first
# time the official launcher runs, vanilla or modded) -- that's the one signal
# that's true across every install and every mod loader, so it's what's checked
# for the base game folder. Update/DLC concepts don't map onto Minecraft, so
# those pickers fall back to the generic "folder exists" check.

function Test-NFMinecraftGameFolder {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath (Join-Path $Path 'versions') -PathType Container)) {
        return [PSCustomObject]@{
            Valid  = $false
            Reason = "That doesn't look like a .minecraft folder. Nova Forge expects a 'versions' subfolder here (created the first time the Minecraft launcher runs)."
        }
    }
    return [PSCustomObject]@{ Valid = $true; Reason = "" }
}
