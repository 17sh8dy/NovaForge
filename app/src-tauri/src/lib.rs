// Nova Forge backend. Local-only: JSON files under %APPDATA%\NovaForge. Nothing here installs,
// patches or distributes any game or mod file. It stores bookkeeping, validates folders you point
// it at, starts programs you tell it to, and makes read-only copies of saves for backup.
use serde_json::{json, Map, Value};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

const GAMES_JSON: &str = include_str!("../games.json");
const LEGAL_MD: &str = include_str!("../../../LEGAL.md");

fn data_dir() -> PathBuf {
    let base = std::env::var("APPDATA").map(PathBuf::from).unwrap_or_else(|_| PathBuf::from("."));
    let d = base.join("NovaForge");
    let _ = fs::create_dir_all(&d);
    d
}

/// A game id is used as a folder name, so only plain ids are accepted.
fn safe_id(s: &str) -> Result<&str, String> {
    if !s.is_empty() && s.len() <= 64 && s.chars().all(|c| c.is_ascii_alphanumeric() || c == '-' || c == '_') {
        Ok(s)
    } else {
        Err(format!("invalid id: {s}"))
    }
}

fn read_json(path: &Path) -> Option<Value> {
    let raw = fs::read_to_string(path).ok()?;
    serde_json::from_str(raw.trim_start_matches('\u{feff}')).ok()
}

fn write_json(path: &Path, v: &Value) -> Result<(), String> {
    if let Some(p) = path.parent() {
        fs::create_dir_all(p).map_err(|e| e.to_string())?;
    }
    fs::write(path, serde_json::to_string_pretty(v).map_err(|e| e.to_string())?).map_err(|e| e.to_string())
}

fn now_iso() -> String {
    let secs = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0) as i64;
    let (days, rem) = (secs.div_euclid(86400), secs.rem_euclid(86400));
    // civil-from-days (Howard Hinnant)
    let z = days + 719468;
    let era = z.div_euclid(146097);
    let doe = z.rem_euclid(146097);
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    format!("{y:04}-{m:02}-{d:02}T{:02}:{:02}:{:02}Z", rem / 3600, (rem % 3600) / 60, rem % 60)
}

fn copy_dir(src: &Path, dst: &Path) -> std::io::Result<(u64, u64)> {
    fs::create_dir_all(dst)?;
    let (mut files, mut bytes) = (0u64, 0u64);
    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let to = dst.join(entry.file_name());
        if entry.file_type()?.is_dir() {
            let (f, b) = copy_dir(&entry.path(), &to)?;
            files += f;
            bytes += b;
        } else {
            bytes += fs::copy(entry.path(), &to)?;
            files += 1;
        }
    }
    Ok((files, bytes))
}

/// One-time import of the old PowerShell prototype's data (dev builds only, next to this repo).
fn migrate_legacy(dir: &Path) {
    if dir.join("profiles").exists() || dir.join("config.json").exists() {
        return;
    }
    let legacy = Path::new(env!("CARGO_MANIFEST_DIR")).join("..").join("..");
    if !legacy.join("profiles").exists() {
        return;
    }
    for sub in ["profiles", "mods", "backups"] {
        if legacy.join(sub).exists() {
            let _ = copy_dir(&legacy.join(sub), &dir.join(sub));
        }
    }
    let _ = fs::copy(legacy.join("config.json"), dir.join("config.json"));
}

fn config_path() -> PathBuf {
    data_dir().join("config.json")
}

fn profiles_dir(game: &str) -> Result<PathBuf, String> {
    Ok(data_dir().join("profiles").join(safe_id(game)?))
}

fn new_profile(game: &str, name: &str) -> Value {
    let now = now_iso();
    json!({
        "id": uuid::Uuid::new_v4().to_string(), "gameId": game, "name": name,
        "gameDirectory": null, "dlcDirectory": null, "updateDirectory": null,
        "previousGameDirectory": null, "previousDlcDirectory": null, "previousUpdateDirectory": null,
        "saveDirectory": null, "notes": "", "createdUtc": now, "modifiedUtc": now
    })
}

