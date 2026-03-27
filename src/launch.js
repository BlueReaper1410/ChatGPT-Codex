function rebuildShipStats() {
  let mass = 0;
  let engineCount = 0;
  let thrusterCount = 0;
  let wingCount = 0;
  let weaponCount = 0;
  let shieldCount = 0;

  flightBlocks.forEach(v => {
    mass += v.type.id === 'hull' ? 1.25 : 1;
    if (v.type.id === 'engine') engineCount++;
    if (v.type.id === 'thruster') thrusterCount++;
    if (v.type.id === 'wing') wingCount++;
    if (v.type.id === 'weapon') weaponCount++;
    if (v.type.id === 'shield') shieldCount++;
  });

  const massFactor = Math.max(0.8, mass / 12);
  shipStats = {
    mass,
    enginePower: (0.55 + engineCount * 1.05 + thrusterCount * 0.12) / massFactor,
    rcsPower: (0.35 + thrusterCount * 0.9 + wingCount * 0.08) / massFactor,
    brakeDrag: THREE.MathUtils.clamp(0.83 + thrusterCount * 0.022, 0.83, 0.95),
    weaponCount,
    shieldCount,
  };
}

function engageHyperdrive() {
  if (!launchMode) return;
  if (hyperdriveState === 'spool' || hyperdriveState === 'active') return;

  const target = getSelectedWarpTarget();
  if (!target?.systemCoord) {
    showAlert('SELECT A TARGET');
    return;
  }

  hyperdriveState = 'spool';
  hyperdriveTimer = HYPERDRIVE_SPOOL_TIME;
  hyperdriveGraceTimer = 0;
  hyperdriveCharge = 0;
  shipAlignTarget = normalizeWarpTarget(target);

  streamSectorWindow(true);
  closeStarmap();
  showAlert(`HYPERDRIVE SPOOLING -> ${getTargetLabel(target)}`);
  updateHUD();
}

function disengageHyperdrive(message = 'HYPERDRIVE OFF') {
  if (!launchMode) return;
  if (hyperdriveState === 'spooldown') return;

  if (hyperdriveState === 'off') {
    hyperdriveGraceTimer = HYPERDRIVE_ASTEROID_GRACE;
    streamSectorWindow(true);
    if (message) showAlert(message);
    updateHUD();
    return;
  }

  hyperdriveState = 'spooldown';
  hyperdriveTimer = HYPERDRIVE_SPOOLDOWN_TIME;
  hyperdriveGraceTimer = HYPERDRIVE_ASTEROID_GRACE;
  hyperdriveCharge = 0;
  shipAlignTarget = null;
  if (message) showAlert(message);
  updateHUD();
}

function attemptHyperdrive() {
  if (!launchMode) return;

  if (hyperdriveState === 'off' || hyperdriveState === 'spooldown') engageHyperdrive();
  else if (hyperdriveState === 'spool' || hyperdriveState === 'active') disengageHyperdrive('HYPERDRIVE DISENGAGING');
  else {
    hyperdriveState = 'off';
    hyperdriveTimer = 0;
    hyperdriveGraceTimer = HYPERDRIVE_ASTEROID_GRACE;
    streamSectorWindow(true);
    showAlert('HYPERDRIVE ABORTED');
    updateHUD();
  }
}

