// -----------------------------------------------------------------------------
//                     Scene to interact with the IK system
// -----------------------------------------------------------------------------

class InteractiveIK extends Scene {

  int axis = 0;

  boolean typing = false;
  String text = "";
  boolean waitingForSave = false;
  boolean waitingForLoad = false;

  int selected;
  PVector selectedEnd;
  PVector selectedStart;

  boolean keyHints = false;

  boolean pause = true;
  boolean hideTargets = false;
  boolean drawJointAxes = false;
  boolean jointInfo = false;

  // Need to make sure the three are synced (depends on implementation)
  public ArrayList<IKJoint> joints = new ArrayList<IKJoint>();
  ArrayList<IKJacobianSolver> solvers;
  ArrayList<SimpleMatrix> targets;

  public InteractiveIK() {
    targets = new ArrayList<SimpleMatrix>();
    solvers = new ArrayList<IKJacobianSolver>();

    // Here are a few options for generating chains:

    // Load joints from file
    // LoadJoints(joints, "skeleton");

    // Generate a long arm
    for (int i = 0; i < 10; i++) {
      IKJoint j = new IKJoint(10);
      j.name = "Joint " + str(i);
      if (i > 0) { j.SetParent(joints.get(joints.size() - 1)); }
      //j.translation.set(0,0, random(-10, 10));
      //j.scale = random(0.1, 2.0);
      joints.add(j);
    }

    // Generate a random chain
    /*for (int i = 0; i < 20; i++) {
      IKJoint j = new IKJoint(random(1, 3));
      j.name = "Joint " + str(i);
      if (i > 0) {
        j.rotation = CreateRotationSimpleMatrix(random(-PI, PI),
                                          random(-PI, PI),
                                          random(-PI, PI));
        j.originalRotation = j.rotation.copy();
        j.SetParent(joints.get(floor(random(0, joints.size()))));
      }
      joints.add(j);
    }*/

    //CreateSkeleton(joints);

  }

  private void drawKeyHint(String keyName, String hint, float x, float y) {
    drawTextPair(String.format("[%s]", keyName), hint, x, y, 128);
  }

  // Draws keyboard shortcuts if enabled
  private void drawKeyHints() {
    pushStyle();
    textAlign(LEFT, TOP);
    setFont(UI_BOLD, UI_FONTSIZE_NORMAL);
    fill(255);
    noStroke();

    ListCoords l = new ListCoords(20, 20, 20);
    if (keyHints) {
      pushStyle();
      fill(0, 0, 0, 64);
      rect(0, 0, 450, l.ls * 26);
      popStyle();
      drawKeyHint("Key(s)", "Function", l.x, l.next());
      setFont(UI_REGULAR, UI_FONTSIZE_NORMAL);
      drawKeyHint("K", "Display keyboard shortcuts", l.x, l.next());
      drawKeyHint("Esc", "Exit application", l.x, l.next());
      drawKeyHint("F1", "Display scene info", l.x, l.next());
      drawKeyHint("F2", "Perspective/Ortho", l.x, l.next());
      drawKeyHint(
        "F5,F6,F7",
        "Front/Right/Top view (Shift to invert)", l.x, l.next()
      );
      drawKeyHint("Double Click", "Reset camera", l.x, l.next());
      l.skip(1);
      drawKeyHint(
        "+,-",
        "Selected joint: " + joints.get(selected).name, l.x, l.next()
      );
      drawKeyHint("I", "Display joint info", l.x, l.next());
      drawKeyHint("B", "Draw joint axes: " + drawJointAxes, l.x, l.next());
      drawKeyHint("S", "Save joint configuration", l.x, l.next());
      drawKeyHint("L", "Load joint configuration", l.x, l.next());
      l.skip(1);
      drawKeyHint("A", "Add solver to selected", l.x, l.next());
      drawKeyHint("D", "Delete solver of selected", l.x, l.next());
      drawKeyHint("Up,Down", "Change solve depth", l.x, l.next());
      drawKeyHint("E", "Toggle transpose/inverse method", l.x, l.next());
      drawKeyHint("C", "Toggle continuous solving", l.x, l.next());
      drawKeyHint("M", "Manual iteration", l.x, l.next());
      drawKeyHint("Space", "Pause solvers: " + pause, l.x, l.next());
      drawKeyHint("H", "Hide targets: " + hideTargets, l.x, l.next());
      drawKeyHint(
        "X,Y,Z",
        "Move direction: " +
        (axis == ROT_X ? "X" : axis == ROT_Y ? "Y" : "Z"), l.x, l.next()
      );
      drawKeyHint("R", "Reset chain and targets", l.x, l.next());
    } else {
      text("Press K for keyboard shortcuts", l.x, l.y);
    }
    popStyle();
  }

