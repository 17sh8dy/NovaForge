// Nova Forge UI. Plain JS, no build step. All data work happens in the Rust backend (src-tauri/src/lib.rs).
"use strict";
const { invoke } = window.__TAURI__.core;
const api = (cmd, args) => invoke(cmd, args || {});

/* ---------- tiny helpers ---------- */
function h(tag, props, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props || {})) {
    if (v == null || v === false) continue;
    if (k === "class") el.className = v;
    else if (k === "html") el.innerHTML = v;
    else if (k.startsWith("on")) el.addEventListener(k.slice(2), v);
    else if (k === "value") el.value = v;
    else if (k === "checked" || k === "disabled" || k === "readOnly" || k === "selected") el[k] = !!v;
    else el.setAttribute(k, v === true ? "" : v);
  }
  for (const kid of kids.flat(Infinity)) {
    if (kid == null || kid === false) continue;
    el.append(kid instanceof Node ? kid : document.createTextNode(String(kid)));
  }
  return el;
}
const ICONS = {
  home: '<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/>',
  overview: '<rect x="3" y="3" width="7" height="9"/><rect x="14" y="3" width="7" height="5"/><rect x="14" y="12" width="7" height="9"/><rect x="3" y="16" width="7" height="5"/>',
  tool: '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
  user: '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  users: '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  package: '<path d="M16.5 9.4l-9-5.19"/><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/>',
  save: '<path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/>',
  sliders: '<line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/>',
  back: '<line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/>',
  ext: '<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/>',
  shield: '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
  info: '<circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>',
  edit: '<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4z"/>',
  play: '<polygon points="5 3 19 12 5 21 5 3"/>',
  scissors: '<circle cx="6" cy="6" r="3"/><circle cx="6" cy="18" r="3"/><line x1="20" y1="4" x2="8.12" y2="15.88"/><line x1="14.47" y1="14.48" x2="20" y2="20"/><line x1="8.12" y1="8.12" x2="12" y2="12"/>',
  gamepad: '<line x1="6" y1="12" x2="10" y2="12"/><line x1="8" y1="10" x2="8" y2="14"/><line x1="15" y1="13" x2="15.01" y2="13"/><line x1="18" y1="11" x2="18.01" y2="11"/><rect x="2" y="6" width="20" height="12" rx="2"/>',
  sparkles: '<path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9z"/><path d="M19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8z"/>',
  globe: '<circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>',
  search: '<circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>',
  file: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/>',
  chevron: '<polyline points="6 9 12 15 18 9"/>',
  arrow: '<line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/>',
};
const icon = (n) => h("span", { html: `<svg class="i" viewBox="0 0 24 24">${ICONS[n] || ""}</svg>` }).firstChild;

function toast(msg, kind) {
  const t = h("div", { class: "toast " + (kind || "") }, msg);
  document.getElementById("toasts").append(t);
  setTimeout(() => t.remove(), kind === "bad" ? 6000 : 3200);
}
const ext = (url) => api("open_url", { url }).catch((e) => toast(String(e), "bad"));
const fail = (e) => toast(String(e), "bad");
const uuid = () => ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, (c) => (c ^ (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))).toString(16));

function openModal(build, cls) {
  const root = document.getElementById("modal");
  const close = () => { root.hidden = true; root.replaceChildren(); };
  root.replaceChildren(h("div", { class: "modal " + (cls || ""), onclick: (e) => e.stopPropagation() }, build(close)));
  root.onclick = close;
  root.hidden = false;
  return close;
}
function askText(title, initial, confirmLabel) {
  return new Promise((resolve) => {
    openModal((close) => {
      const input = h("input", { type: "text", value: initial || "", maxlength: "60" });
      const done = (v) => { close(); resolve(v); };
      input.addEventListener("keydown", (e) => { if (e.key === "Enter" && input.value.trim()) done(input.value.trim()); if (e.key === "Escape") done(null); });
      setTimeout(() => { input.focus(); input.select(); }, 30);
      return [h("h2", {}, title), h("div", { class: "field-block", style: "margin-top:14px" }, input),
        h("div", { class: "actions" },
          h("button", { class: "btn", onclick: () => done(null) }, "Cancel"),
          h("button", { class: "btn primary", onclick: () => input.value.trim() && done(input.value.trim()) }, confirmLabel || "Save"))];
    });
  });
}
function confirmBox(title, text, okLabel) {
  return new Promise((resolve) => {
    openModal((close) => {
      const done = (v) => { close(); resolve(v); };
      return [h("h2", {}, title), h("p", { class: "muted", style: "margin-top:8px" }, text),
        h("div", { class: "actions" },
          h("button", { class: "btn", onclick: () => done(false) }, "Cancel"),
          h("button", { class: "btn danger", onclick: () => done(true) }, okLabel || "Delete"))];
    });
  });
}

/* ---------- state ---------- */
const S = { boot: null, reg: null, cfg: {}, view: "home", gameId: null, tab: "general", profiles: {} };
const ACCENTS = { Violet: ["#9b7bff", "#8062f5"], Cyan: ["#1fb4d6", "#1696b4"], Green: ["#2ee6b8", "#1fb893"], Orange: ["#ff8a3d", "#e0722a"], Pink: ["#ff7ad9", "#e05fbd"] };
const SECTION_META = {
  overview: ["Overview", "overview"], gameSettings: ["Game Settings", "tool"], character: ["Character Customization", "user"],
  mods: ["Mods", "package"], saves: ["Save Management", "save"], profiles: ["Profiles", "users"],
};
const game = (id) => S.reg.games.find((g) => g.id === id);
const saveCfg = () => api("save_config", { config: S.cfg }).catch(fail);

