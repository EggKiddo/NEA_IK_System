// -----------------------------------------------------------------------------
//                   Maths functions for use by the IK system
// -----------------------------------------------------------------------------

final int ROT_X = 0;
final int ROT_Y = 1;
final int ROT_Z = 2;

// Create a complete XYZ rotation SimpleMatrix from angles
SimpleMatrix CreateRotationMatrix(double x, double y, double z) {
  SimpleMatrix mat = SimpleMatrix.identity(4);
  mat = mat.mult(CreateRotationMatrix(ROT_Z, z));
  mat = mat.mult(CreateRotationMatrix(ROT_Y, y));
  mat = mat.mult(CreateRotationMatrix(ROT_X, x));
  return mat;
}

SimpleMatrix CreateRotationMatrix(SimpleMatrix rotation) {
  return CreateRotationMatrix(
    rotation.get(0, 0),
    rotation.get(1, 0),
    rotation.get(2, 0)
  );
}

// Create rotation SimpleMatrix for single axis
SimpleMatrix CreateRotationMatrix(int axis, double angle) {
  double sin = Math.sin(angle);
  double cos = Math.cos(angle);
  SimpleMatrix mat = SimpleMatrix.identity(4);

  if (axis == ROT_X) {
    mat.set(1, 1, cos);
    mat.set(1, 2, sin);
    mat.set(2, 1, -sin);
    mat.set(2, 2, cos);
  }

  if (axis == ROT_Y) {
    mat.set(0, 0, cos);
    mat.set(0, 2, -sin);
    mat.set(2, 0, sin);
    mat.set(2, 2, cos);
  }

  if (axis == ROT_Z) {
    mat.set(0, 0, cos);
    mat.set(0, 1, sin);
    mat.set(1, 0, -sin);
    mat.set(1, 1, cos);
  }

  return mat;
}

// Create XYZ scale SimpleMatrix
SimpleMatrix CreateScaleMatrix(double x, double y, double z) {
  SimpleMatrix mat = SimpleMatrix.identity(4);
  mat.set(0, 0, x);
  mat.set(1, 1, y);
  mat.set(2, 2, z);
  return mat;
}

SimpleMatrix CreateScaleMatrix(SimpleMatrix scl) {
  return CreateScaleMatrix(scl.get(0, 0), scl.get(1, 0), scl.get(2, 0));
}

// Create uniform scale SimpleMatrix
SimpleMatrix CreateScaleMatrix(double s) {
  return CreateScaleMatrix(s, s, s);
}

// Create XYZ translation SimpleMatrix
SimpleMatrix CreateTranslationMatrix(double x, double y, double z) {
  SimpleMatrix mat = SimpleMatrix.identity(4);
  mat.set(0, 3, x);
  mat.set(1, 3, y);
  mat.set(2, 3, z);
  return mat;
}

SimpleMatrix CreateTranslationMatrix(SimpleMatrix trns) {
  return CreateTranslationMatrix(
    trns.get(0, 0),
    trns.get(1, 0),
    trns.get(2, 0)
  );
}

// Clamp double values to range min-max
double clamp(double val, double min, double max) {
  return Math.max(min, Math.min(val, max));
}

// Modified sigmoid function
float mapToOne(float value, float min, float max, float fact) {
  float a = (min + max) / 2.0;
  float b = fact * (float)Math.pow(Math.E, 3) / (max - min);
  float exp = (float)Math.pow(Math.E, b * (value - a));
  return exp / (exp + 1.0);
}

// Calculate squared distance between two points
double dstSqr(SimpleMatrix m1, SimpleMatrix m2) {
  double a = m2.get(0, 0) - m1.get(0, 0);
  double b = m2.get(1, 0) - m1.get(1, 0);
  double c = m2.get(2, 0) - m1.get(2, 0);

  return a * a + b * b + c * c;
}

// Calculate distance between two points
double dst(SimpleMatrix m1, SimpleMatrix m2) {
  return Math.sqrt(dstSqr(m1, m2));
}
