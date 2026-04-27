import * as THREE from "three";

export const MONSTERS = [
  { id: "wolf",  name: "Волк",   level: 2,  hp: 35,  atk: 6, xp: 18,  loot: [3, 8],   color: 0x6b6b6b, scale: 1.0 },
  { id: "boar",  name: "Кабан",  level: 4,  hp: 60,  atk: 9, xp: 32,  loot: [5, 14],  color: 0x4a3528, scale: 1.1 },
  { id: "bear",  name: "Медведь",level: 7,  hp: 110, atk: 14,xp: 70,  loot: [12, 28], color: 0x40291a, scale: 1.4 },
  { id: "gnoll", name: "Гнолл",  level: 5,  hp: 80,  atk: 11,xp: 50,  loot: [8, 20],  color: 0x7a5a35, scale: 1.0 },
  { id: "orc-grunt", name: "Орк-разбойник", level: 9,  hp: 150, atk: 17, xp: 110, loot: [18, 40], color: 0x4a6235, scale: 1.05 },
];

export class Monster {
  constructor({ kind, position }) {
    this.kind = kind;
    this.maxHp = kind.hp;
    this.hp = kind.hp;
    this.dead = false;
    this.target = null;
    this.atkCd = 0;
    this.dmgFlash = 0;
    this.deathT = 0;
    this.group = new THREE.Group();
    this._build();
    this.group.position.copy(position);
  }

  get position() { return this.group.position; }

  _build() {
    const k = this.kind;
    const s = k.scale;

    // Body
    const bodyMat = new THREE.MeshStandardMaterial({ color: k.color, roughness: 0.85 });
    this.body = new THREE.Mesh(
      new THREE.CapsuleGeometry(0.35 * s, 0.55 * s, 4, 8),
      bodyMat,
    );
    this.body.rotation.z = Math.PI / 2;
    this.body.position.y = 0.45 * s;
    this.body.castShadow = true;
    this.group.add(this.body);

    // Head
    this.head = new THREE.Mesh(
      new THREE.SphereGeometry(0.28 * s, 12, 12),
      bodyMat,
    );
    this.head.position.set(0.7 * s, 0.55 * s, 0);
    this.group.add(this.head);

    // Eyes (red glow)
    const eyeMat = new THREE.MeshStandardMaterial({
      color: 0xff3a3a, emissive: 0xff2a2a, emissiveIntensity: 0.7,
    });
    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.04 * s, 8, 8), eyeMat);
    eye.position.set(0.92 * s, 0.62 * s, 0.12 * s);
    this.group.add(eye);
    const eye2 = eye.clone(); eye2.position.z = -0.12 * s; this.group.add(eye2);

    // Snout/tusks/horns
    if (k.id === "boar") {
      const tusk = new THREE.Mesh(
        new THREE.ConeGeometry(0.04 * s, 0.18 * s, 6),
        new THREE.MeshStandardMaterial({ color: 0xfff0c8 }),
      );
      tusk.position.set(0.95 * s, 0.5 * s, 0.1 * s);
      tusk.rotation.z = Math.PI / 2;
      this.group.add(tusk);
      const t2 = tusk.clone(); t2.position.z = -0.1 * s; this.group.add(t2);
    }
    if (k.id === "bear") {
      this.body.scale.set(1.3, 1.3, 1.3);
      this.head.scale.set(1.3, 1.3, 1.3);
    }
    if (k.id === "gnoll") {
      // Add cape
      const cape = new THREE.Mesh(
        new THREE.PlaneGeometry(0.6 * s, 0.7 * s),
        new THREE.MeshStandardMaterial({ color: 0x3a1a1a, side: THREE.DoubleSide }),
      );
      cape.position.set(-0.3 * s, 0.45 * s, 0);
      cape.rotation.y = Math.PI / 2;
      this.group.add(cape);
    }

    // Legs (4 for animals, 2 for humanoids)
    const legCount = (k.id === "gnoll" || k.id === "orc-grunt") ? 2 : 4;
    this.legs = [];
    for (let i = 0; i < legCount; i++) {
      const leg = new THREE.Mesh(
        new THREE.BoxGeometry(0.12 * s, 0.4 * s, 0.12 * s),
        new THREE.MeshStandardMaterial({ color: 0x2a1810 }),
      );
      const sx = (i % 2 === 0 ? 1 : -1) * 0.18 * s;
      const sz = legCount === 4 ? (i < 2 ? 0.4 : -0.4) * s : 0;
      leg.position.set(sx, 0.2 * s, sz);
      leg.castShadow = true;
      this.group.add(leg);
      this.legs.push(leg);
    }

    // HP bar above head (sprite)
    this.hpSprite = makeHpSprite();
    this.hpSprite.position.set(0, 1.6 * s, 0);
    this.group.add(this.hpSprite);

    this.group.userData.monster = this;
  }

  setHp(v) {
    this.hp = Math.max(0, Math.min(this.maxHp, v));
    if (this.hpSprite) updateHpSprite(this.hpSprite, this.hp / this.maxHp, this.kind.color);
    if (this.hp <= 0 && !this.dead) {
      this.dead = true;
      this.deathT = 0;
    }
  }

  flashDamage() { this.dmgFlash = 0.2; }

  update(dt, target) {
    if (this.dead) {
      this.deathT += dt;
      this.group.rotation.z = Math.min(Math.PI / 2, this.deathT * 4);
      const s = Math.max(0, 1 - this.deathT * 0.7);
      this.group.scale.set(s, s, s);
      return;
    }

    if (this.dmgFlash > 0) {
      this.dmgFlash -= dt;
      this.body.material.emissive = new THREE.Color(0xff3030);
      this.body.material.emissiveIntensity = this.dmgFlash * 4;
    } else {
      this.body.material.emissiveIntensity = 0;
    }

    if (this.atkCd > 0) this.atkCd -= dt;

    if (target && !target.dead) {
      const dx = target.position.x - this.position.x;
      const dz = target.position.z - this.position.z;
      const d = Math.hypot(dx, dz);
      if (d < 12) {
        // Face target
        this.group.rotation.y = Math.atan2(dx, dz);
        if (d > 1.6) {
          // Walk toward target
          const s = 2.2 * dt;
          this.position.x += (dx / d) * s;
          this.position.z += (dz / d) * s;
          // Animate legs
          this._walkT = (this._walkT ?? 0) + dt * 10;
          for (let i = 0; i < this.legs.length; i++) {
            this.legs[i].position.y = 0.2 + Math.abs(Math.sin(this._walkT + i * 1.5)) * 0.05;
          }
        } else {
          // Attack
          if (this.atkCd <= 0) {
            this.atkCd = 1.6;
            target.takeDamage(this.kind.atk);
          }
        }
      }
    }

    // Make HP sprite always face the camera (will be set by camera.update or main loop)
    if (this.hpSprite) this.hpSprite.lookAt(this.hpSprite.position.x + 0, this.hpSprite.position.y + 1, 0);
  }
}

