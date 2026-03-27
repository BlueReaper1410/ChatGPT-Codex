function spawnExhaust(forwardDir) {
  let spawnPoint = ship.pos.clone();
  flightBlocks.forEach(v => {
    if (v.type.id === 'engine' || v.type.id === 'thruster') {
      spawnPoint = v.mesh.getWorldPosition(new THREE.Vector3());
    }
  });

  const geo = new THREE.SphereGeometry(0.1, 4, 4);
  const mat = new THREE.MeshBasicMaterial({ color: Math.random() > 0.5 ? 0xff7a1a : 0x33aaff });
  const mesh = new THREE.Mesh(geo, mat);
  mesh.position.copy(spawnPoint);
  scene.add(mesh);

  const spread = new THREE.Vector3((Math.random() - 0.5) * 0.3, (Math.random() - 0.5) * 0.3, (Math.random() - 0.5) * 0.3);
  const vel = forwardDir.clone().negate().multiplyScalar(0.15 + Math.random() * 0.12).add(spread).add(ship.vel.clone().multiplyScalar(0.7));
  projectiles.push({ mesh, vel, life: 0.22 + Math.random() * 0.18, debris: true });
  trimProjectiles();
}

function fireWeapon() {
  const weapons = [...flightBlocks.values()].filter(v => v.type.id === 'weapon');
  if (weapons.length === 0) {
    showAlert('NO WEAPON BLOCKS');
    return;
  }

  const forward = new THREE.Vector3(0, 0, -1).applyQuaternion(ship.quat);
  weapons.forEach(v => {
    const geo = new THREE.CylinderGeometry(0.06, 0.06, 0.55, 6);
    geo.applyMatrix4(new THREE.Matrix4().makeRotationX(Math.PI / 2));
    const mat = new THREE.MeshBasicMaterial({ color: 0xff5533 });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.copy(v.mesh.getWorldPosition(new THREE.Vector3()));
    mesh.quaternion.copy(ship.quat);
    scene.add(mesh);

    const vel = forward.clone().multiplyScalar(PROJ_SPD / 60).add(ship.vel.clone().multiplyScalar(0.7));
    projectiles.push({ mesh, vel, life: 2.5, debris: false });
  });

  weaponCooldown = Math.max(0.08, WPN_CD - shipStats.weaponCount * 0.015);
  trimProjectiles();
}

function trimProjectiles() {
  while (projectiles.length > MAX_PARTICLES) {
    const oldest = projectiles.shift();
    if (oldest) scene.remove(oldest.mesh);
  }
}

function spawnDebris(pos, size, color = 0xffaa33) {
  for (let i = 0; i < 10; i++) {
    const geo = new THREE.BoxGeometry(size * 0.22, size * 0.22, size * 0.22);
    const mat = new THREE.MeshBasicMaterial({
      color: new THREE.Color(color).offsetHSL((Math.random() - 0.5) * 0.06, -0.05, (Math.random() - 0.5) * 0.08),
    });
    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.copy(pos);
    scene.add(mesh);

    const vel = new THREE.Vector3((Math.random() - 0.5) * 0.16, (Math.random() - 0.5) * 0.16, (Math.random() - 0.5) * 0.16)
      .add(ship.vel.clone().multiplyScalar(0.45));
    projectiles.push({ mesh, vel, life: 0.9 + Math.random() * 1.1, debris: true });
  }
  trimProjectiles();
}

function checkCollisions() {
  for (let ai = asteroids.length - 1; ai >= 0; ai--) {
    const asteroid = asteroids[ai];
    for (let pi = projectiles.length - 1; pi >= 0; pi--) {
      const projectile = projectiles[pi];
      if (projectile.debris) continue;
      if (projectile.mesh.position.distanceTo(asteroid.mesh.position) < asteroid.radius + 0.35) {
        asteroid.hp -= 35;
        scene.remove(projectile.mesh);
        projectiles.splice(pi, 1);
        if (asteroid.hp <= 0) {
          spawnDebris(asteroid.mesh.position, asteroid.radius * 0.8, asteroid.color);
          scene.remove(asteroid.mesh);
          asteroids.splice(ai, 1);
        }
        break;
      }
    }
  }

  for (let ai = asteroids.length - 1; ai >= 0; ai--) {
    const asteroid = asteroids[ai];
    if (asteroid.impactCooldown > 0) continue;
    if (ship.pos.distanceTo(asteroid.mesh.position) < asteroid.radius + 2.35) {
      const relativeSpeed = ship.vel.length() + asteroid.vel.length();
      const damage = 22 + relativeSpeed * 28;
      let closestKey = null;
      let closestDistance = Infinity;

      flightBlocks.forEach((v, keyName) => {
        const dist = v.mesh.getWorldPosition(new THREE.Vector3()).distanceTo(asteroid.mesh.position);
        if (dist < closestDistance) {
          closestDistance = dist;
          closestKey = keyName;
        }
      });

      if (closestKey) damageBlock(closestKey, damage);
      asteroid.impactCooldown = 0.16;

      const normal = ship.pos.clone().sub(asteroid.mesh.position).normalize();
      ship.vel.reflect(normal).multiplyScalar(0.22);
      asteroid.vel.add(normal.clone().multiplyScalar(-0.03));
      showAlert('IMPACT!');
    }
  }
}

function damageBlock(keyName, amount) {
  const block = blockHealth.get(keyName);
  if (!block || block.hp <= 0) return;

  block.hp = Math.max(0, block.hp - amount);
  const ratio = block.hp / block.maxHp;
  const voxel = flightBlocks.get(keyName);
  if (voxel) {
    const material = voxel.mesh.material.clone();
    material.emissive.setRGB(0.45 * (1 - ratio), 0.02, 0.02);
    material.emissiveIntensity = 1 + (1 - ratio) * 3.5;
    voxel.mesh.material = material;
  }

  if (block.hp <= 0) destroyBlock(keyName);
}

function destroyBlock(keyName) {
  const voxel = flightBlocks.get(keyName);
  if (!voxel) return;

  spawnDebris(voxel.mesh.getWorldPosition(new THREE.Vector3()), 0.9, voxel.color);
  voxel.mesh.removeFromParent();
  flightBlocks.delete(keyName);
  blockHealth.delete(keyName);
  rebuildShipStats();
  updateHUD();

  if (voxel.type.id === 'cockpit') {
    setTimeout(() => {
      showAlert('COCKPIT DESTROYED - EJECTING');
      setTimeout(() => { if (launchMode) exitLaunchMode(); }, 2000);
    }, 300);
  }

  if (flightBlocks.size === 0) {
    setTimeout(() => {
      showAlert('VESSEL DESTROYED');
      setTimeout(() => { if (launchMode) exitLaunchMode(); }, 2000);
    }, 300);
  }
}
