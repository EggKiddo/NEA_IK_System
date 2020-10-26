// -----------------------------------------------------------------------------
//                      Handling keyboard and mouse input
// -----------------------------------------------------------------------------

// The input functions call the corresponding functions
// of the current scene. The scene is allowed to consume
// the input events

void keyTyped() {
  if (currentScene.keyTyped()) { return; }
}

void keyPressed() {
  // Save modifier key states
  if (keyCode == SHIFT) { shiftDown = true; }
  if (keyCode == CONTROL) { controlDown = true; }
  if (keyCode == ALT) { altDown = true; }

  if (keyCode == F1) { showStatsEnabled = !showStatsEnabled; }
  if (keyCode == F2) { orthoCam = !orthoCam; }

  // Back (F5), Top (F6), Right (F7)
  if (keyCode == F5) { cam.setRotations(0, shiftDown ? 0 : PI, 0);}
  if (keyCode == F6) { cam.setRotations(shiftDown ? -HALF_PI : HALF_PI, 0, 0);}
  if (keyCode == F7) { cam.setRotations(0, shiftDown ? -HALF_PI : HALF_PI, 0);}
  orthoCam = keyCode == F5 || keyCode == F6 || keyCode == F7 || orthoCam;

  if (currentScene.keyPressed()) { return; }

  // Load default scene
  if (key == 'd') {
    loadScene(-1);
  }
}

void keyReleased() {

  // Save modifier key states
  if (keyCode == SHIFT) { shiftDown = false; }
  if (keyCode == CONTROL) { controlDown = false; }
  if (keyCode == ALT) { altDown = false; }

  if (currentScene.keyReleased()) { return; }
}

// No default behaviour defined for these at the moment
void mouseWheel() {
  if (currentScene.mouseMoved()) { return; }
}

void mouseMoved() {
  if (currentScene.mouseMoved()) { return; }
}

void mouseClicked() {
  if (currentScene.mouseClicked()) { return; }
}

void mousePressed() {
  if (currentScene.mousePressed()) { return; }
}

void mouseDragged() {
  if (currentScene.mouseDragged()) { return; }
}

void mouseReleased() {
  if (currentScene.mouseReleased()) { return; }
}
