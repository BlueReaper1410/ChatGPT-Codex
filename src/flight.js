function applyShipRotation(yawDelta, pitchDelta, rollDelta) {
  const deltaQuat = new THREE.Quaternion();

  if (yawDelta) {
    deltaQuat.setFromAxisAngle(new THREE.Vector3(0, 1, 0), yawDelta);
    ship.quat.multiply(deltaQuat);
  }
  if (pitchDelta) {
    deltaQuat.setFromAxisAngle(new THREE.Vector3(1, 0, 0), pitchDelta);
    ship.quat.multiply(deltaQuat);
  }
  if (rollDelta) {
    deltaQuat.setFromAxisAngle(new THREE.Vector3(0, 0, 1), rollDelta);
    ship.quat.multiply(deltaQuat);
  }

  ship.quat.normalize();
}


function applyAlignmentAssist(dt) {
  if (!shipAlignTarget || !shipGroup) return;

  const targetPos = getWarpObjectWorldPosition(shipAlignTarget);
  if (!targetPos) {
    shipAlignTarget = null;
    return;
  }

  const direction = targetPos.clone().sub(ship.pos);
  if (direction.lengthSq() < 1) {
    shipAlignTarget = null;
    return;
  }

  const desiredDirection = direction.normalize();
  const desiredQuat = new THREE.Quaternion().setFromUnitVectors(
    new THREE.Vector3(0, 0, -1),
    desiredDirection
  );
  ship.quat.rotateTowards(desiredQuat, MAX_GYRO_TURN_SPEED * dt);

  if (ship.quat.angleTo(desiredQuat) < 0.01) {
    ship.quat.copy(desiredQuat);
    if (hyperdriveState !== 'active') shipAlignTarget = null;
  }
}

function updateFlightCamera(forward, up, speedFactor) {
  const hyperFactor = hyperdriveState === 'active' ? 1.28 : hyperdriveState === 'spool' ? 1.1 : hyperdriveState === 'spooldown' ? 1.18 : 1;
  const velocityLook = ship.vel.clone().clampLength(0, hyperdriveState === 'active' ? 18 : 8).multiplyScalar(0.22);
  const localOffset = new THREE.Vector3(
    0,
    FLIGHT_CAM_HEIGHT + speedFactor * 1.5,
    (FLIGHT_CAM_DISTANCE + speedFactor * 7) * hyperFactor
  );
  const desiredCameraPos = ship.pos.clone().add(localOffset.applyQuaternion(ship.quat));
  const lookTarget = ship.pos.clone()
    .add(forward.clone().multiplyScalar(FLIGHT_CAM_LOOK_AHEAD + speedFactor * 12 * hyperFactor))
    .add(velocityLook);

  camera.position.copy(desiredCameraPos);

  const lookMatrix = new THREE.Matrix4();
  lookMatrix.lookAt(camera.position, lookTarget, up);
  camera.quaternion.setFromRotationMatrix(lookMatrix);
}