#[tauri::command]
fn bootstrap() -> Value {
    let dir = data_dir();
    migrate_legacy(&dir);
    let games: Value = serde_json::from_str(GAMES_JSON).unwrap_or(Value::Null);
    let config = read_json(&config_path()).unwrap_or_else(|| json!({}));
    json!({
        "registry": games, "config": config, "dataDir": dir.to_string_lossy(),
        "version": env!("CARGO_PKG_VERSION"), "legal": LEGAL_MD
    })
}

#[tauri::command]
fn save_config(config: Value) -> Result<(), String> {
    write_json(&config_path(), &config)
}

#[tauri::command]
fn list_profiles(game: String) -> Result<Vec<Value>, String> {
    let dir = profiles_dir(&game)?;
    let read = |dir: &Path| -> Vec<Value> {
        let mut v: Vec<Value> = fs::read_dir(dir)
            .map(|rd| rd.filter_map(|e| e.ok()).filter_map(|e| read_json(&e.path())).collect())
            .unwrap_or_default();
        v.sort_by(|a, b| a["createdUtc"].as_str().cmp(&b["createdUtc"].as_str()));
        v
    };
    let mut profiles = read(&dir);
    if profiles.is_empty() {
        let p = new_profile(&game, "Default");
        write_json(&dir.join(format!("{}.json", p["id"].as_str().unwrap_or("x"))), &p)?;
        profiles = vec![p];
    }
    Ok(profiles)
}

#[tauri::command]
fn create_profile(game: String, name: String) -> Result<Value, String> {
    let p = new_profile(safe_id(&game)?, name.trim());
    write_json(&profiles_dir(&game)?.join(format!("{}.json", p["id"].as_str().unwrap_or("x"))), &p)?;
    Ok(p)
}

#[tauri::command]
fn save_profile(profile: Value) -> Result<Value, String> {
    let game = profile["gameId"].as_str().ok_or("profile has no gameId")?.to_string();
    let id = profile["id"].as_str().ok_or("profile has no id")?.to_string();
    safe_id(&id)?;
    let mut p = profile;
    p["modifiedUtc"] = json!(now_iso());
    write_json(&profiles_dir(&game)?.join(format!("{id}.json")), &p)?;
    Ok(p)
}

#[tauri::command]
fn delete_profile(game: String, id: String) -> Result<(), String> {
    safe_id(&id)?;
    let f = profiles_dir(&game)?.join(format!("{id}.json"));
    if f.exists() {
        fs::remove_file(f).map_err(|e| e.to_string())?;
    }
    let mods = data_dir().join("mods").join(safe_id(&game)?).join(&id);
    if mods.exists() {
        let _ = fs::remove_dir_all(mods);
    }
    Ok(())
}

#[tauri::command]
fn list_mods(game: String, profile: String) -> Result<Vec<Value>, String> {
    let f = data_dir().join("mods").join(safe_id(&game)?).join(safe_id(&profile)?).join("mods.json");
    Ok(match read_json(&f) {
        Some(Value::Array(a)) => a,
        Some(v @ Value::Object(_)) => vec![v],
        _ => vec![],
    })
}

#[tauri::command]
fn save_mods(game: String, profile: String, mods: Vec<Value>) -> Result<(), String> {
    let f = data_dir().join("mods").join(safe_id(&game)?).join(safe_id(&profile)?).join("mods.json");
    write_json(&f, &Value::Array(mods))
}

