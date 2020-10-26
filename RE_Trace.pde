// -----------------------------------------------------------------------------
//             Classes for tracing 3D points and drawing the trace
// -----------------------------------------------------------------------------

// Class for keeping track of a 3D point, or 3 values
class TracedPoint {
  PVector position;
  ArrayList<PVector> pastPositions;
  int maxTracePoints;
  int traceIndex;
  color pointColor;
  float trailWidth;
  boolean connected = true;

  PVector maxCoordinates;
  PVector minCoordinates;

  public TracedPoint(PVector position, int maxSaved) {
      this.position = new PVector(position.x, position.y, position.z);
      pastPositions = new ArrayList<PVector>();
      maxTracePoints = maxSaved;
      traceIndex = 0;
      pointColor = color(128, 128, 128);
      trailWidth = 1;

      maxCoordinates = position.copy();
      minCoordinates = position.copy();
  }

  public PVector getPosition() {
    return position.copy();
  }

  public void setPosition(PVector newPosition) {
    position = new PVector(newPosition.x, newPosition.y, newPosition.z);
  }

  public void setColor(color pointColor) {
    this.pointColor = pointColor;
  }

  public void setTrailWidth(float newWidth) {
    trailWidth = newWidth;
  }

  public void setConnected(boolean value) { connected = value; };

  public void addTrace() {
    if (pastPositions.size() == maxTracePoints) {
      pastPositions.set(traceIndex, position.copy());
      traceIndex = (traceIndex + 1) % maxTracePoints;
    } else {
      pastPositions.add(position.copy());
    }

    maxCoordinates = maxComponents(position, maxCoordinates);
    minCoordinates = minComponents(position, maxCoordinates);

  }

  private PVector maxComponents(PVector v1, PVector v2) {
    return new PVector(max(v1.x, v2.x), max(v1.y, v2.y), max(v1.z, v2.z));
  }

  private PVector minComponents(PVector v1, PVector v2) {
    return new PVector(min(v1.x, v2.x), min(v1.y, v2.y), min(v1.z, v2.z));
  }

  public void clearTrace() {
    pastPositions = new ArrayList<PVector>();
    maxCoordinates = position.copy();
    minCoordinates = position.copy();
    traceIndex = 0;
  }

  // Draws a trail of the saved snapshots in 3D
  public void draw() {
    // The trail gets thinner and fainter towards the oldest points
    // To mitigate artifacts due to transparency depth sorting
    // should be enabled.
    hint(ENABLE_DEPTH_SORT);
    noFill();
    if (connected) { beginShape(); } else { beginShape(POINTS); }
    float mult;
    for (int i = 0; i < pastPositions.size(); i++) {
      int index = (i + traceIndex) % maxTracePoints;
      mult = map(i, 0, pastPositions.size() - 1, 0, 1);
      stroke(red(pointColor), green(pointColor), blue(pointColor), 255 * mult);
      strokeWeight(trailWidth * mult);
      vertex(
        pastPositions.get(index).x,
        pastPositions.get(index).y,
        pastPositions.get(index).z
      );
    }
    stroke(pointColor);
    vertex(position.x, position.y, position.z);
    endShape();
    point(position.x, position.y, position.z);

    // Depth sorting is expensive, so disable it when finished
    hint(DISABLE_DEPTH_SORT);
  }
}

// Class for visualizing a TracedPoint as a graph
class TraceGrapher  {
  private float x1, y1, x2, y2, rangeMin, rangeMax;
  private boolean autoMin, autoMax;
  private boolean advanced;
  private boolean drawX, drawY, drawZ;
  private color xColor, yColor, zColor;
  private String xLabel, yLabel, zLabel;

  public TraceGrapher(
    boolean advanced,
    float x1, float y1,
    float x2, float y2)
  {
      this.advanced = advanced;
      this.x1 = x1;
      this.y1 = y1;
      this.x2 = x2;
      this.y2 = y2;
      this.autoMin = true;
      this.autoMax = true;
      xLabel = "X";
      yLabel = "Y";
      zLabel = "Z";
      xColor = color(255, 0, 0);
      yColor = color(0, 255, 0);
      zColor = color(0, 0, 255);
      drawX = true;
      drawY = true;
      drawZ = true;
  }

