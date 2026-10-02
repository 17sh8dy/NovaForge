# Nova Forge

A Windows desktop game customization and mod management toolkit, with a clean,
technical Black + Electric Cyan / Ice Blue UI. Prototype stage: **first
supported game is The Legend of Zelda: Breath of the Wild**. Architecture is
modular so more games can be added without touching the shared shell.

Read `LEGAL.md` before distributing or extending this project.

If Nova Forge ever fails to start, check `nova-forge-crash.log` in this folder --
the app writes full exception details there instead of just closing silently.

## Running it

Double-click `NovaForge.bat`, or:

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File src\NovaForge.ps1
```

Requires Windows PowerShell (the `powershell.exe` console host, not `pwsh`) --
WPF needs an STA thread, which `powershell.exe` provides by default.

## What's real in this prototype

- Dark, professional shell: header, sidebar navigation, status bar, Nova Forge branding
- Game selector (BOTW is the only supported entry; others show as "Coming Soon" and do nothing)
- Local profiles per game (create/rename/delete/switch), stored as JSON under `profiles\`
- Game directory picker per profile (existence-checked only -- no authenticity/ownership verification)
- Mod catalog per profile: name/notes/enabled/file-location bookkeeping, stored under `mods\`
  (Nova Forge does **not** install, inject, or patch any mod file yet)
- Save backup: copies a chosen save folder into `backups\<game>\<profile>\<timestamp>\`.
  Read-only against the source -- your save/game files are never written to
- First-run legal disclaimer, plus a full Legal & Disclaimers tab in Settings

## What's intentionally not implemented yet

- Restoring a backup (would write into a live save folder -- disabled in the UI until a tested, safe implementation exists)
- Game settings / config value editing
- Character customization
- Any actual mod installation, injection, or patching
- Any game beyond BOTW (other tiles are placeholders)
- Any emulator bundling -- Nova Forge is not an emulator and will only ever point to actively maintained, supported emulator projects, never discontinued ones

## Roadmap notes (not built, just planned for)

- Organizing the game selector by **platform** (PC, Nintendo, and others), not just a flat game list. `Core\GameRegistry.ps1` already carries a `PlatformGroup` field per entry for this, but the grouped UI itself hasn't been built.
- Nova Forge's legal notice is also meant to be listed on Nova Legal (the shared ecosystem legal site) as a product entry -- see that project for its own review/publish process before treating anything there as final.

## Architecture

```
src/
  App/               Shared, game-agnostic UI shell
    Theme/           Dark color/style ResourceDictionary
    Controls/        Reusable settings controls (toggle, path picker, dropdown, cards, banners)
    Services/        Local JSON storage: config, profiles, mods, backups
    Views/           One file per sidebar section, plus the game selector and legal dialog
    MainWindow.xaml  The shell layout (header, sidebar, content host, status bar)
    MainShell.ps1    Wires state <-> views; the only place that knows the nav structure
  Core/
    GameRegistry.ps1 The list of known games (add an entry here for a new game)
  Games/
    BOTW/            BOTW-specific static content and feature flags
                      (a new game gets its own folder here, not changes to App/)
```

Adding a new supported game means: add an entry to `Core\GameRegistry.ps1`, add a
`src\Games\<id>\` module for its game-specific text/flags, and implement real
functionality behind the existing views -- the shell, navigation, and storage
services do not need to change.

Status: Early prototype -- UI and foundation only, per design.