function applyAccent() {
  const [a, strong] = ACCENTS[S.cfg.accentColor] || ACCENTS.Violet;
  const r = document.documentElement.style;
  r.setProperty("--accent", a); r.setProperty("--accent-strong", strong);
  const n = parseInt(a.slice(1), 16);
  r.setProperty("--accent-soft", `rgba(${n >> 16},${(n >> 8) & 255},${n & 255},0.13)`);
}
async function loadProfiles(gameId) {
  S.profiles[gameId] = await api("list_profiles", { game: gameId });
  return S.profiles[gameId];
}
function activeProfile(gameId) {
  const list = S.profiles[gameId] || [];
  const id = (S.cfg.activeProfileId || {})[gameId];
  return list.find((p) => p.id === id) || list[0] || null;
}
async function setActiveProfile(gameId, id) {
  S.cfg.activeProfileId = Object.assign({}, S.cfg.activeProfileId, { [gameId]: id });
  await saveCfg();
}
async function updateProfile(p, patch) {
  const saved = await api("save_profile", { profile: Object.assign({}, p, patch) });
  const list = S.profiles[p.gameId];
  list[list.findIndex((x) => x.id === p.id)] = saved;
  return saved;
}

/* ---------- navigation ---------- */
async function go(view, gameId) {
  if (gameId !== undefined) S.gameId = gameId;
  S.view = view;
  if (S.gameId && !S.profiles[S.gameId]) await loadProfiles(S.gameId);
  render();
}
const inGame = () => !!S.gameId;
async function openGame(id) {
  await loadProfiles(id);
  S.gameId = id; S.view = "overview"; render();
}

function render() {
  renderSide(); renderTop(); renderContent();
  document.getElementById("content").scrollTop = 0;
}

function navBtn(label, ic, on, click) {
  return h("button", { class: "nav" + (on ? " on" : ""), onclick: click }, icon(ic), label);
}
function renderSide() {
  const side = document.getElementById("side");
  const kids = [h("div", { class: "brand", onclick: () => { S.gameId = null; go("home"); } },
    h("img", { src: "logo.png", alt: "" }), h("b", {}, "NOVA ", h("span", {}, "FORGE")))];
  if (!inGame()) {
    kids.push(navBtn("Home", "home", S.view === "home", () => go("home")));
    kids.push(navBtn("Profiles", "users", S.view === "homeProfiles", () => go("homeProfiles")));
  } else {
    const g = game(S.gameId);
    kids.push(h("div", { class: "gamehead" },
      h("button", { class: "back", onclick: () => { S.gameId = null; go("home"); } }, icon("back"), "All games"),
      h("div", { class: "gname" }, g.name), h("div", { class: "gsub" }, g.platform)));
    for (const key of ["overview", ...g.sections, "profiles"]) {
      const [label, ic] = SECTION_META[key];
      kids.push(navBtn(label, ic, S.view === key, () => go(key)));
    }
  }
  kids.push(h("div", { class: "spacer" }));
  kids.push(navBtn("Settings", "sliders", S.view === "settings", () => go("settings")));
  kids.push(h("p", { class: "disclaimer" }, "Nova Forge is independently developed and is not affiliated with, sponsored by, or endorsed by any third-party company, organization, or rights holder."));
  side.replaceChildren(...kids);
}
function renderTop() {
  const top = document.getElementById("topbar");
  const kids = [novaSwitcher()];
  if (inGame()) {
    const g = game(S.gameId), p = activeProfile(S.gameId);
    kids.push(h("span", { class: "pill" }, `${g.shortName}  ·  Profile: ${p ? p.name : "none"}`));
  }
  kids.push(h("button", { class: "btn ghost sm", onclick: () => { S.tab = "legal"; go("settings"); } }, icon("shield"), "Legal"));
  top.replaceChildren(...kids);
}
async function renderContent() {
  const el = document.getElementById("content");
  const views = { home: viewHome, homeProfiles: viewAllProfiles, settings: viewSettings, overview: viewOverview,
    gameSettings: viewPlanned("gameSettings", "Game Settings"), character: viewPlanned("character", "Character Customization"),
    mods: viewMods, saves: viewSaves, profiles: viewGameProfiles };
  const page = h("div", { class: "page" });
  el.replaceChildren(page);
  try { page.append(...[await views[S.view]()].flat()); } catch (e) { page.append(h("div", { class: "notice" }, String(e))); }
}