  public TraceGrapher(
    boolean advanced,
    float x1, float y1,
    float x2, float y2,
    float min, float max)
  {
    this(advanced, x1, y1, x2, y2);
    this.rangeMin = min;
    this.rangeMax = max;
    this.autoMin = false;
    this.autoMin = false;
  }

  // Set which axes will get drawn
  public void setDrawXYZ(boolean drawX, boolean drawY, boolean drawZ) {
    this.drawX = drawX;
    this.drawY = drawY;
    this.drawZ = drawZ;
  }

  public void setDrawX(boolean draw) { this.drawX = draw; }
  public void setDrawY(boolean draw) { this.drawY = draw; }
  public void setDrawZ(boolean draw) { this.drawZ = draw; }

  // Set the labels for individual axes
  public void setXLabel(String label) {
    xLabel = label;
  }

  public void setYLabel(String label) {
    yLabel = label;
  }

  public void setZLabel(String label) {
    zLabel = label;
  }

  // Manually set displayed range
  public void setMin(float min) {
    this.rangeMin = min;
    autoMin = false;
  }

  public void setMax(float max) {
    this.rangeMax = max;
    autoMax = false;
  }

  public void setMinMax(float min, float max) {
    setMin(min);
    setMax(max);
  }

  // The range of values on the graph can be adjusted automatically
  // based on the lowest and highest value encountered.
  // If disabled, the manually set range is used
  public void setAutoMinMax(boolean autoMin, boolean autoMax) {
    this.autoMin = autoMin;
    this.autoMax = autoMax;
  }

  private float maxComponent(PVector v) {
    return max(v.x, v.y, v.z);
  }

  private float minComponent(PVector v) {
    return min(v.x, v.y, v.z);
  }


