const starmapOverlay = document.getElementById('starmap-overlay');
const starmapCanvas = document.getElementById('starmap-canvas');
const starmapCtx = starmapCanvas.getContext('2d');
const starmapCamera = new THREE.PerspectiveCamera(40, starmapCanvas.width / starmapCanvas.height, 0.1, 1000);
const starmapView = { yaw: 0.7, pitch: 0.38, distance: 18 };
let starmapHits = [];
let starmapDrag = null;

function updateStarmapSelectionUI() {
  const titleEl = document.querySelector('.starmap-title');
  const subEl = document.querySelector('.starmap-sub');
  const nameEl = document.getElementById('starmap-target-name');
  const noteEl = document.getElementById('starmap-target-note');
  const mapBtn = document.getElementById('btn-map');
  const modeBtn = document.getElementById('starmap-mode-btn');

  if (mapBtn) mapBtn.classList.toggle('active-launch', starmapOpen);
  if (modeBtn) modeBtn.textContent = starmapMode === 'galaxy' ? 'SYSTEM VIEW' : 'GALAXY VIEW';
  if (titleEl) titleEl.textContent = starmapMode === 'galaxy' ? 'GALAXY MAP' : 'SYSTEM MAP';
  if (subEl) subEl.textContent = starmapMode === 'galaxy' ? 'CLICK A STAR SYSTEM TO TARGET IT' : 'CLICK A STAR, PLANET, OR BLACK HOLE TARGET';

  const target = getSelectedWarpTarget();
  if (!target?.systemCoord) {
    nameEl.textContent = 'NONE';
    noteEl.textContent = 'Select a system in galaxy view, then inspect its bodies in system view.';
    return;
  }

  nameEl.textContent = getTargetLabel(target);
  const currentPos = getSystemAbsoluteWorldPosition(currentSystemCoord);
  const targetPos = getSystemAbsoluteWorldPosition(target.systemCoord);
  const distanceSectors = Math.round(currentPos.distanceTo(targetPos) / SECTOR_SIZE);
  noteEl.textContent = starmapMode === 'galaxy'
    ? `Galaxy view: choose a system. Current target is about ${distanceSectors} sectors away.`
    : `System view: choose the exact object you want to warp toward. Warp points stay outside stars and the core black hole.`;
}

function openStarmap() {
  ensureUniverseState();
  if (pointerLocked) document.exitPointerLock();
  if (starmapMode === 'galaxy') {
    starmapView.distance = THREE.MathUtils.clamp(32, STARMAP_MIN_DISTANCE, STARMAP_MAX_DISTANCE);
    starmapView.pitch = 0.38;
  } else {
    starmapView.distance = THREE.MathUtils.clamp(12, STARMAP_MIN_DISTANCE, STARMAP_MAX_DISTANCE);
    starmapView.pitch = 0.42;
  }
  starmapOpen = true;
  starmapOverlay.classList.add('open');
  updateStarmapSelectionUI();
  drawStarmap();
}

function closeStarmap() {
  starmapOpen = false;
  starmapOverlay.classList.remove('open');
  updateStarmapSelectionUI();
}

function toggleStarmap() {
  starmapOpen ? closeStarmap() : openStarmap();
}

function toggleStarmapMode() {
  if (starmapMode === 'galaxy') {
    starmapMode = 'system';
    starmapView.distance = THREE.MathUtils.clamp(12, STARMAP_MIN_DISTANCE, STARMAP_MAX_DISTANCE);
    starmapView.pitch = 0.42;
  } else {
    starmapMode = 'galaxy';
    starmapView.distance = THREE.MathUtils.clamp(32, STARMAP_MIN_DISTANCE, STARMAP_MAX_DISTANCE);
    starmapView.pitch = 0.38;
  }
  updateStarmapSelectionUI();
  drawStarmap();
}

function drawGrid() {
  starmapCtx.strokeStyle = 'rgba(255,255,255,0.06)';
  starmapCtx.lineWidth = 1;

  for (let i = 1; i < 5; i++) {
    const x = (starmapCanvas.width / 5) * i;
    const y = (starmapCanvas.height / 5) * i;
    starmapCtx.beginPath();
    starmapCtx.moveTo(x, 0);
    starmapCtx.lineTo(x, starmapCanvas.height);
    starmapCtx.stroke();
    starmapCtx.beginPath();
    starmapCtx.moveTo(0, y);
    starmapCtx.lineTo(starmapCanvas.width, y);
    starmapCtx.stroke();
  }
}