/* ---------- Home ---------- */
const pageHead = (title, sub) => h("div", { class: "pagehead" }, h("h1", {}, title), sub && h("p", {}, sub));
function legalBanner() {
  return h("div", { class: "notice" }, icon("shield"),
    h("div", {}, "Nova Forge does not own, sell, host, or distribute any third-party game files. You must provide your own legally obtained copies. ",
      h("a", { onclick: () => { S.tab = "legal"; go("settings"); } }, "View full legal notice")));
}
function gameCard(g) {
  const banner = h("div", { class: "banner", style: `background:linear-gradient(135deg, ${g.colors[0]}, ${g.colors[1]})` },
    h("div", { class: "mono" }, g.monogram), h("span", { class: "badge" }, g.supported ? "SUPPORTED" : "COMING SOON"));
  const body = h("div", { class: "gbody" }, h("h3", {}, g.name), h("div", { class: "plat" }, g.platform));
  if (g.supported) {
    const list = S.profiles[g.id] || [];
    const act = activeProfile(g.id);
    const sel = h("select", { onchange: async () => { await setActiveProfile(g.id, sel.value); } },
      list.map((p) => h("option", { value: p.id, selected: act && p.id === act.id }, p.name)));
    body.append(h("label", {}, "Profile"), sel,
      h("div", { class: "gactions" },
        h("button", { class: "btn primary", onclick: () => openGame(g.id) }, "Open →"),
        h("button", { class: "btn", title: "Create, rename or delete profiles", onclick: () => manageProfiles(g.id) }, icon("edit"), "Profiles")));
  } else {
    body.append(h("p", { class: "faint small", style: "margin-top:10px" }, "Not supported yet."));
  }
  return h("div", { class: "game " + (g.supported ? "live" : "soon") }, banner, body);
}
async function viewHome() {
  await Promise.all(S.reg.games.filter((g) => g.supported).map((g) => loadProfiles(g.id)));
  const out = [pageHead("Choose a game", "Pick a game and a profile. Everything else lives inside the game."), legalBanner()];
  for (const grp of [...new Set(S.reg.games.map((g) => g.group))]) {
    const games = S.reg.games.filter((g) => g.group === grp);
    out.push(h("div", { class: "section-title" }, h("h2", {}, grp), h("span", {}, games.length === 1 ? "1 game" : `${games.length} games`)));
    out.push(h("div", { class: "grid" }, games.map(gameCard)));
  }
  return out;
}
function manageProfiles(gameId) {
  openModal((close) => [h("h2", {}, game(gameId).name), h("p", { class: "muted", style: "margin:4px 0 16px" }, "Profiles keep separate folders, mods and backups."),
    profilePanel(gameId, () => { close(); render(); }), h("div", { class: "actions" }, h("button", { class: "btn", onclick: () => { close(); render(); } }, "Done"))]);
}

/* ---------- Profiles ---------- */
function profilePanel(gameId, onChange) {
  const wrap = h("div", {});
  const draw = () => {
    const list = S.profiles[gameId] || [], act = activeProfile(gameId);
    const rows = list.map((p) => h("div", { class: "row" },
      h("div", { class: "grow" }, h("div", { class: "title" }, p.name, act && act.id === p.id ? h("span", { class: "badge on", style: "margin-left:10px" }, "ACTIVE") : null),
        h("div", { class: "meta" }, p.gameDirectory ? p.gameDirectory : "No game folder set")),
      act && act.id === p.id ? null : h("button", { class: "btn sm", onclick: async () => { await setActiveProfile(gameId, p.id); draw(); onChange && onChange(); } }, "Use"),
      h("button", { class: "btn sm", onclick: async () => {
        const n = await askText("Rename profile", p.name, "Rename"); if (!n) return;
        await updateProfile(p, { name: n }).catch(fail); draw(); onChange && onChange(); } }, "Rename"),
      h("button", { class: "btn sm danger", disabled: list.length <= 1, title: list.length <= 1 ? "A game needs at least one profile" : "", onclick: async () => {
        if (!(await confirmBox("Delete profile?", `"${p.name}" and its mod list will be removed. Your game files are not touched.`))) return;
        await api("delete_profile", { game: gameId, id: p.id }).catch(fail);
        await loadProfiles(gameId);
        if (act && act.id === p.id) await setActiveProfile(gameId, S.profiles[gameId][0].id);
        draw(); onChange && onChange(); } }, "Delete")));
    const input = h("input", { type: "text", placeholder: "New profile name", maxlength: "60" });
    const add = async () => {
      const name = input.value.trim(); if (!name) return;
      const p = await api("create_profile", { game: gameId, name }).catch(fail); if (!p) return;
      await loadProfiles(gameId); await setActiveProfile(gameId, p.id); toast(`Created "${name}"`, "ok"); draw(); onChange && onChange();
    };
    input.addEventListener("keydown", (e) => e.key === "Enter" && add());
    wrap.replaceChildren(h("div", { class: "list" }, rows), h("div", { class: "fieldrow", style: "margin-top:14px" }, input, h("button", { class: "btn primary", onclick: add }, "Create profile")));
  };
  draw();
  return wrap;
}
async function viewAllProfiles() {
  await Promise.all(S.reg.games.filter((g) => g.supported).map((g) => loadProfiles(g.id)));
  const out = [pageHead("Profiles", "Create, rename and delete profiles for any game. Each profile has its own game folders, mods and backups.")];
  for (const g of S.reg.games.filter((x) => x.supported)) {
    out.push(h("div", { class: "card" }, h("h2", {}, g.name), h("div", { class: "sub" }, g.platform), profilePanel(g.id)));
  }
  return out;
}
async function viewGameProfiles() {
  const g = game(S.gameId);
  return [pageHead("Profiles", g.name), h("div", { class: "card" }, profilePanel(g.id, () => { renderTop(); }))];
}