  private void drawJointInfo() {
    if (!jointInfo) { return; }

    IKJoint j = joints.get(selected);
    int si = FindSolverIndex(j);

    // Prepare the renderer
    pushStyle();
    textAlign(LEFT, TOP);
    setFont(UI_BOLD, UI_FONTSIZE_NORMAL);
    fill(255);
    noStroke();
    float ls = 20;
    ListCoords l = new ListCoords(20, height - ls * 11, ls);
    float spacing = 150;

    // Background rect
    pushStyle();
    fill(0, 0, 0, 64);
    rect(0, l.y - ls, 450, height);
    popStyle();

    drawTextPair("Joint:", j.name, l.x, l.next(), spacing);
    setFont(UI_REGULAR, UI_FONTSIZE_NORMAL);
    drawTextPair(
      "Parent:",
      j.parent != null ? j.parent.name : "null", l.x, l.next(), spacing
    );

    String txt = j.limit[0] ? String.format(
      " (Min: %f, Max: %f)", j.limits.get(0, 0), j.limits.get(0, 1)) : "";
    drawTextPair("X limited: ", j.limit[0] + txt, l.x, l.next(), spacing);

    txt = j.limit[1] ? String.format(
      " (Min: %f, Max: %f)", j.limits.get(1, 0), j.limits.get(1, 1)) : "";
    drawTextPair("Y limited: ", j.limit[1] + txt, l.x, l.next(), spacing);

    txt = j.limit[2] ? String.format(
      " (Min: %f, Max: %f)", j.limits.get(2, 0), j.limits.get(2, 1)) : "";
    drawTextPair("Z limited: ", j.limit[2] + txt, l.x, l.next(), spacing);

    PVector v = MatToPVec(j.originalRotation);
    txt = String.format("X: %f Y: %f Z: %f", v.x, v.y, v.z);
    drawTextPair("Original rotation:", txt, l.x, l.next(), spacing);

    v = MatToPVec(j.rotation);
    txt = String.format("X: %f Y: %f Z: %f", v.x, v.y, v.z);
    drawTextPair("Rotation:", txt, l.x, l.next(), spacing);

    v = MatToPVec(j.translation);
    txt = String.format("X: %f Y: %f Z: %f", v.x, v.y, v.z);
    drawTextPair("Translation:", txt, l.x, l.next(), spacing);

    drawTextPair("Scale:",
      String.format("%f", j.scale), l.x, l.next(), spacing);
    drawTextPair("Length:",
      String.format("%f", j.length), l.x, l.next(), spacing);
    popStyle();

    // Draw the details of the associated solver
    drawSolverInfo(si);
  }

  // Lists the visible properties of the solver at 'index'
  private void drawSolverInfo(int index) {
    if (index < 0) { return; }
    IKJacobianSolver s = solvers.get(index);

    // Prepare renderer
    pushStyle();
    textAlign(LEFT, TOP);
    setFont(UI_BOLD, UI_FONTSIZE_NORMAL);
    fill(255);
    noStroke();
    float ls = 20;
    ListCoords l = new ListCoords(470, height - ls * 11, ls);
    float spacing = 150;

    // Draw separator and background rect.
    pushStyle();
    fill(0, 0, 0, 64);
    rect(450, l.y - ls, 450, height);
    stroke(255);
    strokeWeight(1);
    line(450, l.y, 450, height - ls);
    popStyle();

    text("Solver:", l.x, l.next());
    setFont(UI_REGULAR, UI_FONTSIZE_NORMAL);

    PVector t = MatToPVec(s.Target());
    String txt = String.format("X: %f Y: %f Z: %f", t.x, t.y, t.z);
    drawTextPair("Target: ", txt, l.x, l.next(), spacing);
    txt = String.format("%f", s.Error());
    drawTextPair("Error: ", txt, l.x, l.next(), spacing);
    txt = String.format("%f", s.tolerance);
    drawTextPair("Tolerance: ", txt, l.x, l.next(), spacing);
    drawTextPair("Max depth: ", depthString(s), l.x, l.next(), spacing);
    boolean isInverse = s.InverseMethodEnabled();
    txt = isInverse ? "inverse" : "transpose";
    drawTextPair("Solver method: ", txt, l.x, l.next(), spacing);
    txt = str(s.ContinuousEnabled());
    drawTextPair("Continuous: ", txt, l.x, l.next(), spacing);
    txt = str(s.Iterations());
    drawTextPair("Iterations: ", txt, l.x, l.next(), spacing);
    popStyle();
  }

