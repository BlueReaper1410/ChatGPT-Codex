let galaxySystems = null;

function makeCoord(x = 0, y = 0, z = 0) {
  return { x, y, z };
}

function cloneCoord(coord) {
  return coord ? { x: coord.x, y: coord.y, z: coord.z } : null;
}

function coordKey(coord) {
  return `${coord.x},${coord.y},${coord.z}`;
}

function coordLabel(coord) {
  if (!coord) return '--';
  return `${coord.x}:${coord.y}:${coord.z}`;
}

function coordsEqual(a, b) {
  return !!a && !!b && a.x === b.x && a.y === b.y && a.z === b.z;
}

function addCoord(a, b) {
  return makeCoord(a.x + b.x, a.y + b.y, a.z + b.z);
}

function subCoord(a, b) {
  return makeCoord(a.x - b.x, a.y - b.y, a.z - b.z);
}

function positiveMod(value, divisor) {
  return ((value % divisor) + divisor) % divisor;
}

function floorDiv(value, divisor) {
  return Math.floor(value / divisor);
}

function hashString(input) {
  let hash = 2166136261;
  for (let i = 0; i < input.length; i++) {
    hash ^= input.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function mulberry32(seed) {
  let a = seed >>> 0;
  return function next() {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t ^= t + Math.imul(t ^ (t >>> 7), 61 | t);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function makeRng(label) {
  return mulberry32(hashString(`${WORLD_SEED}:${label}`));
}

function randRange(rng, min, max) {
  return min + (max - min) * rng();
}

function randInt(rng, min, max) {
  return Math.floor(randRange(rng, min, max + 1));
}

function moveValueTowards(current, target, maxDelta) {
  if (Math.abs(target - current) <= maxDelta) return target;
  return current + Math.sign(target - current) * maxDelta;
}

function getAbsoluteWorldPositionForSector(sectorCoord) {
  return new THREE.Vector3(
    sectorCoord.x * SECTOR_SIZE,
    sectorCoord.y * SECTOR_SIZE,
    sectorCoord.z * SECTOR_SIZE
  );
}

function getCurrentWorldOrigin() {
  return currentSectorCoord ? getAbsoluteWorldPositionForSector(currentSectorCoord) : new THREE.Vector3();
}

function getPlayerAbsoluteWorldPosition() {
  return getCurrentWorldOrigin().add(ship?.pos ? ship.pos.clone() : new THREE.Vector3());
}

function getSectorCoordFromWorldPosition(worldPosition) {
  return makeCoord(
    Math.round(worldPosition.x / SECTOR_SIZE),
    Math.round(worldPosition.y / SECTOR_SIZE),
    Math.round(worldPosition.z / SECTOR_SIZE)
  );
}

function getSystemAbsoluteWorldPosition(systemCoord) {
  const galaxyPos = getGalaxyPositionForCoord(systemCoord);
  return new THREE.Vector3(
    galaxyPos.x * GALAXY_WORLD_SCALE,
    galaxyPos.y * GALAXY_WORLD_Y_SCALE,
    galaxyPos.z * GALAXY_WORLD_SCALE
  );
}

function getSystemCoordFromSector(sectorCoord) {
  const entry = getNearestSystemEntry(getAbsoluteWorldPositionForSector(sectorCoord));
  return entry ? cloneCoord(entry.coord) : cloneCoord(HOME_SYSTEM_COORD);
}

function getSystemCenterSector(systemCoord) {
  return getSectorCoordFromWorldPosition(getSystemAbsoluteWorldPosition(systemCoord));
}

function getSystemLocalSector(sectorCoord) {
  const systemCoord = getSystemCoordFromSector(sectorCoord);
  const local = getAbsoluteWorldPositionForSector(sectorCoord)
    .sub(getSystemAbsoluteWorldPosition(systemCoord))
    .divideScalar(SECTOR_SIZE);
  return makeCoord(Math.round(local.x), Math.round(local.y), Math.round(local.z));
}

function getSpawnSectorForSystem(systemCoord) {
  const spawnWorld = getSystemAbsoluteWorldPosition(systemCoord).add(new THREE.Vector3(0, 0, SECTOR_SIZE * 5));
  return getSectorCoordFromWorldPosition(spawnWorld);
}

function getSectorWorldPosition(sectorCoord) {
  return getAbsoluteWorldPositionForSector(sectorCoord).sub(getCurrentWorldOrigin());
}

function getSystemWorldPosition(systemCoord) {
  return getSystemAbsoluteWorldPosition(systemCoord).sub(getCurrentWorldOrigin());
}

function getGalaxySystems() {
  if (galaxySystems) return galaxySystems;

  const systems = [];
  const used = new Set();
  const addSystem = (coord, galaxyPos, special = null) => {
    const keyName = coordKey(coord);
    if (used.has(keyName)) return false;
    used.add(keyName);
    systems.push({ coord: cloneCoord(coord), galaxyPos: galaxyPos.clone(), special });
    return true;
  };

  addSystem(makeCoord(0, 0, 0), new THREE.Vector3(0, 0, 0), 'blackhole');
  addSystem(makeCoord(6, 0, 2), new THREE.Vector3(34, 1.4, 12), 'home');

  const rng = makeRng('galaxy-layout');
  const armCount = 4;
  const totalSystems = 180;

  for (let i = 0; systems.length < totalSystems && i < 900; i++) {
    const arm = i % armCount;
    const radial = 6 + i * 0.27;
    const armBase = (Math.PI * 2 / armCount) * arm;
    const angle = armBase + radial * 0.42 + randRange(rng, -0.22, 0.22);
    const spread = 0.78 + radial * 0.06;
    const galaxyPos = new THREE.Vector3(
      Math.cos(angle) * radial * 5.5 + randRange(rng, -spread, spread),
      randRange(rng, -2.6, 2.6),
      Math.sin(angle) * radial * 5.5 + randRange(rng, -spread, spread)
    );

    const coord = makeCoord(
      Math.round(galaxyPos.x * 0.42),
      Math.round(galaxyPos.y * 0.32),
      Math.round(galaxyPos.z * 0.42)
    );

    if (Math.hypot(coord.x, coord.z) < 3) continue;
    addSystem(coord, galaxyPos);
  }

  for (let i = 0; systems.length < totalSystems + 24 && i < 240; i++) {
    const radial = 2.2 + Math.pow(rng(), 0.55) * 22;
    const angle = rng() * Math.PI * 2;
    const vertical = randRange(rng, -3.4, 3.4) * (0.35 + radial * 0.025);
    const swirl = radial < 8 ? radial * 0.2 : 0;
    const galaxyPos = new THREE.Vector3(
      Math.cos(angle + swirl) * radial * randRange(rng, 3.1, 4.4),
      vertical,
      Math.sin(angle + swirl) * radial * randRange(rng, 3.1, 4.4)
    );
    const coord = makeCoord(
      Math.round(galaxyPos.x * 0.4 + randRange(rng, -1.3, 1.3)),
      Math.round(galaxyPos.y * 0.3 + randRange(rng, -0.8, 0.8)),
      Math.round(galaxyPos.z * 0.4 + randRange(rng, -1.3, 1.3))
    );

    if (Math.hypot(coord.x, coord.z) < 2) continue;
    addSystem(coord, galaxyPos);
  }

  galaxySystems = systems;
  return galaxySystems;
}

function getGalaxyEntry(systemCoord) {
  return getGalaxySystems().find(entry => coordsEqual(entry.coord, systemCoord)) || null;
}

function getGalaxyPositionForCoord(systemCoord) {
  const entry = getGalaxyEntry(systemCoord);
  if (entry) return entry.galaxyPos.clone();
  const fallback = new THREE.Vector3(systemCoord.x * 4.6, systemCoord.y * 1.4, systemCoord.z * 4.6);
  return fallback;
}

function getNearestSystemEntry(worldPosition) {
  let best = null;
  let bestDistSq = Infinity;

  getGalaxySystems().forEach(entry => {
    const absPos = getSystemAbsoluteWorldPosition(entry.coord);
    const distSq = absPos.distanceToSquared(worldPosition);
    if (distSq < bestDistSq) {
      best = entry;
      bestDistSq = distSq;
    }
  });

  return best;
}

function ensureUniverseState() {
  if (!universeInitialized || !currentSectorCoord) {
    currentSystemCoord = cloneCoord(HOME_SYSTEM_COORD);
    currentSectorCoord = getSpawnSectorForSystem(currentSystemCoord);
    universeInitialized = true;
  }

  const nearestSystem = getNearestSystemEntry(getPlayerAbsoluteWorldPosition());
  currentSystemCoord = nearestSystem ? cloneCoord(nearestSystem.coord) : cloneCoord(HOME_SYSTEM_COORD);

  if (!selectedSystemCoord || coordsEqual(selectedSystemCoord, currentSystemCoord)) {
    const nearby = getGalaxySystems()
      .map(entry => ({
        coord: entry.coord,
        dist: getSystemAbsoluteWorldPosition(entry.coord).distanceTo(getSystemAbsoluteWorldPosition(currentSystemCoord)),
      }))
      .filter(entry => !coordsEqual(entry.coord, currentSystemCoord))
      .sort((a, b) => a.dist - b.dist);
    selectedSystemCoord = nearby[0] ? cloneCoord(nearby[0].coord) : addCoord(currentSystemCoord, makeCoord(1, 0, 0));
  }

  if (!selectedWarpTarget || !selectedWarpTarget.systemCoord) {
    selectedWarpTarget = getDefaultWarpTarget(selectedSystemCoord);
  }
}

function getCurrentSystemData() {
  ensureUniverseState();
  return getSystemData(currentSystemCoord);
}

function generateSystemName(rng, special = null) {
  if (special === 'blackhole') return 'Eventide Maw';
  if (special === 'home') return 'Helios Gate';
  const left = ['Astra', 'Vela', 'Cygn', 'Ori', 'Heli', 'Nexa', 'Tauri', 'Sera', 'Draco', 'Luma', 'Cari', 'Nyx', 'Iona', 'Khepri'];
  const right = ['dor', 'ion', 'aris', 'eus', 'ara', 'is', 'ora', 'eth', 'os', 'une', 'arae', 'tal', 'mir', 'axis'];
  const suffix = [' Reach', ' Gate', ' Expanse', ' Drift', ' Verge', ' Halo', ' Crown', ' Bastion'];
  return `${left[Math.floor(rng() * left.length)]}${right[Math.floor(rng() * right.length)]}${suffix[Math.floor(rng() * suffix.length)]}`;
}

function createSystemObjects(systemCoord, special, rng, starRadius) {
  if (special === 'blackhole') {
    return [{
      id: 'primary',
      kind: 'blackhole',
      name: 'Singularity',
      radius: starRadius,
      orbitRadius: 0,
      orbitAngle: 0,
      orbitTilt: 0,
      color: 0x05070d,
      emissive: 0x4f46ff,
    }];
  }

  const objects = [{
    id: 'primary',
    kind: 'star',
    name: 'Primary Star',
    radius: starRadius,
    orbitRadius: 0,
    orbitAngle: 0,
    orbitTilt: 0,
    color: null,
    emissive: null,
  }];

  const planetCount = randInt(rng, 2, 5);
  const palettes = [
    { color: 0x587db6, emissive: 0x0a1c34 },
    { color: 0xc7a96d, emissive: 0x35240a },
    { color: 0x7ec49e, emissive: 0x0d2518 },
    { color: 0x9f80c8, emissive: 0x231538 },
    { color: 0xc16e63, emissive: 0x34120d },
  ];

  for (let i = 0; i < planetCount; i++) {
    const palette = palettes[i % palettes.length];
    objects.push({
      id: `planet-${i}`,
      kind: 'planet',
      name: `Planet ${i + 1}`,
      radius: randRange(rng, 240, 720),
      orbitRadius: 4800 + i * randRange(rng, 2700, 5200),
      orbitAngle: randRange(rng, 0, Math.PI * 2),
      orbitTilt: randRange(rng, -0.25, 0.25),
      color: palette.color,
      emissive: palette.emissive,
    });
  }

  return objects;
}

function getSystemData(systemCoord) {
  const keyName = coordKey(systemCoord);
  if (systemCache.has(keyName)) return systemCache.get(keyName);

  const entry = getGalaxyEntry(systemCoord);
  const special = entry?.special || null;
  const rng = makeRng(`system:${keyName}`);
  const palettes = special === 'blackhole'
    ? [{ star: 0x080a0f, glow: 0x5d4dff, background: 0x010103, accent: 0x0f1034 }]
    : [
      { star: 0xffd38d, glow: 0xff9f43, background: 0x05080f, accent: 0x1e3048 },
      { star: 0x9ccfff, glow: 0x5c84ff, background: 0x040814, accent: 0x162a54 },
      { star: 0xffa1a1, glow: 0xff5d6a, background: 0x09050c, accent: 0x4a1f29 },
      { star: 0xb8ffd0, glow: 0x46f3a4, background: 0x04110d, accent: 0x15382f },
    ];
  const palette = palettes[Math.floor(rng() * palettes.length)];
  const starRadius = special === 'blackhole' ? 1320 : randRange(rng, 760, 1080);
  const objects = createSystemObjects(systemCoord, special, rng, starRadius);

  const data = {
    coord: cloneCoord(systemCoord),
    galaxyPos: getGalaxyPositionForCoord(systemCoord),
    name: generateSystemName(rng, special),
    special,
    backgroundColor: palette.background,
    accentColor: palette.accent,
    star: {
      kind: special === 'blackhole' ? 'blackhole' : 'star',
      color: palette.star,
      emissive: palette.glow,
      size: starRadius,
      influenceRadius: special === 'blackhole' ? 24000 : randRange(rng, 12000, 17500),
      hazardStrength: special === 'blackhole' ? 2.8 : randRange(rng, 0.4, 1.25),
    },
    asteroidBands: special === 'blackhole'
      ? [{ radius: 9, thickness: 1.6, vertical: 1 }]
      : [
        { radius: 5 + randInt(rng, 0, 1), thickness: 1.25, vertical: randInt(rng, 0, 1) },
        { radius: 8 + randInt(rng, 0, 2), thickness: 1.7, vertical: randInt(rng, 0, 2) },
      ],
    objects,
  };

  systemCache.set(keyName, data);
  return data;
}

function getSystemObjects(systemCoord) {
  return getSystemData(systemCoord).objects;
}

function getObjectById(systemCoord, objectId = 'primary') {
  return getSystemObjects(systemCoord).find(object => object.id === objectId) || getSystemObjects(systemCoord)[0];
}

function getObjectLocalPosition(systemCoord, objectOrId) {
  const object = typeof objectOrId === 'string' ? getObjectById(systemCoord, objectOrId) : objectOrId;
  if (!object || object.kind === 'star' || object.kind === 'blackhole') return new THREE.Vector3();

  const x = Math.cos(object.orbitAngle) * object.orbitRadius;
  const z = Math.sin(object.orbitAngle) * object.orbitRadius;
  const y = Math.sin(object.orbitAngle * 0.7) * object.orbitRadius * object.orbitTilt;
  return new THREE.Vector3(x, y, z);
}

function getTargetLabel(target) {
  const normalized = target || selectedWarpTarget;
  if (!normalized?.systemCoord) return 'NONE';
  const system = getSystemData(normalized.systemCoord);
  const object = getObjectById(normalized.systemCoord, normalized.objectId || 'primary');
  if (object?.kind === 'blackhole') return `${system.name} CORE`;
  if (object?.kind === 'star') return `${system.name} STAR`;
  return `${system.name} / ${object.name}`;
}

function getDefaultWarpTarget(systemCoord) {
  return { kind: 'object', systemCoord: cloneCoord(systemCoord), objectId: 'primary' };
}

function normalizeWarpTarget(target) {
  if (!target) return null;
  const systemCoord = cloneCoord(target.systemCoord || selectedSystemCoord);
  const objectId = target.objectId || 'primary';
  return { kind: target.kind || 'object', systemCoord, objectId };
}

function setSelectedWarpTarget(target) {
  const normalized = normalizeWarpTarget(target);
  if (!normalized) return;
  selectedWarpTarget = normalized;
  selectedSystemCoord = cloneCoord(normalized.systemCoord);
  selectedSystemObjectId = normalized.objectId || 'primary';
  if (launchMode) {
    buildDistantSystemStars();
    buildStellarTargets();
  }
  if (typeof updateStarmapSelectionUI === 'function') updateStarmapSelectionUI();
}

function getSelectedWarpTarget() {
  if (selectedWarpTarget?.systemCoord) return selectedWarpTarget;
  return getDefaultWarpTarget(selectedSystemCoord);
}

function getWarpArrivalDistance(target) {
  const object = getObjectById(target.systemCoord, target.objectId || 'primary');
  if (!object) return 1500;
  if (object.kind === 'blackhole') return object.radius + 5200;
  if (object.kind === 'star') return object.radius + 2600;
  return object.radius + 1400;
}

function getWarpStopThreshold(target) {
  const object = getObjectById(target.systemCoord, target.objectId || 'primary');
  if (!object) return WARP_STOP_THRESHOLD;
  if (object.kind === 'blackhole') return 1200;
  if (object.kind === 'star') return 950;
  return Math.max(650, Math.min(1100, object.radius * 0.7));
}

function getWarpObjectWorldPosition(target) {
  const normalized = normalizeWarpTarget(target);
  if (!normalized) return null;

  const systemPos = getSystemWorldPosition(normalized.systemCoord);
  const object = getObjectById(normalized.systemCoord, normalized.objectId || 'primary');
  const localPos = getObjectLocalPosition(normalized.systemCoord, object);
  return systemPos.clone().add(localPos);
}

function getWarpTargetWorldPosition(target, safe = true) {
  const normalized = normalizeWarpTarget(target);
  if (!normalized) return null;

  const base = getWarpObjectWorldPosition(normalized);
  if (!safe) return base;

  const standoff = getWarpArrivalDistance(normalized);
  let dir = base.clone().sub(ship.pos);
  if (dir.lengthSq() < 1) dir = new THREE.Vector3(0, 0, 1);
  dir.normalize();
  return base.clone().add(dir.multiplyScalar(-standoff));
}

function getSectorData(sectorCoord) {
  const keyName = coordKey(sectorCoord);
  if (sectorCache.has(keyName)) return sectorCache.get(keyName);

  const sectorAbsPos = getAbsoluteWorldPositionForSector(sectorCoord);
  const nearestSystem = getNearestSystemEntry(sectorAbsPos);
  const systemCoord = nearestSystem ? cloneCoord(nearestSystem.coord) : cloneCoord(currentSystemCoord || HOME_SYSTEM_COORD);
  const system = getSystemData(systemCoord);
  const systemAbsPos = getSystemAbsoluteWorldPosition(systemCoord);
  const localVec = sectorAbsPos.clone().sub(systemAbsPos).divideScalar(SECTOR_SIZE);
  const local = makeCoord(localVec.x, localVec.y, localVec.z);
  const dx = localVec.x;
  const dy = localVec.y;
  const dz = localVec.z;
  const rng = makeRng(`sector:${keyName}`);
  const warpedRadius = Math.hypot(dx + randRange(rng, -0.45, 0.45), dz + randRange(rng, -0.45, 0.45));
  const verticalDistance = Math.abs(dy + randRange(rng, -0.3, 0.3));
  const starSectorCoord = getSystemCenterSector(systemCoord);

  let type = 'void';
  let band = null;

  if (coordsEqual(sectorCoord, starSectorCoord)) {
    type = system.special === 'blackhole' ? 'blackhole' : 'star';
  } else {
    band = system.asteroidBands.find(entry =>
      Math.abs(warpedRadius - entry.radius) <= entry.thickness &&
      verticalDistance <= entry.vertical + 1
    ) || null;

    if (band) type = 'asteroid';
  }

  const data = { coord: cloneCoord(sectorCoord), systemCoord, localCoord: local, type, band };
  sectorCache.set(keyName, data);
  return data;
}

function getNearbySystems(radius = STARMAP_SYSTEM_RADIUS) {
  ensureUniverseState();
  const currentAbsPos = getSystemAbsoluteWorldPosition(currentSystemCoord);
  return getGalaxySystems()
    .map(entry => ({
      coord: cloneCoord(entry.coord),
      data: getSystemData(entry.coord),
      dist: coordsEqual(entry.coord, currentSystemCoord) ? 0 : getSystemAbsoluteWorldPosition(entry.coord).distanceTo(currentAbsPos),
    }))
    .filter(entry => entry.dist <= Math.max(GALAXY_WORLD_SCALE * 3.2, radius * GALAXY_WORLD_SCALE * 8) || coordsEqual(entry.coord, currentSystemCoord))
    .sort((a, b) => a.dist - b.dist || a.data.name.localeCompare(b.data.name))
    .slice(0, 18);
}

function selectSystemCoord(coord) {
  if (!coord) return;
  selectedSystemCoord = cloneCoord(coord);
  setSelectedWarpTarget(getDefaultWarpTarget(coord));
}

function getSelectedSystemData() {
  return selectedSystemCoord ? getSystemData(selectedSystemCoord) : null;
}

function pointShipToTarget(target = getSelectedWarpTarget(), silent = false) {
  if (!launchMode || !shipGroup || !target?.systemCoord) return;
  shipAlignTarget = normalizeWarpTarget(target);
  if (!silent) showAlert(`GYRO ALIGN -> ${getTargetLabel(target)}`);
}

function pointShipToSystem(targetCoord = selectedSystemCoord, silent = false) {
  pointShipToTarget(getDefaultWarpTarget(targetCoord), silent);
}

function clearLocalStar() {
  if (!localStar) return;
  scene.remove(localStar);
  localStar.traverse?.(child => {
    child.geometry?.dispose?.();
    child.material?.dispose?.();
  });
  localStar = null;
}

function clearDistantSystemStars() {
  if (!distantSystemStars) return;
  scene.remove(distantSystemStars);
  distantSystemStars.traverse?.(child => {
    child.geometry?.dispose?.();
    child.material?.dispose?.();
  });
  distantSystemStars = null;
}

function clearLocalPlanets() {
  localPlanets.forEach(body => {
    scene.remove(body);
    body.traverse?.(child => {
      child.geometry?.dispose?.();
      child.material?.dispose?.();
    });
  });
  localPlanets = [];
}

function clearStellarTargets() {
  stellarTargets.forEach(target => {
    scene.remove(target.mesh);
    target.mesh.traverse?.(child => {
      child.geometry?.dispose?.();
      child.material?.dispose?.();
    });
  });
  stellarTargets = [];
}

function shouldSuppressAsteroids() {
  return hyperdriveState === 'active' || hyperdriveGraceTimer > 0;
}

function removeAsteroids() {
  asteroids.forEach(asteroid => {
    scene.remove(asteroid.mesh);
    asteroid.mesh.geometry?.dispose?.();
    asteroid.mesh.material?.dispose?.();
  });
  asteroids = [];
}

function clearSectorStream() {
  streamedSectors.forEach(record => {
    if (record.group) {
      scene.remove(record.group);
      record.group.traverse?.(child => {
        child.geometry?.dispose?.();
        child.material?.dispose?.();
      });
    }
  });
  streamedSectors.clear();
  removeAsteroids();
}

function clearWorld() {
  clearSectorStream();
  clearDistantSystemStars();
  clearLocalStar();
  clearLocalPlanets();
  clearStellarTargets();

  projectiles.forEach(projectile => {
    scene.remove(projectile.mesh);
    projectile.mesh.geometry?.dispose?.();
    projectile.mesh.material?.dispose?.();
  });
  projectiles = [];
}

function buildStarfieldLayer(count, radius, size, opacity) {
  const geo = new THREE.BufferGeometry();
  const positions = new Float32Array(count * 3);
  const colors = new Float32Array(count * 3);

  for (let i = 0; i < count; i++) {
    const theta = Math.random() * Math.PI * 2;
    const phi = Math.acos(2 * Math.random() - 1);
    const r = radius * (0.45 + Math.random() * 0.55);
    const brightness = 0.65 + Math.random() * 0.35;
    positions[i * 3] = Math.sin(phi) * Math.cos(theta) * r;
    positions[i * 3 + 1] = Math.sin(phi) * Math.sin(theta) * r * 0.82;
    positions[i * 3 + 2] = Math.cos(phi) * r;
    colors[i * 3] = brightness;
    colors[i * 3 + 1] = brightness * (0.96 + Math.random() * 0.04);
    colors[i * 3 + 2] = brightness * (0.92 + Math.random() * 0.08);
  }

  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
  return new THREE.Points(geo, new THREE.PointsMaterial({
    size,
    transparent: true,
    opacity,
    vertexColors: true,
    sizeAttenuation: true,
    depthWrite: false,
    fog: false,
  }));
}

function refreshStarfield() {
  if (starfield) {
    scene.remove(starfield);
    starfield.traverse?.(child => {
      child.geometry?.dispose?.();
      child.material?.dispose?.();
    });
    starfield = null;
  }

  starfield = new THREE.Group();
  starfield.add(buildStarfieldLayer(3200, 76000, 1.25, 0.82));
  starfield.add(buildStarfieldLayer(2100, 112000, 1.7, 0.35));
  starfield.add(buildStarfieldLayer(1400, 148000, 2.2, 0.16));
  scene.add(starfield);

  refreshUniverseScene(true);
}

function buildDistantSystemStars() {
  clearDistantSystemStars();

  const visibleSystems = getGalaxySystems()
    .filter(entry => !coordsEqual(entry.coord, currentSystemCoord))
    .map(entry => ({
      entry,
      system: getSystemData(entry.coord),
      pos: getWarpObjectWorldPosition(getDefaultWarpTarget(entry.coord)),
    }))
    .filter(record => !!record.pos && record.pos.distanceTo(ship.pos) <= STAR_RENDER_DISTANCE);

  if (!visibleSystems.length) return;

  const corePositions = new Float32Array(visibleSystems.length * 3);
  const glowPositions = new Float32Array(visibleSystems.length * 3);
  const colors = new Float32Array(visibleSystems.length * 3);

  visibleSystems.forEach((record, index) => {
    corePositions[index * 3] = record.pos.x;
    corePositions[index * 3 + 1] = record.pos.y;
    corePositions[index * 3 + 2] = record.pos.z;
    glowPositions[index * 3] = record.pos.x;
    glowPositions[index * 3 + 1] = record.pos.y;
    glowPositions[index * 3 + 2] = record.pos.z;

    const color = new THREE.Color(record.entry.special === 'blackhole' ? 0x8e74ff : record.system.star.color);
    colors[index * 3] = color.r;
    colors[index * 3 + 1] = color.g;
    colors[index * 3 + 2] = color.b;
  });

  const coreGeo = new THREE.BufferGeometry();
  coreGeo.setAttribute('position', new THREE.BufferAttribute(corePositions, 3));
  coreGeo.setAttribute('color', new THREE.BufferAttribute(colors, 3));

  const glowGeo = new THREE.BufferGeometry();
  glowGeo.setAttribute('position', new THREE.BufferAttribute(glowPositions, 3));
  glowGeo.setAttribute('color', new THREE.BufferAttribute(colors, 3));

  const corePoints = new THREE.Points(coreGeo, new THREE.PointsMaterial({
    size: 11,
    transparent: true,
    opacity: 0.96,
    vertexColors: true,
    sizeAttenuation: false,
    depthWrite: false,
    depthTest: false,
    fog: false,
  }));
  corePoints.frustumCulled = false;

  const glowPoints = new THREE.Points(glowGeo, new THREE.PointsMaterial({
    size: 28,
    transparent: true,
    opacity: 0.24,
    vertexColors: true,
    sizeAttenuation: false,
    depthWrite: false,
    depthTest: false,
    fog: false,
    blending: THREE.AdditiveBlending,
  }));
  glowPoints.frustumCulled = false;

  distantSystemStars = new THREE.Group();
  distantSystemStars.add(glowPoints);
  distantSystemStars.add(corePoints);
  scene.add(distantSystemStars);
}

function updateSceneLighting(system) {
  renderer.setClearColor(system.backgroundColor);
  scene.fog = null;

  ambient.color.setHex(system.special === 'blackhole' ? 0x141422 : 0x213040);
  ambient.intensity = system.special === 'blackhole' ? 0.38 : 0.55;

  sun.color.setHex(system.star.color);
  sun.intensity = system.special === 'blackhole' ? 0.65 : 1.35;
  sun.position.set(18, 14, -20);

  fill.color.setHex(system.accentColor);
  fill.intensity = system.special === 'blackhole' ? 0.5 : 0.42;
  fill.position.set(-10, 6, -6);

  rim.color.setHex(system.star.emissive);
  rim.intensity = system.special === 'blackhole' ? 1.6 : 1.15;
  rim.distance = 140;
}

function buildLocalSystemBodies() {
  clearLocalStar();
  clearLocalPlanets();

  const system = getCurrentSystemData();
  const starGroup = new THREE.Group();
  const starPos = getSystemWorldPosition(currentSystemCoord);
  const primary = getObjectById(currentSystemCoord, 'primary');
  const starColor = system.special === 'blackhole' ? 0x06080e : system.star.color;

  const core = new THREE.Mesh(
    new THREE.SphereGeometry(system.star.size, 30, 30),
    new THREE.MeshBasicMaterial({ color: starColor, fog: false })
  );
  starGroup.add(core);

  const shell = new THREE.Mesh(
    new THREE.SphereGeometry(system.star.size * (system.special === 'blackhole' ? 1.5 : 1.25), 22, 22),
    new THREE.MeshBasicMaterial({
      color: system.star.emissive,
      transparent: true,
      opacity: system.special === 'blackhole' ? 0.22 : 0.16,
      fog: false,
    })
  );
  starGroup.add(shell);

  starGroup.position.copy(starPos);
  scene.add(starGroup);
  localStar = starGroup;

  getSystemObjects(currentSystemCoord).forEach(object => {
    if (object.id === 'primary') return;
    const pos = starPos.clone().add(getObjectLocalPosition(currentSystemCoord, object));
    const body = new THREE.Mesh(
      new THREE.SphereGeometry(object.radius, 22, 22),
      new THREE.MeshStandardMaterial({
        color: object.color,
        emissive: object.emissive,
        emissiveIntensity: 0.3,
        roughness: 0.95,
        metalness: 0.05,
        fog: false,
      })
    );
    body.position.copy(pos);
    scene.add(body);
    localPlanets.push(body);
  });
}

function createTargetStar(system, worldPos, target) {
  const group = new THREE.Group();
  const object = getObjectById(target.systemCoord, target.objectId || 'primary');
  const isSelected = selectedWarpTarget && coordsEqual(target.systemCoord, selectedWarpTarget.systemCoord) && (target.objectId || 'primary') === (selectedWarpTarget.objectId || 'primary');
  const baseRadius = object.kind === 'blackhole' ? 130 : object.kind === 'planet' ? 90 : 115;
  const glowRadius = object.kind === 'blackhole' ? 220 : object.kind === 'planet' ? 150 : 185;
  const color = object.kind === 'planet' ? object.color : system.star.color;
  const emissive = object.kind === 'planet' ? object.emissive : system.star.emissive;

  const core = new THREE.Mesh(
    new THREE.SphereGeometry(baseRadius, 18, 18),
    new THREE.MeshBasicMaterial({ color, fog: false })
  );
  group.add(core);

  const glow = new THREE.Mesh(
    new THREE.SphereGeometry(glowRadius, 14, 14),
    new THREE.MeshBasicMaterial({
      color: emissive,
      transparent: true,
      opacity: isSelected ? 0.24 : 0.14,
      fog: false,
    })
  );
  group.add(glow);

  group.position.copy(worldPos);
  group.userData.baseScale = isSelected ? 1.3 : 1;
  group.userData.target = normalizeWarpTarget(target);
  scene.add(group);
  return group;
}

function buildStellarTargets() {
  clearStellarTargets();
  const systems = getGalaxySystems()
    .map(entry => ({
      coord: cloneCoord(entry.coord),
      data: getSystemData(entry.coord),
      dist: getWarpObjectWorldPosition(getDefaultWarpTarget(entry.coord)).distanceTo(ship.pos),
    }))
    .filter(entry => !coordsEqual(entry.coord, currentSystemCoord))
    .filter(entry => coordsEqual(entry.coord, selectedSystemCoord) || entry.dist <= GALAXY_WORLD_SCALE * 14)
    .sort((a, b) => a.dist - b.dist);

  systems.forEach(entry => {
    const starTarget = getDefaultWarpTarget(entry.coord);
    const starWorldPos = getWarpTargetWorldPosition(starTarget, false);
    if (starWorldPos.distanceTo(ship.pos) <= STAR_RENDER_DISTANCE) {
      stellarTargets.push({ target: starTarget, mesh: createTargetStar(entry.data, starWorldPos, starTarget) });
    }

    if (entry.dist > SYSTEM_OBJECT_RENDER_DISTANCE) return;

    const firstPlanet = getSystemObjects(entry.coord).find(object => object.kind === 'planet');
    if (firstPlanet) {
      const planetTarget = { kind: 'object', systemCoord: cloneCoord(entry.coord), objectId: firstPlanet.id };
      const planetPos = getWarpTargetWorldPosition(planetTarget, false);
      if (planetPos.distanceTo(ship.pos) <= SYSTEM_OBJECT_RENDER_DISTANCE) {
        stellarTargets.push({ target: planetTarget, mesh: createTargetStar(entry.data, planetPos, planetTarget) });
      }
    }
  });
}

function createAsteroidMesh(radius, color) {
  const variants = [
    new THREE.IcosahedronGeometry(radius, 1),
    new THREE.DodecahedronGeometry(radius, 1),
    new THREE.OctahedronGeometry(radius, 2),
  ];
  const geo = variants[Math.floor(Math.random() * variants.length)].toNonIndexed();
  const position = geo.attributes.position;

  for (let i = 0; i < position.count; i++) {
    const vertex = new THREE.Vector3().fromBufferAttribute(position, i);
    const noise = 0.68 + Math.random() * 0.62;
    vertex.normalize().multiplyScalar(radius * noise);
    vertex.x *= 0.82 + Math.random() * 0.42;
    vertex.y *= 0.82 + Math.random() * 0.42;
    vertex.z *= 0.82 + Math.random() * 0.42;
    position.setXYZ(i, vertex.x, vertex.y, vertex.z);
  }

  position.needsUpdate = true;
  geo.computeVertexNormals();
  return new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    color,
    roughness: 1,
    metalness: 0.04,
    flatShading: true,
  }));
}

function spawnAsteroidsForSector(sectorData) {
  if (shouldSuppressAsteroids()) return;

  const rng = makeRng(`asteroids:${coordKey(sectorData.coord)}`);
  const basePos = getSectorWorldPosition(sectorData.coord);
  const count = randInt(rng, 1, sectorData.systemCoord.x === 0 && sectorData.systemCoord.z === 0 ? 4 : 3);
  const colors = [0x4a4035, 0x5a4d40, 0x6a5b4c, 0x3b342d, 0x57463c];

  for (let i = 0; i < count; i++) {
    const radius = randRange(rng, 3.2, 8.5);
    const mesh = createAsteroidMesh(radius, colors[i % colors.length]);
    const localOffset = new THREE.Vector3(
      randRange(rng, -ASTEROID_SECTOR_RADIUS, ASTEROID_SECTOR_RADIUS),
      randRange(rng, -420, 420),
      randRange(rng, -ASTEROID_SECTOR_RADIUS, ASTEROID_SECTOR_RADIUS)
    );

    if (localOffset.length() < ASTEROID_SAFE_DISTANCE) {
      localOffset.setLength(ASTEROID_SAFE_DISTANCE + randRange(rng, 350, 950));
    }

    mesh.position.copy(basePos).add(localOffset);
    mesh.rotation.set(randRange(rng, 0, Math.PI), randRange(rng, 0, Math.PI), randRange(rng, 0, Math.PI));

    const speed = randRange(rng, 0.008, 0.026);
    const vel = new THREE.Vector3(
      randRange(rng, -speed, speed),
      randRange(rng, -speed * 0.14, speed * 0.14),
      randRange(rng, -speed, speed)
    );
    const av = new THREE.Vector3(randRange(rng, -0.004, 0.004), randRange(rng, -0.004, 0.004), randRange(rng, -0.004, 0.004));
    const hp = Math.round(radius * 48);

    scene.add(mesh);
    asteroids.push({
      mesh,
      vel,
      av,
      radius,
      color: colors[i % colors.length],
      hp,
      maxHp: hp,
      impactCooldown: 0,
      sectorKey: coordKey(sectorData.coord),
    });
  }
}

function streamSectorWindow(force = false) {
  ensureUniverseState();
  const desiredKeys = new Set();
  const suppressAsteroids = shouldSuppressAsteroids();

  if (force || suppressAsteroids) removeAsteroids();

  for (let x = -SECTOR_STREAM_RADIUS; x <= SECTOR_STREAM_RADIUS; x++) {
    for (let y = -SECTOR_STREAM_RADIUS; y <= SECTOR_STREAM_RADIUS; y++) {
      for (let z = -SECTOR_STREAM_RADIUS; z <= SECTOR_STREAM_RADIUS; z++) {
        const sectorCoord = addCoord(currentSectorCoord, makeCoord(x, y, z));
        const sectorData = getSectorData(sectorCoord);
        const keyName = coordKey(sectorCoord);
        desiredKeys.add(keyName);

        const existing = streamedSectors.get(keyName);
        const needsRefresh = force || !existing || existing.suppressed !== suppressAsteroids;

        if (needsRefresh) {
          streamedSectors.set(keyName, {
            coord: cloneCoord(sectorCoord),
            type: sectorData.type,
            suppressed: suppressAsteroids,
            group: null,
          });

          if (sectorData.type === 'asteroid' && !suppressAsteroids) {
            spawnAsteroidsForSector(sectorData);
          }
        }
      }
    }
  }

  streamedSectors.forEach((record, keyName) => {
    if (!desiredKeys.has(keyName)) streamedSectors.delete(keyName);
  });

  asteroids = asteroids.filter(asteroid => {
    if (!desiredKeys.has(asteroid.sectorKey) || suppressAsteroids) {
      scene.remove(asteroid.mesh);
      asteroid.mesh.geometry?.dispose?.();
      asteroid.mesh.material?.dispose?.();
      return false;
    }
    return true;
  });
}

function refreshUniverseScene(force = false) {
  ensureUniverseState();
  const system = getCurrentSystemData();

  updateSceneLighting(system);
  buildDistantSystemStars();
  buildLocalSystemBodies();
  buildStellarTargets();
  streamSectorWindow(force);

  if (typeof updateStarmapSelectionUI === 'function') updateStarmapSelectionUI();
}

function chooseDefaultTargetSystem() {
  const nearby = getNearbySystems(1).filter(entry => !coordsEqual(entry.coord, currentSystemCoord));
  if (nearby[0]) setSelectedWarpTarget(getDefaultWarpTarget(nearby[0].coord));
}

function handleSystemChange(previousSystemCoord) {
  const system = getCurrentSystemData();
  refreshUniverseScene(true);

  if (selectedWarpTarget?.systemCoord && coordsEqual(selectedWarpTarget.systemCoord, currentSystemCoord) && !coordsEqual(previousSystemCoord, currentSystemCoord)) {
    showAlert(`ENTERED ${system.name}`);
  } else if (!coordsEqual(previousSystemCoord, currentSystemCoord)) {
    showAlert(`ENTERED ${system.name}`);
  }
}

function shiftProjectiles(deltaVec) {
  projectiles.forEach(projectile => projectile.mesh.position.sub(deltaVec));
}

function updateFloatingOrigin() {
  const shift = makeCoord(0, 0, 0);
  const halfSector = SECTOR_SIZE * 0.5;

  while (ship.pos.x > halfSector) { ship.pos.x -= SECTOR_SIZE; shift.x++; }
  while (ship.pos.x < -halfSector) { ship.pos.x += SECTOR_SIZE; shift.x--; }
  while (ship.pos.y > halfSector) { ship.pos.y -= SECTOR_SIZE; shift.y++; }
  while (ship.pos.y < -halfSector) { ship.pos.y += SECTOR_SIZE; shift.y--; }
  while (ship.pos.z > halfSector) { ship.pos.z -= SECTOR_SIZE; shift.z++; }
  while (ship.pos.z < -halfSector) { ship.pos.z += SECTOR_SIZE; shift.z--; }

  if (shift.x === 0 && shift.y === 0 && shift.z === 0) return;

  currentSectorCoord = addCoord(currentSectorCoord, shift);
  const nearestSystem = getNearestSystemEntry(getPlayerAbsoluteWorldPosition());
  currentSystemCoord = nearestSystem ? cloneCoord(nearestSystem.coord) : cloneCoord(HOME_SYSTEM_COORD);

  const deltaVec = new THREE.Vector3(shift.x * SECTOR_SIZE, shift.y * SECTOR_SIZE, shift.z * SECTOR_SIZE);
  shiftProjectiles(deltaVec);
  camera.position.sub(deltaVec);
  if (starfield) starfield.position.sub(deltaVec);
  refreshUniverseScene(true);
}

function updateSpaceAnchors() {
  if (starfield) starfield.position.copy(ship.pos);

  if (localStar) {
    localStar.children.forEach((child, index) => {
      child.rotation.y += 0.0004 * (index + 1);
    });
  }

  stellarTargets.forEach(target => {
    const dist = target.mesh.position.distanceTo(ship.pos);
    const isPlanet = target.target?.objectId && target.target.objectId !== 'primary';
    const distanceFactor = THREE.MathUtils.clamp(dist / (isPlanet ? 120000 : 900000), 0, 1);
    const scale = (1 + distanceFactor * (isPlanet ? 0.18 : 0.08)) * (target.mesh.userData.baseScale || 1);
    target.mesh.scale.setScalar(scale);
    target.mesh.rotation.y += 0.0006;
  });
}

function snapshotBuild() {
  return [...voxels.entries()].map(([keyName, voxel]) => ({
    key: keyName,
    x: voxel.x,
    y: voxel.y,
    z: voxel.z,
    type: voxel.type,
    color: voxel.color,
    rotation: voxel.rotation ? { ...voxel.rotation } : { x: 0, y: 0, z: 0 },
  }));
}