/* ---------- Game: Overview ---------- */
function dirRow(g, p, kind, field, prevField, label, help) {
  const rule = (g.validate || {})[kind];
  const input = h("input", { type: "text", readOnly: true, value: p[field] || "", placeholder: "Not set" });
  const msg = h("div", { class: "err", hidden: true });
  const browse = h("button", { class: "btn", onclick: async () => {
    const pick = await api("pick_folder", { title: `Select your ${label}` }).catch(fail); if (!pick) return;
    if (rule) {
      const r = await api("validate_folder", { requires: rule.requires, label: rule.label, hint: rule.hint, path: pick });
      if (!r.valid) { msg.textContent = r.reason; msg.hidden = false; return; }
    } else if (!(await api("validate_folder", { requires: [], label: "", hint: "", path: pick })).valid) { msg.textContent = "That folder doesn't exist."; msg.hidden = false; return; }
    const patch = { [field]: pick }; if (p[field] && p[field] !== pick) patch[prevField] = p[field];
    await updateProfile(p, patch).catch(fail); toast(`${label} saved`, "ok"); render();
  } }, "Browse…");
  const revert = p[prevField] ? h("button", { class: "btn ghost", title: p[prevField], onclick: async () => {
    await updateProfile(p, { [field]: p[prevField], [prevField]: p[field] }).catch(fail); render(); } }, "Revert") : null;
  return h("div", { class: "field-block" }, h("label", { class: "field" }, label), help && h("div", { class: "help" }, help),
    h("div", { class: "fieldrow" }, input, browse, revert), msg);
}
async function viewOverview() {
  const g = game(S.gameId), p = activeProfile(g.id);
  const out = [pageHead(g.name, `${g.platform}  ·  Active profile: ${p.name}`)];
  if (g.about) out.push(h("div", { class: "notice info" }, icon("info"), g.about));
  if (g.supported && g.emulators.length) out.push(await playCard(g, p));
  out.push(legalBanner());

  const dirs = h("div", { class: "card" }, h("h2", {}, "Game Directory"),
    h("div", { class: "sub" }, "Point Nova Forge at your own legally obtained files. Each folder is checked before it's accepted — nothing is copied, moved or uploaded."));
  dirs.append(dirRow(g, p, "game", "gameDirectory", "previousGameDirectory", "Game folder", (g.folderHelp || {}).game));
  if ((g.validate || {}).update) dirs.append(dirRow(g, p, "update", "updateDirectory", "previousUpdateDirectory", "Update folder", "Optional. Your update/patch dump, if installed separately from the base game."));
  if ((g.validate || {}).dlc) dirs.append(dirRow(g, p, "dlc", "dlcDirectory", "previousDlcDirectory", "DLC folder", "Optional. Your add-on content dump, if you own it."));
  dirs.append(h("div", { class: "notice info", style: "margin:4px 0 0" }, icon("info"), "Already have mods, saves or DLC somewhere on this PC? Point Nova Forge at those folders directly — nothing needs re-downloading."));
  out.push(dirs);

  if (!p.gameDirectory) {
    const note = g.getNote.map((k) => S.reg[k]).join(" ");
    out.push(h("div", { class: "card" }, h("h2", {}, "Don't have the game yet?"), h("p", { class: "muted", style: "margin:6px 0 14px" }, note),
      h("div", { style: "display:flex;flex-direction:column;gap:8px;align-items:flex-start" },
        g.getLinks.map((k) => { const l = S.reg.links[k]; return h("button", { class: "btn", onclick: () => ext(l.url) }, l.label, icon("ext")); }))));
  }
  if (g.emulators.length) {
    out.push(h("div", { class: "card" }, h("h2", {}, "Suggested Emulators"),
      h("div", { class: "sub" }, "Nova Forge is not an emulator and includes none. These are actively maintained projects you install yourself, with your own game files. Discontinued projects (such as Yuzu) are not listed."),
      h("div", { class: "list" }, g.emulators.map((k) => { const e = S.reg.emulators[k];
        return h("div", { class: "row" }, h("div", { class: "grow" }, h("div", { class: "title" }, `${e.name}  ·  ${e.system}`), h("div", { class: "meta" }, e.note)),
          h("button", { class: "btn sm", onclick: () => ext(e.url) }, "Open site", icon("ext"))); }))));
  }
  return out;
}


