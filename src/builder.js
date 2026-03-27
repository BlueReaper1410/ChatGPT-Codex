function key(x, y, z) { return `${x},${y},${z}`; }

function placeVoxel(x, y, z, blockType, recordHistory = true, rot = null) {
  if (y < 0) return;
  const k = key(x, y, z);
  if (voxels.has(k)) return;

  const col = blockType.id === 'custom' ? customColor : blockType.color;
  const mesh = createVoxelMesh(blockType, col);
  mesh.position.set(x, y + 0.5, z);
  const rotation = rot ? { x: rot.x, y: rot.y, z: rot.z } : { ...placementRotation };
  mesh.rotation.set(rotation.x, rotation.y, rotation.z);

  scene.add(mesh);
  voxels.set(k, { mesh, type: blockType, x, y, z, color: col, rotation });

  if (recordHistory) pushHistory('add', { x, y, z, blockType, color: col, rotation });
  updateInfo();
}

function eraseVoxel(x, y, z, recordHistory = true) {
  const k = key(x, y, z);
  if (!voxels.has(k)) return;
  const v = voxels.get(k);
  scene.remove(v.mesh);
  voxels.delete(k);
  if (recordHistory) pushHistory('erase', { x, y, z, blockType: v.type, color: v.color, rotation: v.rotation });
  updateInfo();
}

function paintVoxel(x, y, z) {
  const k = key(x, y, z);
  if (!voxels.has(k)) return;
  const v = voxels.get(k);
  const col = activeBlock.id === 'custom' ? customColor : activeBlock.color;
  const emi = activeBlock.id === 'custom' ? 0x001122 : activeBlock.emissive;
  v.mesh.material = getMat(col, emi);
  v.color = col;
}

function withSymmetry(fn, x, y, z) {
  fn(x, y, z);
  if (symmetry) fn(-x, y, z);
}

function pushHistory(action, data) {
  history.push({ action, ...data });
  if (history.length > 200) history.shift();
  future = [];
}

function undo() {
  if (!history.length) return;
  const h = history.pop();
  future.push(h);
  if (h.action === 'add') eraseVoxel(h.x, h.y, h.z, false);
  else if (h.action === 'erase') placeVoxel(h.x, h.y, h.z, h.blockType, false, h.rotation);
}

function redo() {
  if (!future.length) return;
  const h = future.pop();
  history.push(h);
  if (h.action === 'add') placeVoxel(h.x, h.y, h.z, h.blockType, false, h.rotation);
  else if (h.action === 'erase') eraseVoxel(h.x, h.y, h.z, false);
}

function clearAll() {
  if (!confirm('Clear all blocks?')) return;
  voxels.forEach(v => scene.remove(v.mesh));
  voxels.clear();
  history = [];
  future = [];
  updateInfo();
}

function setTool(t) {
  tool = t;
  document.querySelectorAll('.tool-btn').forEach(b => b.classList.remove('active'));
  document.getElementById(`t-${t}`)?.classList.add('active');
  document.getElementById('st-tool').textContent = t.toUpperCase();
  ghostMesh.visible = false;
}

function setActiveBlock(block) {
  activeBlock = block;
  document.querySelectorAll('.block-item').forEach((el, i) => {
    el.classList.toggle('active', BLOCKS[i] === block);
  });
  document.getElementById('st-block').textContent = block.name;
}

function updateRotationDisplay() {
  const quarterTurns = value => Math.round(value / rotationStep) % 4;
  document.getElementById('st-rot').textContent = [
    quarterTurns(placementRotation.x),
    quarterTurns(placementRotation.y),
    quarterTurns(placementRotation.z),
  ].join(' ');
}

function rotatePlacement(axis) {
  placementRotation[axis] = (placementRotation[axis] + rotationStep) % (Math.PI * 2);
  updateRotationDisplay();
  if (ghostMesh.visible) {
    ghostMesh.rotation.set(placementRotation.x, placementRotation.y, placementRotation.z);
  }
}

function resetPlacementRotation() {
  placementRotation = { x: 0, y: 0, z: 0 };
  updateRotationDisplay();
  if (ghostMesh.visible) {
    ghostMesh.rotation.set(0, 0, 0);
  }
}

function toggleGrid() {
  showGrid = !showGrid;
  gridHelper.visible = showGrid;
}

function toggleSymmetry() {
  symmetry = !symmetry;
  document.getElementById('sym-state').textContent = symmetry ? 'ON' : 'OFF';
}

function setCustomColor(hex) {
  customColor = Number.parseInt(hex.replace('#', ''), 16);
  renderBlockList();
}

function updateInfo() {
  document.getElementById('info-count').textContent = voxels.size;
  if (!voxels.size) {
    document.getElementById('info-pos').textContent = '-';
  }
}

function renderBlockList() {
  const list = document.getElementById('block-list');
  list.innerHTML = '';

  BLOCKS.forEach(block => {
    const item = document.createElement('button');
    item.className = 'block-item';
    item.type = 'button';
    item.innerHTML = `
      <span class="swatch" style="background:#${(block.id === 'custom' ? customColor : block.color).toString(16).padStart(6, '0')}"></span>
      <span>${block.name}</span>
      <span class="keycap">${block.key}</span>
    `;
    item.addEventListener('click', () => setActiveBlock(block));
    list.appendChild(item);
  });

  setActiveBlock(activeBlock);
}

function exportJSON() {
  const payload = {
    blocks: [...voxels.values()].map(v => ({
      x: v.x,
      y: v.y,
      z: v.z,
      type: v.type.id,
      color: v.color,
      rotation: v.rotation,
    })),
  };

  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = 'vessel-blueprint.json';
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 0);
}

function seedShip() {
  for (let y = 0; y < 3; y++) placeVoxel(0, y, 0, BLOCKS[0], false);
  for (let z = -2; z <= 2; z++) placeVoxel(0, 0, z, BLOCKS[0], false);
  placeVoxel(0, 1, -1, BLOCKS[0], false);
  placeVoxel(0, 1, 1, BLOCKS[0], false);
  placeVoxel(0, 2, 0, BLOCKS[1], false);
  [-2, -1, 1, 2].forEach(x => placeVoxel(x, 0, 0, BLOCKS[2], false));
  placeVoxel(-1, 0, -1, BLOCKS[2], false);
  placeVoxel(1, 0, -1, BLOCKS[2], false);
  placeVoxel(-1, 0, 2, BLOCKS[3], false);
  placeVoxel(1, 0, 2, BLOCKS[3], false);
  placeVoxel(0, 0, 2, BLOCKS[4], false);
  placeVoxel(0, 0, -2, BLOCKS[5], false);
  updateInfo();
}
