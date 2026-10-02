# ModService.ps1
# Organizational metadata about mods a user manages themselves. Nova Forge does NOT
# copy, inject, patch, or otherwise apply these files to any game installation yet.
# Storage: <root>\mods\<gameId>\<profileId>\mods.json

function Get-NFModDir {
    param([Parameter(Mandatory)][string]$GameId, [Parameter(Mandatory)][string]$ProfileId)
    $dir = Join-Path (Join-Path $Global:NF_ModsDir $GameId) $ProfileId
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return $dir
}

function Get-NFMods {
    param([Parameter(Mandatory)][string]$GameId, [Parameter(Mandatory)][string]$ProfileId)
    $dir = Get-NFModDir -GameId $GameId -ProfileId $ProfileId
    $path = Join-Path $dir 'mods.json'
    if (Test-Path -LiteralPath $path) {
        try {
            $data = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
            return @($data)
        } catch {
            Write-Warning "Mod list was unreadable: $_"
        }
    }
    return @()
}

function Save-NFMods {
    param(
        [Parameter(Mandatory)][string]$GameId,
        [Parameter(Mandatory)][string]$ProfileId,
        [Parameter(Mandatory)][AllowEmptyCollection()][array]$Mods
    )
    $dir = Get-NFModDir -GameId $GameId -ProfileId $ProfileId
    $path = Join-Path $dir 'mods.json'
    ($Mods | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $path -Encoding UTF8
}

function New-NFModEntry {
    param(
        [Parameter(Mandatory)][string]$GameId,
        [Parameter(Mandatory)][string]$ProfileId,
        [Parameter(Mandatory)][string]$Name,
        [string]$Notes = "",
        [string]$SourcePath = $null
    )
    $mods = @(Get-NFMods -GameId $GameId -ProfileId $ProfileId)
    $entry = [PSCustomObject]@{
        id         = [guid]::NewGuid().ToString()
        name       = $Name
        notes      = $Notes
        sourcePath = $SourcePath
        enabled    = $true
        addedUtc   = (Get-Date).ToUniversalTime().ToString('o')
    }
    $mods += $entry
    Save-NFMods -GameId $GameId -ProfileId $ProfileId -Mods $mods
    return $entry
}

function Remove-NFModEntry {
    param(
        [Parameter(Mandatory)][string]$GameId,
        [Parameter(Mandatory)][string]$ProfileId,
        [Parameter(Mandatory)][string]$ModId
    )
    $mods = @(Get-NFMods -GameId $GameId -ProfileId $ProfileId | Where-Object { $_.id -ne $ModId })
    Save-NFMods -GameId $GameId -ProfileId $ProfileId -Mods $mods
}
