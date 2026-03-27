// ─── RENDER LOOP ─────────────────────────────────────────────────────────────
renderBlockList();
seedShip();
updateRotationDisplay();
orbitApply();

let frame = 0;
let lastT = 0;
function animate(t) {
  requestAnimationFrame(animate);
  const dt = Math.min((t - lastT) / 1000, 0.05); lastT = t;
  if (launchMode) updateFlight(dt);
  renderer.render(scene, camera);
  if (frame % 2 === 0) drawAxis();
  frame++;
}
animate(0);
