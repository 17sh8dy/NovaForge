# ConfigService.ps1
# App-level configuration (theme, last active game/profile, window state).
# Storage: <root>\config.json

function Get-NFConfig {
    $cfg = $null
    if (Test-Path -LiteralPath $Global:NF_ConfigPath) {
        try {
            $raw = Get-Content -LiteralPath $Global:NF_ConfigPath -Raw -Encoding UTF8
            if ($raw) { $cfg = $raw | ConvertFrom-Json }
        } catch {
            Write-Warning "Config file was unreadable, falling back to defaults: $_"
        }
    }
    if (-not $cfg) {
        $cfg = [PSCustomObject]@{
            name                 = "Nova Forge"
            version              = "0.1.0"
            theme                = "dark"
            activeGameId         = $null
            activeProfileId      = @{}
            acceptedLegalNotice  = $false
            accentColor          = 'Cyan'
            games                = @()
        }
    }
    # Backfill fields for configs created by earlier/placeholder versions.
    if (-not (Get-Member -InputObject $cfg -Name 'activeProfileId' -MemberType NoteProperty)) {
        $cfg | Add-Member -NotePropertyName 'activeProfileId' -NotePropertyValue @{}
    }
    if (-not (Get-Member -InputObject $cfg -Name 'acceptedLegalNotice' -MemberType NoteProperty)) {
        $cfg | Add-Member -NotePropertyName 'acceptedLegalNotice' -NotePropertyValue $false
    }
    if (-not (Get-Member -InputObject $cfg -Name 'activeGameId' -MemberType NoteProperty)) {
        $cfg | Add-Member -NotePropertyName 'activeGameId' -NotePropertyValue $null
    }
    if (-not (Get-Member -InputObject $cfg -Name 'accentColor' -MemberType NoteProperty)) {
        $cfg | Add-Member -NotePropertyName 'accentColor' -NotePropertyValue 'Cyan'
    }
    return $cfg
}

function Save-NFConfig {
    param([Parameter(Mandatory)]$Config)
    $json = $Config | ConvertTo-Json -Depth 8
    Set-Content -LiteralPath $Global:NF_ConfigPath -Value $json -Encoding UTF8
}

function Get-NFActiveProfileId {
    param([Parameter(Mandatory)][string]$GameId)
    $cfg = Get-NFConfig
    if ($cfg.activeProfileId -is [System.Management.Automation.PSCustomObject]) {
        $prop = Get-Member -InputObject $cfg.activeProfileId -Name $GameId -MemberType NoteProperty
        if ($prop) { return $cfg.activeProfileId.$GameId }
    } elseif ($cfg.activeProfileId -is [hashtable]) {
        if ($cfg.activeProfileId.ContainsKey($GameId)) { return $cfg.activeProfileId[$GameId] }
    }
    return $null
}

function Set-NFActiveProfileId {
    param([Parameter(Mandatory)][string]$GameId, [Parameter(Mandatory)][string]$ProfileId)
    $cfg = Get-NFConfig
    if ($cfg.activeProfileId -isnot [System.Management.Automation.PSCustomObject]) {
        $cfg.activeProfileId = [PSCustomObject]@{}
    }
    if (Get-Member -InputObject $cfg.activeProfileId -Name $GameId -MemberType NoteProperty) {
        $cfg.activeProfileId.$GameId = $ProfileId
    } else {
        $cfg.activeProfileId | Add-Member -NotePropertyName $GameId -NotePropertyValue $ProfileId
    }
    Save-NFConfig -Config $cfg
}