function updateHyperdriveState(dt, forward, frameFactor) {
  if (hyperdriveState === 'spool') {
    hyperdriveTimer = Math.max(0, hyperdriveTimer - dt);
    hyperdriveCharge = 1 - hyperdriveTimer / HYPERDRIVE_SPOOL_TIME;
    if (hyperdriveTimer <= 0) {
      hyperdriveState = 'active';
      hyperdriveTimer = 0;
      hyperdriveCharge = 1;
      removeAsteroids();
      streamSectorWindow(true);
      showAlert('HYPERDRIVE ACTIVE');
    }
  } else if (hyperdriveState === 'spooldown') {
    hyperdriveTimer = Math.max(0, hyperdriveTimer - dt);
    hyperdriveCharge = hyperdriveTimer / HYPERDRIVE_SPOOLDOWN_TIME;
    if (hyperdriveTimer <= 0) {
      hyperdriveState = 'off';
      hyperdriveTimer = 0;
      hyperdriveCharge = 0;
      streamSectorWindow(true);
      showAlert('NORMAL SPACE');
    }
  }

  if (hyperdriveGraceTimer > 0) {
    const previous = hyperdriveGraceTimer;
    hyperdriveGraceTimer = Math.max(0, hyperdriveGraceTimer - dt);
    if (previous > 0 && hyperdriveGraceTimer === 0 && launchMode) {
      streamSectorWindow(true);
    }
  }

  if (hyperdriveState === 'active') {
    const forwardSpeed = ship.vel.dot(forward);
    const nextForwardSpeed = moveValueTowards(forwardSpeed, HYPERDRIVE_MAX_SPEED, HYPERDRIVE_ACCEL * frameFactor);
    const lateral = ship.vel.clone().sub(forward.clone().multiplyScalar(forwardSpeed)).multiplyScalar(0.9);
    ship.vel.copy(forward.clone().multiplyScalar(nextForwardSpeed).add(lateral));
  } else if (hyperdriveState === 'spooldown') {
    ship.vel.multiplyScalar(Math.max(0.72, 1 - HYPERDRIVE_SPOOLDOWN_DRAG * frameFactor));
  }

  if (hyperdriveState === 'active' && selectedWarpTarget?.systemCoord) {
    const targetPos = getWarpObjectWorldPosition(selectedWarpTarget);
    if (targetPos && ship.pos.distanceTo(targetPos) <= getWarpArrivalDistance(selectedWarpTarget)) {
      disengageHyperdrive(`ARRIVED -> ${getTargetLabel(selectedWarpTarget)}`);
    }
  }
}

