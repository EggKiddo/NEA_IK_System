// -----------------------------------------------------------------------------
//                    Class to help with drawing text lists
// -----------------------------------------------------------------------------

// This class is just for better readability in code
// when drawing multiple lines of text manually
class ListCoords {
  int row;
  float ls;
  float x;
  float y;

  // Takes the start x, y co-ordinates and the line spacing
  public ListCoords(float startX, float startY, float lineSpacing) {
    this.x = startX;
    this.y = startY;
    this.ls = lineSpacing;
    this.row = 0;
  }

  // Returns the y co-ordinate of the next empty line
  public float next() {
    float val = current();
    row++;
    return val;
  }

  // Returns the y co-ordinate of the current line
  public float current() {
    return y + row * ls;
  }

  // Skip n lines
  public void skip(int n) {
    row += n;
  }
}
