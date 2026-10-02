# BackupService.ps1
# Backups are strictly READ from the user's save location and WRITTEN into Nova Forge's
# own backups\ folder. Nova Forge never writes back into a game or save directory here.
# Restore is intentionally NOT implemented yet -- see Restore-NFBackup below.
# Storage: <root>\backups\<gameId>\<profileId>\<timestamp>\  + index.json

function Get-NFBackupDir {
    param([Parameter(Mandatory)][string]$GameId, [Parameter(Mandatory)][string]$ProfileId)
    $dir = Join-Path (Join-Path $Global:NF_BackupsDir $GameId) $ProfileId
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    return $dir
}

function Get-NFBackupIndexPath {
    param([Parameter(Mandatory)][string]$GameId, [Parameter(Mandatory)][string]$ProfileId)
    return Join-Path (Get-NFBackupDir -GameId $GameId -ProfileId $ProfileId) 'index.json'
}

function Get-NFBackups {
    param([Parameter(Mandatory)][string]$GameId, [Parameter(Mandatory)][string]$ProfileId)
    $idxPath = Get-NFBackupIndexPath -GameId $GameId -ProfileId $ProfileId
    if (Test-Path -LiteralPath $idxPath) {
        try {
            return @(Get-Content -LiteralPath $idxPath -Raw -Encoding UTF8 | ConvertFrom-Json)
        } catch {
            Write-Warning "Backup index was unreadable: $_"
        }
    }
    return @()
}

function New-NFBackup {
    <#
        Copies the contents of $SourcePath into a new timestamped folder under
        the profile's backup directory. Read-only against the source; the game
        or save directory is never modified.
    #>
    param(
        [Parameter(Mandatory)][string]$GameId,
        [Parameter(Mandatory)][string]$ProfileId,
        [Parameter(Mandatory)][string]$SourcePath
    )
    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Save location does not exist: $SourcePath"
    }
    $stamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')
    $destRoot = Get-NFBackupDir -GameId $GameId -ProfileId $ProfileId
    $dest = Join-Path $destRoot $stamp
    New-Item -ItemType Directory -Force -Path $dest | Out-Null

    $item = Get-Item -LiteralPath $SourcePath
    if ($item.PSIsContainer) {
        Copy-Item -LiteralPath "$SourcePath\*" -Destination $dest -Recurse -Force -ErrorAction Stop
    } else {
        Copy-Item -LiteralPath $SourcePath -Destination $dest -Force -ErrorAction Stop
    }

    $sizeBytes = (Get-ChildItem -LiteralPath $dest -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if (-not $sizeBytes) { $sizeBytes = 0 }

    $record = [PSCustomObject]@{
        id         = [guid]::NewGuid().ToString()
        timestamp  = $stamp
        createdUtc = (Get-Date).ToUniversalTime().ToString('o')
        sourcePath = $SourcePath
        folder     = $dest
        sizeBytes  = $sizeBytes
    }

    $index = @(Get-NFBackups -GameId $GameId -ProfileId $ProfileId)
    $index += $record
    ($index | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath (Get-NFBackupIndexPath -GameId $GameId -ProfileId $ProfileId) -Encoding UTF8

    return $record
}

function Restore-NFBackup {
    <#
        NOT IMPLEMENTED. Restoring would write into a user's live save/game
        directory, which Nova Forge will not do without a tested, explicit
        implementation and clear safety checks. Left as a stub so the UI can
        wire the intent without silently pretending to succeed.
    #>
    param($BackupRecord)
    throw "Restore is not implemented yet in this prototype. No files were changed."
}