function configureStarmapCamera() {
  starmapCamera.position.set(
    Math.sin(starmapView.yaw) * Math.cos(starmapView.pitch) * starmapView.distance,
    Math.sin(starmapView.pitch) * starmapView.distance,
    Math.cos(starmapView.yaw) * Math.cos(starmapView.pitch) * starmapView.distance
  );
  starmapCamera.lookAt(0, 0, 0);
  starmapCamera.updateMatrixWorld();
}

function drawGalaxyMap(width, height) {
  const currentGalaxy = new THREE.Vector3(0, 0, 0);
  const systems = getGalaxySystems();
  starmapHits = [];

  systems.forEach(entry => {
    const point = entry.galaxyPos.clone().sub(currentGalaxy).multiplyScalar(0.068);
    const projected = point.project(starmapCamera);
    if (projected.z < -1.2 || projected.z > 1.2) return;

    const x = (projected.x * 0.5 + 0.5) * width;
    const y = (-projected.y * 0.5 + 0.5) * height;
    const isCurrent = coordsEqual(entry.coord, currentSystemCoord);
    const isSelected = coordsEqual(entry.coord, selectedSystemCoord);
    const radius = isCurrent ? 8 : isSelected ? 6.3 : entry.special === 'blackhole' ? 7.2 : 4.2;

    starmapHits.push({ kind: 'system', systemCoord: cloneCoord(entry.coord), x, y, radius });

    starmapCtx.beginPath();
    starmapCtx.arc(x, y, radius, 0, Math.PI * 2);
    starmapCtx.fillStyle = entry.special === 'blackhole'
      ? '#8e74ff'
      : isCurrent
        ? '#00ff88'
        : `#${getSystemData(entry.coord).star.color.toString(16).padStart(6, '0')}`;
    starmapCtx.fill();

    starmapCtx.beginPath();
    starmapCtx.arc(x, y, radius * 2.2, 0, Math.PI * 2);
    starmapCtx.strokeStyle = isSelected ? 'rgba(0,229,255,0.85)' : 'rgba(255,255,255,0.1)';
    starmapCtx.lineWidth = isSelected ? 1.4 : 0.6;
    starmapCtx.stroke();

    if (isCurrent || isSelected || entry.special === 'blackhole') {
      starmapCtx.fillStyle = isCurrent ? '#b7ffe0' : '#c8d0d8';
      starmapCtx.font = '11px IBM Plex Mono';
      starmapCtx.fillText(getSystemData(entry.coord).name, x + radius + 6, y - radius - 4);
    }
  });
}

function drawSystemMap(width, height) {
  const systemCoord = selectedSystemCoord || currentSystemCoord;
  const system = getSystemData(systemCoord);
  const objects = getSystemObjects(systemCoord);
  starmapHits = [];

  objects.forEach(object => {
    const point = getObjectLocalPosition(systemCoord, object).multiplyScalar(1 / 1600);
    const projected = point.project(starmapCamera);
    if (projected.z < -1.2 || projected.z > 1.2) return;

    const x = (projected.x * 0.5 + 0.5) * width;
    const y = (-projected.y * 0.5 + 0.5) * height;
    const isSelected = selectedWarpTarget && coordsEqual(systemCoord, selectedWarpTarget.systemCoord) && object.id === (selectedWarpTarget.objectId || 'primary');
    const radius = object.kind === 'blackhole' ? 11 : object.kind === 'star' ? 9 : THREE.MathUtils.clamp(object.radius / 90, 4, 8);
    const target = { kind: 'object', systemCoord: cloneCoord(systemCoord), objectId: object.id };

    starmapHits.push({ kind: 'object', target, x, y, radius: radius + 4 });

    starmapCtx.beginPath();
    starmapCtx.arc(x, y, radius, 0, Math.PI * 2);
    starmapCtx.fillStyle = object.kind === 'blackhole'
      ? '#13061e'
      : object.kind === 'star'
        ? `#${system.star.color.toString(16).padStart(6, '0')}`
        : `#${object.color.toString(16).padStart(6, '0')}`;
    starmapCtx.fill();

    starmapCtx.beginPath();
    starmapCtx.arc(x, y, radius * 1.9, 0, Math.PI * 2);
    starmapCtx.strokeStyle = isSelected ? 'rgba(0,229,255,0.85)' : 'rgba(255,255,255,0.12)';
    starmapCtx.lineWidth = isSelected ? 1.4 : 0.7;
    starmapCtx.stroke();

    starmapCtx.fillStyle = '#c8d0d8';
    starmapCtx.font = '11px IBM Plex Mono';
    starmapCtx.fillText(object.name, x + radius + 6, y - radius - 4);
  });
}

