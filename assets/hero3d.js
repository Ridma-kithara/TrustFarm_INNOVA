/* TrustFarm AI — real-world 3D farm diorama (Three.js) */
import * as THREE from "three";
import { RoundedBoxGeometry } from "three/addons/geometries/RoundedBoxGeometry.js";
import { RoomEnvironment } from "three/addons/environments/RoomEnvironment.js";

const canvas = document.getElementById("scene");
const hero = document.querySelector(".hero");
if (canvas && hero) init();

function init() {
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const isMobile = () => window.innerWidth < 900;
  const TAU = Math.PI * 2;

  const renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: true,
    alpha: true,
    powerPreference: "high-performance"
  });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, isMobile() ? 1.6 : 2));
  renderer.setClearColor(0x000000, 0);
  renderer.shadowMap.enabled = !isMobile();
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.12;
  renderer.outputColorSpace = THREE.SRGBColorSpace;

  const scene = new THREE.Scene();
  scene.fog = new THREE.FogExp2(0x07110c, 0.011);
  const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 160);

  /* ── Lights ─────────────────────────────────────────────── */
  const hemi = new THREE.HemisphereLight(0xd8ecff, 0x203a2b, 1.15);
  scene.add(hemi);

  const key = new THREE.DirectionalLight(0xfff2d8, 3.2);
  key.position.set(11, 18, 9);
  key.castShadow = !isMobile();
  key.shadow.mapSize.set(isMobile() ? 1024 : 2048, isMobile() ? 1024 : 2048);
  key.shadow.camera.left = -14;
  key.shadow.camera.right = 14;
  key.shadow.camera.top = 14;
  key.shadow.camera.bottom = -14;
  key.shadow.camera.near = 1;
  key.shadow.camera.far = 55;
  key.shadow.bias = -0.0005;
  key.shadow.normalBias = 0.03;
  scene.add(key);

  const fill = new THREE.DirectionalLight(0x8bdcff, 1.15);
  fill.position.set(-13, 8, -8);
  scene.add(fill);

  const warm = new THREE.PointLight(0xfbbf24, 24, 20, 2);
  warm.position.set(-5, 2.5, 5);
  scene.add(warm);

  const holoLight = new THREE.PointLight(0x34d399, 42, 18, 2);
  holoLight.position.set(0, 5.3, 0);
  scene.add(holoLight);

  if (!isMobile()) {
    try {
      const pmrem = new THREE.PMREMGenerator(renderer);
      scene.environment = pmrem.fromScene(new RoomEnvironment(renderer), 0.04).texture;
      scene.environmentIntensity = 0.45;
      pmrem.dispose();
    } catch (e) {}
  }

  /* ── Procedural textures ────────────────────────────────── */
  function makeTexture(w, h, draw, repeatX, repeatY) {
    const c = document.createElement("canvas");
    c.width = w;
    c.height = h;
    const g = c.getContext("2d");
    draw(g, w, h);
    const tex = new THREE.CanvasTexture(c);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(repeatX || 1, repeatY || 1);
    tex.anisotropy = 4;
    return tex;
  }

  const grassTex = makeTexture(512, 512, (g, w, h) => {
    const base = g.createLinearGradient(0, 0, w, h);
    base.addColorStop(0, "#2c5a3a");
    base.addColorStop(0.55, "#356a44");
    base.addColorStop(1, "#295238");
    g.fillStyle = base;
    g.fillRect(0, 0, w, h);
    for (let i = 0; i < 2800; i++) {
      const x = Math.random() * w;
      const y = Math.random() * h;
      const len = 2 + Math.random() * 9;
      const green = Math.random();
      g.strokeStyle = green < 0.35 ? "rgba(92,141,86,0.45)" : green < 0.7 ? "rgba(34,80,48,0.4)" : "rgba(128,164,103,0.24)";
      g.lineWidth = 0.7 + Math.random() * 0.8;
      g.beginPath();
      g.moveTo(x, y);
      g.lineTo(x + (Math.random() - 0.5) * 3, y - len);
      g.stroke();
    }
    for (let i = 0; i < 120; i++) {
      g.fillStyle = Math.random() > 0.5 ? "rgba(221,214,164,0.16)" : "rgba(15,49,29,0.2)";
      g.beginPath();
      g.arc(Math.random() * w, Math.random() * h, 0.8 + Math.random() * 2.2, 0, TAU);
      g.fill();
    }
  }, 3, 3);

  const dirtTex = makeTexture(512, 512, (g, w, h) => {
    const base = g.createLinearGradient(0, 0, 0, h);
    base.addColorStop(0, "#4a3625");
    base.addColorStop(0.35, "#3f2d1f");
    base.addColorStop(0.7, "#4b3726");
    base.addColorStop(1, "#332318");
    g.fillStyle = base;
    g.fillRect(0, 0, w, h);
    for (let i = 0; i < 9; i++) {
      g.strokeStyle = i % 2 ? "rgba(23,15,9,0.22)" : "rgba(114,84,56,0.16)";
      g.lineWidth = 2 + Math.random() * 9;
      g.beginPath();
      const y = (i / 9) * h + Math.random() * 18;
      g.moveTo(0, y);
      for (let x = 0; x <= w; x += 32) g.lineTo(x, y + Math.sin(x * 0.02 + i) * 5);
      g.stroke();
    }
    for (let i = 0; i < 900; i++) {
      g.fillStyle = Math.random() > 0.5 ? "rgba(19,12,7,0.35)" : "rgba(151,113,77,0.18)";
      g.beginPath();
      g.arc(Math.random() * w, Math.random() * h, 0.6 + Math.random() * 2.4, 0, TAU);
      g.fill();
    }
  }, 5, 2);

  const rockTex = makeTexture(512, 512, (g, w, h) => {
    g.fillStyle = "#34302b";
    g.fillRect(0, 0, w, h);
    for (let i = 0; i < 280; i++) {
      const shade = 40 + Math.floor(Math.random() * 50);
      g.fillStyle = `rgba(${shade},${shade - 4},${shade - 8},0.5)`;
      const x = Math.random() * w;
      const y = Math.random() * h;
      g.beginPath();
      g.ellipse(x, y, 3 + Math.random() * 17, 2 + Math.random() * 11, Math.random() * TAU, 0, TAU);
      g.fill();
    }
  }, 2, 1);

  const woodTex = makeTexture(256, 256, (g, w, h) => {
    g.fillStyle = "#6d5239";
    g.fillRect(0, 0, w, h);
    for (let i = 0; i < 36; i++) {
      g.strokeStyle = i % 3 ? "rgba(53,36,23,0.24)" : "rgba(137,107,77,0.22)";
      g.lineWidth = 1 + Math.random() * 2;
      g.beginPath();
      const x = (i / 36) * w + Math.random() * 3;
      g.moveTo(x, 0);
      g.bezierCurveTo(x + 3, h * 0.3, x - 3, h * 0.7, x, h);
      g.stroke();
    }
  }, 2, 1);

  const glowTex = makeTexture(256, 256, (g, w, h) => {
    const grad = g.createRadialGradient(w / 2, h / 2, 2, w / 2, h / 2, w / 2);
    grad.addColorStop(0, "rgba(255,255,255,1)");
    grad.addColorStop(0.28, "rgba(255,255,255,0.5)");
    grad.addColorStop(0.65, "rgba(255,255,255,0.12)");
    grad.addColorStop(1, "rgba(255,255,255,0)");
    g.fillStyle = grad;
    g.fillRect(0, 0, w, h);
  });

  const shadowTex = makeTexture(256, 256, (g, w, h) => {
    const grad = g.createRadialGradient(w / 2, h / 2, 4, w / 2, h / 2, w / 2);
    grad.addColorStop(0, "rgba(0,0,0,0.62)");
    grad.addColorStop(0.5, "rgba(0,0,0,0.25)");
    grad.addColorStop(1, "rgba(0,0,0,0)");
    g.fillStyle = grad;
    g.fillRect(0, 0, w, h);
  });

  /* ── Materials ──────────────────────────────────────────── */
  const grassMat = new THREE.MeshStandardMaterial({ map: grassTex, roughness: 0.96, metalness: 0 });
  const dirtMat = new THREE.MeshStandardMaterial({ map: dirtTex, roughness: 1, metalness: 0 });
  const rockMat = new THREE.MeshStandardMaterial({ map: rockTex, roughness: 0.95, metalness: 0.04 });
  const woodMat = new THREE.MeshStandardMaterial({ map: woodTex, roughness: 0.82, metalness: 0 });
  const soilMat = new THREE.MeshStandardMaterial({ color: 0x2b1c12, roughness: 1 });
  const leafMats = [
    new THREE.MeshStandardMaterial({ color: 0x3f8a4f, roughness: 0.78 }),
    new THREE.MeshStandardMaterial({ color: 0x2f7041, roughness: 0.8 }),
    new THREE.MeshStandardMaterial({ color: 0x559b58, roughness: 0.75 })
  ];
  const fruitMats = [
    new THREE.MeshStandardMaterial({ color: 0xe4462f, roughness: 0.38, metalness: 0 }),
    new THREE.MeshStandardMaterial({ color: 0xf07a2a, roughness: 0.4 })
  ];
  const stemMat = new THREE.MeshStandardMaterial({ color: 0x3c7a43, roughness: 0.85 });
  const metalMat = new THREE.MeshStandardMaterial({ color: 0xc9d1d6, metalness: 0.85, roughness: 0.26 });
  const darkMetal = new THREE.MeshStandardMaterial({ color: 0x1d2622, metalness: 0.4, roughness: 0.5 });
  const goldMat = new THREE.MeshStandardMaterial({ color: 0xe8b53f, metalness: 0.9, roughness: 0.26 });
  const copperMat = new THREE.MeshStandardMaterial({ color: 0xb87333, metalness: 0.85, roughness: 0.32 });
  const greenTankMat = new THREE.MeshStandardMaterial({ color: 0x2f7d54, metalness: 0.25, roughness: 0.42 });
  const orangeMat = new THREE.MeshStandardMaterial({ color: 0xc05a1c, metalness: 0.4, roughness: 0.45 });
  const blueMat = new THREE.MeshStandardMaterial({ color: 0x2b6c9e, metalness: 0.2, roughness: 0.5 });
  const pcbMat = new THREE.MeshStandardMaterial({ color: 0x14532d, roughness: 0.62 });

  /* ── Island ─────────────────────────────────────────────── */
  const world = new THREE.Group();
  scene.add(world);

  const island = new THREE.Group();
  world.add(island);

  const SIZE = 8.3;
  const top = new THREE.Mesh(
    new THREE.CylinderGeometry(SIZE, SIZE * 0.985, 0.5, 72),
    [new THREE.MeshStandardMaterial({ map: grassTex, color: 0x9fc9a2, roughness: 0.95 }), grassMat, dirtMat]
  );
  top.position.y = -0.25;
  top.receiveShadow = true;
  top.castShadow = true;
  island.add(top);

  const soil = new THREE.Mesh(
    new THREE.CylinderGeometry(SIZE * 0.985, SIZE * 0.9, 2.05, 72),
    [dirtMat, dirtMat, dirtMat]
  );
  soil.position.y = -1.52;
  soil.receiveShadow = true;
  soil.castShadow = true;
  island.add(soil);

  const base = new THREE.Mesh(
    new THREE.CylinderGeometry(SIZE * 0.9, SIZE * 0.62, 1.5, 48),
    [rockMat, rockMat, rockMat]
  );
  base.position.y = -3.3;
  base.castShadow = true;
  base.receiveShadow = true;
  island.add(base);

  const rim = new THREE.Mesh(
    new THREE.TorusGeometry(SIZE - 0.03, 0.1, 8, 96),
    new THREE.MeshStandardMaterial({ color: 0x24462f, roughness: 0.9 })
  );
  rim.rotation.x = Math.PI / 2;
  rim.position.y = 0.01;
  island.add(rim);

  // Soft floating shadow
  const shadow = new THREE.Mesh(
    new THREE.PlaneGeometry(32, 32),
    new THREE.MeshBasicMaterial({ map: shadowTex, transparent: true, opacity: 0.5, depthWrite: false })
  );
  shadow.rotation.x = -Math.PI / 2;
  shadow.position.y = -4.45;
  world.add(shadow);

  /* ── Helpers ────────────────────────────────────────────── */
  function box(w, h, d, mat, x, y, z, parent, radius) {
    const geo = radius ? new RoundedBoxGeometry(w, h, d, 3, radius) : new THREE.BoxGeometry(w, h, d);
    const m = new THREE.Mesh(geo, mat);
    m.position.set(x, y, z);
    m.castShadow = true;
    m.receiveShadow = true;
    (parent || island).add(m);
    return m;
  }
  function tube(points, color, radius, opacity, parent) {
    const curve = new THREE.CatmullRomCurve3(points.map((p) => new THREE.Vector3(p[0], p[1], p[2])));
    const geo = new THREE.TubeGeometry(curve, 48, radius, 5, false);
    const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({ color, roughness: 0.55, metalness: 0.1 }));
    mesh.castShadow = true;
    (parent || island).add(mesh);
    return { mesh, curve };
  }

  /* ── Raised beds & crops ────────────────────────────────── */
  const bedsZ = [-2.45, 0, 2.45];
  const plantGroups = [];
  const rowMeta = [];
  const stemGeo = new THREE.CylinderGeometry(0.018, 0.028, 0.62, 6);
  const leafGeo = new THREE.SphereGeometry(1, 7, 5);
  const fruitGeo = new THREE.SphereGeometry(0.075, 10, 8);
  const stakeGeo = new THREE.CylinderGeometry(0.012, 0.012, 1.15, 5);

  bedsZ.forEach((z, bedIndex) => {
    box(6.7, 0.38, 1.28, woodMat, -0.4, 0.19, z, island, 0.06);
    box(6.35, 0.07, 0.98, soilMat, -0.4, 0.4, z, island, 0.03);
    // timber slats
    for (let s = 0; s < 7; s++) {
      box(0.04, 0.32, 1.24, woodMat, -3.65 + s * 1.02, 0.2, z, island, 0.01);
    }
    for (let p = 0; p < 7; p++) {
      const px = -3.05 + p * 0.98 + (Math.random() - 0.5) * 0.08;
      const pz = z + (Math.random() - 0.5) * 0.2;
      const plant = new THREE.Group();
      plant.position.set(px, 0.44, pz);
      plant.rotation.y = Math.random() * TAU;
      const scale = 0.82 + Math.random() * 0.38;
      plant.scale.setScalar(scale);

      const stem = new THREE.Mesh(stemGeo, stemMat);
      stem.position.y = 0.31;
      stem.castShadow = true;
      plant.add(stem);

      for (let l = 0; l < 3; l++) {
        const leaf = new THREE.Mesh(leafGeo, leafMats[(p + l + bedIndex) % leafMats.length]);
        const ang = l * 2.1 + Math.random();
        leaf.position.set(Math.cos(ang) * 0.14, 0.22 + l * 0.16, Math.sin(ang) * 0.14);
        leaf.scale.set(0.17, 0.032, 0.095);
        leaf.rotation.y = ang;
        leaf.rotation.z = 0.25 + Math.random() * 0.2;
        leaf.castShadow = true;
        plant.add(leaf);
      }
      const fruitCount = p % 3 === 0 ? 2 : 1;
      for (let f = 0; f < fruitCount; f++) {
        const fruit = new THREE.Mesh(fruitGeo, fruitMats[(p + f) % 2]);
        fruit.position.set((Math.random() - 0.5) * 0.18, 0.3 + Math.random() * 0.18, (Math.random() - 0.5) * 0.18);
        fruit.castShadow = true;
        plant.add(fruit);
      }
      if (p % 3 === 1) {
        const stake = new THREE.Mesh(stakeGeo, woodMat);
        stake.position.set(0.08, 0.55, -0.05);
        stake.rotation.z = 0.03;
        plant.add(stake);
      }
      plant.userData.phase = Math.random() * TAU;
      plant.userData.sway = 0.018 + Math.random() * 0.022;
      island.add(plant);
      plantGroups.push(plant);
    }
    // Drip irrigation line
    const drip = tube(
      [[-3.7, 0.5, z], [-1.5, 0.53, z + 0.03], [1.2, 0.52, z - 0.02], [3.8, 0.5, z]],
      0x1b2a22,
      0.022,
      1
    );
    rowMeta.push({ z, drip: drip.curve });
  });

  // Grass tufts around the island edges
  const bladeGeo = new THREE.ConeGeometry(0.028, 0.34, 3);
  bladeGeo.translate(0, 0.17, 0);
  const bladeCount = isMobile() ? 170 : 340;
  const blades = new THREE.InstancedMesh(bladeGeo, new THREE.MeshStandardMaterial({ color: 0x6a9a5e, roughness: 1 }), bladeCount);
  const dummy = new THREE.Object3D();
  const bladeColor = new THREE.Color();
  for (let i = 0; i < bladeCount; i++) {
    let x, z;
    if (i < bladeCount * 0.72) {
      const a = Math.random() * TAU;
      const r = SIZE - 1.55 + Math.random() * 1.35;
      x = Math.cos(a) * r - 0.4;
      z = Math.sin(a) * r;
    } else {
      x = (Math.random() - 0.5) * 13;
      z = (Math.random() - 0.5) * 7;
      if (Math.abs(z - bedsZ[0]) < 0.9 || Math.abs(z - bedsZ[1]) < 0.9 || Math.abs(z - bedsZ[2]) < 0.9) {
        z += z > 0 ? 1.3 : -1.3;
      }
    }
    dummy.position.set(x, 0, z);
    dummy.rotation.y = Math.random() * TAU;
    dummy.rotation.z = (Math.random() - 0.5) * 0.14;
    dummy.scale.set(0.7 + Math.random() * 0.8, 0.65 + Math.random() * 1.1, 0.7 + Math.random() * 0.8);
    dummy.updateMatrix();
    blades.setMatrixAt(i, dummy.matrix);
    bladeColor.setHSL(0.27 + Math.random() * 0.06, 0.3 + Math.random() * 0.18, 0.3 + Math.random() * 0.18);
    blades.setColorAt(i, bladeColor);
  }
  blades.castShadow = true;
  blades.receiveShadow = true;
  island.add(blades);

  // Rocks & bushes
  const rockGeo = new THREE.DodecahedronGeometry(0.3, 0);
  for (let i = 0; i < 11; i++) {
    const a = Math.random() * TAU;
    const r = SIZE - 0.7 - Math.random() * 0.35;
    const rock = new THREE.Mesh(rockGeo, rockMat);
    rock.position.set(Math.cos(a) * r - 0.4, 0.09, Math.sin(a) * r);
    rock.scale.set(0.55 + Math.random() * 1.15, 0.4 + Math.random() * 0.55, 0.55 + Math.random() * 1.1);
    rock.rotation.set(Math.random(), Math.random() * TAU, Math.random());
    rock.castShadow = true;
    rock.receiveShadow = true;
    island.add(rock);
  }

  const bushMatA = new THREE.MeshStandardMaterial({ color: 0x2f6b42, roughness: 0.85 });
  const bushMatB = new THREE.MeshStandardMaterial({ color: 0x3d814f, roughness: 0.8 });
  function bush(x, z, s) {
    const g = new THREE.Group();
    for (let i = 0; i < 4; i++) {
      const m = new THREE.Mesh(new THREE.IcosahedronGeometry(0.42, 1), i % 2 ? bushMatA : bushMatB);
      m.position.set((Math.random() - 0.5) * 0.6, 0.28 + Math.random() * 0.4, (Math.random() - 0.5) * 0.6);
      m.scale.set(1, 0.8 + Math.random() * 0.4, 1);
      m.castShadow = true;
      g.add(m);
    }
    g.position.set(x, 0, z);
    g.scale.setScalar(s);
    island.add(g);
    return g;
  }
  bush(-7.1, -3.4, 0.95);
  bush(6.6, -3.6, 0.8);
  bush(-6.6, 1.2, 0.7);

  // Tiny wildflowers
  const flowerGeo = new THREE.SphereGeometry(0.035, 6, 5);
  const flowerMats = [
    new THREE.MeshBasicMaterial({ color: 0xf4e6a1 }),
    new THREE.MeshBasicMaterial({ color: 0xf3b5c8 }),
    new THREE.MeshBasicMaterial({ color: 0xe9f4d0 })
  ];
  for (let i = 0; i < 40; i++) {
    const a = Math.random() * TAU;
    const r = SIZE - 1.2 - Math.random() * 0.8;
    const f = new THREE.Mesh(flowerGeo, flowerMats[i % 3]);
    f.position.set(Math.cos(a) * r - 0.4, 0.24 + Math.random() * 0.12, Math.sin(a) * r);
    island.add(f);
  }

  /* ── Water tank and drip feed ───────────────────────────── */
  const tank = new THREE.Mesh(new THREE.CylinderGeometry(0.62, 0.66, 1.35, 24), blueMat);
  tank.position.set(5.45, 0.68, 4.35);
  tank.castShadow = true;
  tank.receiveShadow = true;
  island.add(tank);
  const tankLid = new THREE.Mesh(new THREE.CylinderGeometry(0.68, 0.68, 0.12, 24), darkMetal);
  tankLid.position.set(5.45, 1.4, 4.35);
  tankLid.castShadow = true;
  island.add(tankLid);
  for (const y of [0.35, 0.92]) {
    const band = new THREE.Mesh(new THREE.TorusGeometry(0.65, 0.025, 6, 32), darkMetal);
    band.rotation.x = Math.PI / 2;
    band.position.set(5.45, y, 4.35);
    island.add(band);
  }
  tube([[5.45, 0.25, 4.0], [5.2, 0.16, 2.9], [4.4, 0.13, 2.45], [3.85, 0.5, 2.45]], 0x2b6c9e, 0.035, 1);

  /* ── Energy corner: digester, generator, battery ────────── */
  const energy = new THREE.Group();
  energy.position.set(-5.0, 0, 4.45);
  island.add(energy);

  const digester = new THREE.Mesh(new THREE.CylinderGeometry(0.62, 0.68, 1.05, 24), greenTankMat);
  digester.position.set(0, 0.55, 0);
  digester.castShadow = true;
  digester.receiveShadow = true;
  energy.add(digester);
  const dome = new THREE.Mesh(new THREE.SphereGeometry(0.64, 24, 14, 0, TAU, 0, Math.PI / 2), greenTankMat);
  dome.position.set(0, 1.07, 0);
  dome.castShadow = true;
  energy.add(dome);
  for (const y of [0.26, 0.78]) {
    const band = new THREE.Mesh(new THREE.TorusGeometry(0.655, 0.025, 6, 32), darkMetal);
    band.rotation.x = Math.PI / 2;
    band.position.set(0, y, 0);
    energy.add(band);
  }
  const gasPipe = tube([[0.5, 1.15, 0], [1.0, 1.28, 0.05], [1.55, 0.9, 0.1], [1.85, 0.55, 0.1]], 0x8a8f86, 0.035, 1, energy);
  const gen = box(1.0, 0.58, 0.72, orangeMat, 2.2, 0.31, 0.12, energy, 0.05);
  const genPanel = box(0.62, 0.28, 0.03, darkMetal, 2.2, 0.34, 0.5, energy, 0.01);
  box(0.07, 0.03, 0.02, goldMat, 2.02, 0.38, 0.52, energy);
  box(0.07, 0.03, 0.02, goldMat, 2.15, 0.38, 0.52, energy);
  box(0.07, 0.03, 0.02, goldMat, 2.28, 0.38, 0.52, energy);
  const exhaust = new THREE.Mesh(new THREE.CylinderGeometry(0.055, 0.065, 0.55, 10), metalMat);
  exhaust.position.set(2.55, 0.82, -0.1);
  exhaust.castShadow = true;
  energy.add(exhaust);
  for (let v = 0; v < 3; v++) {
    box(0.5, 0.025, 0.02, darkMetal, 2.2, 0.17 + v * 0.07, 0.44, energy);
  }
  // Battery + controller
  const battery = box(0.72, 0.42, 0.48, darkMetal, 3.45, 0.23, 0.5, energy, 0.04);
  const termA = new THREE.Mesh(new THREE.CylinderGeometry(0.055, 0.055, 0.08, 12), new THREE.MeshStandardMaterial({ color: 0xdc2626, metalness: 0.4, roughness: 0.4 }));
  termA.position.set(3.22, 0.47, 0.38);
  energy.add(termA);
  const termB = new THREE.Mesh(new THREE.CylinderGeometry(0.055, 0.055, 0.08, 12), new THREE.MeshStandardMaterial({ color: 0x111111, metalness: 0.4, roughness: 0.4 }));
  termB.position.set(3.22, 0.47, 0.62);
  energy.add(termB);
  box(0.38, 0.26, 0.3, new THREE.MeshStandardMaterial({ color: 0x1f8a72, metalness: 0.3, roughness: 0.4 }), 3.45, 0.14, 0.05, energy, 0.03);
  // Energy cables
  tube([[2.7, 0.22, 0.2], [2.95, 0.17, 0.35], [3.1, 0.24, 0.5]], 0xdc2626, 0.028, 1, energy);
  tube([[3.8, 0.2, 0.5], [4.1, 0.16, 0.7], [4.3, 0.12, 1.0]], 0xdc2626, 0.028, 1, energy);

  /* ── ESP32 node & probes ────────────────────────────────── */
  const node = new THREE.Group();
  node.position.set(4.65, 0, 1.65);
  island.add(node);
  box(0.78, 0.28, 0.54, darkMetal, 0, 0.14, 0, node, 0.04);
  box(0.52, 0.055, 0.88, pcbMat, 0, 0.32, 0, node, 0.02);
  box(0.28, 0.075, 0.36, metalMat, 0, 0.39, -0.14, node, 0.015);
  for (let i = 0; i < 5; i++) {
    box(0.035, 0.04, 0.045, goldMat, -0.22, 0.36, -0.3 + i * 0.13, node);
    box(0.035, 0.04, 0.045, goldMat, 0.22, 0.36, -0.3 + i * 0.13, node);
  }
  const boardLed = new THREE.Mesh(new THREE.SphereGeometry(0.025, 8, 6), new THREE.MeshBasicMaterial({ color: 0x4ade80 }));
  boardLed.position.set(0.12, 0.37, 0.28);
  node.add(boardLed);
  const antenna = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.012, 1.05, 6), metalMat);
  antenna.position.set(-0.2, 0.8, -0.28);
  node.add(antenna);
  const antennaTip = new THREE.Mesh(new THREE.SphereGeometry(0.05, 10, 8), new THREE.MeshBasicMaterial({ color: 0x6ee7b7 }));
  antennaTip.position.set(-0.2, 1.34, -0.28);
  node.add(antennaTip);
  const antennaLight = new THREE.PointLight(0x34d399, 8, 4, 2);
  antennaLight.position.copy(antennaTip.position);
  node.add(antennaLight);

  const probeMat = new THREE.MeshStandardMaterial({ color: 0x1d4e89, roughness: 0.55 });
  const probe1 = new THREE.Group();
  probe1.position.set(1.55, 0.42, 2.45);
  probe1.rotation.z = -0.08;
  box(0.16, 0.6, 0.035, probeMat, 0, 0.3, 0, probe1, 0.01);
  box(0.1, 0.16, 0.02, goldMat, 0, 0.62, 0.01, probe1);
  island.add(probe1);
  const probe2 = new THREE.Group();
  probe2.position.set(2.3, 0.42, 2.42);
  probe2.rotation.z = 0.09;
  box(0.16, 0.6, 0.035, probeMat, 0, 0.3, 0, probe2, 0.01);
  box(0.1, 0.16, 0.02, goldMat, 0, 0.62, 0.01, probe2);
  island.add(probe2);

  // Sensor → node cables
  tube([[1.55, 0.95, 2.45], [2.2, 1.25, 2.1], [3.4, 1.05, 1.85], [4.35, 0.52, 1.68]], 0x38bdf8, 0.024, 1);
  tube([[2.3, 0.95, 2.42], [2.9, 1.18, 2.0], [3.9, 0.92, 1.8], [4.45, 0.52, 1.65]], 0x22d3ee, 0.024, 1);
  // 12 V battery to node
  tube([[-1.55, 0.45, 4.95], [-0.2, 0.9, 4.0], [2.4, 1.0, 2.8], [4.25, 0.52, 1.85]], 0xdc2626, 0.03, 1);

  /* ── Hologram ───────────────────────────────────────────── */
  const holo = new THREE.Group();
  holo.position.set(0.2, 5.55, 0.1);
  island.add(holo);

  const ringMat = new THREE.MeshBasicMaterial({
    color: 0x5eead4,
    transparent: true,
    opacity: 0.65,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    toneMapped: false
  });
  const rings = [];
  for (let i = 0; i < 3; i++) {
    const ring = new THREE.Mesh(new THREE.TorusGeometry(1.45 + i * 0.16, 0.011, 6, 120, Math.PI * (1.1 + i * 0.18)), ringMat.clone());
    ring.rotation.x = Math.PI / 2 + (i - 1) * 0.24;
    ring.rotation.z = i * 0.75;
    holo.add(ring);
    rings.push(ring);
  }

  const halo = new THREE.Sprite(new THREE.SpriteMaterial({
    map: glowTex,
    color: 0x34d399,
    transparent: true,
    opacity: 0.55,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    toneMapped: false
  }));
  halo.scale.set(5.2, 5.2, 1);
  holo.add(halo);

  const logoMaterial = new THREE.SpriteMaterial({
    transparent: true,
    depthWrite: false,
    opacity: 0.96,
    color: 0xd9ffe9,
    toneMapped: false
  });
  const logo = new THREE.Sprite(logoMaterial);
  logo.scale.set(2.35, 2.62, 1);
  logo.visible = false;
  holo.add(logo);

  const texLoader = new THREE.TextureLoader();
  texLoader.load("assets/logo-mark.png", (tex) => {
    tex.colorSpace = THREE.SRGBColorSpace;
    logoMaterial.map = tex;
    logoMaterial.needsUpdate = true;
    logo.visible = true;
    updateChips();
    if (reduceMotion) renderer.render(scene, camera);
    document.dispatchEvent(new CustomEvent("tf-hero-ready"));
  }, undefined, () => {});

  const beam = new THREE.Mesh(
    new THREE.CylinderGeometry(1.35, 2.05, 4.9, 32, 1, true),
    new THREE.MeshBasicMaterial({
      color: 0x34d399,
      transparent: true,
      opacity: 0.055,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      toneMapped: false
    })
  );
  beam.position.y = -2.45;
  holo.add(beam);

  const groundGlow = new THREE.Mesh(
    new THREE.PlaneGeometry(5.8, 5.8),
    new THREE.MeshBasicMaterial({ map: glowTex, color: 0x34d399, transparent: true, opacity: 0.32, blending: THREE.AdditiveBlending, depthWrite: false, toneMapped: false })
  );
  groundGlow.rotation.x = -Math.PI / 2;
  groundGlow.position.y = 0.03;
  holo.add(groundGlow);

  const orbitGeo = new THREE.SphereGeometry(0.035, 6, 5);
  const orbitMat = new THREE.MeshBasicMaterial({ color: 0x99f6e4, toneMapped: false });
  const orbiters = [];
  for (let i = 0; i < 26; i++) {
    const dot = new THREE.Mesh(orbitGeo, orbitMat);
    dot.userData.angle = Math.random() * TAU;
    dot.userData.radius = 1.5 + Math.random() * 0.65;
    dot.userData.y = (Math.random() - 0.5) * 0.7;
    dot.userData.speed = 0.16 + Math.random() * 0.24;
    holo.add(dot);
    orbiters.push(dot);
  }

  /* ── Data arcs and travelling packets ───────────────────── */
  const packets = [];
  const packetGeo = new THREE.SphereGeometry(0.05, 7, 6);
  function arc(points, color) {
    const curve = new THREE.CatmullRomCurve3(points.map((p) => new THREE.Vector3(p[0], p[1], p[2])));
    const mesh = new THREE.Mesh(
      new THREE.TubeGeometry(curve, 52, 0.012, 4, false),
      new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.5, blending: THREE.AdditiveBlending, depthWrite: false, toneMapped: false })
    );
    island.add(mesh);
    for (let i = 0; i < 3; i++) {
      const p = new THREE.Mesh(packetGeo, new THREE.MeshBasicMaterial({ color, toneMapped: false }));
      p.userData = { curve, t: i / 3, speed: 0.08 + Math.random() * 0.05 };
      island.add(p);
      packets.push(p);
    }
    return curve;
  }
  const arcProbe1 = arc([[1.55, 1.06, 2.45], [1.9, 2.7, 2.1], [0.6, 5.0, 0.7], [0.2, 5.45, 0.15]], 0x38bdf8);
  const arcProbe2 = arc([[2.3, 1.06, 2.42], [2.7, 2.5, 1.8], [1.4, 4.8, 0.5], [0.35, 5.45, 0.1]], 0x22d3ee);
  const arcEnergy = arc([[-2.8, 1.5, 4.5], [-1.2, 3.2, 3.0], [0.2, 4.9, 0.8], [0.2, 5.45, 0.2]], 0xfbbf24);
  const arcNode = arc([[4.65, 1.4, 1.65], [3.4, 2.6, 1.2], [1.4, 4.4, 0.5], [0.35, 5.4, 0.1]], 0x34d399);

  /* ── Water droplets ─────────────────────────────────────── */
  const dropGeo = new THREE.SphereGeometry(0.035, 6, 5);
  const dropMat = new THREE.MeshBasicMaterial({ color: 0x7dd3fc, transparent: true, opacity: 0.8, toneMapped: false });
  const droplets = [];
  bedsZ.forEach((z) => {
    for (let i = 0; i < 6; i++) {
      const d = new THREE.Mesh(dropGeo, dropMat);
      d.userData = { x: -3 + i * 1.15, z, y: 0.55 + Math.random() * 0.1, speed: 0.35 + Math.random() * 0.25 };
      d.position.set(d.userData.x, d.userData.y, z);
      island.add(d);
      droplets.push(d);
    }
  });

  /* ── Fireflies & dust ───────────────────────────────────── */
  const fireflyCount = isMobile() ? 44 : 80;
  const fireflyGeo = new THREE.BufferGeometry();
  const fireflyPos = new Float32Array(fireflyCount * 3);
  const fireflySeeds = [];
  for (let i = 0; i < fireflyCount; i++) {
    const a = Math.random() * TAU;
    const r = 2 + Math.random() * 8;
    const x = Math.cos(a) * r - 0.4;
    const z = Math.sin(a) * r;
    const y = 0.8 + Math.random() * 5.2;
    fireflyPos[i * 3] = x;
    fireflyPos[i * 3 + 1] = y;
    fireflyPos[i * 3 + 2] = z;
    fireflySeeds.push({ x, z, phase: Math.random() * TAU, amp: 0.3 + Math.random() * 1.2 });
  }
  fireflyGeo.setAttribute("position", new THREE.BufferAttribute(fireflyPos, 3));
  const fireflyMat = new THREE.PointsMaterial({
    map: glowTex,
    color: 0xa7f3d0,
    size: 0.16,
    transparent: true,
    opacity: 0.65,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    sizeAttenuation: true,
    toneMapped: false
  });
  const fireflies = new THREE.Points(fireflyGeo, fireflyMat);
  island.add(fireflies);

  /* ── HTML scene chips ───────────────────────────────────── */
  const chipEls = Array.from(document.querySelectorAll(".scene-chip"));
  const anchors = {
    trust: new THREE.Vector3(0.2, 5.45, 0.15),
    soil: new THREE.Vector3(1.9, 1.65, 2.45),
    energy: new THREE.Vector3(-2.6, 1.55, 4.6)
  };
  const tmp = new THREE.Vector3();
  function updateChips() {
    if (!chipEls.length || isMobile()) return;
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    chipEls.forEach((el) => {
      const key = el.getAttribute("data-anchor");
      const local = anchors[key];
      if (!local) return;
      tmp.copy(local);
      island.localToWorld(tmp);
      tmp.project(camera);
      const x = (tmp.x * 0.5 + 0.5) * w;
      const y = (-tmp.y * 0.5 + 0.5) * h;
      el.style.transform = `translate(-50%, -50%) translate(${x.toFixed(1)}px, ${y.toFixed(1)}px)`;
      el.classList.toggle("ready", tmp.z < 1);
    });
  }

  /* ── Camera layout ──────────────────────────────────────── */
  const target = new THREE.Vector3(0, 1.6, 0);
  const basePos = new THREE.Vector3(19, 15, 25.5);
  let camBase = basePos.clone();
  const pointer = { x: 0, y: 0, tx: 0, ty: 0 };

  function layout() {
    const mobile = isMobile();
    const w = canvas.clientWidth || window.innerWidth;
    const h = canvas.clientHeight || window.innerHeight;
    const band = mobile && h <= 500; /* dedicated stage strip under the copy */
    renderer.setSize(w, h, false);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, mobile ? 1.6 : 2));
    camera.aspect = w / Math.max(h, 1);
    camera.fov = mobile ? (band ? 46 : 49) : 34;
    camera.updateProjectionMatrix();

    island.scale.setScalar(mobile ? (band ? 1.0 : 0.72) : 1);
    island.position.set(mobile ? (band ? -0.4 : 0) : 6.0, band ? -0.9 : -1.55, 0);
    shadow.position.x = island.position.x;
    if (mobile) {
      if (band) {
        target.set(0, 1.35, 0);
        camBase.set(11.8, 8.6, 18.8);
      } else {
        target.set(0, 3.15, 0);
        camBase.set(13.5, 12.5, 24);
      }
    } else {
      target.set(0, 1.6, 0);
      camBase.copy(basePos);
    }
    camera.position.copy(camBase);
    camera.lookAt(target);
    updateChips();
    if (reduceMotion) renderer.render(scene, camera);
    renderer.shadowMap.enabled = !mobile;
    key.castShadow = !mobile;
  }
  layout();

  /* ── Theme sync ─────────────────────────────────────────── */
  function syncTheme(theme) {
    const light = theme === "light";
    scene.fog.color.set(light ? 0xdbe9df : 0x07110c);
    scene.fog.density = light ? 0.006 : 0.011;
    renderer.toneMappingExposure = light ? 1.02 : 1.12;
    hemi.intensity = light ? 1.65 : 1.15;
    key.intensity = light ? 2.35 : 3.2;
    fill.intensity = light ? 0.7 : 1.15;
    warm.intensity = light ? 12 : 24;
    holoLight.intensity = light ? 18 : 42;
    shadow.material.opacity = light ? 0.2 : 0.5;
    fireflyMat.opacity = light ? 0.26 : 0.65;
    fireflyMat.color.set(light ? 0x15803d : 0xa7f3d0);
    ringMat.color.set(light ? 0x0f766e : 0x5eead4);
    rings.forEach((r) => { r.material.color.set(light ? 0x0f766e : 0x5eead4); r.material.opacity = light ? 0.45 : 0.65; });
    halo.material.color.set(light ? 0x059669 : 0x34d399);
    halo.material.opacity = light ? 0.28 : 0.55;
    logoMaterial.color.set(light ? 0x047857 : 0xd9ffe9);
    beam.material.color.set(light ? 0x047857 : 0x34d399);
    beam.material.opacity = light ? 0.035 : 0.055;
    groundGlow.material.color.set(light ? 0x059669 : 0x34d399);
    groundGlow.material.opacity = light ? 0.18 : 0.32;
    antennaTip.material.color.set(light ? 0x047857 : 0x6ee7b7);
    if (scene.environment) scene.environmentIntensity = light ? 0.75 : 0.45;
  }
  syncTheme(document.documentElement.dataset.theme === "light" ? "light" : "dark");
  document.addEventListener("tf-theme", (e) => {
    if (e.detail && e.detail.theme) syncTheme(e.detail.theme);
  });

  /* ── Pointer parallax ───────────────────────────────────── */
  hero.addEventListener("pointermove", (e) => {
    if (reduceMotion) return;
    pointer.tx = (e.clientX / window.innerWidth - 0.5) * 2;
    pointer.ty = (e.clientY / window.innerHeight - 0.5) * 2;
  }, { passive: true });
  hero.addEventListener("pointerleave", () => { pointer.tx = 0; pointer.ty = 0; });

  /* ── Animation loop ─────────────────────────────────────── */
  let started = performance.now();
  let visible = true;
  let raf = 0;

  if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver((entries) => {
      entries.forEach((entry) => { visible = entry.isIntersecting; });
      if (visible && !reduceMotion && !raf) {
        started = performance.now() - 2000;
        raf = requestAnimationFrame(frame);
      }
    }, { threshold: 0.02 });
    io.observe(hero);
  }

  function frame(now) {
    raf = 0;
    if (!visible || document.hidden) return;
    const t = (now - started) / 1000;
    pointer.x += (pointer.tx - pointer.x) * 0.035;
    pointer.y += (pointer.ty - pointer.y) * 0.035;

    island.rotation.y = Math.sin(t * 0.08) * 0.07 + pointer.x * 0.05;
    world.rotation.y = pointer.x * 0.012;

    camera.position.x = camBase.x + pointer.x * 1.05;
    camera.position.y = camBase.y - pointer.y * 0.62;
    camera.lookAt(target);

    // Crops sway
    for (let i = 0; i < plantGroups.length; i++) {
      const p = plantGroups[i];
      p.rotation.z = Math.sin(t * 1.2 + p.userData.phase) * p.userData.sway;
      p.rotation.x = Math.cos(t * 0.9 + p.userData.phase) * p.userData.sway * 0.4;
    }

    // Hologram
    holo.position.y = 5.55 + Math.sin(t * 0.9) * 0.12;
    holo.rotation.y = t * 0.15;
    rings[0].rotation.z = t * 0.38;
    rings[1].rotation.z = -t * 0.3;
    rings[2].rotation.z = t * 0.22;
    rings[0].rotation.x = Math.PI / 2 + Math.sin(t * 0.6) * 0.12;
    logoMaterial.opacity = 0.87 + Math.sin(t * 1.6) * 0.09;
    orbiters.forEach((dot) => {
      const a = dot.userData.angle + t * dot.userData.speed;
      dot.position.set(Math.cos(a) * dot.userData.radius, dot.userData.y + Math.sin(t * 1.4 + a) * 0.12, Math.sin(a) * dot.userData.radius);
    });

    // Packets
    packets.forEach((p) => {
      p.userData.t = (p.userData.t + p.userData.speed * 0.016) % 1;
      p.position.copy(p.userData.curve.getPointAt(p.userData.t));
      p.scale.setScalar(0.8 + Math.sin(t * 5 + p.userData.t * 8) * 0.25);
    });

    // Droplets
    droplets.forEach((d) => {
      d.position.y -= d.userData.speed * 0.016;
      if (d.position.y < 0.44) {
        d.position.y = 0.55;
        d.userData.x = -3 + Math.random() * 6.8;
        d.position.x = d.userData.x;
      }
    });

    // Fireflies & antenna
    const fp = fireflyGeo.attributes.position.array;
    for (let i = 0; i < fireflyCount; i++) {
      const s = fireflySeeds[i];
      fp[i * 3] = s.x + Math.sin(t * 0.22 + s.phase) * s.amp * 0.3;
      fp[i * 3 + 1] += Math.sin(t * 0.5 + s.phase) * 0.0007;
      fp[i * 3 + 2] = s.z + Math.cos(t * 0.18 + s.phase) * s.amp * 0.3;
    }
    fireflyGeo.attributes.position.needsUpdate = true;
    if (antennaLight) antennaLight.intensity = 5 + Math.sin(t * 3.2) * 3;
    // energy hum pulse
    holoLight.intensity = (document.documentElement.dataset.theme === "light" ? 18 : 42) + Math.sin(t * 2) * 6;

    // Keep the scene chips anchored to their 3D targets
    updateChips();

    renderer.render(scene, camera);
    raf = requestAnimationFrame(frame);
  }

  /* ── Resize ─────────────────────────────────────────────── */
  let resizeTimer = 0;
  window.addEventListener("resize", () => {
    window.clearTimeout(resizeTimer);
    resizeTimer = window.setTimeout(() => {
      layout();
      if (reduceMotion) renderer.render(scene, camera);
    }, 120);
  });

  /* ── Start ──────────────────────────────────────────────── */
  canvas.classList.add("ready");
  if (reduceMotion) {
    updateChips();
    renderer.render(scene, camera);
  } else {
    raf = requestAnimationFrame(frame);
  }
}