export function spawnMonsters(scene, count = 8) {
  const out = [];
  for (let i = 0; i < count; i++) {
    const kind = MONSTERS[Math.floor(Math.random() * MONSTERS.length)];
    const angle = Math.random() * Math.PI * 2;
    const dist = 14 + Math.random() * 30;
    const m = new Monster({
      kind,
      position: new THREE.Vector3(Math.cos(angle) * dist, 0, Math.sin(angle) * dist),
    });
    scene.add(m.group);
    out.push(m);
  }
  return out;
}

// ==== HP Sprite ====
function makeHpSprite() {
  const c = document.createElement("canvas");
  c.width = 128; c.height = 28;
  const ctx = c.getContext("2d");
  const tex = new THREE.CanvasTexture(c);
  const mat = new THREE.SpriteMaterial({ map: tex, transparent: true });
  const s = new THREE.Sprite(mat);
  s.scale.set(1.4, 0.3, 1);
  updateHpSprite(s, 1, 0x6b6b6b);
  return s;
}
function updateHpSprite(sprite, frac, color) {
  const c = sprite.material.map.image;
  const ctx = c.getContext("2d");
  ctx.clearRect(0, 0, c.width, c.height);
  ctx.fillStyle = "rgba(0,0,0,0.65)";
  ctx.fillRect(0, 0, c.width, c.height);
  ctx.strokeStyle = "#000";
  ctx.lineWidth = 2;
  ctx.strokeRect(1, 1, c.width - 2, c.height - 2);
  // HP fill
  ctx.fillStyle = "#c33636";
  ctx.fillRect(3, 3, (c.width - 6) * Math.max(0, frac), c.height - 6);
  sprite.material.map.needsUpdate = true;
}
