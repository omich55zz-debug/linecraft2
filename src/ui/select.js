import { RACES, CLASSES } from "../game/races.js";

export function initSelectScreen(onStart) {
  const screen = document.getElementById("select-screen");
  const raceList = document.getElementById("race-list");
  const classList = document.getElementById("class-list");
  const nameInput = document.getElementById("hero-name");
  const startBtn = document.getElementById("start-btn");

  let selRace = null;
  let selClass = null;

  function refreshStart() {
    startBtn.disabled = !(selRace && selClass);
  }

  RACES.forEach((r) => {
    const card = document.createElement("div");
    card.className = "race-card";
    card.dataset.race = r.id;
    card.innerHTML = `<span class="icon">${r.icon}</span><div class="name">${r.name}</div><div class="desc">${r.desc}</div>`;
    card.addEventListener("click", () => {
      selRace = r;
      selClass = null;
      raceList.querySelectorAll(".race-card").forEach((c) => c.classList.toggle("active", c.dataset.race === r.id));
      classList.innerHTML = "";
      r.classes.forEach((cid) => {
        const k = CLASSES[cid];
        const cc = document.createElement("div");
        cc.className = "class-card";
        cc.dataset.cls = cid;
        cc.innerHTML = `<div class="name">${k.name}</div><div class="desc">${k.desc}</div>`;
        cc.addEventListener("click", () => {
          selClass = k;
          classList.querySelectorAll(".class-card").forEach((c) => c.classList.toggle("active", c.dataset.cls === cid));
          refreshStart();
        });
        classList.appendChild(cc);
      });
      refreshStart();
    });
    raceList.appendChild(card);
  });

  startBtn.addEventListener("click", () => {
    if (!selRace || !selClass) return;
    const name = (nameInput.value || "").trim() || "Авантюрист";
    screen.classList.add("hidden");
    onStart({ race: selRace, klass: selClass, name });
  });
}
