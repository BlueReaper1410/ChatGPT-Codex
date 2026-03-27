function showAlert(msg) {
  const el = document.getElementById('hud-alert');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(el._t);
  el._t = setTimeout(() => el.classList.remove('show'), 1300);
}

function requestFlightPointerLock() {
  if (!launchMode || pointerLocked) return;
  canvas.requestPointerLock();
}

function toggleFlightPointerLock() {
  if (!launchMode) return;
  if (pointerLocked) document.exitPointerLock();
  else requestFlightPointerLock();
}

function getDriveStatusText() {
  if (hyperdriveState === 'spool') return `SPOOL ${hyperdriveTimer.toFixed(1)}s`;
  if (hyperdriveState === 'active') return 'ACTIVE';
  if (hyperdriveState === 'spooldown') return `COAST ${hyperdriveTimer.toFixed(1)}s`;
  if (hyperdriveGraceTimer > 0) return 'CLEAR';
  return 'OFF';
}

function updateHUD() {
  document.getElementById('hud-speed').textContent = ship.vel.length().toFixed(2);

  let hullCurrent = 0;
  flightBlocks.forEach((v, keyName) => {
    if (v.type.id !== 'shield') {
      const block = blockHealth.get(keyName);
      if (block) hullCurrent += block.hp;
    }
  });

  const hullPercent = Math.max(0, Math.round(hullCurrent / totalHullMax * 100));
  const hullFill = document.getElementById('hud-hull-fill');
  const hullValue = document.getElementById('hud-hull-val');
  if (hullFill) {
    hullFill.style.width = `${hullPercent}%`;
    hullFill.style.background = hullPercent > 50 ? 'var(--accent)' : hullPercent > 20 ? 'var(--warn)' : 'var(--danger)';
  }
  if (hullValue) {
    hullValue.textContent = `${hullPercent}%`;
    hullValue.className = `hud-val${hullPercent < 20 ? ' crit' : hullPercent < 50 ? ' warn' : ''}`;
  }

  let shieldCurrent = 0;
  flightBlocks.forEach((v, keyName) => {
    if (v.type.id === 'shield') {
      const block = blockHealth.get(keyName);
      if (block) shieldCurrent += block.hp;
    }
  });

  const shieldPercent = totalShieldMax > 0 ? Math.max(0, Math.round(shieldCurrent / totalShieldMax * 100)) : 0;
  const shieldFill = document.getElementById('hud-shield-fill');
  const shieldValue = document.getElementById('hud-shield-val');
  if (shieldFill) shieldFill.style.width = `${totalShieldMax > 0 ? shieldPercent : 0}%`;
  if (shieldValue) shieldValue.textContent = totalShieldMax > 0 ? `${shieldPercent}%` : 'NONE';

  document.getElementById('hud-threats').textContent = asteroids.length;

  const systemData = getCurrentSystemData();
  const hudSystem = document.getElementById('hud-system');
  if (hudSystem) hudSystem.textContent = `${systemData.name} ${coordLabel(currentSectorCoord)}`;

  const driveEl = document.getElementById('hud-drive');
  if (driveEl) {
    driveEl.textContent = getDriveStatusText();
    driveEl.className = `hud-val${hyperdriveState === 'active' ? ' warn' : hyperdriveState === 'spool' || hyperdriveState === 'spooldown' ? ' crit' : ''}`;
  }

  const weaponsLocked = hyperdriveState === 'active' || hyperdriveState === 'spool';
  const ready = !weaponsLocked && weaponCooldown <= 0;
  const weaponStatus = document.getElementById('hud-weapon-st');
  const weaponFill = document.getElementById('hud-weapon-fill');
  if (weaponStatus) {
    weaponStatus.textContent = weaponsLocked ? 'LOCKED' : ready ? 'READY' : 'LOADING';
    weaponStatus.className = ready && !weaponsLocked ? '' : 'cooling';
  }
  if (weaponFill) {
    const cooldownRatio = weaponsLocked ? 100 : ready ? 100 : Math.round((1 - weaponCooldown / WPN_CD) * 100);
    weaponFill.style.width = `${cooldownRatio}%`;
  }

  document.getElementById('hud-lock').classList.toggle('gone', !launchMode || pointerLocked);
}

canvas.addEventListener('mousedown', e => {
  if (!launchMode) return;
  if (e.button === 0) {
    if (!pointerLocked) requestFlightPointerLock();
    else flightKeys.fire = true;
  }
});

document.addEventListener('mouseup', e => {
  if (e.button === 0) flightKeys.fire = false;
});

document.addEventListener('pointerlockchange', () => {
  pointerLocked = document.pointerLockElement === canvas;
  if (!pointerLocked) {
    mouseFDx = 0;
    mouseFDy = 0;
    flightKeys.fire = false;
  }
  updateHUD();
});

document.addEventListener('mousemove', e => {
  if (launchMode && pointerLocked) {
    mouseFDx += e.movementX;
    mouseFDy += e.movementY;
  }
});