/* ---------- Play: start an emulator you already installed ---------- */
const EMU_NAME = { cemu: "Cemu", ryubing: "Ryubing / Ryujinx" };
const emuKind = (exe) => (exe && exe.toLowerCase().endsWith("cemu.exe") ? "cemu" : exe && exe.toLowerCase().endsWith("ryujinx.exe") ? "ryubing" : null);
async function playCard(g, p) {
  // The folder scan can take a few seconds, so it runs once per session and is reused.
  if (!S.emus) S.emus = await api("detect_emulators", { extra: [] });
  const found = S.emus.filter((e) => g.emulators.includes(e.kind));
  const gameSrc = p.gameFile || p.gameDirectory || "";
  // Default to the emulator that lives next to this game's files, otherwise the first one found.
  const dirOf = (f) => f.slice(0, f.lastIndexOf("\\") + 1).toLowerCase();
  const beside = found.find((e) => gameSrc && gameSrc.toLowerCase().startsWith(dirOf(e.exe)));
  const exe = p.emulatorPath || (beside || found[0] || {}).exe || "";
  const kind = emuKind(exe);
  const target = kind && gameSrc ? await api("resolve_game", { kind, path: gameSrc }) : null;
  const choose = async (path) => { await updateProfile(p, { emulatorPath: path }).catch(fail); render(); };

  const options = found.map((e) => h("option", { value: e.exe, selected: e.exe === exe }, `${EMU_NAME[e.kind]} \u2014 ${e.exe}`));
  if (exe && !found.some((e) => e.exe === exe)) options.unshift(h("option", { value: exe, selected: true }, `${EMU_NAME[kind] || "Emulator"} \u2014 ${exe}`));
  const sel = h("select", { onchange: () => choose(sel.value) }, options.length ? options : [h("option", { value: "" }, "No emulator found \u2014 use Browse")]);

  let status;
  if (!exe) status = h("div", { class: "faint small" }, "Pick an emulator you've installed. Nova Forge doesn't include one \u2014 see Suggested Emulators below.");
  else if (!gameSrc) status = h("div", { class: "faint small" }, "Set a game folder below (or choose a game file) so Nova Forge knows what to start.");
  else if (!target) status = h("div", { class: "err" }, kind === "cemu" ? "No .rpx game file found in that folder." : "Ryubing / Ryujinx needs a Switch game file (.nsp or .xci). Choose one with \u201cChoose game file\u201d.");
  else status = h("div", { class: "small muted", style: "overflow-wrap:anywhere" }, "Will start: " + target);

  const play = h("button", { class: "btn primary", disabled: !(exe && target), onclick: async () => {
    const r = await api("play", { emulator: exe, game: gameSrc }).catch(fail);
    if (r) toast(`Starting ${EMU_NAME[kind]}\u2026`, "ok"); } }, icon("play"), "Play");

  return h("div", { class: "card" }, h("h2", {}, "Play"),
    h("div", { class: "sub" }, "Starts the emulator you installed, using this profile's game. Nova Forge only launches it \u2014 it doesn't change your game, and mods are applied by the emulator itself."),
    h("div", { class: "field-block" }, h("label", { class: "field" }, "Emulator"), h("div", { class: "fieldrow" }, sel,
      h("button", { class: "btn", onclick: async () => {
        const v = await api("pick_file", { title: "Select Cemu.exe or Ryujinx.exe", ext: "exe" }).catch(fail); if (!v) return;
        if (!g.emulators.includes(emuKind(v))) return toast("Pick Cemu.exe or Ryujinx.exe for this game.", "bad");
        if (!S.emus.some((e) => e.exe === v)) S.emus.push({ kind: emuKind(v), exe: v });
        choose(v); } }, "Browse\u2026"))),
    h("div", { class: "field-block" }, h("label", { class: "field" }, "Game"), status,
      kind ? h("div", { style: "margin-top:8px" }, h("button", { class: "btn sm", onclick: async () => {
        const v = await api("pick_file", { title: "Select the game file", ext: kind === "cemu" ? "rpx,wua,wud,wux" : "nsp,xci" }).catch(fail); if (!v) return;
        await updateProfile(p, { gameFile: v }).catch(fail); render(); } }, "Choose game file\u2026"),
        p.gameFile ? h("button", { class: "btn sm ghost", onclick: async () => { await updateProfile(p, { gameFile: null }).catch(fail); render(); } }, "Use game folder") : null) : null),
    play);
}

/* ---------- Nova Legal links ---------- */
const NOVA_LEGAL = "https://nova-legal.shadylabs.workers.dev";
function legalLinks() {
  return h("div", { class: "card" }, h("h2", {}, "Full legal information"),
    h("div", { class: "sub" }, "The complete, current documents live on Nova Legal."),
    h("div", { style: "display:flex;flex-wrap:wrap;gap:8px" },
      [["Nova Forge on Nova Legal", "/products/nova-forge"], ["Nova Forge Terms", "/nova-forge-terms"], ["Copyright & DMCA notices", "/dmca"], ["Nova Legal home", "/"]]
        .map(([label, path]) => h("button", { class: "btn", onclick: () => ext(NOVA_LEGAL + path) }, label, icon("ext")))));
}

