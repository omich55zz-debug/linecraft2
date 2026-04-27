import * as THREE from "three";
import { Character } from "../entities/character.js";

export class Player {
  constructor({ race, klass, name, scene }) {
    this.name = name || "Авантюрист";
    this.race = race;
    this.klass = klass;
    this.level = 1;
    this.xp = 0;
    this.maxHp = klass.baseHp + Math.floor(race.stats.con * 0.6);
    this.hp = this.maxHp;
    this.maxMp = klass.baseMp + Math.floor(race.stats.men * 0.5);
    this.mp = this.maxMp;
    this.atk = klass.atk + Math.floor(race.stats.str * 0.2);
    this.mAtk = klass.mAtk + Math.floor(race.stats.int * 0.2);
    this.dead = false;

    this.character = new Character({ race, klass, isPlayer: true });
    this.character.setRingColor(0x6effa0);
    this.character.showRing(true);
    scene.add(this.character.group);

    this.target = null;          // current Monster instance or null
    this.moveTarget = null;      // THREE.Vector3 or null
    this.atkCd = 0;
    this.gcd = 0;
    this._lastPos = new THREE.Vector3();
    this._mvSpeed = 0;
    this.onChange = null;        // callback(this) when stats change
  }

  get position() { return this.character.position; }

  emit() { this.onChange?.(this); }

  takeDamage(dmg) {
    if (this.dead) return;
    this.hp = Math.max(0, this.hp - dmg);
    if (this.hp <= 0) { this.dead = true; this.character.triggerDeath(); }
    this.emit();
  }

  heal(amount) {
    this.hp = Math.min(this.maxHp, this.hp + amount);
    this.emit();
  }

  spendMp(cost) {
    if (this.mp < cost) return false;
    this.mp -= cost;
    this.emit();
    return true;
  }

  awardXp(xp) {
    this.xp += xp;
    while (this.xp >= xpForLevel(this.level)) {
      this.xp -= xpForLevel(this.level);
      this.level++;
      this.maxHp += 8 + Math.floor(this.race.stats.con * 0.15);
      this.maxMp += 4 + Math.floor(this.race.stats.men * 0.12);
      this.atk += 2;
      this.mAtk += 1;
      this.hp = this.maxHp;
      this.mp = this.maxMp;
      this._leveledUp = true;
    }
    this.emit();
  }

  consumeLevelUp() { const v = !!this._leveledUp; this._leveledUp = false; return v; }

  update(dt) {
    if (this.dead) {
      this.character.update(dt, 0);
      return;
    }
    if (this.atkCd > 0) this.atkCd -= dt;
    if (this.gcd > 0) this.gcd -= dt;

    // HP/MP regen
    this.hp = Math.min(this.maxHp, this.hp + dt * 1.6);
    this.mp = Math.min(this.maxMp, this.mp + dt * 2.0);

    // Movement
    if (this.moveTarget) {
      const p = this.position;
      const dx = this.moveTarget.x - p.x;
      const dz = this.moveTarget.z - p.z;
      const d = Math.hypot(dx, dz);
      if (d < 0.1) {
        this.moveTarget = null;
        this._mvSpeed = 0;
      } else {
        const speed = 4.5;
        const mv = Math.min(d, speed * dt);
        p.x += (dx / d) * mv;
        p.z += (dz / d) * mv;
        // Face direction
        this.character.group.rotation.y = Math.atan2(dx, dz);
        this._mvSpeed = mv / dt;
      }
    } else {
      this._mvSpeed = 0;
    }

    // Auto-attack the current target if in range
    if (this.target && !this.target.dead) {
      const tp = this.target.position;
      const dx = tp.x - this.position.x;
      const dz = tp.z - this.position.z;
      const d = Math.hypot(dx, dz);
      if (d < 1.8) {
        // In range; stop moving
        this.moveTarget = null;
        // Face target
        this.character.group.rotation.y = Math.atan2(dx, dz);
        if (this.atkCd <= 0 && this.gcd <= 0) {
          this.atkCd = 1.5;
          this.character.triggerAttack();
          const dmg = this.atk + Math.floor(Math.random() * 4);
          this._pendingHit = { target: this.target, dmg };
          // delay damage application by a tick to sync with arm swing
          setTimeout(() => {
            if (!this._pendingHit) return;
            const t = this._pendingHit.target;
            if (!t.dead) {
              t.setHp(t.hp - this._pendingHit.dmg);
              t.flashDamage();
              this._onHit?.(t, this._pendingHit.dmg);
            }
            this._pendingHit = null;
          }, 200);
        }
      } else if (!this.moveTarget) {
        // Walk toward target
        this.moveTarget = new THREE.Vector3(tp.x, 0, tp.z);
      }
    }

    this.character.update(dt, this._mvSpeed);
    this.emit();
  }
}

export function xpForLevel(level) {
  return Math.floor(60 * Math.pow(level, 1.6));
}
