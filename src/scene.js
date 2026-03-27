const canvas = document.getElementById('c');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, powerPreference:'high-performance', logarithmicDepthBuffer: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.setClearColor(0x080a0c);

const scene = new THREE.Scene();
const defaultFog = new THREE.Fog(0x080a0c, 40, 100);
scene.fog = defaultFog;

const camera = new THREE.PerspectiveCamera(55, 1, 0.1, 6000000);
camera.position.set(10, 12, 16);
camera.lookAt(0, 0, 0);

const ambient = new THREE.AmbientLight(0x223344, 0.6);
scene.add(ambient);

const sun = new THREE.DirectionalLight(0x88aacc, 1.2);
sun.position.set(10, 20, 10);
sun.castShadow = true;
sun.shadow.mapSize.set(1024, 1024);
sun.shadow.camera.near = 0.5;
sun.shadow.camera.far = 100;
sun.shadow.camera.left = sun.shadow.camera.bottom = -20;
sun.shadow.camera.right = sun.shadow.camera.top = 20;
scene.add(sun);

const fill = new THREE.DirectionalLight(0x334455, 0.4);
fill.position.set(-8, 5, -8);
scene.add(fill);

const rim = new THREE.PointLight(0x0088ff, 0.8, 30);
rim.position.set(-5, 10, -10);
scene.add(rim);

const gridHelper = new THREE.GridHelper(30, 30, 0x1a2530, 0x111820);
scene.add(gridHelper);

const dotGeo = new THREE.SphereGeometry(0.08, 6, 6);
const dotMat = new THREE.MeshBasicMaterial({ color: 0x00e5ff });
scene.add(new THREE.Mesh(dotGeo, dotMat));

const ghostGeo = new THREE.BoxGeometry(1, 1, 1);
const ghostMat = new THREE.MeshBasicMaterial({ color: 0x00e5ff, wireframe: false, transparent: true, opacity: 0.25 });
const ghostEdgeMat = new THREE.LineBasicMaterial({ color: 0x00e5ff, transparent: true, opacity: 0.7 });
const ghostMesh = new THREE.Mesh(ghostGeo, ghostMat);
const ghostEdge = new THREE.LineSegments(new THREE.EdgesGeometry(ghostGeo), ghostEdgeMat);
ghostMesh.add(ghostEdge);
ghostMesh.visible = false;
scene.add(ghostMesh);

const raycaster = new THREE.Raycaster();
const groundPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);

const sharedGeo = new THREE.BoxGeometry(0.98, 0.98, 0.98);
const edgesGeo = new THREE.EdgesGeometry(sharedGeo);
const matCache = new Map();

function getMat(color, emissive) {
  const key = `${color}_${emissive}`;
  if (!matCache.has(key)) {
    matCache.set(key, new THREE.MeshStandardMaterial({
      color,
      emissive,
      emissiveIntensity: 1,
      roughness: 0.7,
      metalness: 0.3,
    }));
  }
  return matCache.get(key);
}

function createVoxelMesh(blockType, colorOverride = null) {
  const color = colorOverride ?? (blockType.id === 'custom' ? customColor : blockType.color);
  const emissive = blockType.id === 'custom' ? 0x001122 : blockType.emissive;
  const mesh = new THREE.Mesh(sharedGeo, getMat(color, emissive));
  mesh.castShadow = true;
  mesh.receiveShadow = true;

  const edgeMat = new THREE.LineBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.3 });
  const edges = new THREE.LineSegments(edgesGeo, edgeMat);
  mesh.add(edges);
  return mesh;
}