/* ---------- Game: Mods ---------- */
async function viewMods() {
  const g = game(S.gameId), p = activeProfile(g.id);
  let mods = await api("list_mods", { game: g.id, profile: p.id });
  const persist = () => api("save_mods", { game: g.id, profile: p.id, mods }).catch(fail);
  const out = [pageHead("Mods", `${g.name}  ·  profile: ${p.name}`),
    h("div", { class: "notice info" }, icon("info"), "This is a personal catalog. Nova Forge doesn't install, inject or patch mod files — track what you have and where it lives. A mod that ships its own launcher gets an Open launcher button.")];
  out.push(h("div", { class: "notice" }, icon("shield"), h("div", {}, "You're responsible for the legality of any file you catalog. Nova Forge doesn't host, provide or verify mod content. ",
    h("a", { onclick: () => openModal((close) => [h("h2", {}, "Well-known mod sites"), h("p", { class: "muted", style: "margin:6px 0 14px" }, "Nova Forge doesn't host or vet any of these. Always read a mod's page before installing it."),
      h("div", { class: "list" }, S.reg.modSites.map((s) => h("div", { class: "row" }, h("div", { class: "grow title" }, s.name), h("button", { class: "btn sm", onclick: () => ext(s.url) }, "Open", icon("ext"))))),
      h("div", { class: "actions" }, h("button", { class: "btn", onclick: close }, "Close"))]) }, "Browse mod sites"))));

  const list = h("div", { class: "list" });
  const draw = () => {
    list.replaceChildren(...(mods.length ? mods.map((m) => {
      const lp = m.launcherPath;
      return h("div", { class: "row" },
        h("div", { class: "grow" }, h("div", { class: "title" }, m.name), m.notes && h("div", { class: "meta" }, m.notes), m.sourcePath && h("div", { class: "meta" }, "Location: " + m.sourcePath)),
        m.sourcePath ? h("button", { class: "btn sm ghost", title: m.sourcePath, onclick: () => api("open_path", { path: m.sourcePath }).catch(() => toast("That folder doesn't exist on this PC.", "bad")) }, "Show folder") : null,
        lp ? h("button", { class: "btn sm", title: lp, onclick: () => api("launch_exe", { path: lp }).catch(fail) }, icon("play"), "Open launcher") : null,
        h("label", { class: "toggle" }, h("input", { type: "checkbox", checked: m.enabled, onchange: (e) => { m.enabled = e.target.checked; persist(); } }), h("span", {})),
        h("button", { class: "btn sm danger", onclick: async () => { if (await confirmBox("Remove entry?", `"${m.name}" will be removed from this catalog. The mod's files are not touched.`, "Remove")) { mods = mods.filter((x) => x.id !== m.id); await persist(); draw(); count.textContent = `Cataloged mods (${mods.length})`; } } }, "Remove"));
    }) : [h("div", { class: "empty" }, "No mods cataloged yet for this profile.")]));
  };
  const count = h("h2", {}, `Cataloged mods (${mods.length})`);
  out.push(h("div", { class: "card" }, count, h("div", { style: "height:12px" }), list));
  draw();

  const name = h("input", { type: "text", placeholder: "Mod name", maxlength: "80" });
  const notes = h("input", { type: "text", placeholder: "Notes (optional)", maxlength: "300" });
  const loc = h("input", { type: "text", readOnly: true, placeholder: "Where you keep the files (optional)" });
  const exe = h("input", { type: "text", readOnly: true, placeholder: "Launcher program (optional, .exe)" });
  out.push(h("div", { class: "card" }, h("h2", {}, "Add a mod entry"), h("div", { style: "height:12px" }),
    h("div", { class: "field-block" }, h("label", { class: "field" }, "Name"), name),
    h("div", { class: "field-block" }, h("label", { class: "field" }, "Notes"), notes),
    h("div", { class: "field-block" }, h("label", { class: "field" }, "File location"), h("div", { class: "fieldrow" }, loc,
      h("button", { class: "btn", onclick: async () => { const v = await api("pick_folder", { title: "Select the mod's folder" }); if (v) loc.value = v; } }, "Browse…"))),
    h("div", { class: "field-block" }, h("label", { class: "field" }, "Launcher"), h("div", { class: "help" }, "If this mod has its own app, Nova Forge can start it for you."), h("div", { class: "fieldrow" }, exe,
      h("button", { class: "btn", onclick: async () => { const v = await api("pick_file", { title: "Select the launcher", ext: "exe" }); if (v) exe.value = v; } }, "Browse…"))),
    h("button", { class: "btn primary", onclick: async () => {
      if (!name.value.trim()) return toast("Give the mod a name first.", "bad");
      mods.push({ id: uuid(), name: name.value.trim(), notes: notes.value.trim(), sourcePath: loc.value || null, launcherPath: exe.value || null, enabled: true, addedUtc: new Date().toISOString() });
      await persist(); render(); } }, "Add mod entry")));
  return out;
}

/* ---------- Game: Saves ---------- */
const fmtBytes = (n) => n > 1e9 ? (n / 1e9).toFixed(2) + " GB" : n > 1e6 ? (n / 1e6).toFixed(1) + " MB" : Math.max(1, Math.round(n / 1e3)) + " KB";
async function viewSaves() {
  const g = game(S.gameId), p = activeProfile(g.id);
  const backups = (await api("list_backups", { game: g.id, profile: p.id })).reverse();
  const out = [pageHead("Save Management", `${g.name}  ·  profile: ${p.name}`)];
  if (g.saveNote) out.push(h("div", { class: "notice info" }, icon("info"), g.saveNote));
  const input = h("input", { type: "text", readOnly: true, value: p.saveDirectory || "", placeholder: "Not set" });
  const backBtn = h("button", { class: "btn primary", disabled: !p.saveDirectory, onclick: async () => {
    backBtn.disabled = true;
    const r = await api("backup_save", { game: g.id, profile: p.id, source: p.saveDirectory }).catch(fail);
    if (r) toast(`Backed up ${r.files} files (${fmtBytes(r.sizeBytes)})`, "ok"); render(); } }, "Back up now");
  out.push(h("div", { class: "card" }, h("h2", {}, "Save location"), h("div", { class: "sub" }, "Backups only ever read from this folder."),
    h("div", { class: "fieldrow" }, input, h("button", { class: "btn", onclick: async () => {
      const v = await api("pick_folder", { title: `Select your ${g.shortName} save folder` }); if (!v) return; await updateProfile(p, { saveDirectory: v }).catch(fail); render(); } }, "Browse…")),
    h("div", { style: "margin-top:14px" }, backBtn)));
  out.push(h("div", { class: "card" }, h("h2", {}, `Backups (${backups.length})`),
    h("div", { class: "sub" }, "Restoring a backup isn't available yet — it would write into a live save folder, and Nova Forge won't do that until it's been built and tested safely."),
    h("div", { class: "list" }, backups.length ? backups.map((b) => h("div", { class: "row" },
      h("div", { class: "grow" }, h("div", { class: "title" }, new Date(b.createdUtc).toLocaleString()), h("div", { class: "meta" }, `${b.files} files · ${fmtBytes(b.sizeBytes)} · from ${b.sourcePath}`)),
      h("button", { class: "btn sm", onclick: () => api("open_path", { path: b.folder }).catch(fail) }, "Show"))) : [h("div", { class: "empty" }, "No backups yet.")])));
  return out;
}

