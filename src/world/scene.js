import * as THREE from "three";

export function createWorld() {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0x1a1f2c);
  scene.fog = new THREE.Fog(0x1a1f2c, 35, 90);

  // Ground
  const groundMat = new THREE.MeshStandardMaterial({
    color: 0x405530,
    roughness: 0.95,
    map: makeGrassTexture(),
  });
  groundMat.map.repeat.set(40, 40);
  const ground = new THREE.Mesh(new THREE.PlaneGeometry(200, 200), groundMat);
  ground.rotation.x = -Math.PI / 2;
  ground.receiveShadow = true;
  scene.add(ground);

  // Path texture in center area (a slight color variation circle)
  const path = new THREE.Mesh(
    new THREE.CircleGeometry(8, 32),
    new THREE.MeshStandardMaterial({ color: 0x6a5a3a, roughness: 0.95 }),
  );
  path.rotation.x = -Math.PI / 2;
  path.position.y = 0.01;
  scene.add(path);

  // Trees
  for (let i = 0; i < 50; i++) {
    const angle = Math.random() * Math.PI * 2;
    const dist = 12 + Math.random() * 60;
    const x = Math.cos(angle) * dist;
    const z = Math.sin(angle) * dist;
    scene.add(buildTree(x, z));
  }

  // Stones
  for (let i = 0; i < 25; i++) {
    const x = (Math.random() - 0.5) * 100;
    const z = (Math.random() - 0.5) * 100;
    if (x * x + z * z < 50) continue;
    scene.add(buildStone(x, z));
  }

  // Lighting
  const sun = new THREE.DirectionalLight(0xffeec8, 1.4);
  sun.position.set(20, 30, 10);
  sun.castShadow = true;
  sun.shadow.mapSize.width = 1024;
  sun.shadow.mapSize.height = 1024;
  sun.shadow.camera.left = -30;
  sun.shadow.camera.right = 30;
  sun.shadow.camera.top = 30;
  sun.shadow.camera.bottom = -30;
  scene.add(sun);

  const amb = new THREE.AmbientLight(0x6c7a90, 0.55);
  scene.add(amb);

  // Hemisphere for sky/ground tint
  const hemi = new THREE.HemisphereLight(0x6e8aa8, 0x2a3520, 0.4);
  scene.add(hemi);

  return { scene, ground, sun };
}

function buildTree(x, z) {
  const g = new THREE.Group();
  const trunk = new THREE.Mesh(
    new THREE.CylinderGeometry(0.25, 0.35, 1.8, 8),
    new THREE.MeshStandardMaterial({ color: 0x4a3018, roughness: 0.95 }),
  );
  trunk.position.y = 0.9;
  trunk.castShadow = true;
  g.add(trunk);
  const crown = new THREE.Mesh(
    new THREE.ConeGeometry(1.2, 2.4, 8),
    new THREE.MeshStandardMaterial({ color: 0x2a4a25, roughness: 0.85 }),
  );
  crown.position.y = 2.6;
  crown.castShadow = true;
  g.add(crown);
  g.position.set(x, 0, z);
  g.rotation.y = Math.random() * Math.PI;
  const s = 0.8 + Math.random() * 0.6;
  g.scale.set(s, s + Math.random() * 0.3, s);
  return g;
}

function buildStone(x, z) {
  const g = new THREE.Mesh(
    new THREE.DodecahedronGeometry(0.35 + Math.random() * 0.5, 0),
    new THREE.MeshStandardMaterial({ color: 0x8a8a8a, roughness: 0.9 }),
  );
  g.position.set(x, 0.2, z);
  g.castShadow = true;
  return g;
}

function makeGrassTexture() {
  const c = document.createElement("canvas");
  c.width = c.height = 128;
  const ctx = c.getContext("2d");
  ctx.fillStyle = "#3d5028";
  ctx.fillRect(0, 0, 128, 128);
  for (let i = 0; i < 800; i++) {
    const x = Math.random() * 128, y = Math.random() * 128;
    const v = 30 + Math.floor(Math.random() * 40);
    ctx.fillStyle = `rgb(${v - 5},${v + 30},${v - 10})`;
    ctx.fillRect(x, y, 1.5, 1.5);
  }
  // Random darker patches
  for (let i = 0; i < 80; i++) {
    const x = Math.random() * 128, y = Math.random() * 128;
    ctx.fillStyle = `rgba(0,0,0,${Math.random() * 0.18})`;
    ctx.beginPath();
    ctx.arc(x, y, 2 + Math.random() * 4, 0, Math.PI * 2);
    ctx.fill();
  }
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  return tex;
}