function drawStarmap() {
  if (!starmapOpen) return;

  const width = starmapCanvas.width;
  const height = starmapCanvas.height;
  starmapCtx.clearRect(0, 0, width, height);
  starmapCtx.fillStyle = 'rgba(6, 10, 18, 0.97)';
  starmapCtx.fillRect(0, 0, width, height);
  drawGrid();
  configureStarmapCamera();

  if (starmapMode === 'galaxy') drawGalaxyMap(width, height);
  else drawSystemMap(width, height);

  starmapCtx.fillStyle = 'rgba(200,208,216,0.58)';
  starmapCtx.font = '10px IBM Plex Mono';
  starmapCtx.fillText('Drag to rotate | Wheel to zoom | Click to select', 16, height - 18);

  requestAnimationFrame(drawStarmap);
}

function pointShipToSelectedSystem() {
  if (!launchMode) {
    showAlert('LAUNCH TO POINT SHIP');
    return;
  }
  const target = getSelectedWarpTarget();
  if (!target?.systemCoord) {
    showAlert('SELECT A TARGET');
    return;
  }
  pointShipToTarget(target);
  closeStarmap();
}

starmapOverlay.addEventListener('click', e => {
  if (e.target === starmapOverlay) closeStarmap();
});

starmapCanvas.addEventListener('mousedown', e => {
  starmapDrag = { x: e.clientX, y: e.clientY, moved: false };
});

starmapCanvas.addEventListener('mousemove', e => {
  if (!starmapDrag) return;
  const dx = e.clientX - starmapDrag.x;
  const dy = e.clientY - starmapDrag.y;
  starmapDrag.x = e.clientX;
  starmapDrag.y = e.clientY;
  if (Math.abs(dx) + Math.abs(dy) > 3) starmapDrag.moved = true;
  starmapView.yaw += dx * 0.004;
  starmapView.pitch = THREE.MathUtils.clamp(starmapView.pitch + dy * 0.0035, -1.05, 1.05);
});

document.addEventListener('mouseup', e => {
  if (!starmapDrag) return;
  if (!starmapDrag.moved) {
    const rect = starmapCanvas.getBoundingClientRect();
    if (e.clientX < rect.left || e.clientX > rect.right || e.clientY < rect.top || e.clientY > rect.bottom) {
      starmapDrag = null;
      return;
    }
    const x = (e.clientX - rect.left) * (starmapCanvas.width / rect.width);
    const y = (e.clientY - rect.top) * (starmapCanvas.height / rect.height);
    let best = null;
    let bestDist = Infinity;
    starmapHits.forEach(hit => {
      const dist = Math.hypot(hit.x - x, hit.y - y);
      if (dist < hit.radius + 8 && dist < bestDist) {
        best = hit;
        bestDist = dist;
      }
    });

    if (best?.kind === 'system') {
      selectedSystemCoord = cloneCoord(best.systemCoord);
      setSelectedWarpTarget(getDefaultWarpTarget(best.systemCoord));
      if (starmapMode !== 'system') {
        starmapMode = 'system';
        starmapView.distance = THREE.MathUtils.clamp(12, STARMAP_MIN_DISTANCE, STARMAP_MAX_DISTANCE);
        starmapView.pitch = 0.42;
      }
    } else if (best?.kind === 'object') {
      setSelectedWarpTarget(best.target);
    }
    updateStarmapSelectionUI();
  }
  starmapDrag = null;
});

starmapCanvas.addEventListener('wheel', e => {
  e.preventDefault();
  starmapView.distance = THREE.MathUtils.clamp(
    starmapView.distance + e.deltaY * 0.02,
    STARMAP_MIN_DISTANCE,
    STARMAP_MAX_DISTANCE
  );
}, { passive: false });