  // Convert SimpleMatrix to PMatrix3D (only for rendering)
  PMatrix3D MatToPMat(SimpleMatrix mat) {
    PMatrix3D pmat = new PMatrix3D();
    float[] data = new float[16];
    for (int i = 0; i < 16; i++) {
      data[i] = (float)mat.get(floor(i / 4), i % 4);
    }
    pmat.set(data);
    return pmat;
  }

  SimpleMatrix PVecToMat(PVector vec) {
    SimpleMatrix mat = new SimpleMatrix(4, 1);
    mat.set(0, 0, vec.x);
    mat.set(1, 0, vec.y);
    mat.set(2, 0, vec.z);
    // Assuming 'vec' is a position vector
    mat.set(3, 0, 1);

    return mat;
  }

  PVector MatToPVec(SimpleMatrix mat) {
    // Some precision is lost, but it's only for rendering
    // purposes, so it is nothing to worry about
    return new PVector(
      (float)mat.get(0, 0),
      (float)mat.get(1, 0),
      (float)mat.get(2, 0));
  }

  void drawLine(SimpleMatrix m1, SimpleMatrix m2) {
    line(
      (float)m1.get(0, 0),
      (float)m1.get(1, 0),
      (float)m1.get(2, 0),

      (float)m2.get(0, 0),
      (float)m2.get(1, 0),
      (float)m2.get(2, 0));
  }

  // Draws a bone representing the joint
  void drawBone(IKJoint j) {
    if (drawJointAxes) { drawAxes(3, true); }
    float len = (float)j.length * 0.1;
    PVector corner = new PVector(len, len, len);
    // Bottom (short) half
    beginShape(TRIANGLE_FAN);
    vertex(0, 0, 0);
    vertex(corner.x, corner.y, corner.z);
    vertex(-corner.x, corner.y, corner.z);
    vertex(-corner.x, -corner.y, corner.z);
    vertex(corner.x, -corner.y, corner.z);
    vertex(corner.x, corner.y, corner.z);
    endShape(CLOSE);

    // Top (long) half
    beginShape(TRIANGLE_FAN);
    vertex(0, 0, (float)j.length);
    vertex(corner.x, corner.y, corner.z);
    vertex(-corner.x, corner.y, corner.z);
    vertex(-corner.x, -corner.y, corner.z);
    vertex(corner.x, -corner.y, corner.z);
    vertex(corner.x, corner.y, corner.z);
    endShape(CLOSE);
  }

  public String depthString(IKJacobianSolver s) {
    int d = s.MaxDepth();
    // If 0 or less, the solve depth is unlimited
    return str(d) + ((d <= 0) ? " (unlimited)" : "");
  }

  // Begins typing and disables input to camera
  void StartTyping(String str) {
    if (typing) { EndTyping(); }
    cam.setActive(false);
    text = str;
    typing = true;
  }

  // Re-enables camrea and returns the typed text
  String EndTyping() {
    cam.setActive(true);
    typing = false;
    return text;
  }

  void checkTyping() {
    if (!typing) {
      if (waitingForSave && text.length() > 0) {
        if (!SaveJoints(joints, text)) {
          Message("Could not save to " + text, UI_ERROR, 2000);
        } else {
          Message("Saved to " + text, UI_SUCCESS, 2000);
        }
        waitingForSave = false;
      }

      if (waitingForLoad && text.length() > 0) {
        // Clears the current joints, solvers and targets
        ArrayList<IKJoint> js = new ArrayList<IKJoint>();
        targets = new ArrayList<SimpleMatrix>();
        solvers = new ArrayList<IKJacobianSolver>();
        selected = 0;
        // Loads new joints
        if (!LoadJoints(js, text)) {
          Message("Could not load " + text, UI_ERROR, 2000);
        } else {
          joints = js;
          Message("Loaded " + text, UI_SUCCESS, 2000);
        }
        waitingForLoad = false;
      }
    }
  }