function enterLaunchMode() {
  if (voxels.size === 0) { alert('BUILD SOMETHING FIRST'); return; }
  if (launchMode) return;

  ensureUniverseState();
  launchSnapshot = snapshotBuild();
  flightBlocks.clear();

  let cx = 0;
  let cy = 0;
  let cz = 0;
  launchSnapshot.forEach(v => {
    cx += v.x;
    cy += v.y + 0.5;
    cz += v.z;
  });
  cx /= launchSnapshot.length;
  cy /= launchSnapshot.length;
  cz /= launchSnapshot.length;

  shipGroup = new THREE.Group();
  ship.pos.set(cx, Math.max(cy, 5), cz);
  ship.vel.set(0, 0, 0);
  ship.quat.identity();
  shipGroup.position.copy(ship.pos);
  scene.add(shipGroup);

  totalHullMax = 0;
  totalShieldMax = 0;
  blockHealth.clear();
  voxels.forEach(v => { v.mesh.visible = false; });

  launchSnapshot.forEach(v => {
    const mesh = createVoxelMesh(v.type, v.color);
    mesh.position.set(v.x - cx, v.y + 0.5 - cy, v.z - cz);
    mesh.rotation.set(v.rotation?.x ?? 0, v.rotation?.y ?? 0, v.rotation?.z ?? 0);
    shipGroup.add(mesh);
    flightBlocks.set(v.key, { ...v, mesh });
    const maxHp = BLOCK_HP[v.type.id] || 80;
    blockHealth.set(v.key, { hp: maxHp, maxHp });
    if (v.type.id === 'shield') totalShieldMax += maxHp;
    else totalHullMax += maxHp;
  });

  if (totalHullMax === 0) totalHullMax = 1;
  rebuildShipStats();

  clearWorld();
  gridHelper.visible = false;
  refreshStarfield();
  ghostMesh.visible = false;
  mouseDown = false;
  mouseOrbit = false;
  orb.active = false;

  const launchOffset = new THREE.Vector3(0, FLIGHT_CAM_HEIGHT, FLIGHT_CAM_DISTANCE).applyQuaternion(ship.quat);
  camera.position.copy(ship.pos).add(launchOffset);
  camera.up.copy(new THREE.Vector3(0, 1, 0).applyQuaternion(ship.quat));
  camera.lookAt(ship.pos.clone().add(new THREE.Vector3(0, 0, -1).applyQuaternion(ship.quat).multiplyScalar(FLIGHT_CAM_LOOK_AHEAD)));

  document.body.classList.add('in-flight');
  document.getElementById('btn-launch').textContent = 'EXIT';
  document.getElementById('btn-launch').classList.add('active-launch');
  launchMode = true;
  weaponCooldown = 0;
  hyperdriveState = 'off';
  hyperdriveTimer = 0;
  hyperdriveGraceTimer = 0;
  hyperdriveCharge = 0;
  shipAlignTarget = null;
  setSelectedWarpTarget(getDefaultWarpTarget(selectedSystemCoord));
  scene.fog = null;
  updateHUD();
  requestFlightPointerLock();
}

function exitLaunchMode() {
  if (!launchMode && !shipGroup) return;

  launchMode = false;
  document.body.classList.remove('in-flight');
  document.getElementById('btn-launch').textContent = 'LAUNCH';
  document.getElementById('btn-launch').classList.remove('active-launch');

  voxels.forEach(v => {
    v.mesh.visible = true;
    v.mesh.position.set(v.x, v.y + 0.5, v.z);
    v.mesh.quaternion.identity();
    v.mesh.rotation.set(v.rotation?.x ?? 0, v.rotation?.y ?? 0, v.rotation?.z ?? 0);
  });

  if (shipGroup) {
    scene.remove(shipGroup);
    shipGroup = null;
  }

  if (starmapOpen) closeStarmap();
  flightBlocks.clear();
  launchSnapshot = null;
  blockHealth.clear();
  clearWorld();
  renderer.setClearColor(0x080a0c);
  scene.fog = defaultFog;
  gridHelper.visible = showGrid;
  resetCamera();
  if (pointerLocked) document.exitPointerLock();
  document.getElementById('hud-alert').classList.remove('show');
  mouseFDx = 0;
  mouseFDy = 0;
  mouseDown = false;
  mouseOrbit = false;
  orb.active = false;
  hyperdriveState = 'off';
  hyperdriveTimer = 0;
  hyperdriveGraceTimer = 0;
  hyperdriveCharge = 0;
  shipAlignTarget = null;
  flightKeys = {};
  updateHUD();
}

function toggleLaunchMode() {
  launchMode ? exitLaunchMode() : enterLaunchMode();
}
