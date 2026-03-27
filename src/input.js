let orb = { active:false, touch2:false, lastX:0, lastY:0, pinchDist:0,
            theta: Math.atan2(16, 10), phi: Math.atan2(12, Math.sqrt(200)), r: 22 };

function orbitApply() {
  const sinP = Math.sin(orb.phi), cosP = Math.cos(orb.phi);
  camera.position.set(
    orb.r * Math.sin(orb.theta) * cosP,
    orb.r * sinP,
    orb.r * Math.cos(orb.theta) * cosP
  );
  camera.lookAt(0, 0, 0);
}

function orbitDelta(dx, dy) {
  const sens = 0.007 * camSettings.sensitivity;
  const xDir = camSettings.invertX ? 1 : -1;
  const yDir = camSettings.invertY ? 1 : -1;
  orb.theta += dx * sens * xDir;
  // Full vertical: clamp just shy of straight up/down to avoid gimbal flip
  orb.phi = Math.max(-Math.PI / 2 + 0.01, Math.min(Math.PI / 2 - 0.01, orb.phi + dy * sens * yDir));
  orbitApply();
}

function resetCamera() {
  orb.theta = 0.7; orb.phi = 0.6; orb.r = 22;
  orbitApply();
}

// ─── MOUSE INTERACTION ───────────────────────────────────────────────────────
let mouse = new THREE.Vector2();
let lastMouseAction = 0;

function getNDC(clientX, clientY) {
  const rect = canvas.getBoundingClientRect();
  return new THREE.Vector2(
    ((clientX - rect.left) / rect.width) * 2 - 1,
    -((clientY - rect.top) / rect.height) * 2 + 1
  );
}

function getVoxelTarget(ndc) {
  raycaster.setFromCamera(ndc, camera);

  // Check existing voxels
  const meshes = [...voxels.values()].map(v => v.mesh);
  const hits = raycaster.intersectObjects(meshes);
  if (hits.length > 0) {
    const hit = hits[0];
    const n = hit.face.normal.clone();
    const pos = hit.object.position.clone();
    const wx = Math.round(pos.x + n.x);
    const wy = Math.round(pos.y - 0.5 + n.y);
    const wz = Math.round(pos.z + n.z);
    const bx = Math.round(pos.x - 0.5);
    const by = Math.round(pos.y - 0.5);
    const bz = Math.round(pos.z - 0.5);
    return { place:{x:wx, y:wy, z:wz}, erase:{x:bx, y:by, z:bz}, hit:true };
  }

  // Check ground plane
  const pt = new THREE.Vector3();
  if (raycaster.ray.intersectPlane(groundPlane, pt)) {
    const gx = Math.floor(pt.x + 0.5);
    const gz = Math.floor(pt.z + 0.5);
    return { place:{x:gx, y:0, z:gz}, erase:null, hit:false };
  }
  return null;
}

function doAction(ndc) {
  const target = getVoxelTarget(ndc);
  if (!target) return;
  if (tool === 'add' && target.place) {
    withSymmetry((x,y,z) => placeVoxel(x,y,z,activeBlock), target.place.x, target.place.y, target.place.z);
  } else if (tool === 'erase' && target.erase) {
    withSymmetry((x,y,z) => eraseVoxel(x,y,z), target.erase.x, target.erase.y, target.erase.z);
  } else if (tool === 'paint' && target.erase) {
    paintVoxel(target.erase.x, target.erase.y, target.erase.z);
  }
}

// ─── MOUSE EVENTS ────────────────────────────────────────────────────────────
let mouseDown = false, mouseOrbit = false, mouseMoved = false;

canvas.addEventListener('mousedown', e => {
  if (launchMode) return;
  if (e.button === 2 || e.button === 1) { orb.active = true; orb.lastX = e.clientX; orb.lastY = e.clientY; return; }
  mouseDown = true; mouseMoved = false;
  orb.lastX = e.clientX; orb.lastY = e.clientY;
});

canvas.addEventListener('mousemove', e => {
  if (launchMode) return;
  mouse = getNDC(e.clientX, e.clientY);
  if (mouseDown && !orb.active) {
    const dx = e.clientX - orb.lastX, dy = e.clientY - orb.lastY;
    if (Math.abs(dx) + Math.abs(dy) > 4) { mouseOrbit = true; mouseMoved = true; }
    if (mouseOrbit) {
      orbitDelta(dx, dy);
      orb.lastX = e.clientX; orb.lastY = e.clientY;
    }
  }
  if (orb.active) {
    orbitDelta(e.clientX - orb.lastX, e.clientY - orb.lastY);
    orb.lastX = e.clientX; orb.lastY = e.clientY;
  }
  updateGhost(mouse);
});

