# ThemeService.ps1
# Runtime accent-color switching.
#
# This REPLACES the Brush.Accent/Glow.Accent* dictionary entries with brand new
# objects rather than mutating the existing ones in place. WPF automatically
# freezes (seals) a Freezable the first time it's used by a Style Setter that
# actually renders, so mutating the *same* brush/effect instance only works
# before the very first paint -- after that it throws "read-only state".
# Theme.xaml's accent-related Setters use {DynamicResource}, which re-resolves
# from the dictionary and updates live, so replacing the entry here is enough
# for shell chrome (buttons, nav, badges, hover glow). Views built procedurally
# via Get-NFRes pick up the new objects the next time they're rebuilt, which is
# why the Settings screen re-shows itself right after a change.
# Requires MainWindow.xaml + Controls.ps1 to already be loaded.

function Get-NFAccentPresets {
    return @(
        [PSCustomObject]@{ Name = 'Cyan';   Accent = '#FF1FB4D6'; Hover = '#FF6ED9EE'; Pressed = '#FF127E96'; Muted = '#261FB4D6' }
        [PSCustomObject]@{ Name = 'Orange'; Accent = '#FFFF8A3D'; Hover = '#FFFFAD73'; Pressed = '#FFCC6A26'; Muted = '#26FF8A3D' }
        [PSCustomObject]@{ Name = 'Green';  Accent = '#FF2EE6B8'; Hover = '#FF7BF2D3'; Pressed = '#FF1FA886'; Muted = '#262EE6B8' }
        [PSCustomObject]@{ Name = 'Violet'; Accent = '#FFB18AFF'; Hover = '#FFD1BBFF'; Pressed = '#FF8560D9'; Muted = '#26B18AFF' }
    )
}

function Set-NFAccentColor {
    param([Parameter(Mandatory)][string]$Name)

    $preset = Get-NFAccentPresets | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    if (-not $preset) { $preset = Get-NFAccentPresets | Select-Object -First 1 }

    $accentColor = [System.Windows.Media.ColorConverter]::ConvertFromString($preset.Accent)
    $hoverColor = [System.Windows.Media.ColorConverter]::ConvertFromString($preset.Hover)
    $pressedColor = [System.Windows.Media.ColorConverter]::ConvertFromString($preset.Pressed)
    $mutedColor = [System.Windows.Media.ColorConverter]::ConvertFromString($preset.Muted)

    # Explicit [Type] casts force PowerShell to hand WPF a raw CLR object instead
    # of a PSObject wrapper -- a bare New-Object result stored straight into the
    # dictionary makes WPF's hard (Brush)/(Effect) cast at render time throw
    # "Unable to cast ... PSObject ... to ... Brush".
    $res = $Global:NF_Window.Resources
    $res['Brush.Accent'] = [System.Windows.Media.Brush](New-Object System.Windows.Media.SolidColorBrush($accentColor))
    $res['Brush.AccentHover'] = [System.Windows.Media.Brush](New-Object System.Windows.Media.SolidColorBrush($hoverColor))
    $res['Brush.AccentPressed'] = [System.Windows.Media.Brush](New-Object System.Windows.Media.SolidColorBrush($pressedColor))
    $res['Brush.AccentMuted'] = [System.Windows.Media.Brush](New-Object System.Windows.Media.SolidColorBrush($mutedColor))

    $glow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $glow.Color = $accentColor; $glow.BlurRadius = 16; $glow.ShadowDepth = 0; $glow.Opacity = 0.55
    $res['Glow.Accent'] = [System.Windows.Media.Effects.Effect]$glow

    $glowSoft = New-Object System.Windows.Media.Effects.DropShadowEffect
    $glowSoft.Color = $accentColor; $glowSoft.BlurRadius = 10; $glowSoft.ShadowDepth = 0; $glowSoft.Opacity = 0.35
    $res['Glow.AccentSoft'] = [System.Windows.Media.Effects.Effect]$glowSoft
}
