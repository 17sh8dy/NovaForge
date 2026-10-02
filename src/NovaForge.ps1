<#
    Nova Forge - entry point.
    Run with: powershell.exe -NoProfile -ExecutionPolicy Bypass -File src\NovaForge.ps1
    (Windows PowerShell's console host defaults to STA, which WPF requires.)
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Write-Error "Nova Forge must run in an STA PowerShell session. Launch via powershell.exe (not pwsh) or use NovaForge.bat."
    exit 1
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml, System.Windows.Forms | Out-Null

$Global:NF_Version = '0.1.0'
$Global:NF_Root = Split-Path -Parent $PSScriptRoot
$Global:NF_SrcRoot = $PSScriptRoot
$Global:NF_ConfigPath = Join-Path $Global:NF_Root 'config.json'
$Global:NF_ProfilesDir = Join-Path $Global:NF_Root 'profiles'
$Global:NF_ModsDir = Join-Path $Global:NF_Root 'mods'
$Global:NF_BackupsDir = Join-Path $Global:NF_Root 'backups'
$Global:NF_CrashLogPath = Join-Path $Global:NF_Root 'nova-forge-crash.log'

function Write-NFCrashLog {
    param([Parameter(Mandatory)]$ErrorRecord, [string]$Context = "")
    $lines = @(
        "===== $(Get-Date -Format o) ====="
        if ($Context) { "Context: $Context" }
        "Message: $($ErrorRecord.Exception.Message)"
        "Exception: $($ErrorRecord.Exception.ToString())"
        "ScriptStackTrace: $($ErrorRecord.ScriptStackTrace)"
        ""
    )
    try { $lines | Out-File -LiteralPath $Global:NF_CrashLogPath -Append -Encoding UTF8 } catch {}
}

try {
    foreach ($dir in @($Global:NF_ProfilesDir, $Global:NF_ModsDir, $Global:NF_BackupsDir)) {
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    }

    # --- Load services, core, game modules, shared UI, views (order matters: later files use earlier functions) ---
    . (Join-Path $Global:NF_SrcRoot 'App\Services\ConfigService.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Services\ProfileService.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Services\ModService.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Services\BackupService.ps1')
    . (Join-Path $Global:NF_SrcRoot 'Core\GameRegistry.ps1')
    . (Join-Path $Global:NF_SrcRoot 'Games\BOTW\BotwModule.ps1')
    . (Join-Path $Global:NF_SrcRoot 'Games\Minecraft\MinecraftModule.ps1')

    # --- Load the shell window (merges Theme\Theme.xaml via its own Window.Resources) ---
    $mainWindowXamlPath = Join-Path $Global:NF_SrcRoot 'App\MainWindow.xaml'
    $fs = [System.IO.File]::OpenRead($mainWindowXamlPath)
    try {
        $parserContext = New-Object System.Windows.Markup.ParserContext
        $parserContext.BaseUri = New-Object System.Uri($mainWindowXamlPath)
        $Global:NF_Window = [System.Windows.Markup.XamlReader]::Load($fs, $parserContext)
    } finally {
        $fs.Dispose()
    }

    # --- App icon (window + taskbar) and header logo. Non-fatal: a missing icon never blocks startup. ---
    try {
        $iconDir = Join-Path $Global:NF_Root 'Logo\F1'
        $icoPath = Join-Path $iconDir 'novaforge-f1.ico'
        if (Test-Path -LiteralPath $icoPath) {
            $Global:NF_Window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object System.Uri($icoPath)))
        }
        $logoPng = Join-Path $iconDir 'novaforge-f1-64.png'
        $brandBtn = $Global:NF_Window.FindName('BrandHomeButton')
        if ($brandBtn -and (Test-Path -LiteralPath $logoPng)) {
            $logo = New-Object System.Windows.Controls.Image
            $logo.Source = New-Object System.Windows.Media.Imaging.BitmapImage(New-Object System.Uri($logoPng))
            $logo.Width = 24; $logo.Height = 24; $logo.Margin = '0,0,10,0'
            $logo.VerticalAlignment = 'Center'
            [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($logo, 'HighQuality')
            $brandBtn.Content.Children.Insert(0, $logo)
        }
        # Own taskbar identity so Windows shows the Nova Forge icon, not PowerShell's.
        Add-Type -Name NFShell -Namespace NovaForge -MemberDefinition '[DllImport("shell32.dll")] public static extern int SetCurrentProcessExplicitAppUserModelID([MarshalAs(UnmanagedType.LPWStr)] string id);' -ErrorAction Stop
        [NovaForge.NFShell]::SetCurrentProcessExplicitAppUserModelID('NovaForge.App') | Out-Null
    } catch {
        Write-NFCrashLog -ErrorRecord $_ -Context "App icon (non-fatal)"
    }

    # --- Controls + views need $Global:NF_Window's resources to already exist ---
    . (Join-Path $Global:NF_SrcRoot 'App\Controls\Controls.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Services\ThemeService.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Views\LegalDisclaimerDialog.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Views\GameSelectorView.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Views\OverviewView.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Views\GameSettingsView.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Views\CharacterCustomizationView.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Views\ModsView.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Views\SaveManagementView.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Views\ProfilesView.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\Views\SettingsView.ps1')
    . (Join-Path $Global:NF_SrcRoot 'App\MainShell.ps1')

    # --- Apply saved appearance before anything is shown ---
    $cfg = Get-NFConfig
    try {
        Set-NFAccentColor -Name $cfg.accentColor
    } catch {
        Write-NFCrashLog -ErrorRecord $_ -Context "Set-NFAccentColor at startup (non-fatal)"
    }

    # --- First-run legal acknowledgement gate ---
    if (-not $cfg.acceptedLegalNotice) {
        try {
            $accepted = Show-NFLegalDisclaimer
        } catch {
            Write-NFCrashLog -ErrorRecord $_ -Context "Show-NFLegalDisclaimer"
            throw
        }
        if (-not $accepted) {
            exit 0
        }
        try {
            $cfg = Get-NFConfig
            $cfg.acceptedLegalNotice = $true
            Save-NFConfig -Config $cfg
        } catch {
            Write-NFCrashLog -ErrorRecord $_ -Context "Saving acceptedLegalNotice"
            throw
        }
    }

    # --- Dark title bar (best-effort; app still works fine if this fails, but we log it) ---
    try {
        Add-Type -Name NFDwm -Namespace NovaForge -MemberDefinition @'
[DllImport("dwmapi.dll")]
public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
'@ -ErrorAction Stop
        $Global:NF_Window.Add_SourceInitialized({
            try {
                $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($Global:NF_Window)).Handle
                $darkMode = 1
                [NovaForge.NFDwm]::DwmSetWindowAttribute($hwnd, 20, [ref]$darkMode, 4) | Out-Null
            } catch {
                Write-NFCrashLog -ErrorRecord $_ -Context "DWM dark title bar (SourceInitialized, non-fatal)"
            }
        }) | Out-Null
    } catch {
        Write-NFCrashLog -ErrorRecord $_ -Context "DWM Add-Type (non-fatal)"
    }

    try {
        Initialize-NFShell
    } catch {
        Write-NFCrashLog -ErrorRecord $_ -Context "Initialize-NFShell"
        throw
    }

    $Global:NF_Window.ShowDialog() | Out-Null
} catch {
    Write-NFCrashLog -ErrorRecord $_ -Context "Top-level"
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue | Out-Null
        [System.Windows.MessageBox]::Show(
            "Nova Forge hit an unexpected error and has to close.`n`n$($_.Exception.Message)`n`nFull details were written to:`n$Global:NF_CrashLogPath",
            "Nova Forge - Error",
            'OK', 'Error') | Out-Null
    } catch {}
    exit 1
}
