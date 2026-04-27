// Procedurally builds a low-poly humanoid for any race.
// Uses pivot groups for limbs so we can animate walk/run/attack.
import * as THREE from "three";

export class Character {
  constructor({ race, klass, isPlayer = false }) {
    this.race = race;
    this.klass = klass;
    this.isPlayer = isPlayer;
    this.group = new THREE.Group();
    this.t = 0;
    this.walkT = 0;
    this.attackT = 0;
    this.deathT = 0;
    this.dead = false;
    this._build();
  }

  get position() { return this.group.position; }

  _build() {
    const r = this.race;
    const h = r.height ?? 1;
    const skin = new THREE.MeshStandardMaterial({ color: r.skin, roughness: 0.7 });
    const cloth = new THREE.MeshStandardMaterial({ color: r.cape ?? 0x355978, roughness: 0.85 });
    const dark = new THREE.MeshStandardMaterial({ color: shade(r.cape ?? 0x355978, -0.4), roughness: 0.85 });
    const hair = new THREE.MeshStandardMaterial({ color: r.hair ?? 0x6f4e2a, roughness: 0.7 });
    const metal = new THREE.MeshStandardMaterial({ color: 0xa8b0c4, metalness: 0.7, roughness: 0.35 });

    // Torso pivot for body lean / attack tilt
    this.torso = new THREE.Group();
    this.torso.position.y = 0.95 * h;
    this.group.add(this.torso);

    const body = new THREE.Mesh(new THREE.CapsuleGeometry(0.32 * h, 0.6 * h, 4, 8), cloth);
    body.castShadow = true;
    this.torso.add(body);

    // Belt
    const belt = new THREE.Mesh(new THREE.TorusGeometry(0.34 * h, 0.05 * h, 8, 16), metal);
    belt.rotation.x = Math.PI / 2;
    belt.position.y = -0.18 * h;
    this.torso.add(belt);

    // Head
    const headSize = 0.22 * h;
    this.head = new THREE.Mesh(new THREE.SphereGeometry(headSize, 16, 16), skin);
    this.head.position.y = 0.55 * h;
    this.head.castShadow = true;
    this.torso.add(this.head);

    // Hair / hood
    const hairMesh = new THREE.Mesh(
      new THREE.SphereGeometry(headSize * 1.08, 16, 16, 0, Math.PI * 2, 0, Math.PI / 2),
      hair,
    );
    hairMesh.position.copy(this.head.position);
    hairMesh.position.y += 0.02;
    this.torso.add(hairMesh);

    // Ears (long for elves / dark elves)
    if (r.earsLong) {
      const ear = new THREE.Mesh(new THREE.ConeGeometry(0.05 * h, 0.22 * h, 8), skin);
      ear.position.set(headSize * 0.95, 0.55 * h, 0);
      ear.rotation.z = -Math.PI / 2.2;
      this.torso.add(ear);
      const earR = ear.clone(); earR.position.x = -headSize * 0.95; earR.rotation.z = Math.PI / 2.2;
      this.torso.add(earR);
    }

    // Beard for dwarves
    if (r.beard) {
      const beard = new THREE.Mesh(new THREE.ConeGeometry(0.18 * h, 0.3 * h, 12), hair);
      beard.position.set(0, 0.4 * h, 0.18 * h);
      beard.rotation.x = Math.PI;
      this.torso.add(beard);
    }

    // Tusks for orcs
    if (r.tusks) {
      const tuskMat = new THREE.MeshStandardMaterial({ color: 0xfff0c8, roughness: 0.5 });
      const tusk = new THREE.Mesh(new THREE.ConeGeometry(0.025 * h, 0.12 * h, 6), tuskMat);
      tusk.position.set(0.06 * h, 0.5 * h, 0.18 * h);
      tusk.rotation.x = -Math.PI;
      this.torso.add(tusk);
      const t2 = tusk.clone(); t2.position.x = -0.06 * h; this.torso.add(t2);
    }

    // Wings for kamael
    if (r.wings) {
      const wingMat = new THREE.MeshStandardMaterial({
        color: 0x1a1a26, side: THREE.DoubleSide, roughness: 0.85, transparent: true, opacity: 0.92,
      });
      const wL = new THREE.Mesh(new THREE.PlaneGeometry(0.55 * h, 0.7 * h), wingMat);
      wL.position.set(0.36 * h, 0.15 * h, -0.18 * h);
      wL.rotation.set(0, -0.5, 0.3);
      this.torso.add(wL);
      const wR = wL.clone();
      wR.position.x = -0.36 * h;
      wR.rotation.set(0, 0.5, -0.3);
      this.torso.add(wR);
      this._wingsL = wL; this._wingsR = wR;
    }

    // Legs
    this.legL = new THREE.Group();
    this.legL.position.set(0.13 * h, 0.55 * h, 0);
    const legL = new THREE.Mesh(new THREE.BoxGeometry(0.16 * h, 0.5 * h, 0.18 * h), dark);
    legL.position.y = -0.25 * h;
    legL.castShadow = true;
    this.legL.add(legL);
    this.group.add(this.legL);
    this.legR = this.legL.clone(true);
    this.legR.position.x = -0.13 * h;
    this.group.add(this.legR);

    // Arms
    this.armR = new THREE.Group();
    this.armR.position.set(0.32 * h, 1.25 * h, 0);
    const upR = new THREE.Mesh(new THREE.BoxGeometry(0.13 * h, 0.5 * h, 0.13 * h), cloth);
    upR.position.y = -0.18 * h;
    this.armR.add(upR);
    // Hand
    const handR = new THREE.Mesh(new THREE.BoxGeometry(0.13 * h, 0.13 * h, 0.13 * h), skin);
    handR.position.y = -0.5 * h;
    this.armR.add(handR);
    // Weapon attached to right hand
    this.weapon = buildWeapon(this.klass.id);
    this.weapon.position.set(0, -0.5 * h, 0.05 * h);
    this.armR.add(this.weapon);
    this.group.add(this.armR);

    this.armL = new THREE.Group();
    this.armL.position.set(-0.32 * h, 1.25 * h, 0);
    const upL = upR.clone();
    this.armL.add(upL);
    const handL = handR.clone();
    this.armL.add(handL);
    // Shield for fighters
    if (this.klass.id === "fighter" || this.klass.id === "trooper" || this.klass.id === "raider") {
      const shield = new THREE.Mesh(new THREE.BoxGeometry(0.45 * h, 0.55 * h, 0.06 * h), metal);
      shield.position.set(0.05 * h, -0.5 * h, 0.12 * h);
      this.armL.add(shield);
    }
    this.group.add(this.armL);

    // Cape
    this.cape = new THREE.Mesh(
      new THREE.ConeGeometry(0.5 * h, 1.1 * h, 12, 1, true),
      new THREE.MeshStandardMaterial({ color: shade(r.cape ?? 0x355978, -0.3), side: THREE.DoubleSide, roughness: 0.95 }),
    );
    this.cape.position.set(0, 0.9 * h, -0.08 * h);
    this.cape.rotation.x = Math.PI;
    this.cape.castShadow = true;
    this.torso.add(this.cape);

    // Selection / target ring (hidden by default)
    const ringGeo = new THREE.RingGeometry(0.55, 0.7, 24);
    this.ring = new THREE.Mesh(
      ringGeo,
      new THREE.MeshBasicMaterial({ color: 0x6effa0, transparent: true, opacity: 0.9, side: THREE.DoubleSide }),
    );
    this.ring.rotation.x = -Math.PI / 2;
    this.ring.position.y = 0.02;
    this.ring.visible = false;
    this.group.add(this.ring);
  }

