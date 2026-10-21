/* TrustFarm AI — realistic 3D system-flow diorama (Three.js) */
import * as THREE from "three";
import { RoundedBoxGeometry } from "three/addons/geometries/RoundedBoxGeometry.js";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { RoomEnvironment } from "three/addons/environments/RoomEnvironment.js";

const canvas = document.getElementById("flowScene");
const stage = document.getElementById("flowStage");
if (canvas && stage) init();

function init() {
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const $ = (s) => document.querySelector(s);
  const $$ = (s) => Array.from(document.querySelectorAll(s));
  const mobile = () => window.innerWidth < 720;

  const renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: true,
    alpha: true,
    powerPreference: "high-performance"
  });
  renderer.setClearColor(0x000000, 0);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.52;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.shadowMap.enabled = !mobile();
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(34, 1, 0.1, 120);
  camera.position.set(0, 14.8, 19.8);

  const controls = new OrbitControls(camera, canvas);
  controls.target.set(0, 0.9, 0);
  controls.enableDamping = true;
  controls.dampingFactor = 0.055;
  controls.enablePan = false;
  controls.minDistance = 15;
  controls.maxDistance = 44;
  controls.minPolarAngle = Math.PI * 0.18;
  controls.maxPolarAngle = Math.PI * 0.46;
  controls.autoRotate = !reduceMotion;
  controls.autoRotateSpeed = 0.36;
  controls.update();

  const env = new THREE.PMREMGenerator(renderer);
  scene.environment = env.fromScene(new RoomEnvironment(renderer), 0.04).texture;
  scene.environmentIntensity = 0.5;
  env.dispose();

  /* ── Lights ─────────────────────────────────────────────── */
  const hemi = new THREE.HemisphereLight(0xd9f6ff, 0x113324, 1.38);
  scene.add(hemi);
  const key = new THREE.DirectionalLight(0xfff2dd, 3.85);
  key.position.set(10, 20, 13);
  key.castShadow = !mobile();
  key.shadow.mapSize.set(mobile() ? 1024 : 2048, mobile() ? 1024 : 2048);
  key.shadow.camera.left = -18;
  key.shadow.camera.right = 18;
  key.shadow.camera.top = 14;
  key.shadow.camera.bottom = -14;
  key.shadow.camera.near = 1;
  key.shadow.camera.far = 60;
  key.shadow.bias = -0.0006;
  scene.add(key);
  const rim = new THREE.DirectionalLight(0x38bdf8, 1.25);
  rim.position.set(-14, 11, -11);
  scene.add(rim);
  const warm = new THREE.PointLight(0xfbbf24, 15, 14, 2);
  warm.position.set(-3, 4, -4);
  scene.add(warm);
  const overhead = new THREE.PointLight(0x6ee7b7, 22, 32, 2);
  overhead.position.set(0, 8.5, 7);
  scene.add(overhead);

  /* ── Materials ──────────────────────────────────────────── */
  const M = {
    board: new THREE.MeshPhysicalMaterial({ color: 0x07130d, roughness: 0.48, metalness: 0.62, clearcoat: 0.35, clearcoatRoughness: 0.55 }),
    boardEdge: new THREE.MeshStandardMaterial({ color: 0x0f2b1e, roughness: 0.42, metalness: 0.7 }),
    pcb: new THREE.MeshStandardMaterial({ color: 0x0b5134, roughness: 0.62, metalness: 0.12 }),
    pcbBlue: new THREE.MeshStandardMaterial({ color: 0x0b2b57, roughness: 0.6, metalness: 0.16 }),
    chip: new THREE.MeshStandardMaterial({ color: 0x111821, roughness: 0.4, metalness: 0.24 }),
    metal: new THREE.MeshStandardMaterial({ color: 0xa8b7b1, roughness: 0.27, metalness: 0.9 }),
    darkMetal: new THREE.MeshStandardMaterial({ color: 0x1b2723, roughness: 0.34, metalness: 0.8 }),
    gold: new THREE.MeshStandardMaterial({ color: 0xd9a514, roughness: 0.24, metalness: 0.95 }),
    green: new THREE.MeshStandardMaterial({ color: 0x34d399, emissive: 0x10b981, emissiveIntensity: 1.7, roughness: 0.25 }),
    cyan: new THREE.MeshStandardMaterial({ color: 0x22d3ee, emissive: 0x0891b2, emissiveIntensity: 1.8, roughness: 0.24 }),
    amber: new THREE.MeshStandardMaterial({ color: 0xfbbf24, emissive: 0xf59e0b, emissiveIntensity: 1.8, roughness: 0.26 }),
    red: new THREE.MeshStandardMaterial({ color: 0xfb7185, emissive: 0xe11d48, emissiveIntensity: 1.8, roughness: 0.26 }),
    glass: new THREE.MeshPhysicalMaterial({ color: 0xbdf7e4, roughness: 0.08, metalness: 0.05, transmission: 0.55, transparent: true, opacity: 0.38, ior: 1.45, thickness: 0.4 }),
    screen: new THREE.MeshStandardMaterial({ color: 0x07110c, roughness: 0.3, metalness: 0.1, emissive: 0x0a2a1c, emissiveIntensity: 0.6 }),
    wireRed: new THREE.MeshStandardMaterial({ color: 0xb91c1c, roughness: 0.4, metalness: 0.2 }),
    wireBlack: new THREE.MeshStandardMaterial({ color: 0x111418, roughness: 0.52, metalness: 0.2 })
  };

  function rbox(w, h, d, mat, pos, parent, r) {
    const geo = r ? new RoundedBoxGeometry(w, h, d, 4, r) : new THREE.BoxGeometry(w, h, d);
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.set(pos[0], pos[1], pos[2]);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    (parent || board).add(mesh);
    return mesh;
  }
  function cyl(r, h, mat, pos, parent, seg = 20) {
    const mesh = new THREE.Mesh(new THREE.CylinderGeometry(r, r, h, seg), mat);
    mesh.position.set(pos[0], pos[1], pos[2]);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    (parent || board).add(mesh);
    return mesh;
  }
  function glowDot(color, size, pos, parent) {
    const m = new THREE.Mesh(new THREE.SphereGeometry(size, 10, 10), new THREE.MeshBasicMaterial({ color, toneMapped: false }));
    m.position.set(pos[0], pos[1], pos[2]);
    (parent || board).add(m);
    return m;
  }
  function makeGridTexture() {
    const c = document.createElement("canvas");
    c.width = 1024;
    c.height = 352;
    const g = c.getContext("2d");
    g.fillStyle = "#0a1c12";
    g.fillRect(0, 0, c.width, c.height);
    const grad = g.createRadialGradient(512, 176, 20, 512, 176, 520);
    grad.addColorStop(0, "rgba(52,211,153,0.3)");
    grad.addColorStop(0.55, "rgba(34,211,238,0.05)");
    grad.addColorStop(1, "rgba(0,0,0,0)");
    g.fillStyle = grad;
    g.fillRect(0, 0, c.width, c.height);
    g.strokeStyle = "rgba(110,231,183,0.26)";
    g.lineWidth = 1;
    for (let x = 0; x <= c.width; x += 64) {
      g.beginPath(); g.moveTo(x, 0); g.lineTo(x, c.height); g.stroke();
    }
    for (let y = 0; y <= c.height; y += 64) {
      g.beginPath(); g.moveTo(0, y); g.lineTo(c.width, y); g.stroke();
    }
    g.strokeStyle = "rgba(34,211,238,0.2)";
    g.lineWidth = 2;
    g.strokeRect(1, 1, c.width - 2, c.height - 2);
    const t = new THREE.CanvasTexture(c);
    t.colorSpace = THREE.SRGBColorSpace;
    t.anisotropy = Math.min(8, renderer.capabilities.getMaxAnisotropy());
    return t;
  }
  function makePhoneTexture() {
    const c = document.createElement("canvas");
    c.width = 384;
    c.height = 760;
    const g = c.getContext("2d");
    g.fillStyle = "#06100a";
    g.fillRect(0, 0, c.width, c.height);
    g.fillStyle = "#0a1d14";
    g.fillRect(0, 0, c.width, 116);
    g.fillStyle = "#34d399";
    g.font = "bold 20px sans-serif";
    g.fillText("TRUSTFARM", 28, 42);
    g.fillStyle = "#eafff4";
    g.font = "bold 32px sans-serif";
    g.fillText("Field 01", 28, 82);
    g.fillStyle = "#91b9a3";
    g.font = "15px sans-serif";
    g.fillText("Live · 60 s telemetry", 28, 104);
    g.fillStyle = "#0c2418";
    g.beginPath(); g.roundRect(22, 136, 340, 156, 20); g.fill();
    g.strokeStyle = "rgba(110,231,183,0.25)";
    g.stroke();
    g.fillStyle = "#6ee7b7";
    g.font = "bold 15px sans-serif";
    g.fillText("TRUST SCORE", 42, 170);
    g.fillStyle = "#ffffff";
    g.font = "bold 66px sans-serif";
    g.fillText("96", 42, 242);
    g.fillStyle = "#91b9a3";
    g.font = "18px sans-serif";
    g.fillText("/100", 126, 242);
    g.fillStyle = "#34d399";
    g.beginPath(); g.arc(315, 202, 40, 0, Math.PI * 2); g.fill();
    g.fillStyle = "#052e1b";
    g.font = "bold 19px sans-serif";
    g.fillText("GREEN", 282, 209);
    g.fillStyle = "#0c2418";
    g.beginPath(); g.roundRect(22, 310, 340, 210, 18); g.fill();
    g.strokeStyle = "rgba(110,231,183,0.16)";
    g.stroke();
    g.fillStyle = "#91b9a3";
    g.font = "14px sans-serif";
    g.fillText("SOIL MOISTURE · 3 H", 40, 342);
    g.strokeStyle = "#34d399";
    g.lineWidth = 4;
    g.beginPath();
    const pts = [[40, 448], [82, 430], [124, 438], [166, 406], [208, 415], [250, 380], [292, 392], [334, 360]];
    pts.forEach((p, i) => i ? g.lineTo(p[0], p[1]) : g.moveTo(p[0], p[1]));
    g.stroke();
    g.fillStyle = "rgba(52,211,153,0.15)";
    g.lineTo(334, 486); g.lineTo(40, 486); g.closePath(); g.fill();
    g.fillStyle = "#91b9a3";
    g.font = "14px sans-serif";
    g.fillText("CURRENT  28.4%", 40, 518);
    g.fillStyle = "#18c47f";
    g.font = "bold 16px sans-serif";
    g.fillText("ADVICE · IRRIGATE 18:40", 40, 548);
    g.fillStyle = "#0c2418";
    g.beginPath(); g.roundRect(22, 580, 340, 140, 18); g.fill();
    g.fillStyle = "#6ee7b7";
    g.font = "bold 15px sans-serif";
    g.fillText("ENERGY GATE", 40, 613);
    g.fillStyle = "#eafff4";
    g.font = "bold 28px sans-serif";
    g.fillText("74%", 40, 666);
    g.fillStyle = "#91b9a3";
    g.font = "14px sans-serif";
    g.fillText("Battery · 78 W charging", 106, 664);
    g.fillStyle = "#0f2d1d";
    g.fillRect(40, 692, 304, 9);
    g.fillStyle = "#34d399";
    g.fillRect(40, 692, 225, 9);
    const t = new THREE.CanvasTexture(c);
    t.colorSpace = THREE.SRGBColorSpace;
    return t;
  }

  /* ── Board ──────────────────────────────────────────────── */
  const board = new THREE.Group();
  scene.add(board);
  rbox(22.4, 0.5, 8.0, M.boardEdge, [0, 0, 0], board, 0.28);
  rbox(22, 0.12, 7.7, M.board, [0, 0.3, 0], board, 0.2);
  const gridPlane = new THREE.Mesh(
    new THREE.PlaneGeometry(21.5, 7.2),
    new THREE.MeshBasicMaterial({ map: makeGridTexture(), transparent: true, opacity: 0.95, depthWrite: false })
  );
  gridPlane.rotation.x = -Math.PI / 2;
  gridPlane.position.set(0, 0.375, 0);
  board.add(gridPlane);
  rbox(22.3, 0.055, 0.055, M.green, [0, 0.34, 3.93], board);
  rbox(22.3, 0.055, 0.055, M.cyan, [0, 0.34, -3.93], board);
  for (const [x, z] of [[-10.3, -3.3], [10.3, -3.3], [-10.3, 3.3], [10.3, 3.3]]) {
    cyl(0.22, 0.5, M.darkMetal, [x, -0.45, z], board, 8);
  }

  /* Contact shadow / glow under the board */
  function radialTexture(inner, outer) {
    const c = document.createElement("canvas");
    c.width = c.height = 256;
    const g = c.getContext("2d");
    const gr = g.createRadialGradient(128, 128, 4, 128, 128, 126);
    gr.addColorStop(0, inner);
    gr.addColorStop(1, outer);
    g.fillStyle = gr;
    g.fillRect(0, 0, 256, 256);
    return new THREE.CanvasTexture(c);
  }
  const floorGlow = new THREE.Mesh(
    new THREE.PlaneGeometry(30, 14),
    new THREE.MeshBasicMaterial({ map: radialTexture("rgba(16,185,129,0.22)", "rgba(0,0,0,0)"), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending })
  );
  floorGlow.rotation.x = -Math.PI / 2;
  floorGlow.position.y = -0.75;
  scene.add(floorGlow);

  /* ── Shared helpers ─────────────────────────────────────── */
  const halos = [];
  function addHalo(parent, x, z, radius) {
    const mat = new THREE.MeshBasicMaterial({
      color: 0x34d399,
      transparent: true,
      opacity: 0.1,
      side: THREE.DoubleSide,
      depthWrite: false,
      blending: THREE.AdditiveBlending
    });
    const ring = new THREE.Mesh(new THREE.RingGeometry(radius * 0.7, radius, 48), mat);
    ring.rotation.x = -Math.PI / 2;
    ring.position.set(x, 0.04, z);
    parent.add(ring);
    halos.push(ring);
    return ring;
  }
  function addCable(parent, points, mat, radius = 0.016) {
    const curve = new THREE.CatmullRomCurve3(points.map((p) => new THREE.Vector3(p[0], p[1], p[2])));
    const tube = new THREE.Mesh(new THREE.TubeGeometry(curve, 28, radius, 6, false), mat);
    tube.castShadow = true;
    parent.add(tube);
    return tube;
  }

  /* ── 01 · Field node ────────────────────────────────────── */
  const field = new THREE.Group();
  field.position.set(-7.8, 0.38, 0);
  board.add(field);
  rbox(2.75, 0.14, 2.1, M.pcb, [0, 0, 0], field, 0.08);
  rbox(1.05, 0.22, 0.66, M.chip, [-0.3, 0.18, -0.34], field, 0.04);
  rbox(0.98, 0.035, 0.58, M.metal, [-0.3, 0.305, -0.34], field, 0.02);
  for (let i = 0; i < 8; i++) {
    cyl(0.018, 0.16, M.gold, [-0.78 + i * 0.14, 0.11, 0.04], field, 6);
    cyl(0.018, 0.16, M.gold, [-0.78 + i * 0.14, 0.11, -0.74], field, 6);
  }
  rbox(0.5, 0.09, 0.4, M.darkMetal, [0.66, 0.12, 0.35], field, 0.03);
  cyl(0.07, 0.16, M.metal, [0.66, 0.23, 0.35], field);
  glowDot(0x34d399, 0.035, [1.04, 0.15, -0.55], field);
  glowDot(0xfbbf24, 0.032, [1.04, 0.15, -0.34], field);
  // two soil probes in a small stand
  for (const px of [-1.55, -1.05]) {
    const probe = new THREE.Group();
    probe.position.set(px, 0.08, 0.55);
    field.add(probe);
    rbox(0.27, 0.045, 1.12, M.pcbBlue, [0, 0, 0], probe, 0.03);
    rbox(0.17, 0.06, 0.22, M.chip, [0, 0.05, 0.35], probe, 0.02);
    rbox(0.12, 0.02, 0.5, M.gold, [0, 0.035, -0.18], probe);
  }
  // small solar panel
  const solar = new THREE.Group();
  solar.position.set(-0.1, 0.5, 1.08);
  solar.rotation.x = -0.42;
  field.add(solar);
  rbox(1.35, 0.04, 0.62, M.pcbBlue, [0, 0, 0], solar, 0.02);
  for (let i = -2; i <= 2; i++) rbox(0.02, 0.012, 0.56, M.metal, [i * 0.25, 0.025, 0], solar);
  // antenna
  cyl(0.022, 0.7, M.darkMetal, [1.0, 0.4, -0.62], field, 8);
  glowDot(0x22d3ee, 0.04, [1.0, 0.77, -0.62], field);
  addCable(field, [[-0.75, 0.12, 0.35], [-0.35, 0.25, 0.8], [0.52, 0.18, 0.55]], M.wireRed, 0.012);
  addCable(field, [[-0.78, 0.11, 0.08], [-0.2, 0.23, 0.95], [0.56, 0.18, 0.3]], M.wireBlack, 0.012);
  addHalo(field, 0, 0, 1.6);

  /* ── 02 · Gateway node ──────────────────────────────────── */
  const gateway = new THREE.Group();
  gateway.position.set(-3.4, 0.38, 0);
  board.add(gateway);
  rbox(1.05, 0.12, 1.05, M.darkMetal, [0, 0, 0], gateway, 0.05);
  cyl(0.075, 2.25, M.metal, [0, 1.16, 0], gateway, 12);
  rbox(0.96, 0.48, 0.62, M.chip, [0, 2.3, 0], gateway, 0.06);
  rbox(0.72, 0.045, 0.44, M.green, [0, 2.55, 0], gateway, 0.02);
  for (let i = 0; i < 3; i++) glowDot(i === 0 ? 0x34d399 : 0x22d3ee, 0.028, [-0.22 + i * 0.22, 2.30, 0.33], gateway);
  for (let i = 0; i < 2; i++) {
    const a = cyl(0.018, 0.78, M.darkMetal, [0.34 + i * 0.18, 2.72, -0.12], gateway, 8);
    a.rotation.z = (i ? 1 : -1) * 0.42;
    glowDot(0x34d399, 0.032, [0.34 + i * 0.18 + (i ? 0.15 : -0.15), 3.07, -0.12], gateway);
  }
  addHalo(gateway, 0, 0, 1.2);

  /* ── 03 · Trust core ────────────────────────────────────── */
  const trust = new THREE.Group();
  trust.position.set(0.4, 0.38, 0);
  board.add(trust);
  rbox(1.72, 0.13, 1.65, M.darkMetal, [0, 0, 0], trust, 0.07);
  // server tower: three stacked units and a glass front
  for (let i = 0; i < 3; i++) {
    const y = 0.42 + i * 0.62;
    rbox(1.35, 0.54, 1.25, i === 1 ? M.boardEdge : M.chip, [0, y, 0], trust, 0.055);
    for (let v = 0; v < 5; v++) rbox(0.9, 0.018, 0.02, M.darkMetal, [0, y - 0.15 + v * 0.075, 0.64], trust);
    glowDot(i === 2 ? 0x34d399 : 0x22d3ee, 0.026, [0.48, y + 0.12, 0.66], trust);
  }
  const shieldShape = new THREE.Shape();
  shieldShape.moveTo(0, 0.58);
  shieldShape.bezierCurveTo(0.25, 0.58, 0.5, 0.46, 0.5, 0.32);
  shieldShape.lineTo(0.5, -0.08);
  shieldShape.bezierCurveTo(0.5, -0.48, 0.15, -0.68, 0, -0.76);
  shieldShape.bezierCurveTo(-0.15, -0.68, -0.5, -0.48, -0.5, -0.08);
  shieldShape.lineTo(-0.5, 0.32);
  shieldShape.bezierCurveTo(-0.5, 0.46, -0.25, 0.58, 0, 0.58);
  const shieldGeo = new THREE.ExtrudeGeometry(shieldShape, { depth: 0.08, bevelEnabled: true, bevelSegments: 3, bevelSize: 0.025, bevelThickness: 0.025, curveSegments: 16 });
  shieldGeo.center();
  const shieldMat = new THREE.MeshPhysicalMaterial({ color: 0x6ee7b7, emissive: 0x10b981, emissiveIntensity: 1.35, metalness: 0.35, roughness: 0.2, transparent: true, opacity: 0.96 });
  const shield = new THREE.Mesh(shieldGeo, shieldMat);
  shield.position.set(0, 1.34, 0.73);
  shield.scale.setScalar(0.74);
  trust.add(shield);
  const shieldEdges = new THREE.LineSegments(new THREE.EdgesGeometry(shieldGeo), new THREE.LineBasicMaterial({ color: 0xd1fae5, transparent: true, opacity: 0.45 }));
  shieldEdges.position.copy(shield.position);
  shieldEdges.scale.copy(shield.scale);
  trust.add(shieldEdges);
  const trustRing = new THREE.Mesh(new THREE.TorusGeometry(0.78, 0.018, 8, 64), M.green);
  trustRing.rotation.x = Math.PI / 2;
  trustRing.position.y = 2.24;
  trust.add(trustRing);
  const trustLight = new THREE.PointLight(0x34d399, 10, 8, 2);
  trustLight.position.set(0, 1.4, 0.9);
  trust.add(trustLight);
  addHalo(trust, 0, 0, 1.5);

  /* ── 04 · Forecast / advice node ───────────────────────── */
  const ai = new THREE.Group();
  ai.position.set(4.4, 0.38, 0);
  board.add(ai);
  rbox(1.65, 0.13, 1.65, M.darkMetal, [0, 0, 0], ai, 0.08);
  cyl(0.48, 0.14, M.glass, [0, 0.22, 0], ai, 24);
  const orb = new THREE.Mesh(new THREE.OctahedronGeometry(0.54, 1), new THREE.MeshPhysicalMaterial({ color: 0x67e8f9, emissive: 0x0891b2, emissiveIntensity: 1.15, metalness: 0.22, roughness: 0.16, transmission: 0.24, transparent: true, opacity: 0.72 }));
  orb.position.set(0, 1.33, 0);
  ai.add(orb);
  const orbWire = new THREE.Mesh(new THREE.OctahedronGeometry(0.57, 1), new THREE.MeshBasicMaterial({ color: 0x22d3ee, wireframe: true, transparent: true, opacity: 0.28 }));
  orbWire.position.copy(orb.position);
  ai.add(orbWire);
  const orbit1 = new THREE.Mesh(new THREE.TorusGeometry(0.82, 0.012, 6, 64), M.cyan);
  orbit1.position.y = 1.33;
  orbit1.rotation.x = Math.PI / 2.3;
  ai.add(orbit1);
  const orbit2 = new THREE.Mesh(new THREE.TorusGeometry(0.98, 0.009, 6, 64), M.green);
  orbit2.position.y = 1.33;
  orbit2.rotation.x = Math.PI / 1.7;
  orbit2.rotation.z = 0.55;
  ai.add(orbit2);
  const aiLight = new THREE.PointLight(0x22d3ee, 9, 7, 2);
  aiLight.position.set(0, 1.35, 0.8);
  ai.add(aiLight);
  addHalo(ai, 0, 0, 1.35);

  /* ── 05 · Power node ────────────────────────────────────── */
  const power = new THREE.Group();
  power.position.set(2.7, 0.38, 2.7);
  board.add(power);
  rbox(2.1, 0.72, 1.15, M.chip, [0, 0.36, 0], power, 0.08);
  rbox(2.16, 0.1, 1.2, M.darkMetal, [0, 0.76, 0], power, 0.03);
  for (let i = 0; i < 3; i++) {
    cyl(0.17, 0.58, M.boardEdge, [-0.62 + i * 0.62, 0.93, 0], power, 16);
    cyl(0.055, 0.05, M.metal, [-0.62 + i * 0.62, 1.24, 0], power, 12);
  }
  cyl(0.1, 0.26, M.red, [-0.78, 0.74, 0.52], power, 10);
  cyl(0.1, 0.26, M.darkMetal, [0.78, 0.74, 0.52], power, 10);
  rbox(0.88, 0.08, 0.36, M.amber, [0, 0.48, 0.6], power, 0.02);
  // small generator canister
  const gen = new THREE.Group();
  gen.position.set(1.9, 0.34, 0.05);
  power.add(gen);
  rbox(0.95, 0.7, 0.85, M.amber, [0, 0, 0], gen, 0.1);
  cyl(0.22, 0.82, M.darkMetal, [0.35, 0.06, 0], gen, 16).rotation.z = Math.PI / 2;
  rbox(0.24, 0.18, 0.05, M.screen, [0, 0.2, 0.44], gen, 0.02);
  addHalo(power, 0.6, 0, 1.5);

  /* ── 06 · Farmer app node ───────────────────────────────── */
  const app = new THREE.Group();
  app.position.set(8.2, 0.38, 0);
  board.add(app);
  rbox(1.6, 0.1, 1.2, M.darkMetal, [0, 0, 0], app, 0.06);
  const phone = new THREE.Group();
  phone.position.set(0, 0.98, 0);
  phone.rotation.x = -0.08;
  phone.rotation.y = -0.24;
  app.add(phone);
  rbox(0.98, 1.82, 0.11, M.darkMetal, [0, 0, 0], phone, 0.09);
  const screen = new THREE.Mesh(new THREE.PlaneGeometry(0.87, 1.65), new THREE.MeshBasicMaterial({ map: makePhoneTexture(), toneMapped: false }));
  screen.position.set(0, 0, 0.065);
  phone.add(screen);
  rbox(0.22, 0.035, 0.02, M.chip, [0, 0.84, 0.07], phone, 0.01);
  rbox(1.3, 0.06, 1.0, M.metal, [0, 0.08, 0], app, 0.04);
  const stand = rbox(0.08, 0.62, 0.08, M.metal, [0, 0.34, -0.45], app, 0.02);
  stand.rotation.x = 0.35;
  const appLight = new THREE.PointLight(0x34d399, 6, 6, 2);
  appLight.position.set(0, 1.35, 0.55);
  app.add(appLight);
  addHalo(app, 0, 0, 1.3);

  [field, gateway, trust, ai, app, power].forEach((g) => g.scale.setScalar(1.22));

  /* ── Data & energy paths ────────────────────────────────── */
  const paths = [];
  function addPath(points, color, speed, holdAt) {
    const curve = new THREE.CatmullRomCurve3(points.map((p) => new THREE.Vector3(p[0], p[1], p[2])));
    const tube = new THREE.Mesh(
      new THREE.TubeGeometry(curve, 52, 0.026, 6, false),
      new THREE.MeshBasicMaterial({ color, transparent: true, opacity: 0.25, depthWrite: false, blending: THREE.AdditiveBlending })
    );
    board.add(tube);
    const packets = [];
    for (let i = 0; i < 3; i++) {
      const p = new THREE.Mesh(new THREE.SphereGeometry(0.055, 8, 8), new THREE.MeshBasicMaterial({ color, toneMapped: false }));
      board.add(p);
      packets.push({ mesh: p, offset: i / 3 });
    }
    paths.push({ curve, packets, speed, holdAt, color });
  }
  addPath([[-7.4, 1.0, 0], [-5.4, 2.25, 0.2], [-3.4, 2.0, 0]], 0x22d3ee, 0.16, false);
  addPath([[-2.9, 2.3, 0], [-1.3, 2.65, 0.1], [0.4, 2.1, 0]], 0x34d399, 0.14, false);
  addPath([[1.1, 2.0, 0], [2.7, 2.55, 0.12], [4.4, 1.5, 0]], 0x6ee7b7, 0.17, true);
  addPath([[5.0, 1.4, 0], [6.6, 1.95, 0.1], [8.1, 1.5, 0]], 0x22d3ee, 0.15, true);
  addPath([[2.7, 0.8, 2.7], [-2.8, 0.72, 3.2], [-7.3, 0.56, 0.5]], 0xfbbf24, 0.1, false);
  addPath([[2.7, 0.8, 2.7], [1.8, 1.05, 2.0], [0.4, 1.2, 1.05]], 0xfbbf24, 0.12, false);

  /* ── DOM interaction / labels ───────────────────────────── */
  const stepEls = $$(".flow-step");
  const labelEls = $$(".flow-node-label");
  const labelWrap = $("#flowLabels");
  const flowState = $("#flowState");
  const greenState = flowState ? flowState.querySelector(".state-green") : null;
  const redState = flowState ? flowState.querySelector(".state-red") : null;
  const nodeGroups = [field, gateway, trust, ai, power];
  const anchors = [
    new THREE.Vector3(-7.8, 2.95, 0),
    new THREE.Vector3(-3.4, 3.9, 0),
    new THREE.Vector3(0.4, 3.3, 0),
    new THREE.Vector3(4.4, 3.1, 0),
    new THREE.Vector3(2.7, 1.8, 2.7)
  ];
  let activeStep = 0;
  let userLock = 0;
  let nextStep = 3;

  function setStep(index) {
    activeStep = ((index % 5) + 5) % 5;
    stepEls.forEach((el, i) => el.classList.toggle("is-active", i === activeStep));
    labelEls.forEach((el, i) => el.classList.toggle("is-active", i === activeStep));
    halos.forEach((ring, i) => {
      ring.material.color.set(i === activeStep ? 0x6ee7b7 : 0x34d399);
    });
  }
  stepEls.forEach((el) => {
    el.addEventListener("click", () => {
      setStep(parseInt(el.getAttribute("data-step"), 10) || 0);
      userLock = performance.now() + 9000;
    });
  });
  setStep(0);

  const projected = new THREE.Vector3();
  function updateLabels() {
    if (!labelWrap) return;
    const w = canvas.clientWidth;
    const h = canvas.clientHeight;
    labelEls.forEach((el, i) => {
      if (!anchors[i]) return;
      projected.copy(anchors[i]);
      board.localToWorld(projected);
      projected.project(camera);
      const x = (projected.x * 0.5 + 0.5) * w;
      const y = (-projected.y * 0.5 + 0.5) * h;
      el.style.transform = `translate(-50%, -50%) translate(${x.toFixed(1)}px, ${y.toFixed(1)}px)`;
    });
    if (!labelWrap.classList.contains("is-ready")) labelWrap.classList.add("is-ready");
  }

  function layout() {
    const w = canvas.clientWidth || 600;
    const h = canvas.clientHeight || 480;
    renderer.setSize(w, h, false);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    camera.aspect = w / Math.max(h, 1);
    camera.fov = mobile() ? 46 : 34;
    if (mobile()) {
      camera.position.set(0, 16, 28);
      controls.target.set(0, 0.9, 0);
    } else {
      camera.position.set(0, 14.8, 19.8);
      controls.target.set(0, 0.9, 0);
    }
    camera.updateProjectionMatrix();
    controls.update();
    updateLabels();
    if (reduceMotion) renderer.render(scene, camera);
  }

  /* ── Animation ──────────────────────────────────────────── */
  const clock = new THREE.Clock();
  let frameId = null;
  let visible = true;
  let fault = false;
  let firstFrame = true;

  function frame() {
    const t = reduceMotion ? 2.2 : clock.getElapsedTime();
    const now = performance.now();
    if (!reduceMotion) {
      controls.update();
      if (now > userLock && now > nextStep) {
        setStep(activeStep + 1);
        nextStep = now + 3200;
      }
    }

    const cycle = t % 18;
    const nextFault = cycle > 11.2 && cycle < 14.6;
    if (nextFault !== fault) {
      fault = nextFault;
      if (flowState) flowState.classList.toggle("is-red", fault);
      if (greenState) greenState.hidden = fault;
      if (redState) redState.hidden = !fault;
      shieldMat.color.set(fault ? 0xfb7185 : 0x6ee7b7);
      shieldMat.emissive.set(fault ? 0xe11d48 : 0x10b981);
      trustLight.color.set(fault ? 0xfb7185 : 0x34d399);
    }
    shieldMat.emissiveIntensity = 1.2 + Math.sin(t * 2.1) * 0.2;
    trustRing.rotation.z = t * 0.34;
    orb.rotation.y = t * 0.42;
    orb.rotation.x = Math.sin(t * 0.3) * 0.12;
    orbWire.rotation.y = -t * 0.35;
    orbit1.rotation.z = t * 0.3;
    orbit2.rotation.z = -t * 0.24;
    warm.intensity = 10 + Math.sin(t * 1.8) * 2;
    aiLight.intensity = 8 + Math.sin(t * 2.4) * 2;
    appLight.intensity = 5 + Math.sin(t * 2.8) * 1.5;

    paths.forEach((path, pi) => {
      path.packets.forEach((packet) => {
        let u = (t * path.speed + packet.offset) % 1;
        if (fault && path.holdAt) u = Math.min(u, 0.48);
        const p = path.curve.getPointAt(u);
        packet.mesh.position.copy(p);
        packet.mesh.visible = !(fault && path.holdAt && u > 0.45);
      });
      path.packets.forEach((packet, i) => {
        const pulse = 1 + Math.sin(t * 5 + i) * 0.16;
        packet.mesh.scale.setScalar(pulse);
      });
    });

    halos.forEach((ring, i) => {
      const pulse = i === activeStep ? 0.38 + Math.sin(t * 3.2) * 0.12 : 0.06;
      ring.material.opacity += (pulse - ring.material.opacity) * 0.12;
      ring.rotation.z = t * (i === activeStep ? 0.3 : 0.08);
    });

    // Field sensor LEDs stay alive; gateway antennas blink.
    hemi.intensity = 1.05 + Math.sin(t * 0.7) * 0.03;
    if (firstFrame) {
      firstFrame = false;
      if (labelWrap) labelWrap.classList.add("is-ready");
    }
    updateLabels();
    renderer.render(scene, camera);
    if (!reduceMotion && visible) frameId = requestAnimationFrame(frame);
  }

  function start() {
    if (frameId !== null) cancelAnimationFrame(frameId);
    frameId = requestAnimationFrame(frame);
  }
  if ("IntersectionObserver" in window) {
    new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        visible = entry.isIntersecting;
        if (visible && !reduceMotion) start();
        else if (!visible && frameId !== null) {
          cancelAnimationFrame(frameId);
          frameId = null;
        }
      });
    }, { threshold: 0.06 }).observe(stage);
  }
  window.addEventListener("resize", () => {
    layout();
    if (reduceMotion) renderer.render(scene, camera);
  });
  document.addEventListener("tf-language", updateLabels);

  layout();
  start();
  if (reduceMotion) renderer.render(scene, camera);
}