  // Finds the first joint with name 'name' in the array
  // If two joints use the same name, it is unreliable
  public IKJoint FindJoint(ArrayList<IKJoint> js, String name) {
    for (int i = 0; i < js.size(); i++) {
      // Uses linear search, so not optimal
      if (js.get(i).name.equals(name)) {
        return js.get(i);
      }
    }
    return null;
  }

  // Tries to find the solver associated with the passed joint
  int FindSolverIndex(IKJoint j) {
    for (int i = 0; i < solvers.size(); i++) {
      if (solvers.get(i).endJoint == j) { return i; }
    }
    return -1;
  }

  // Returns whether it succeeded or not
  boolean AddSolver(IKJoint j) {
    for (int i = 0; i < solvers.size(); i++) {
      if (solvers.get(i).endJoint == j) { return false; }
    }
    SimpleMatrix target = j.WorldEnd();
    targets.add(target);
    solvers.add(new IKJacobianSolver(j, target));
    return true;
  }

  // Returns whether it succeeded or not
  boolean RemoveSolver(IKJoint j) {
    int solverIndex = FindSolverIndex(j);

    if (solverIndex < 0) { return false; }
    solvers.get(solverIndex).ResetChain();
    targets.remove(solverIndex);
    solvers.remove(solverIndex);
    return true;
  }

  // This method gets called every frame by the Application
  @Override
  public void draw() {
    background(clearColor);

    // Check whether the user finished typing
    checkTyping();

    if (!pause) {
      // Do 50 iterations for each solver, alternating between them
      for (int i = 0; i < 50; i++) {
        for(int k = 0; k < solvers.size(); k++) {
          solvers.get(k).Iterate();
        }
      }
    }

    // Set up lighting for the scene
    ambientLight(red(clearColor), green(clearColor), blue(clearColor));
    directionalLight(255, 255, 255, -0.5, -1, 2);

    drawAxes(100, true);

    // Draw a crosshair for each target
    strokeWeight(1);
    for (int i = 0; i < targets.size() && !hideTargets; i++) {
      boolean isSelected = solvers.get(i).endJoint == joints.get(selected);
      if (isSelected) { stroke(255, 255, 0); } else { stroke(255); }
      drawPoint(
        (float)targets.get(i).get(0, 0),
        (float)targets.get(i).get(1, 0),
        (float)targets.get(i).get(2, 0)
      );
    }

    // Draw bones
    int si = FindSolverIndex(joints.get(selected));
    IKJacobianSolver s = si >= 0 ? solvers.get(si) : null;
    for (int i = joints.size() - 1; i >= 0; i--) {
      pushMatrix();

      IKJoint j = joints.get(i);

      // Move to joint's local co-ordinate space to simplify drawing
      PMatrix3D mat = MatToPMat(j.GetTransform());
      applyMatrix(mat);

      fill(255);
      stroke(0);

      // Highlight selected
      if (i == selected) {
        fill(255, 255, 0);
        stroke(255);
      } else if (s != null) {
        // Highlight joints affected by solver
        int depth = 0;
        for (
          IKJoint jnt = s.endJoint;
          (depth < s.MaxDepth() || s.MaxDepth() <= 0) && jnt != null;
          jnt = jnt.parent, depth++)
        {
          if (jnt == j) {
            fill(0, 255, 0);
            break;
          }
        }
      }

      strokeWeight(1);
      drawBone(j);

      // Return to world co-ordinates
      popMatrix();

      // Drawing a line between origin and joint start helps
      // visualize the relationship between translated joints
      double t = Math.abs(j.translation.get(0, 0)) +
                 Math.abs(j.translation.get(1, 0)) +
                 Math.abs(j.translation.get(2, 0));

      if (t != 0) {
        drawLine(
          j.WorldStart(),
          j.parent != null ? j.parent.WorldEnd() : new SimpleMatrix(3, 1)
        );
      }

      // IKJoint j = solvers.get(solver).endJoint;
      // selectedEnd = WorldToScreen(MatToPVec(j.WorldEnd()));
      // selectedStart = WorldToScreen(MatToPVec(j.WorldStart()));
    }
  };