#[tauri::command]
fn validate_folder(requires: Vec<String>, label: String, hint: String, path: String) -> Value {
    let p = Path::new(&path);
    if !p.is_dir() {
        return json!({ "valid": false, "reason": "That folder doesn't exist." });
    }
    for sub in &requires {
        if !p.join(sub).is_dir() {
            return json!({ "valid": false, "reason": format!(
                "That doesn't look like a {label} folder. Nova Forge expects to find: {} ({hint}) \u{2014} '{sub}' is missing.",
                requires.join(", ")) });
        }
    }
    json!({ "valid": true, "reason": "" })
}

#[tauri::command]
async fn pick_folder(title: String) -> Option<String> {
    tauri::async_runtime::spawn_blocking(move || {
        rfd::FileDialog::new().set_title(&title).pick_folder().map(|p| p.to_string_lossy().to_string())
    })
    .await
    .ok()
    .flatten()
}

#[tauri::command]
async fn pick_file(title: String, ext: String) -> Option<String> {
    tauri::async_runtime::spawn_blocking(move || {
        rfd::FileDialog::new().set_title(&title).add_filter(&ext, &[ext.as_str()]).pick_file().map(|p| p.to_string_lossy().to_string())
    })
    .await
    .ok()
    .flatten()
}

#[tauri::command]
fn open_url(url: String) -> Result<(), String> {
    if !url.starts_with("https://") {
        return Err("only https links can be opened".into());
    }
    Command::new("explorer.exe").arg(url).spawn().map(|_| ()).map_err(|e| e.to_string())
}

#[tauri::command]
fn open_path(path: String) -> Result<(), String> {
    if !Path::new(&path).exists() {
        return Err("that location doesn't exist".into());
    }
    Command::new("explorer.exe").arg(path).spawn().map(|_| ()).map_err(|e| e.to_string())
}

/// Starts a program the user catalogued (e.g. a mod's own launcher). It never installs or patches anything.
#[tauri::command]
fn launch_exe(path: String) -> Result<(), String> {
    let p = Path::new(&path);
    let is_exe = p.extension().map(|e| e.eq_ignore_ascii_case("exe")).unwrap_or(false);
    if !is_exe || !p.is_file() {
        return Err("launcher not found (expected an existing .exe)".into());
    }
    let mut c = Command::new(p);
    if let Some(dir) = p.parent() {
        c.current_dir(dir);
    }
    c.spawn().map(|_| ()).map_err(|e| e.to_string())
}

fn backup_root(game: &str, profile: &str) -> Result<PathBuf, String> {
    Ok(data_dir().join("backups").join(safe_id(game)?).join(safe_id(profile)?))
}

#[tauri::command]
fn list_backups(game: String, profile: String) -> Result<Vec<Value>, String> {
    let idx = backup_root(&game, &profile)?.join("index.json");
    Ok(match read_json(&idx) {
        Some(Value::Array(a)) => a,
        _ => vec![],
    })
}

/// Read-only against the source: copies `source` into a new timestamped backup folder.
#[tauri::command]
fn backup_save(game: String, profile: String, source: String) -> Result<Value, String> {
    let src = Path::new(&source);
    if !src.exists() {
        return Err(format!("Save location does not exist: {source}"));
    }
    let root = backup_root(&game, &profile)?;
    let stamp = now_iso().replace(':', "-");
    let dest = root.join(&stamp);
    let (files, bytes) = if src.is_dir() {
        copy_dir(src, &dest).map_err(|e| e.to_string())?
    } else {
        fs::create_dir_all(&dest).map_err(|e| e.to_string())?;
        let b = fs::copy(src, dest.join(src.file_name().ok_or("bad file name")?)).map_err(|e| e.to_string())?;
        (1, b)
    };
    let rec = json!({ "id": uuid::Uuid::new_v4().to_string(), "createdUtc": now_iso(), "sourcePath": source,
                      "folder": dest.to_string_lossy(), "files": files, "sizeBytes": bytes });
    let idx = root.join("index.json");
    let mut list = match read_json(&idx) { Some(Value::Array(a)) => a, _ => vec![] };
    list.push(rec.clone());
    write_json(&idx, &Value::Array(list))?;
    Ok(rec)
}

