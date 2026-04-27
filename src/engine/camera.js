import * as THREE from "three";

// Lineage 2-style follow camera: orbits around target, mouse-wheel zoom,
// right-click drag for yaw, keyboard arrows or WASD for free pan when needed.
export class FollowCamera {
  constructor({ camera, target, dom }) {
    this.camera = camera;
    this.target = target; // THREE.Object3D
    this.dom = dom;
    this.distance = 12;
    this.minDist = 4;
    this.maxDist = 30;
    this.yaw = Math.PI * 0.25;   // around Y
    this.pitch = 0.8;            // 0=ground, PI/2=top
    this.minPitch = 0.25;
    this.maxPitch = 1.4;
    this._dragging = false;
    this._lastX = 0;
    this._lastY = 0;
    this._touchYaw = null;

    dom.addEventListener("contextmenu", (e) => e.preventDefault());
    dom.addEventListener("mousedown", (e) => {
      if (e.button !== 2) return;
      this._dragging = true;
      this._lastX = e.clientX;
      this._lastY = e.clientY;
    });
    window.addEventListener("mouseup", (e) => { if (e.button === 2) this._dragging = false; });
    window.addEventListener("mousemove", (e) => {
      if (!this._dragging) return;
      const dx = e.clientX - this._lastX;
      const dy = e.clientY - this._lastY;
      this._lastX = e.clientX; this._lastY = e.clientY;
      this.yaw -= dx * 0.005;
      this.pitch = Math.max(this.minPitch, Math.min(this.maxPitch, this.pitch - dy * 0.005));
    });
    dom.addEventListener("wheel", (e) => {
      e.preventDefault();
      this.distance = Math.max(this.minDist, Math.min(this.maxDist, this.distance + e.deltaY * 0.015));
    }, { passive: false });

    // Touch: 2-finger pinch zoom + 1-finger drag rotate
    let pinchDist = null;
    let touchStart = null;
    dom.addEventListener("touchstart", (e) => {
      if (e.touches.length === 2) {
        const [a, b] = e.touches;
        pinchDist = Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY);
      } else if (e.touches.length === 1) {
        touchStart = { x: e.touches[0].clientX, y: e.touches[0].clientY };
      }
    });
    dom.addEventListener("touchmove", (e) => {
      if (e.touches.length === 2 && pinchDist != null) {
        const [a, b] = e.touches;
        const d = Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY);
        const delta = pinchDist - d;
        this.distance = Math.max(this.minDist, Math.min(this.maxDist, this.distance + delta * 0.04));
        pinchDist = d;
      }
    }, { passive: true });
    dom.addEventListener("touchend", () => { pinchDist = null; touchStart = null; });
  }

  update() {
    const t = this.target.position;
    const cosP = Math.cos(this.pitch), sinP = Math.sin(this.pitch);
    const x = t.x + Math.sin(this.yaw) * this.distance * cosP;
    const z = t.z + Math.cos(this.yaw) * this.distance * cosP;
    const y = t.y + sinP * this.distance + 1.0;
    this.camera.position.set(x, y, z);
    this.camera.lookAt(t.x, t.y + 1.0, t.z);
  }
}
