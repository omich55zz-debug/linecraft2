import { xpForLevel } from "../game/player.js";

export function initHud({ player, onSkill, scene, camera, renderer }) {
  const hud = document.getElementById("hud");
  hud.classList.remove("hidden");

  const hpFill = document.querySelector(".bar.hp > span");
  const mpFill = document.querySelector(".bar.mp > span");
  const xpFill = document.querySelector(".bar.xp > span");
  const hpText = document.getElementById("hp-text");
  const mpText = document.getElementById("mp-text");
  const xpText = document.getElementById("xp-text");
  const charName = document.getElementById("char-name");
  const charMeta = document.getElementById("char-meta");

  const tFrame = document.getElementById("target-frame");
  const tName = document.getElementById("t-name");
  const tLvl = document.getElementById("t-lvl");
  const tHpFill = document.getElementById("t-hp-fill");
  const tHpText = document.getElementById("t-hp-text");

  charName.textContent = player.name;
  charMeta.textContent = `${player.race.name} · ${player.klass.name}`;

  function refresh() {
    hpFill.style.width = `${(player.hp / player.maxHp) * 100}%`;
    mpFill.style.width = `${(player.mp / player.maxMp) * 100}%`;
    const need = xpForLevel(player.level);
    xpFill.style.width = `${Math.min(100, (player.xp / need) * 100)}%`;
    hpText.textContent = `${Math.round(player.hp)} / ${player.maxHp}`;
    mpText.textContent = `${Math.round(player.mp)} / ${player.maxMp}`;
    xpText.textContent = `${Math.round((player.xp / need) * 100)}%`;
    charMeta.textContent = `${player.race.name} · ${player.klass.name} · ур. ${player.level}`;

    if (player.target && !player.target.dead) {
      tFrame.classList.remove("hidden");
      tName.textContent = player.target.kind.name;
      tLvl.textContent = `ур. ${player.target.kind.level}`;
      const f = player.target.hp / player.target.maxHp;
      tHpFill.style.transform = ""; // not used
      const ttFill = tFrame.querySelector(".bar.hp > span");
      if (ttFill) ttFill.style.width = `${f * 100}%`;
      tHpText.textContent = `${Math.round(player.target.hp)} / ${player.target.maxHp}`;
    } else {
      tFrame.classList.add("hidden");
    }
  }
  player.onChange = refresh;
  refresh();

  // Action bar buttons
  document.querySelectorAll("#action-bar .slot").forEach((btn) => {
    btn.addEventListener("click", () => onSkill(btn.dataset.skill));
  });

  // Keyboard shortcuts
  window.addEventListener("keydown", (e) => {
    if (e.target.matches("input, textarea")) return;
    if (e.key === "1") onSkill("attack");
    else if (e.key === "2") onSkill("power");
    else if (e.key === "3") onSkill("heal");
    else if (e.key.toLowerCase() === "r") onSkill("sit");
    else if (e.key === "Escape") player.target = null;
  });

  // Inventory + character modals
  document.getElementById("btn-inventory").addEventListener("click", () => {
    document.getElementById("modal-inventory").showModal();
  });
  document.getElementById("btn-character").addEventListener("click", () => {
    const stats = document.getElementById("char-stats");
    stats.innerHTML = "";
    const r = player.race, k = player.klass;
    const rows = [
      ["Раса", r.name], ["Класс", k.name], ["Уровень", player.level],
      ["HP", `${Math.round(player.hp)} / ${player.maxHp}`],
      ["MP", `${Math.round(player.mp)} / ${player.maxMp}`],
      ["Атака", player.atk], ["Магия", player.mAtk],
      ["STR", r.stats.str], ["DEX", r.stats.dex], ["CON", r.stats.con],
      ["INT", r.stats.int], ["WIT", r.stats.wit], ["MEN", r.stats.men],
    ];
    rows.forEach(([k, v]) => {
      const a = document.createElement("span"); a.textContent = k;
      const b = document.createElement("span"); b.textContent = v;
      stats.appendChild(a); stats.appendChild(b);
    });
    document.getElementById("modal-character").showModal();
  });

  // Floating damage numbers
  function spawnFloatText(world, text, kind = "hit") {
    const proj = world.clone().project(camera);
    const x = (proj.x * 0.5 + 0.5) * window.innerWidth;
    const y = (-proj.y * 0.5 + 0.5) * window.innerHeight;
    if (proj.z > 1) return;
    const el = document.createElement("div");
    el.className = `dmg-num ${kind}`;
    el.textContent = text;
    el.style.left = `${x}px`;
    el.style.top = `${y}px`;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 1000);
  }

  function toast(text, kind = "") {
    const host = document.getElementById("toast-host");
    const el = document.createElement("div");
    el.className = `toast ${kind}`;
    el.textContent = text;
    host.appendChild(el);
    setTimeout(() => el.remove(), 2400);
  }

  return { refresh, spawnFloatText, toast };
}