/* ---------- Nova product switcher: open a sibling Nova product ---------- */
// The UI only ever sends a product id. What an id means (which site to open, which program to start)
// lives in this table, so the UI can't ask the backend to run an arbitrary path or open an arbitrary URL.
// KEEP IN SYNC BY HAND with the product lists in Atlas / Replay.gg / Nova Cut.
const NOVA_HOME_URL: &str = "https://nova-780.pages.dev/";

enum Product {
    Site(&'static str),
    App { names: &'static [&'static str], get_url: &'static str },
}

fn product(id: &str) -> Option<Product> {
    Some(match id {
        "nova-help" => Product::Site("https://nova-help.shadylabs.workers.dev/"),
        "nova" => Product::Site(NOVA_HOME_URL),
        "atlas-site" => Product::Site("https://atlas-website.shadylabs.workers.dev/"),
        "nova-legal" => Product::Site("https://nova-legal.shadylabs.workers.dev/"),
        "atlas" => Product::App { names: &["Atlas"], get_url: "https://atlas-website.shadylabs.workers.dev/" },
        "replay-gg" => Product::App { names: &["Replay.gg", "ReplayGG"], get_url: NOVA_HOME_URL },
        _ => return None,
    })
}

fn norm(s: &str) -> String {
    s.chars().filter(|c| c.is_ascii_alphanumeric()).collect::<String>().to_lowercase()
}

#[cfg(windows)]
fn hidden(c: &mut Command) -> &mut Command {
    use std::os::windows::process::CommandExt;
    c.creation_flags(0x0800_0000) // CREATE_NO_WINDOW
}
#[cfg(not(windows))]
fn hidden(c: &mut Command) -> &mut Command {
    c
}

fn icon_exe(value: &str) -> Option<PathBuf> {
    let mut v = value.trim().trim_start_matches('"').to_string();
    if let Some(i) = v.rfind(',') {
        if v[i + 1..].trim().trim_start_matches('-').chars().all(|c| c.is_ascii_digit()) {
            v.truncate(i);
        }
    }
    let p = PathBuf::from(v.trim().trim_end_matches('"'));
    (p.extension().map(|e| e.eq_ignore_ascii_case("exe")).unwrap_or(false) && p.is_file()).then_some(p)
}

fn exe_in_folder(folder: &str, names: &[&str]) -> Option<PathBuf> {
    let dir = PathBuf::from(folder.trim().trim_matches('"'));
    let files: Vec<PathBuf> = fs::read_dir(&dir).ok()?.filter_map(|e| e.ok()).map(|e| e.path())
        .filter(|p| p.extension().map(|e| e.eq_ignore_ascii_case("exe")).unwrap_or(false)).collect();
    let wanted: Vec<String> = names.iter().map(|n| norm(n)).collect();
    let stem = |p: &PathBuf| norm(&p.file_stem().map(|s| s.to_string_lossy().to_string()).unwrap_or_default());
    files.iter().find(|p| wanted.contains(&stem(p))).cloned().or_else(|| {
        files.iter().find(|p| {
            let n = p.file_name().map(|s| s.to_string_lossy().to_lowercase()).unwrap_or_default();
            !["unins", "uninst", "update", "setup", "crashpad"].iter().any(|b| n.starts_with(b))
        }).cloned()
    })
}

/// Finds an installed program by its name in Windows' own Uninstall registry hives.
fn find_installed(names: &[&str]) -> Option<PathBuf> {
    let wanted: Vec<String> = names.iter().map(|n| norm(n)).collect();
    for key in [
        r"HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        r"HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        r"HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    ] {
        let out = match hidden(Command::new("reg").args(["query", key, "/s"])).output() {
            Ok(o) => String::from_utf8_lossy(&o.stdout).to_string(),
            Err(_) => continue,
        };
        let mut block = String::new();
        let mut blocks: Vec<String> = vec![];
        for line in out.lines() {
            if line.starts_with("HKEY_") && !block.is_empty() {
                blocks.push(std::mem::take(&mut block));
            }
            block.push_str(line);
            block.push('\n');
        }
        blocks.push(block);
        for b in blocks {
            let field = |name: &str| -> Option<String> {
                b.lines().find_map(|l| {
                    let t = l.trim();
                    let (n, rest) = t.split_once(char::is_whitespace)?;
                    if !n.eq_ignore_ascii_case(name) {
                        return None;
                    }
                    let (_ty, val) = rest.trim_start().split_once(char::is_whitespace)?;
                    Some(val.trim().to_string())
                })
            };
            let Some(display) = field("DisplayName") else { continue };
            if !wanted.contains(&norm(&display)) {
                continue;
            }
            if let Some(exe) = field("DisplayIcon").and_then(|v| icon_exe(&v))
                .or_else(|| field("InstallLocation").and_then(|v| exe_in_folder(&v, names)))
            {
                return Some(exe);
            }
        }
    }
    None
}

/// Some Nova apps aren't single-instance: if it's already running, raise its window instead of starting a second copy.
fn raise_if_running(exe: &Path) -> &'static str {
    let script = "$exe = $env:NOVA_EXE; $procs = @(Get-Process | Where-Object { $_.Path -eq $exe }); if ($procs.Count -eq 0) { 'none'; exit }; \
Add-Type -Namespace Nova -Name Win -MemberDefinition '[DllImport(\"user32.dll\")] public static extern bool ShowWindow(System.IntPtr h, int n); [DllImport(\"user32.dll\")] public static extern bool SetForegroundWindow(System.IntPtr h);'; \
$win = $procs | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1; \
if ($win) { [Nova.Win]::ShowWindow($win.MainWindowHandle, 9) | Out-Null; [Nova.Win]::SetForegroundWindow($win.MainWindowHandle) | Out-Null; 'focused' } else { 'running' }";
    let out = hidden(Command::new("powershell").args(["-NoProfile", "-NonInteractive", "-Command", script]).env("NOVA_EXE", exe)).output();
    match out.map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string()) {
        Ok(s) if s == "focused" => "focused",
        Ok(s) if s == "running" => "running",
        _ => "none",
    }
}

