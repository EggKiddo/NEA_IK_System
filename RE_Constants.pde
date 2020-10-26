// -----------------------------------------------------------------------------
//                     Constants used by graphics and input
// -----------------------------------------------------------------------------

import java.util.Map;

// Function key codes
final int F1  = 97;
final int F2  = 98;
final int F3  = 99;
final int F4  = 100;
final int F5  = 101;
final int F6  = 102;
final int F7  = 103;
final int F8  = 104;
final int F9  = 105;
final int F10 = 106;
final int F11 = 107;
final int F12 = 108;

// Colors used by messages
final color UI_SUCCESS = color(128, 255, 128);
final color UI_WARNING = color(255, 192, 64);
final color UI_ERROR = color(255, 64, 64);
final color UI_NEUTRAL = color(128, 192, 255);

// Pre-determined font sizes for consistency
final float UI_FONTSIZE_NORMAL = 13;
final float UI_FONTSIZE_MEDIUM = max(16, UI_FONTSIZE_NORMAL + 1);
final float UI_FONTSIZE_LARGE = max(24, UI_FONTSIZE_MEDIUM + 1);
final float UI_FONTSIZE_MAX = max(32, UI_FONTSIZE_LARGE + 1);
// Size names must make sense ^^^

// Note: worst way to load fonts but this is not the focus of this project
HashMap<Float, PFont> UI_BLACK = new HashMap<Float, PFont>();
HashMap<Float, PFont> UI_BOLD = new HashMap<Float, PFont>();
HashMap<Float, PFont> UI_MEDIUM = new HashMap<Float, PFont>();
HashMap<Float, PFont> UI_REGULAR = new HashMap<Float, PFont>();
HashMap<Float, PFont> UI_LIGHT = new HashMap<Float, PFont>();
HashMap<Float, PFont> UI_THIN = new HashMap<Float, PFont>();

// Loads the correct font file for each font variant
void loadFonts() {
  loadFontMap(UI_BLACK, "Montserrat-Black.ttf");
  loadFontMap(UI_BOLD, "Montserrat-Bold.ttf");
  loadFontMap(UI_MEDIUM, "Montserrat-Medium.ttf");
  loadFontMap(UI_REGULAR, "Montserrat-Regular.ttf");
  loadFontMap(UI_LIGHT, "Montserrat-Light.ttf");
  loadFontMap(UI_THIN, "Montserrat-Thin.ttf");
}

// Generates font atlas for each available font size
// (Processing does not allow vector fonts in 3D)
void loadFontMap(HashMap<Float, PFont> fontMap, String file) {
  fontMap.put(UI_FONTSIZE_NORMAL, createFont(file, UI_FONTSIZE_NORMAL));
  fontMap.put(UI_FONTSIZE_MEDIUM, createFont(file, UI_FONTSIZE_MEDIUM));
  fontMap.put(UI_FONTSIZE_LARGE, createFont(file, UI_FONTSIZE_LARGE));
  fontMap.put(UI_FONTSIZE_MAX, createFont(file, UI_FONTSIZE_MAX));
}

void setFont(HashMap<Float, PFont> fontMap, float size) {
  textFont(fontMap.get(size));
  // Must set it to the font size, otherwise lines
  // in text boxes would have large gaps between them
  textLeading(size);
}
