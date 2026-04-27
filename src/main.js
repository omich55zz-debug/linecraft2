import * as THREE from "three";
import "./style.css";
import { initSelectScreen } from "./ui/select.js";
import { createWorld } from "./world/scene.js";
import { FollowCamera } from "./engine/camera.js";
import { Player } from "./game/player.js";
import { spawnMonsters } from "./entities/monsters.js";
import { initHud } from "./ui/hud.js";

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("./sw.js").catch(() => {});
  });
}

const canvas = document.getElementById("scene");
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

const camera = new THREE.PerspectiveCamera(60, window.innerWidth / window.innerHeight, 0.1, 200);
camera.position.set(8, 12, 8);

window.addEventListener("resize", () => {
  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
});

const { scene, ground } = createWorld();

initSelectScreen(({ race, klass, name }) => {
  startGame({ race, klass, name });
});

function startGame({ race, klass, name }) {
  const player = new Player({ race, klass, name, scene });
  player.position.set(0, 0, 0);

  const monsters = spawnMonsters(scene, 12);

  const camCtrl = new FollowCamera({ camera, target: player.character.group, dom: canvas });

  // Click-to-move + click-to-target via raycast
  const raycaster = new THREE.Raycaster();
  const mouse = new THREE.Vector2();
  const arrowGeom = new THREE.RingGeometry(0.25, 0.45, 16);
  const arrowMat = new THREE.MeshBasicMaterial({ color: 0x6effa0, transparent: true, opacity: 0.85, side: THREE.DoubleSide });
  const moveArrow = new THREE.Mesh(arrowGeom, arrowMat);
  moveArrow.rotation.x = -Math.PI / 2;
  moveArrow.visible = false;
  scene.add(moveArrow);
  let arrowT = 0;

  function getIntersect(event) {
    const rect = canvas.getBoundingClientRect();
    mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
    raycaster.setFromCamera(mouse, camera);
    return raycaster;
  }

  canvas.addEventListener("mousedown", (e) => {
    if (e.button !== 0) return;
    const rc = getIntersect(e);
    // Try monsters first
    const monsterMeshes = monsters.filter((m) => !m.dead).map((m) => m.group);
    const monsterHits = rc.intersectObjects(monsterMeshes, true);
    if (monsterHits.length > 0) {
      let g = monsterHits[0].object;
      while (g && !g.userData?.monster) g = g.parent;
      if (g?.userData?.monster) {
        player.target = g.userData.monster;
        // Highlight
        monsters.forEach((m) => m.targeted = false);
        g.userData.monster.targeted = true;
        return;
      }
    }
    // Otherwise click on ground
    const groundHit = rc.intersectObject(ground);
    if (groundHit.length > 0) {
      const p = groundHit[0].point;
      player.target = null;
      player.moveTarget = new THREE.Vector3(p.x, 0, p.z);
      moveArrow.position.set(p.x, 0.05, p.z);
      moveArrow.visible = true;
      arrowT = 0.6;
    }
  });

  // Skills
  function onSkill(id) {
    if (player.dead) return;
    if (id === "attack") {
      // Toggle target (or click again triggers extra swing)
      if (player.target && !player.target.dead && player.atkCd <= 0) {
        player.atkCd = 0; // force immediate
      }
    } else if (id === "power") {
      if (!player.target || player.target.dead) {
        hud.toast("Нет цели", "bad"); return;
      }
      if (player.gcd > 0) return;
      if (!player.spendMp(8)) { hud.toast("Не хватает MP", "bad"); return; }
      player.gcd = 1.6;
      player.character.triggerAttack();
      const dmg = player.atk * 2 + 5 + Math.floor(Math.random() * 6);
      const t = player.target;
      setTimeout(() => {
        if (!t.dead) {
          t.setHp(t.hp - dmg);
          t.flashDamage();
          hud.spawnFloatText(t.position.clone().add(new THREE.Vector3(0, 1.6, 0)), `-${dmg}`, "crit");
        }
      }, 200);
    } else if (id === "heal") {
      if (player.gcd > 0) return;
      if (!player.spendMp(12)) { hud.toast("Не хватает MP", "bad"); return; }
      player.gcd = 1.6;
      const heal = 25 + Math.floor(Math.random() * 10);
      player.heal(heal);
      hud.spawnFloatText(player.position.clone().add(new THREE.Vector3(0, 2, 0)), `+${heal}`, "heal");
    } else if (id === "sit") {
      // Stop and sit (regen boost)
      player.moveTarget = null;
      player.hp = Math.min(player.maxHp, player.hp + 15);
      player.mp = Math.min(player.maxMp, player.mp + 15);
      player.emit();
      hud.toast("Сел отдыхать", "");
    }
  }

  const hud = initHud({ player, onSkill, scene, camera, renderer });

  // Track auto-attack hits
  player._onHit = (target, dmg) => {
    hud.spawnFloatText(target.position.clone().add(new THREE.Vector3(0, 1.6, 0)), `-${dmg}`, "hit");
    if (target.dead) {
      const xp = target.kind.xp;
      const wasLevel = player.level;
      player.awardXp(xp);
      hud.spawnFloatText(target.position.clone().add(new THREE.Vector3(0, 1.6, 0)), `+${xp} XP`, "heal");
      if (player.consumeLevelUp()) {
        hud.toast(`Уровень ${player.level}!`, "good");
      }
      // Drop loot timer; respawn after 8s
      setTimeout(() => respawn(target), 8000);
      if (player.target === target) player.target = null;
    }
  };

  function respawn(m) {
    const angle = Math.random() * Math.PI * 2;
    const dist = 14 + Math.random() * 30;
    m.dead = false;
    m.deathT = 0;
    m.hp = m.maxHp;
    m.group.scale.set(1, 1, 1);
    m.group.rotation.set(0, 0, 0);
    m.group.position.set(Math.cos(angle) * dist, 0, Math.sin(angle) * dist);
    if (m.hpSprite) {
      m.hpSprite.material.map.needsUpdate = true;
    }
  }

  // Game loop
  let last = performance.now();
  function tick(now) {
    const dt = Math.min(0.1, (now - last) / 1000);
    last = now;

    player.update(dt);
    monsters.forEach((m) => {
      // Aggro: monsters attack player if within 8m
      const dx = player.position.x - m.position.x;
      const dz = player.position.z - m.position.z;
      const d = Math.hypot(dx, dz);
      const aggro = !m.dead && d < 8 ? player : null;
      m.update(dt, aggro);
    });

    // HP sprite billboard
    monsters.forEach((m) => {
      if (m.hpSprite) {
        m.hpSprite.visible = !m.dead && m.hp < m.maxHp;
      }
    });

    if (arrowT > 0) {
      arrowT -= dt;
      if (arrowT <= 0) moveArrow.visible = false;
    }

    camCtrl.update();
    renderer.render(scene, camera);
    requestAnimationFrame(tick);
  }
  requestAnimationFrame(tick);

  // Player death handling
  setInterval(() => {
    if (player.dead) {
      hud.toast("Вы пали в бою. Возрождение...", "bad");
      setTimeout(() => {
        player.dead = false;
        player.character.dead = false;
        player.character.deathT = 0;
        player.character.torso.rotation.x = 0;
        player.hp = player.maxHp; player.mp = player.maxMp;
        player.position.set(0, 0, 0);
        player.emit();
      }, 2500);
    }
  }, 1000);
}
