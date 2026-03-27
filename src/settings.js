function openSettings() {
  document.getElementById('settings-overlay').classList.add('open');
  syncSettingsUI();
}
function closeSettings() {
  document.getElementById('settings-overlay').classList.remove('open');
}
function settingsOverlayClick(e) {
  if (e.target === document.getElementById('settings-overlay')) closeSettings();
}
function syncSettingsUI() {
  setToggleUI('tog-invert-y', camSettings.invertY);
  setToggleUI('tog-invert-x', camSettings.invertX);
  setToggleUI('tog-invert-zoom', camSettings.invertZoom);
  document.getElementById('sl-sensitivity').value = Math.round(camSettings.sensitivity * 100);
  document.getElementById('sl-zoom-sens').value = Math.round(camSettings.zoomSensitivity * 100);
}
function setToggleUI(id, on) {
  document.getElementById(id).classList.toggle('on', on);
}
function toggleSetting(key) {
  camSettings[key] = !camSettings[key];
  setToggleUI({
    invertY:'tog-invert-y', invertX:'tog-invert-x', invertZoom:'tog-invert-zoom'
  }[key], camSettings[key]);
}
function setSensitivity(val) { camSettings.sensitivity = val / 100; }
function setZoomSensitivity(val) { camSettings.zoomSensitivity = val / 100; }