  setRingColor(hex) {
    if (this.ring) this.ring.material.color.setHex(hex);
  }

  showRing(on) {
    if (this.ring) this.ring.visible = !!on;
  }

  triggerAttack() {
    this.attackT = 0.4;
  }

  triggerDeath() {
    if (this.dead) return;
    this.dead = true;
    this.deathT = 0;
  }

  update(dt, moveSpeed = 0) {
    this.t += dt;
    if (this.dead) {
      this.deathT += dt;
      const rot = Math.min(Math.PI / 2, this.deathT * 4);
      this.torso.rotation.x = rot;
      this.group.position.y = Math.max(0, 0.05 - this.deathT * 0.05);
      return;
    }

    const moving = moveSpeed > 0.05 ? 1 : 0;
    this.walkT += dt * 8 * (moving ? 1 : 0);
    const w = Math.sin(this.walkT) * 0.6 * (moving ? 1 : 0);

    if (this.legL) this.legL.rotation.x = w;
    if (this.legR) this.legR.rotation.x = -w;
    if (this.cape) this.cape.rotation.x = Math.PI + Math.sin(this.t * 3) * 0.07;
    // Body bob
    this.group.position.y = moving ? Math.abs(Math.sin(this.walkT * 2)) * 0.04 : 0;

    if (this._wingsL) {
      const flap = Math.sin(this.t * 4) * 0.2;
      this._wingsL.rotation.z = 0.3 + flap;
      this._wingsR.rotation.z = -0.3 - flap;
    }

    // Idle arm sway
    if (this.attackT <= 0) {
      this.armL.rotation.x = Math.sin(this.walkT) * 0.4 * (moving ? 1 : 0.15);
      this.armR.rotation.x = -Math.sin(this.walkT) * 0.3 * (moving ? 1 : 0.15);
      if (this.torso) this.torso.rotation.y *= 0.85;
    } else {
      const phase = 1 - this.attackT / 0.4;
      const swing = Math.sin(Math.PI * phase);
      this.armR.rotation.x = -1.6 * swing;
      this.armR.rotation.z = -0.2 * swing;
      if (this.torso) this.torso.rotation.y = -0.3 * swing;
      this.attackT -= dt;
    }
  }
}