  @Override
  public void draw2D() {
    drawJointInfo();
    drawKeyHints();

    // Draws text prompt on top if user is typing
    if (typing) {
      pushStyle();
      noStroke();
      fill(0, 0, 0, 192);
      rect(0, 0, width, height);
      fill(255);
      textAlign(CENTER, CENTER);
      if (waitingForSave || waitingForLoad) {
        setFont(UI_BOLD, UI_FONTSIZE_LARGE);
        text(
          (waitingForSave ? "SAVE" : "LOAD") + " JOINTS",
          width / 2, height / 2 - UI_FONTSIZE_LARGE * 2
        );
        setFont(UI_BOLD, UI_FONTSIZE_MEDIUM);
        text("File name:", width / 2, height / 2 - UI_FONTSIZE_LARGE);
        setFont(UI_REGULAR, UI_FONTSIZE_MEDIUM);
        text(text, width / 2, height / 2);
      }
      popStyle();
    }
  }

  @Override
  public String getTitle() {
    return "InteractiveIK";
  }

  @Override
  public String getDescription() {
    return "This program allows you to interact with the Inverse Kinematics" +
           " system I developed for my NEA project";
  }

  @Override
  public boolean keyPressed() {
    // Handle input while typing
    if (typing) {
      if (key == BACKSPACE) { text = text.substring(0,max(text.length()-1,0)); }
      if (key == ENTER || key == RETURN) { EndTyping(); }
      return true;
    }

    char keyLower = Character.toLowerCase(key);

    // Change selected joint
    if(key == '+') { selected = constrain(selected + 1, 0, joints.size() - 1); }
    if(key == '-') { selected = constrain(selected - 1, 0, joints.size() - 1); }

    // Change the axis the target is moved on
    if(keyLower == 'x') { axis = ROT_X; Message("Move X", UI_NEUTRAL, 500); }
    if(keyLower == 'y') { axis = ROT_Y; Message("Move Y", UI_NEUTRAL, 500); }
    if(keyLower == 'z') { axis = ROT_Z; Message("Move Z", UI_NEUTRAL, 500); }

    // Add a solver for the selected joint
    if(keyLower == 'a') {
      IKJoint j = joints.get(selected);
      if (AddSolver(j)) {
        Message(
          String.format("Solver added for '%s'", j.name),
          UI_SUCCESS, 2000);
      } else {
        Message(
          String.format("'%s' already has a solver associated with it", j.name),
          UI_ERROR, 2000);
      }
      return true;
    }

    // Remove the solver associated with the selected joint
    if(keyLower == 'd') {
      IKJoint j = joints.get(selected);
      if (RemoveSolver(j)) {
        Message(
          String.format("Solver removed from '%s'", j.name),
          UI_SUCCESS, 2000);
      } else {
        Message(
          String.format("No solver to remove from '%s'", j.name),
          UI_ERROR, 2000);
      }
      return true;
    }

    // Toggle the solver method used (inverse/transpose)
    if (keyLower == 'e') {
      int si = FindSolverIndex(joints.get(selected));
      if (si >= 0) {
        boolean isEnabled = solvers.get(si).InverseMethodEnabled();
        solvers.get(si).InverseMethodEnabled(!isEnabled);
        Message(
          "Jacobian inverse method " + (isEnabled ? "disabled" : "enabled"),
          UI_NEUTRAL, 2000);
      } else {
        Message(
          "No solver associated with '" + joints.get(selected).name + "'",
          UI_NEUTRAL, 2000);
      }
      return true;
    }

    // Toggle continuous solving
    if (keyLower == 'c') {
      int si = FindSolverIndex(joints.get(selected));
      if (si >= 0) {
        boolean isEnabled = solvers.get(si).ContinuousEnabled();
        solvers.get(si).ContinuousEnabled(!isEnabled);
        Message(
          "Continuous solving " + (isEnabled ? "disabled" : "enabled"),
          UI_NEUTRAL, 2000);
      } else {
        Message(
          "No solver associated with '" + joints.get(selected).name + "'",
          UI_NEUTRAL, 2000);
      }
      return true;
    }

    // Perform a single iteration on the selected joint's solver
    if(keyLower == 'm') {
      int si = FindSolverIndex(joints.get(selected));
      if (si >= 0) {
        solvers.get(si).Iterate();
        Message(
          "Iteration performed for '" + joints.get(selected).name + "'",
          UI_SUCCESS, 2000);
      } else {
        Message(
          "No solver associated with '" + joints.get(selected).name + "'",
          UI_ERROR, 2000);
      }
      return true;
    }

    // Toggle key hints panel
    if (keyLower == 'k') { keyHints = !keyHints; return true; }

    // Toggle joint info panel
    if (keyLower == 'i') { jointInfo = !jointInfo; return true; }

    // Hide all targets (can't move them while hidden)
    if (keyLower == 'h') {
      hideTargets = !hideTargets;
      Message(
        "Targets " + (hideTargets ? "Hidden" : "Visible"),
        UI_NEUTRAL, 2000);
      return true;
    }

    // Toggle drawing local joint axes
    if (keyLower == 'b') {
      drawJointAxes = !drawJointAxes;
      Message(
        "Joint axes " + (!drawJointAxes ? "Hidden" : "Visible"),
        UI_NEUTRAL, 2000);
      return true;
    }

    // Pause/unpause solving each frame (only manual iteration)
    if (keyLower == ' ') {
      pause = !pause;
      Message("Solvers " + (pause ? "Paused" : "Unpaused"), UI_NEUTRAL, 2000);
      return true;
    }

    // Move the targets to the original joint positions
    if (keyLower == 'r') {
      if (solvers.size() > 0) {
        Message("Targets reset", UI_NEUTRAL, 2000);
        for (int i = 0; i < solvers.size(); i++) {
          solvers.get(i).ResetChain();
          SimpleMatrix end = solvers.get(i).endJoint.OriginalWorldEnd();
          targets.get(i).set(0, 0, end.get(0, 0));
          targets.get(i).set(1, 0, end.get(1, 0));
          targets.get(i).set(2, 0, end.get(2, 0));
          solvers.get(i).Target(targets.get(i));
        }
      } else {
        Message("No targets to reset", UI_NEUTRAL, 2000);
      }
      return true;
    }

    // Change solve depth of solver associated with selected joint
    if (keyCode == UP || keyCode == DOWN) {
      int si = FindSolverIndex(joints.get(selected));
      if (si >= 0) {
        IKJacobianSolver s = solvers.get(si);
        s.MaxDepth(max(s.MaxDepth() + (keyCode == UP ? 1 : -1), 0));
        Message("Solve depth set to " + depthString(s), UI_NEUTRAL, 2000);
      }
      return true;
    }

    // Input was not handled or not blocking default behaviour
    return false;
  }