/* ---------- Game: planned sections ---------- */
function viewPlanned(key, title) {
  return async () => {
    const g = game(S.gameId), items = (g.planned || {})[key] || [];
    return [pageHead(title, g.name),
      h("div", { class: "notice info" }, icon("info"), `${title} isn't built yet for ${g.shortName}. Nothing here reads or changes your game.`),
      h("div", { class: "card" }, h("h2", {}, "Planned"), h("div", { class: "sub" }, "What this section is meant to cover:"),
        h("div", { class: "plan-list" }, items.length ? items.map((i) => h("span", {}, i)) : h("span", {}, "Nothing planned yet")))];
  };
}

/* ---------- Settings ---------- */
function renderLegal(md) {
  const out = [];
  for (const raw of md.split(/\r?\n/)) {
    const line = raw.trim(); if (!line) continue;
    if (line.startsWith("## ")) out.push(h("h3", {}, line.slice(3)));
    else if (line.startsWith("# ")) continue;
    else {
      const p = h("p", {});
      line.split(/\*\*(.+?)\*\*/g).forEach((part, i) => p.append(i % 2 ? h("strong", { style: "color:var(--text)" }, part) : part));
      out.push(p);
    }
  }
  return h("div", { class: "legal" }, out);
}
async function viewSettings() {
  const tabs = [["general", "General"], ["data", "Data"], ["legal", "Legal"], ["about", "About"]];
  const out = [pageHead("Settings", "App-wide settings. Game-specific tools live inside each game."),
    h("div", { class: "tabs" }, tabs.map(([k, label]) => h("button", { class: "tab" + (S.tab === k ? " on" : ""), onclick: () => { S.tab = k; render(); } }, label)))];
  if (S.tab === "general") {
    out.push(h("div", { class: "card" }, h("h2", {}, "Accent color"), h("div", { class: "sub" }, "Changes highlights across the app."),
      h("div", { class: "swatches" }, Object.entries(ACCENTS).map(([name, [c]]) => h("div", { class: "swatch" + ((S.cfg.accentColor || "Violet") === name ? " on" : ""), title: name, style: `background:${c}`,
        onclick: async () => { S.cfg.accentColor = name; applyAccent(); await saveCfg(); render(); } })))));
  } else if (S.tab === "data") {
    out.push(h("div", { class: "card" }, h("h2", {}, "Where your data lives"), h("div", { class: "sub" }, "Profiles, mod catalogs and backups are stored locally on this PC. Nothing is uploaded."),
      h("div", { class: "fieldrow" }, h("input", { type: "text", readOnly: true, value: S.boot.dataDir }), h("button", { class: "btn", onclick: () => api("open_path", { path: S.boot.dataDir }).catch(fail) }, "Open folder"))));
  } else if (S.tab === "legal") {
    out.push(legalLinks());
    out.push(h("div", { class: "card" }, h("h2", {}, "Legal notice"), h("div", { style: "height:10px" }), renderLegal(S.boot.legal)));
  } else {
    out.push(h("div", { class: "card" }, h("h2", {}, "Nova Forge"), h("p", { class: "muted", style: "margin-top:6px" }, `Version ${S.boot.version}. A game customization and mod catalog tool. Not an emulator; includes no game files.`)));
  }
  return out;
}


/* ---------- Nova product switcher ---------- */
// Same list and behavior as Atlas / Replay.gg / Nova Cut (kept in sync by hand). Apps start if installed,
// otherwise open their download page; sites open in the browser. Address table lives in the backend.
const NOVA_MARK = '<svg viewBox="0 0 24 24" aria-hidden="true"><rect width="24" height="24" rx="5.5" fill="#0E1120"/><path fill="#7C5CFF" d="M12 3.1c.52 5.46 3.95 8.89 9.41 9.41-5.46.52-8.89 3.95-9.41 9.41-.52-5.46-3.95-8.89-9.41-9.41C8.05 11.99 11.48 8.56 12 3.1Z"/></svg>';
const NOVA_CURRENT = "nova-forge";
const NOVA_PRODUCTS = [
  { id: "nova-cut", label: "Nova Cut", tagline: "Create and edit", icon: "scissors", kind: "soon" },
  { id: "replay-gg", label: "Replay.GG", tagline: "Record and clip gameplay", icon: "gamepad", kind: "app" },
  { id: "atlas", label: "Atlas", tagline: "Your desktop assistant", icon: "sparkles", kind: "app" },
  { id: "nova-forge", label: "Nova Forge", tagline: "Customize games and mods", icon: "tool", kind: "app" },
  { id: "nova-games", label: "Nova Games", tagline: "Coming soon", icon: "gamepad", kind: "soon" },
];
const NOVA_SITES = [
  { id: "nova-help", label: "Nova.Help", tagline: "Support and guides", icon: "search", kind: "site" },
  { id: "atlas-site", label: "Atlas Website", tagline: "Download and learn about Atlas", icon: "sparkles", kind: "site" },
  { id: "nova", label: "Nova", tagline: "The Nova home page", icon: "globe", kind: "site" },
  { id: "nova-legal", label: "Nova Legal", tagline: "Terms and privacy", icon: "file", kind: "site" },
  { id: "nova-cut-site", label: "Nova Cut Website", tagline: "Nova Cut, on the web", icon: "scissors", kind: "soon" },
];
let switcherOpen = false;
let switcherMenu = null;

