// -----------------------------------------------------------------------------
//                         Various 2D elements to draw
// -----------------------------------------------------------------------------

// Connects two points on screen
//          _ p2
//         /
//    p1 _/
void horizontalConnect(float x1, float y1, float x2, float y2) {
  line(x1, y1, x1 + 10, y1);
  line(x1 + 10, y1, x2 - 10, y2);
  line(x2 - 10, y2, x2, y2);
}

void horizontalConnect(float x1, float y1, float x2, float y2, boolean flip) {
  if (x1 > x2 && flip) {
    x1 += x2; x2 = x1 - x2; x1 = x1 - x2;
    y1 += y2; y2 = y1 - y2; y1 = y1 - y2;
  }
  pushStyle();
  noFill();
  beginShape();
  vertex(x1, y1);
  vertex(x1 + 10, y1);
  vertex(x2 - 10, y2);
  vertex(x2, y2);
  endShape();
  popStyle();
}

// Connects two points on screen
//        p1
//        |
//       /
//      /
//     |
//    p2
void verticalConnect(float x1, float y1, float x2, float y2) {
  line(x1, y1, x1, y1 + 10);
  line(x1, y1 + 10, x2, y2 - 10);
  line(x2, y2 - 10, x2, y2);
}

void drawText(String text, float x, float y) {
  pushStyle();
  setFont(UI_REGULAR, UI_FONTSIZE_NORMAL);
  textAlign(LEFT, BASELINE);
  text(text, x, y);
  popStyle();
}

void drawText(String text, float x, float y,
              PFont font, int size, int alignH, int alignV)
{
  pushStyle();
  textFont(font);
  textSize(size);
  textAlign(alignH, alignV);
  text(text, x, y);
  setFont(UI_REGULAR, UI_FONTSIZE_NORMAL);
  textAlign(LEFT, BASELINE);
  popStyle();
}

// Draws the co-ordinate axes
void drawAxes(float size, boolean arrows) {
  float range = size / 2.0;

  pushStyle();
  stroke(255, 0, 0);
  float a = arrows ? 10 : 0;
  drawVector(new PVector(range * 2.0, 0, 0), new PVector(-range, 0, 0), 2, a);

  stroke(0, 255, 0);
  drawVector(new PVector(0, range * 2.0, 0), new PVector(0, -range, 0), 2, a);

  stroke(0, 0, 255);
  drawVector(new PVector(0, 0, range * 2.0), new PVector(0, 0, -range), 2, a);
  popStyle();
}

// Draws a grid along the specified planes
void drawGrid(int range, boolean XY, boolean XZ, boolean YZ) {
  drawGrid(range, 1, XY, XZ, YZ);
}

void drawGrid(int range, int steps, boolean XY, boolean XZ, boolean YZ) {
  strokeWeight(1);
  stroke(255, 255, 255, 16);
  // XY Plane
  if (XY) {
    for (int x = -range; x <= range; x+=steps) {
      line(x, range, 0, x, -range, 0);
      line(range, x, 0, -range, x, 0);
    }
  }

  // XZ Plane
  if (XZ) {
    for (int x = -range; x <= range; x+=steps) {
      line(x, 0, range, x, 0, -range);
      line(range, 0, x, -range, 0, x);
    }
  }

  // YZ Plane
  if (YZ) {
    for (int y = -range; y <= range; y+=steps) {
      line(0, y, range, 0, y, -range);
      line(0, range, y, 0, -range, y);
    }
  }
}

// Linearly interpolate between two vectors
PVector vectorLerp(PVector v1, PVector v2, float fact) {
  return new PVector(
    lerp(v1.x, v2.x, fact),
    lerp(v1.y, v2.y, fact),
    lerp(v1.z, v2.z, fact)
    );
}

// Draws a vector as an arrow
void drawVector(PVector vect) {
  drawVector(vect, new PVector(0, 0, 0), 1, 3);
}

void drawVector(PVector vect, float weight) {
  drawVector(vect, new PVector(0, 0, 0), weight, 3);
}

void drawVector(PVector vect, float weight, float tipSize) {
  drawVector(vect, new PVector(0, 0, 0), weight, tipSize);
}

void drawVector(PVector vect, PVector origin) {
  drawVector(vect, origin, 1);
}

void drawVector(PVector vect, PVector origin, float weight) {
  drawVector(vect, origin, weight, 3);
}

float dist(PVector p1, PVector p2) {
  return dist(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z);
}

void drawVector(PVector vect, PVector origin, float weight, float tipSize) {
    PVector end = origin.copy().add(vect);
    PVector end2D = WorldToScreen(end);
    PVector origin2D = WorldToScreen(origin);
    float fact = 1 - constrain(tipSize * weight / dist(end2D, origin2D), 0, 1);
    PVector tip = vectorLerp(origin, end, fact);
    //weight = 10.0 * weight / (float)cam.getDistance();
    beginShape(LINES);
      strokeWeight(weight);
      vertex(origin.x, origin.y, origin.z);
      vertex(tip.x, tip.y, tip.z);
      strokeWeight(weight * 3);
      vertex(tip.x, tip.y, tip.z);
      strokeWeight(0);
      vertex(end.x, end.y, end.z);
    endShape();
}

// Draws a crosshair at a 3D point
void drawPoint(float x, float y, float z) {
    line(x - 1, y, z, x + 1, y, z);
    line(x, y - 1, z, x, y + 1, z);
    line(x, y, z - 1, x, y, z + 1);
}

void drawPoint(PVector vec) {
  drawPoint(vec.x, vec.y, vec.z);
}

// Draws a pair of text on one line with a 'spacing' sized gap
void drawTextPair(String text1, String text2, float x, float y, float spacing) {
  text(text1, x, y);
  text(text2, x + spacing, y);
}

// Draws the frame rate, scene title, scene description and camera position
void showStats() {
  pushStyle();
  fill(0, 0, 0, 64);
  noStroke();
  rect(width - 160, 0, width, height);
  fpsGrapher.draw(fps);

  ListCoords l = new ListCoords(width - 144, 80, 20);
  fill(255);
  setFont(UI_MEDIUM, UI_FONTSIZE_NORMAL);
  text("FPS: ", l.x, l.current());
  setFont(UI_LIGHT, UI_FONTSIZE_NORMAL);
  text(str(frameRate), l.x + 32, l.next());
  setFont(UI_MEDIUM, UI_FONTSIZE_NORMAL);
  text("Title:", l.x, l.current());
  setFont(UI_LIGHT, UI_FONTSIZE_NORMAL);
  text(
    currentScene.getTitle(),
    l.x, l.current(),
    width - 16, l.y + l.ls * (l.row + 3)
  );
  l.skip(3);

  setFont(UI_MEDIUM, UI_FONTSIZE_NORMAL);
  text("Description:", l.x, l.current());
  setFont(UI_LIGHT, UI_FONTSIZE_NORMAL);
  text(
    currentScene.getDescription(),
    l.x, l.current(),
    width - 16, l.y + l.ls * (l.row + 7)
  );
  l.skip(9);

  /*
  float[] camPos = cam.getPosition();
  setFont(UI_MEDIUM, UI_FONTSIZE_NORMAL);
  text("Cam", x, y + ls * row++);
  setFont(UI_LIGHT, UI_FONTSIZE_NORMAL);
  text("X: " + str(camPos[0]), x, y + ls * row++);
  text("Y: " + str(camPos[1]), x, y + ls * row++);
  text("Z: " + str(camPos[2]), x, y + ls * row++);
  */
  popStyle();
}
