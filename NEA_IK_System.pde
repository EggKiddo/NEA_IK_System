// -----------------------------------------------------------------------------
//                  Main loop, draws scenes and handles input
// -----------------------------------------------------------------------------

import peasy.*;
import processing.opengl.*;

// Globals for rendering
Scene currentScene;
PeasyCam cam;
CameraState startCamState;

boolean showStatsEnabled = false;
boolean orthoCam = false;

float nearPlane = 0.1;
float farPlane = 2000;

color clearColor = color(24);

// Keeping track of FPS
TracedPoint fps = new TracedPoint(new PVector(0, 0, 0), 120);
TraceGrapher fpsGrapher;

// Booleans to allow key combinations
boolean shiftDown = false;
boolean controlDown = false;
boolean altDown = false;

// Globals for displaying a message
Timer messageTimer;
String message;
color messageColor;

// Setting up the window and renderer
void setup() {

  // Use OPENGL or P3D
  fullScreen(P3D);
  //size(640, 480, OPENGL);

  smooth(8);

  loadFonts();

  cam = new PeasyCam(this, 150);
  startCamState = cam.getState();

  setFont(UI_REGULAR, UI_FONTSIZE_NORMAL);

  fpsGrapher = new TraceGrapher(false, width - 16, 16, width - 144, 48);
  fpsGrapher.setDrawXYZ(true, false, false);

  loadScene(0);
}

void draw() {

  // Must force ortho since Peasy does not support it
  if (orthoCam) {
    float dist = (float)cam.getDistance() * 0.001;
    float r = width * dist / 2;
    float b = height * dist / 2;
    ortho(-r, r, -b, b, nearPlane, farPlane);
  } else {
    perspective(PI / 3.0, float(width) / float(height), nearPlane, farPlane);
  }

  // Change to Z up coordinate system
  pushMatrix();

  rotateX(HALF_PI);
  scale(1, -1, 1);

  // Draw current scene
  currentScene.draw();

  popMatrix();

  // Draw GUI on top of everything
  drawGUI();

  // Save current FPS
  fps.addTrace();
  fps.setPosition(new PVector(frameRate, 0, 0));
}

public void drawGUI() {
  // Draw on top of everything
  hint(DISABLE_DEPTH_TEST);
  cam.beginHUD();
  
  // Draw scene UI first
  currentScene.draw2D();

  if (showStatsEnabled) { showStats(); }

  // Draw message
  if (messageTimer != null && messageTimer.IsRunning()) {
    pushStyle();

    rectMode(CENTER);
    stroke(messageColor);
    strokeWeight(2);
    fill(red(messageColor), green(messageColor), blue(messageColor), 128);
    rect(width / 2, 48, 512, 32);
    fill(255);
    noStroke();
    setFont(UI_MEDIUM, UI_FONTSIZE_NORMAL);
    textAlign(CENTER, CENTER);
    text(message, width / 2, 48, 512, 32);

    popStyle();
  }

  // Re-enablee depth testing
  cam.endHUD();
  hint(ENABLE_DEPTH_TEST);
}

// Get screen-space position of 3D point
PVector WorldToScreen(PVector vect) {
  return new PVector(
    screenX(vect.x, vect.y, vect.z),
    screenY(vect.x, vect.y, vect.z),
    screenZ(vect.x, vect.y, vect.z));
}

// Prepare variables for drawing message
void Message(String msg, color col, float duration) {
  messageTimer = new Timer(duration);
  messageColor = col;
  message = msg;
}

// Load scenes
void loadScene(int index) {
  cam.reset(0);
  cam.setFreeRotationMode();
  try {
    switch (index) {
      case 0:
        currentScene = new InteractiveIK();
        break;
      default:
        currentScene = new Scene();
    }
  } catch (Exception e) {
    currentScene = new Scene();
    Message("Could not load scene: " + e.getMessage(), UI_ERROR, 15000);
  }
}