/// Opens a Nova product: a website in the browser, or a desktop app (started if installed, otherwise
/// its download page). Returns what happened so the UI can say so.
#[tauri::command]
async fn open_product(id: String) -> Result<String, String> {
    tauri::async_runtime::spawn_blocking(move || -> Result<String, String> {
        let open = |url: &str| Command::new("explorer.exe").arg(url).spawn().map(|_| ()).map_err(|e| e.to_string());
        match product(&id).ok_or("unknown product")? {
            Product::Site(url) => {
                open(url)?;
                Ok("browser".into())
            }
            Product::App { names, get_url } => match find_installed(names) {
                Some(exe) => match raise_if_running(&exe) {
                    "focused" => Ok("focused".into()),
                    "running" => Ok("running".into()),
                    _ => {
                        let mut c = Command::new(&exe);
                        if let Some(d) = exe.parent() {
                            c.current_dir(d);
                        }
                        c.spawn().map_err(|e| e.to_string())?;
                        Ok("launched".into())
                    }
                },
                None => {
                    open(get_url)?;
                    Ok("notinstalled".into())
                }
            },
        }
    })
    .await
    .map_err(|e| e.to_string())?
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let _ = Map::<String, Value>::new();
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            bootstrap, save_config, list_profiles, create_profile, save_profile, delete_profile,
            list_mods, save_mods, validate_folder, pick_folder, pick_file, open_url, open_path,
            launch_exe, list_backups, backup_save, open_product
        ])
        .run(tauri::generate_context!())
        .expect("error while running Nova Forge");
}
