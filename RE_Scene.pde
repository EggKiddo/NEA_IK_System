// -----------------------------------------------------------------------------
//              Base class for all scenes (also the default scene)
// -----------------------------------------------------------------------------

// Class intended to be used more like an interface
// Implements default behaviour in case instantiating
// a derived class fails
class Scene {

  public Scene() {
    // Scene setup
    perspective(PI / 3.0, float(width) / float(height), nearPlane, farPlane);
  }

  public void draw() {
    background(24);
    drawAxes(10, true);
  }

  public void draw2D() {
    textSize(UI_FONTSIZE_MEDIUM);
    textAlign(LEFT, TOP);
    text("Empty Scene", 12, 12);
  }

  public void start2D() {
    hint(DISABLE_DEPTH_TEST);
    cam.beginHUD();
  }

  public void end2D() {
    cam.endHUD();
    hint(ENABLE_DEPTH_TEST);
  }

  public String getTitle() {
    return "Scene";
  }

  public String getDescription() {
    return "Description of scene";
  }

  public boolean keyTyped() { return false; }
  public boolean keyPressed() { return false; }
  public boolean keyReleased() { return false; }
  public boolean mouseMoved() { return false; }
  public boolean mouseClicked() { return false; }
  public boolean mousePressed() { return false; }
  public boolean mouseDragged() { return false; }
  public boolean mouseReleased() { return false; }
}