function closeSwitcher() {
  switcherOpen = false;
  if (switcherMenu) switcherMenu.removeAttribute("data-open");
  document.querySelectorAll(".switcher-trigger").forEach((b) => b.setAttribute("aria-expanded", "false"));
}
async function openNovaProduct(p, after) {
  if (p.kind === "soon") return toast(`${p.label} isn't available yet.`);
  const r = await api("open_product", { id: p.id }).catch((e) => { toast(`Couldn't open ${p.label}: ${e}`, "bad"); return null; });
  if (!r) return;
  if (r === "notinstalled") toast(`${p.label} isn't installed on this PC \u2014 opened its page.`);
  else if (r === "running") toast(`${p.label} is already running (check the system tray).`);
  after && after();
}
function productRow(p, onPick) {
  const current = p.id === NOVA_CURRENT;
  const body = [h("span", { class: "sw-ic" }, icon(p.icon)),
    h("span", { class: "sw-tx" }, h("b", {}, p.label), h("small", {}, current ? "You're here" : p.tagline))];
  if (current) return h("span", { class: "sw-row current", role: "menuitem" }, body);
  if (p.kind === "soon") return h("span", { class: "sw-row soon", role: "menuitem", "aria-disabled": "true" }, body, h("span", { class: "sw-soon" }, "Soon"));
  return h("button", { class: "sw-row", role: "menuitem", onclick: () => onPick(p) }, body, p.kind === "site" ? icon("globe") : null);
}
function openAllProducts() {
  const col = (title, items) => h("div", {}, h("h3", { style: "margin:0 0 8px" }, title), h("div", { class: "sw-list" }, items.map((p) => productRow(p, (x) => openNovaProduct(x)))));
  openModal((close) => [h("h2", {}, "Nova"), h("p", { class: "muted", style: "margin:4px 0 16px" }, "Apps and websites from the Nova family."),
    h("div", { class: "sw-cols" }, col("Apps", NOVA_PRODUCTS), col("Websites", NOVA_SITES)),
    h("div", { class: "actions" }, h("button", { class: "btn", onclick: close }, "Close"))], "wide");
}
function novaSwitcher() {
  const trigger = h("button", { class: "switcher-trigger", "aria-haspopup": "menu", "aria-expanded": "false" },
    h("span", { class: "sw-mark", html: NOVA_MARK }), h("span", {}, "Product Switcher"), icon("chevron"));
  if (!switcherMenu) {
    switcherMenu = h("div", { class: "switcher-menu", role: "menu" });
    document.body.append(switcherMenu);
    document.addEventListener("click", (e) => { if (switcherOpen && !switcherMenu.contains(e.target) && !e.target.closest(".switcher-trigger")) closeSwitcher(); });
    document.addEventListener("keydown", (e) => { if (e.key === "Escape" && switcherOpen) closeSwitcher(); });
  }
  switcherMenu.replaceChildren(h("p", { class: "sw-head" }, "Nova"),
    ...NOVA_PRODUCTS.map((p) => productRow(p, (x) => openNovaProduct(x, closeSwitcher))),
    h("button", { class: "sw-all", onclick: () => { closeSwitcher(); openAllProducts(); } }, "View all", icon("arrow")));
  trigger.addEventListener("click", () => {
    if (switcherOpen) return closeSwitcher();
    const r = trigger.getBoundingClientRect();
    switcherMenu.style.top = r.bottom + 8 + "px"; switcherMenu.style.left = r.left + "px";
    switcherOpen = true; switcherMenu.setAttribute("data-open", ""); trigger.setAttribute("aria-expanded", "true");
  });
  return h("div", { class: "switcher" }, trigger);
}

/* ---------- boot ---------- */
async function init() {
  try {
    S.boot = await api("bootstrap");
    S.reg = S.boot.registry; S.cfg = S.boot.config || {};
    applyAccent();
    render();
    if (!S.cfg.acceptedLegalNotice) {
      openModal((close) => [h("h2", {}, "Before you start"),
        h("div", { class: "legal", style: "margin-top:12px" },
          h("p", {}, "Nova Forge does not own, sell, host, or distribute any third-party games or game files. You must provide your own legally obtained copies."),
          h("p", {}, "It is not an emulator and includes none. It is not affiliated with or endorsed by any game publisher."),
          h("p", {}, "Modding carries risk, including save loss. Back up your saves."),
          h("p", {}, "Full details: ", h("a", { class: "link", onclick: () => ext(NOVA_LEGAL + "/products/nova-forge") }, "Nova Legal"), ".")),
        h("div", { class: "actions" }, h("button", { class: "btn primary", onclick: async () => { S.cfg.acceptedLegalNotice = true; await saveCfg(); close(); } }, "I understand"))]);
      document.getElementById("modal").onclick = null;
    }
  } catch (e) {
    document.getElementById("content").replaceChildren(h("div", { class: "notice" }, "Couldn't start: " + e));
  }
}
init();