canvas.addEventListener('mouseup', e => {
  if (launchMode) return;
  if (orb.active && e.button !== 0) { orb.active = false; return; }
  if (mouseDown && !mouseMoved) {
    const ndc = getNDC(e.clientX, e.clientY);
    const now = Date.now();
    if (now - lastMouseAction > 120) { doAction(ndc); lastMouseAction = now; }
  }
  mouseDown = false; mouseOrbit = false;
});

canvas.addEventListener('contextmenu', e => e.preventDefault());

canvas.addEventListener('wheel', e => {
  if (launchMode) return;
  e.preventDefault();
  const dir = camSettings.invertZoom ? -1 : 1;
  orb.r = Math.max(3, Math.min(60, orb.r + e.deltaY * 0.05 * dir * camSettings.zoomSensitivity));
  orbitApply();
}, { passive: false });

// ─── TOUCH EVENTS ────────────────────────────────────────────────────────────
let touchStart = null, touchMoved = false, touchTime = 0;

canvas.addEventListener('touchstart', e => {
  if (launchMode) return;
  e.preventDefault();
  if (e.touches.length === 1) {
    touchStart = e.touches[0];
    orb.lastX = touchStart.clientX; orb.lastY = touchStart.clientY;
    touchMoved = false; touchTime = Date.now();
  } else if (e.touches.length === 2) {
    const dx = e.touches[0].clientX - e.touches[1].clientX;
    const dy = e.touches[0].clientY - e.touches[1].clientY;
    orb.pinchDist = Math.sqrt(dx*dx+dy*dy);
    orb.touch2 = true;
  }
}, { passive: false });

canvas.addEventListener('touchmove', e => {
  if (launchMode) return;
  e.preventDefault();
  if (e.touches.length === 1 && !orb.touch2) {
    const dx = e.touches[0].clientX - orb.lastX;
    const dy = e.touches[0].clientY - orb.lastY;
    if (Math.abs(dx)+Math.abs(dy) > 5) touchMoved = true;
    orbitDelta(dx, dy);
    orb.lastX = e.touches[0].clientX; orb.lastY = e.touches[0].clientY;
    const ndc = getNDC(e.touches[0].clientX, e.touches[0].clientY);
    updateGhost(ndc);
  } else if (e.touches.length === 2) {
    const dx = e.touches[0].clientX - e.touches[1].clientX;
    const dy = e.touches[0].clientY - e.touches[1].clientY;
    const dist = Math.sqrt(dx*dx+dy*dy);
    const dir = camSettings.invertZoom ? -1 : 1;
    orb.r = Math.max(3, Math.min(60, orb.r - (dist - orb.pinchDist)*0.04*dir));
    orb.pinchDist = dist;
    orbitApply();
  }
}, { passive: false });

canvas.addEventListener('touchend', e => {
  if (launchMode) return;
  e.preventDefault();
  if (!touchMoved && !orb.touch2 && Date.now()-touchTime < 350 && touchStart) {
    const ndc = getNDC(touchStart.clientX, touchStart.clientY);
    doAction(ndc);
  }
  if (e.touches.length < 2) orb.touch2 = false;
  if (e.touches.length === 0) touchStart = null;
}, { passive: false });

// ─── GHOST PREVIEW ───────────────────────────────────────────────────────────
function updateGhost(ndc) {
  if (tool === 'select') { ghostMesh.visible = false; return; }
  const target = getVoxelTarget(ndc);
  if (!target) { ghostMesh.visible = false; return; }

  let pos = (tool === 'erase' || tool === 'paint') ? target.erase : target.place;
  if (!pos) { ghostMesh.visible = false; return; }

  ghostMesh.position.set(pos.x, pos.y + 0.5, pos.z);
  ghostMesh.visible = true;
  ghostMesh.rotation.set(placementRotation.x, placementRotation.y, placementRotation.z);

  if (tool === 'erase') {
    ghostMat.color.set(0xff3b3b); ghostMat.opacity = 0.3;
    ghostEdgeMat.color.set(0xff3b3b);
  } else if (tool === 'paint') {
    const c = activeBlock.id === 'custom' ? customColor : activeBlock.color;
    ghostMat.color.set(c); ghostMat.opacity = 0.5;
    ghostEdgeMat.color.set(c);
  } else {
    ghostMat.color.set(0x00e5ff); ghostMat.opacity = 0.25;
    ghostEdgeMat.color.set(0x00e5ff);
  }

  // Position info
  document.getElementById('info-pos').textContent = `${pos.x}, ${pos.y}, ${pos.z}`;
}