function updateFlight(dt) {
  if (!launchMode || !shipGroup) return;
  dt = Math.min(dt, 0.05);
  const frameFactor = dt * 60;

  const driveEnvelope = hyperdriveState === 'active' || hyperdriveState === 'spooldown';
  const inputScale = hyperdriveState === 'active' ? HYPERDRIVE_STEER_MULT : hyperdriveState === 'spool' ? 0.55 : hyperdriveState === 'spooldown' ? 0.65 : 1;
  const rotationPower = THREE.MathUtils.clamp(shipStats.rcsPower, 0.7, 2.8) * inputScale;
  const yawSign = camSettings.invertX ? 1 : -1;
  const pitchSign = camSettings.invertY ? 1 : -1;
  const yawDelta = pointerLocked ? mouseFDx * FLIGHT_MOUSE_SENS * camSettings.sensitivity * yawSign * rotationPower : 0;
  const pitchDelta = pointerLocked ? mouseFDy * FLIGHT_MOUSE_SENS * camSettings.sensitivity * pitchSign * rotationPower : 0;
  const rollInput = (flightKeys.q ? 1 : 0) - (flightKeys.e ? 1 : 0);
  const rollDelta = rollInput * ROLL_SPD * frameFactor * rotationPower;
  const manualTurning = Math.abs(yawDelta) + Math.abs(pitchDelta) + Math.abs(rollDelta) > 0.00001;

  if (manualTurning && shipAlignTarget) shipAlignTarget = null;
  if (yawDelta || pitchDelta || rollDelta) applyShipRotation(yawDelta, pitchDelta, rollDelta);
  else applyAlignmentAssist(dt);

  mouseFDx = 0;
  mouseFDy = 0;

  shipGroup.position.copy(ship.pos);
  shipGroup.quaternion.copy(ship.quat);

  const forward = new THREE.Vector3(0, 0, -1).applyQuaternion(ship.quat);
  const right = new THREE.Vector3(1, 0, 0).applyQuaternion(ship.quat);
  const up = new THREE.Vector3(0, 1, 0).applyQuaternion(ship.quat);

  let thrusting = false;
  let strafing = false;
  let lifting = false;

  if (!driveEnvelope) {
    if (flightKeys.w) {
      ship.vel.addScaledVector(forward, THRUST * shipStats.enginePower * frameFactor);
      thrusting = true;
    }
    if (flightKeys.s) {
      ship.vel.addScaledVector(forward, -THRUST * 0.58 * shipStats.enginePower * frameFactor);
    }
    if (flightKeys.a) {
      ship.vel.addScaledVector(right, -STRAFE_F * shipStats.rcsPower * frameFactor);
      strafing = true;
    }
    if (flightKeys.d) {
      ship.vel.addScaledVector(right, STRAFE_F * shipStats.rcsPower * frameFactor);
      strafing = true;
    }
    if (flightKeys.space) {
      ship.vel.addScaledVector(up, LIFT_F * shipStats.rcsPower * frameFactor);
      lifting = true;
    }
    if (flightKeys.shift) {
      ship.vel.addScaledVector(up, -LIFT_F * shipStats.rcsPower * frameFactor);
      lifting = true;
    }
    if (flightKeys.control) ship.vel.multiplyScalar(Math.pow(shipStats.brakeDrag, frameFactor));
  } else {
    thrusting = true;
  }

  updateHyperdriveState(dt, forward, frameFactor);

  if (!driveEnvelope && hyperdriveState !== 'spool') {
    if (ship.vel.length() > MAX_SPD) ship.vel.setLength(MAX_SPD);
    ship.vel.multiplyScalar(1 - DRAG * Math.max(0.8, shipStats.mass / 12) * frameFactor);
  } else if (ship.vel.length() > HYPERDRIVE_MAX_SPEED) {
    ship.vel.setLength(HYPERDRIVE_MAX_SPEED);
  }

  ship.pos.addScaledVector(ship.vel, frameFactor);
  const previousSystemCoord = cloneCoord(currentSystemCoord);
  updateFloatingOrigin();
  ensureUniverseState();
  if (previousSystemCoord && currentSystemCoord && !coordsEqual(previousSystemCoord, currentSystemCoord)) {
    handleSystemChange(previousSystemCoord);
  }
  shipGroup.position.copy(ship.pos);
  shipGroup.quaternion.copy(ship.quat);

  const speed = ship.vel.length();
  document.getElementById('thr-main').style.width = thrusting ? `${Math.min(100, 28 + speed / Math.max(MAX_SPD, HYPERDRIVE_MAX_SPEED) * 100)}%` : '0%';
  document.getElementById('thr-rcs').style.width = (strafing || lifting || manualTurning || shipAlignTarget) ? '72%' : '0%';

  if (thrusting && !driveEnvelope && hyperdriveState !== 'spool' && Math.random() > 0.42) spawnExhaust(forward);

  for (let i = projectiles.length - 1; i >= 0; i--) {
    const projectile = projectiles[i];
    projectile.mesh.position.addScaledVector(projectile.vel, frameFactor);
    projectile.life -= dt;
    if (projectile.debris) projectile.mesh.rotation.x += 0.12 * frameFactor;
    if (projectile.life <= 0) {
      scene.remove(projectile.mesh);
      projectiles.splice(i, 1);
    }
  }

  asteroids.forEach(asteroid => {
    if (asteroid.impactCooldown > 0) asteroid.impactCooldown = Math.max(0, asteroid.impactCooldown - dt);
    asteroid.mesh.position.addScaledVector(asteroid.vel, frameFactor);
    asteroid.mesh.rotation.x += asteroid.av.x * frameFactor;
    asteroid.mesh.rotation.y += asteroid.av.y * frameFactor;
    asteroid.mesh.rotation.z += asteroid.av.z * frameFactor;
  });

  if (weaponCooldown > 0) weaponCooldown -= dt;
  if (flightKeys.fire && weaponCooldown <= 0 && hyperdriveState !== 'active' && hyperdriveState !== 'spool') {
    fireWeapon();
  }

  if (!driveEnvelope) {
    checkCollisions();
  } else if (asteroids.length) {
    removeAsteroids();
  }

  updateSpaceAnchors();
  updateFlightCamera(forward, up, Math.min(speed / MAX_SPD, hyperdriveState === 'active' ? 3 : hyperdriveState === 'spooldown' ? 2.2 : 1.4));
  updateHUD();
}