  public void draw(TracedPoint tp) {

    if (tp.pastPositions.size() == 0) { return; }

    // Calculate min and max range
    float max = autoMax ? maxComponent(tp.maxCoordinates) * 1.1 : rangeMax;
    float min = autoMin ? minComponent(tp.minCoordinates) * 1.1 : rangeMin;

    // Calculate mid Y coordinate and zero line coordinate
    float zeroY = map(0, min, max, y2, y1);
    float middleY = (y1 + y2) / 2.0;

    // Make sure (x1, y1) is top-left corner, (x2, y2) is bottom-right corner
    float temp = x1;
    x1 = min(x1, x2);
    x2 = max(temp, x2);
    temp = y1;
    y1 = min(y1, y2);
    y2 = max(temp, y2);

    // Prepare drawing background layer
    rectMode(CORNERS);
    noStroke();
    fill(255, 255, 255, 20);
    rect(x1, y1, x2, y2);

    // Draw zero line
    if (y1 <= zeroY && zeroY <= y2) {
      stroke(255);
      strokeWeight(1);
      line(x1, zeroY, x2, zeroY);
      noStroke();
    }

    // If not enough data, stop here
    if (tp.pastPositions.size() <= 1) { return; }

    // Plot X, Y and Z on main graph
    float y;
    strokeWeight(1);

    if (drawX) {
      noFill();
      stroke(xColor);
      beginShape();
      for (int i = 0; i < tp.pastPositions.size(); i++) {
        vertex(
          map(i, 0, tp.maxTracePoints - 1, x1, x2),
          map(
            tp.pastPositions.get((i + tp.traceIndex) % tp.maxTracePoints).x,
            min, max, y2, y1)
        );
      }
      endShape();
    }

    if (drawY) {
      noFill();
      stroke(yColor);
      beginShape();
      for (int i = 0; i < tp.pastPositions.size(); i++) {
        vertex(
          map(i, 0, tp.maxTracePoints - 1, x1, x2),
          map(
            tp.pastPositions.get((i + tp.traceIndex) % tp.maxTracePoints).y,
            min, max, y2, y1)
        );
      }
      endShape();
    }

    if (drawZ) {
      noFill();
      stroke(zColor);
      beginShape();
      for (int i = 0; i < tp.pastPositions.size(); i++) {
        vertex(
          map(i, 0, tp.maxTracePoints - 1, x1, x2),
          map(tp.pastPositions.get((i + tp.traceIndex) % tp.maxTracePoints).z,
          min, max, y2, y1)
        );
      }
      endShape();
    }

    // Draw advanced if enabled
    if (advanced) {
      if ((x1 <= mouseX && mouseX <= x2) && (y1 <= mouseY && mouseY <= y2)) {

        float halfZoom = 30;

        float clampedX = constrain(mouseX, x1 + halfZoom, x2 - halfZoom);
        float zoomLeft = clampedX - halfZoom;
        float zoomRight = clampedX + halfZoom;
        float zx1 = x1;
        float zy1 = 2.0 * y1 - y2 - 50;
        float zx2 = x2;
        float zy2 = y1 - 50;
        float zZeroY = map(0, min, max, zy2, zy1);
        float zMiddleY = (zy1 + zy2) / 2.0;

        noStroke();
        fill(255, 255, 255, 20);
        rect(zoomLeft, y1, zoomRight, y2);
        rect(x1, 2.0 * y1 - y2 - 50, x2, y1 - 50);

        if (zy1 <= zZeroY && zZeroY <= zy2) {
          stroke(255);
          strokeWeight(1);
          line(x1, zZeroY, x2, zZeroY);
        }

        stroke(255);
        verticalConnect(x1, y1 - 40, zoomLeft, y1 - 10);
        verticalConnect(x2, y1 - 40, zoomRight, y1 - 10);

        int minIndex = max(
          floor(map(zoomLeft, x1, x2, 0, tp.maxTracePoints - 1)), 0);
        int maxIndex = min(
          ceil(map(zoomRight, x1, x2, 0, tp.maxTracePoints - 1)),
          tp.pastPositions.size() - 1
        );

        if (minIndex <= tp.pastPositions.size()) {
          if (drawX){
            noFill();
            stroke(xColor);
            beginShape();
            for (int i = minIndex; i <= maxIndex; i++) {
              vertex(
                map(
                  map(i, 0, tp.maxTracePoints - 1, x1, x2),
                  zoomLeft, zoomRight, zx1, zx2),
                map(
                  tp.pastPositions.get((i+tp.traceIndex) % tp.maxTracePoints).x,
                  min, max, zy2, zy1)
              );
            }
            endShape();
          }

          if (drawY) {
            stroke(yColor);
            beginShape();
            for (int i = minIndex; i <= maxIndex; i++) {
              vertex(
                map(
                  map(i, 0, tp.maxTracePoints - 1, x1, x2),
                  zoomLeft, zoomRight, zx1, zx2),
                map(
                  tp.pastPositions.get((i+tp.traceIndex) % tp.maxTracePoints).y,
                  min, max, zy2, zy1)
              );
            }
            endShape();
          }

          if (drawZ) {
            stroke(zColor);
            beginShape();
            for (int i = minIndex; i <= maxIndex; i++) {
              vertex(
                map(
                  map(i, 0, tp.maxTracePoints - 1, x1, x2),
                  zoomLeft, zoomRight, zx1, zx2),
                map(
                  tp.pastPositions.get((i+tp.traceIndex) % tp.maxTracePoints).z,
                  min, max, zy2, zy1)
              );
            }
            endShape();
          }
        }
      }

      // Draw labels and values
      textAlign(LEFT, CENTER);
      int i = (tp.pastPositions.size() - 1 + tp.traceIndex) % tp.maxTracePoints;
      PVector p = tp.pastPositions.get(i);
      y = map(p.x, min, max, y2, y1);
      stroke(xColor);
      horizontalConnect(x2 + 10, y, x2 + 50, middleY - 30);
      fill(xColor);
      drawText(xLabel + ": " + str(p.x), x2 + 60, middleY - 30);

      y = map(p.y, min, max, y2, y1);
      stroke(yColor);
      horizontalConnect(x2 + 10, y, x2 + 50, middleY);
      fill(yColor);
      drawText(yLabel + ": " + str(p.y), x2 + 60, middleY);

      y = map(p.z, min, max, y2, y1);
      stroke(zColor);
      horizontalConnect(x2 + 10, y, x2 + 50, middleY + 30);
      fill(zColor);
      drawText(zLabel + ": " + str(p.z), x2 + 60, middleY + 30);
    }
  }
}