// ─── AXIS INDICATOR ──────────────────────────────────────────────────────────
const axisCanvas = document.getElementById('axis-canvas');
const axisCtx = axisCanvas.getContext('2d');
axisCanvas.width = axisCanvas.height = 60;
const axisColors = { x:'#ff4444', y:'#44ff88', z:'#4488ff' };
const axisVecs = {
  x: new THREE.Vector3(1,0,0), y: new THREE.Vector3(0,1,0), z: new THREE.Vector3(0,0,1)
};

function drawAxis() {
  axisCtx.clearRect(0,0,60,60);
  const cx=30, cy=30, len=22;
  const proj = axis => {
    const v = axisVecs[axis].clone().project(camera);
    return { x: cx + v.x*len, y: cy - v.y*len };
  };
  ['z','x','y'].forEach(axis => {
    const p = proj(axis);
    axisCtx.beginPath();
    axisCtx.moveTo(cx, cy);
    axisCtx.lineTo(p.x, p.y);
    axisCtx.strokeStyle = axisColors[axis];
    axisCtx.lineWidth = 1.5;
    axisCtx.stroke();
    axisCtx.fillStyle = axisColors[axis];
    axisCtx.font = '8px IBM Plex Mono, monospace';
    axisCtx.fillText(axis.toUpperCase(), p.x+2, p.y+3);
  });
  axisCtx.beginPath();
  axisCtx.arc(cx, cy, 2.5, 0, Math.PI*2);
  axisCtx.fillStyle = '#ffffff55';
  axisCtx.fill();
}

// ─── UI HELPERS ──────────────────────────────────────────────────────────────

document.addEventListener('keydown', e => {
  const tag = e.target.tagName;
  if (tag === 'INPUT' || tag === 'TEXTAREA') return;
  const k = e.key.toLowerCase();

  // Flight mode keys
  if (launchMode) {
    if (k === 'tab') { e.preventDefault(); exitLaunchMode(); return; }
    if (k === 'escape') { if (starmapOpen) closeStarmap(); else if (pointerLocked) document.exitPointerLock(); return; }
    if (k === 'j') { e.preventDefault(); toggleFlightPointerLock(); return; }
    if (k === 'm') { e.preventDefault(); toggleStarmap(); return; }
    if (k === 'h') { e.preventDefault(); attemptHyperdrive(); return; }
    flightKeys[k] = true;
    if (k === ' ') { e.preventDefault(); flightKeys.space = true; }
    return; // don't process build keys during flight
  }

  if (k === 'a') setTool('add');
  else if (k === 'e') setTool('erase');
  else if (k === 'p') setTool('paint');
  else if (k === 's') setTool('select');
  else if (k === 'z' && (e.ctrlKey||e.metaKey)) { e.preventDefault(); e.shiftKey ? redo() : undo(); }
  else if (k === 'y' && (e.ctrlKey||e.metaKey)) { e.preventDefault(); redo(); }
  else if (k === 'g') toggleGrid();
  else if (k === 'x') toggleSymmetry();
  else {
    const b = BLOCKS.find(b => b.key === k);
    if (b) {
      setActiveBlock(b);
    }
  }
});

function toggleRight() {
  document.getElementById('panel-right').classList.toggle('open');
}

document.addEventListener('keyup', e => {
  const k = e.key.toLowerCase();
  flightKeys[k] = false;
  if (e.key === ' ') flightKeys['space'] = false;
});

// ─── HINT ────────────────────────────────────────────────────────────────────
const hintEl = document.getElementById('hint');
hintTimer = setTimeout(() => hintEl.classList.add('hidden'), 4000);

// ─── RESIZE ───────────────────────────────────────────────────────────────────
function resize() {
  const w = window.innerWidth, h = window.innerHeight;
  renderer.setSize(w, h);
  camera.aspect = w/h;
  camera.updateProjectionMatrix();
}
resize();
window.addEventListener('resize', resize);