function buildWeapon(classId) {
  const g = new THREE.Group();
  const wood = new THREE.MeshStandardMaterial({ color: 0x4a3018, roughness: 0.9 });
  const metal = new THREE.MeshStandardMaterial({ color: 0xc8d0d8, metalness: 0.85, roughness: 0.25 });
  const gold = new THREE.MeshStandardMaterial({ color: 0xc9a14a, metalness: 0.7, roughness: 0.3 });

  switch (classId) {
    case "mystic":
    case "shaman": {
      // Staff
      const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.04, 0.04, 1.4, 8), wood);
      shaft.position.y = 0.4;
      g.add(shaft);
      const orb = new THREE.Mesh(
        new THREE.SphereGeometry(0.12, 16, 16),
        new THREE.MeshStandardMaterial({
          color: 0x6effd1, emissive: 0x33aa88, emissiveIntensity: 0.8, roughness: 0.4,
        }),
      );
      orb.position.y = 1.15;
      g.add(orb);
      break;
    }
    case "raider":
    case "trooper": {
      // Two-handed axe / great sword
      const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.05, 1.0, 8), wood);
      shaft.position.y = 0.2;
      g.add(shaft);
      const head = new THREE.Mesh(new THREE.BoxGeometry(0.5, 0.32, 0.06), metal);
      head.position.y = 0.78;
      g.add(head);
      break;
    }
    case "soldier": {
      // Crossbow-like
      const shaft = new THREE.Mesh(new THREE.BoxGeometry(0.5, 0.06, 0.1), wood);
      shaft.position.y = 0.1;
      g.add(shaft);
      const arms = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.06, 0.5), metal);
      arms.position.y = 0.1;
      arms.position.x = 0.18;
      g.add(arms);
      break;
    }
    case "scavenger":
    case "artisan": {
      // Pickaxe/hammer
      const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.04, 0.04, 0.9, 8), wood);
      shaft.position.y = 0.2;
      g.add(shaft);
      const head = new THREE.Mesh(new THREE.BoxGeometry(0.36, 0.18, 0.18), metal);
      head.position.y = 0.7;
      g.add(head);
      break;
    }
    default: {
      // One-handed sword
      const blade = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.85, 0.02), metal);
      blade.position.y = 0.5;
      g.add(blade);
      const guard = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.06, 0.06), gold);
      guard.position.y = 0.05;
      g.add(guard);
      const grip = new THREE.Mesh(new THREE.CylinderGeometry(0.04, 0.04, 0.18, 8), wood);
      grip.position.y = -0.05;
      g.add(grip);
      break;
    }
  }
  return g;
}

function shade(hex, amt) {
  const r = (hex >> 16) & 0xff, g = (hex >> 8) & 0xff, b = hex & 0xff;
  const f = (v) => Math.max(0, Math.min(255, Math.round(v + amt * 255)));
  return (f(r) << 16) | (f(g) << 8) | f(b);
}