  @Override
  public boolean keyReleased() { return false; }

  @Override
  public boolean keyTyped() {
    // Only valid characters are inserted into text prompt
    if (typing) {
      if (key != CODED) {
        text = text + key;
      }
      return true;
    }

    // If this check is performed in keyPressed, the same key gets inserted
    // into the text promt instantly. That is undesired behaviour
    char keyLower = Character.toLowerCase(key);
    if(keyLower == 's') { StartTyping(""); waitingForSave = true; }
    if(keyLower == 'l') { StartTyping(""); waitingForLoad = true; }

    return false;
  }

  @Override
  public boolean mouseDragged() {
    // Move target along selected axis
    if (mouseButton == RIGHT) {
      if (axis <= 2 && !hideTargets) {
        int targetIndex = -1;
        for (int i = 0; i < solvers.size(); i++) {
          if (solvers.get(i).endJoint == joints.get(selected)) {
            targetIndex = i; break;
          }
        }

        if (targetIndex < 0) { return false; }

        double currentValue = targets.get(targetIndex).get(axis, 0);
        double offset = (mouseX - pmouseX) * 0.01;
        targets.get(targetIndex).set(axis, 0, currentValue + offset);
        solvers.get(targetIndex).Target(targets.get(targetIndex));
      }
    }

    return false;
  }

  @Override
  public boolean mousePressed() {
    // Camera uses both mouse buttons for input, so we need to
    // disable it to stop the view rotating while moving targets
    if (mouseButton == RIGHT) {
      cam.setActive(false);
    }
    return false;
  }

  @Override
  public boolean mouseReleased() {
    // Re-enable the camera when finished moving targets
    if (mouseButton == RIGHT) {
      cam.setActive(true);
    }
    return false;
  }
}
