# ProfileService.ps1
# Per-game user profiles: local configuration only (game directory, DLC/update
# directories, save directory, notes).
# Storage: <root>\profiles\<gameId>\<profileId>.json

function Get-NFProfileDir {
    param([Parameter(Mandatory)][string]$GameId)
    $dir = Join-Path $Global:NF_ProfilesDir $GameId
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return $dir
}

function Add-NFProfileFieldBackfill {
    param([Parameter(Mandatory)]$Profile)
    # Profiles saved before DLC/update-directory support won't have these
    # NoteProperties; Set-StrictMode makes plain dot-access to a missing one risky.
    foreach ($field in @('dlcDirectory', 'updateDirectory', 'previousGameDirectory', 'previousDlcDirectory', 'previousUpdateDirectory')) {
        if (-not (Get-Member -InputObject $Profile -Name $field -MemberType NoteProperty)) {
            $Profile | Add-Member -NotePropertyName $field -NotePropertyValue $null
        }
    }
    return $Profile
}

function Get-NFProfiles {
    param([Parameter(Mandatory)][string]$GameId)
    $dir = Get-NFProfileDir -GameId $GameId
    $results = @()
    Get-ChildItem -LiteralPath $dir -Filter '*.json' -File -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $p = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            $results += (Add-NFProfileFieldBackfill -Profile $p)
        } catch {
            Write-Warning "Skipped unreadable profile file: $($_.FullName)"
        }
    }
    return @($results | Sort-Object -Property createdUtc)
}

function New-NFProfile {
    param(
        [Parameter(Mandatory)][string]$GameId,
        [Parameter(Mandatory)][string]$Name
    )
    $now = (Get-Date).ToUniversalTime().ToString('o')
    $profile = [PSCustomObject]@{
        id                     = [guid]::NewGuid().ToString()
        gameId                 = $GameId
        name                   = $Name
        gameDirectory          = $null
        dlcDirectory           = $null
        updateDirectory        = $null
        previousGameDirectory  = $null
        previousDlcDirectory   = $null
        previousUpdateDirectory = $null
        saveDirectory          = $null
        notes                  = ""
        createdUtc             = $now
        modifiedUtc            = $now
    }
    Save-NFProfile -Profile $profile
    return $profile
}

function Save-NFProfile {
    param([Parameter(Mandatory)]$Profile)
    $Profile.modifiedUtc = (Get-Date).ToUniversalTime().ToString('o')
    $dir = Get-NFProfileDir -GameId $Profile.gameId
    $path = Join-Path $dir "$($Profile.id).json"
    ($Profile | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $path -Encoding UTF8
}

function Rename-NFProfile {
    param(
        [Parameter(Mandatory)][string]$GameId,
        [Parameter(Mandatory)][string]$ProfileId,
        [Parameter(Mandatory)][string]$NewName
    )
    $profile = Get-NFProfile -GameId $GameId -ProfileId $ProfileId
    if (-not $profile) { return }
    $profile.name = $NewName
    Save-NFProfile -Profile $profile
}

function Remove-NFProfile {
    param([Parameter(Mandatory)][string]$GameId, [Parameter(Mandatory)][string]$ProfileId)
    $dir = Get-NFProfileDir -GameId $GameId
    $path = Join-Path $dir "$ProfileId.json"
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
}

function Get-NFProfile {
    param([Parameter(Mandatory)][string]$GameId, [Parameter(Mandatory)][string]$ProfileId)
    $dir = Get-NFProfileDir -GameId $GameId
    $path = Join-Path $dir "$ProfileId.json"
    if (Test-Path -LiteralPath $path) {
        $p = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        return (Add-NFProfileFieldBackfill -Profile $p)
    }
    return $null
}
