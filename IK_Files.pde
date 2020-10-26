// -----------------------------------------------------------------------------
//                   Saving and loading joint configurations
// -----------------------------------------------------------------------------

import java.util.Map;

// Loads a set of joints from a file into the passed array
boolean LoadJoints(ArrayList<IKJoint> out, String filename) {
  BufferedReader r = createReader("saved/" + filename);
  ArrayList<String> js = new ArrayList<String>();
  try {
    for (String line = r.readLine(); line != null; line = r.readLine()) {
      js.add(line);
    }
    
    int[] parents;
    parents = new int[js.size()];
    for (int i = 0; i < js.size(); i++) {
      String[] data = js.get(i).split(",");
      if (data.length > 19) { return false; }
      // NAME, PARENT, LENGTH, SCALE
      IKJoint j = new IKJoint(Double.parseDouble(data[2]));
      j.name = data[0];
      j.scale = Double.parseDouble(data[3]);
      // ROTATION X, Y, Z
      j.rotation.set(0, 0, Double.parseDouble(data[4]));
      j.rotation.set(1, 0, Double.parseDouble(data[5]));
      j.rotation.set(2, 0, Double.parseDouble(data[6]));
      j.originalRotation = j.rotation.copy();
      // TRANSLATION X, Y, Z
      j.translation.set(0, 0, Double.parseDouble(data[7]));
      j.translation.set(1, 0, Double.parseDouble(data[8]));
      j.translation.set(2, 0, Double.parseDouble(data[9]));
      // LIMIT X, Y, Z
      j.limit[0] = boolean(data[10]);
      j.limit[1] = boolean(data[11]);
      j.limit[2] = boolean(data[12]);
      // LIMIT X MIN, MAX
      j.limits.set(0, 0, Double.parseDouble(data[13]));
      j.limits.set(0, 1, Double.parseDouble(data[14]));
      // LIMIT Y MIN, MAX
      j.limits.set(1, 0, Double.parseDouble(data[15]));
      j.limits.set(1, 1, Double.parseDouble(data[16]));
      // LIMIT Z MIN, MAX
      j.limits.set(2, 0, Double.parseDouble(data[17]));
      j.limits.set(2, 1, Double.parseDouble(data[18]));
      // PARENT INDEX
      parents[i] = Integer.parseInt(data[1]);
      out.add(j);
    }
  
    // Find and set parents
    for (int i = 0; i < out.size(); i++) {
      if (parents[i] < 0) { continue; }
      out.get(i).SetParent(out.get(parents[i]));
    }
  
    return true;
  } catch (Exception e) {
    return false;
  }
}

// Saves a set of joints as plain text
boolean SaveJoints(ArrayList<IKJoint> in, String filename) {
  PrintWriter w = createWriter("saved/" + filename);
  for (int i = 0; i < in.size(); i++) {
    IKJoint j = in.get(i);
    if(i != 0) { w.write("\n"); }
    // NAME, PARENT, LENGTH, SCALE
    w.write(String.format(
      "%s,%d,%g,%g,",
      j.name, in.indexOf(j.parent), j.length, j.scale
    ));
    // ROTATION X, Y, Z
    w.write(String.format(
      "%g,%g,%g,",
      j.rotation.get(0, 0), j.rotation.get(1, 0), j.rotation.get(2, 0)
    ));
    // TRANSLATION X, Y, Z
    w.write(String.format(
      "%g,%g,%g,",
      j.translation.get(0, 0), j.translation.get(1, 0), j.translation.get(2, 0)
    ));
    // LIMIT X, Y, Z
    w.write(String.format("%b,%b,%b,", j.limit[0], j.limit[0], j.limit[0]));
    // LIMIT X MIN, MAX
    w.write(String.format("%g,%g,", j.limits.get(0, 0), j.limits.get(0, 1)));
    // LIMIT Y MIN, MAX
    w.write(String.format("%g,%g,", j.limits.get(1, 0), j.limits.get(1, 1)));
    // LIMIT Z MIN, MAX
    w.write(String.format("%g,%g", j.limits.get(2, 0), j.limits.get(2, 1)));
  }
  w.flush();
  w.close();
  return true;
}

// DEPRECATED FUNCTION
// Keeping it for backup if I happen to delete the saved file
void CreateSkeleton(ArrayList<IKJoint> out) {
  IKJoint j;

  class Bone {
    public String name;
    public int parent;
    public Bone(String name, int parent) {
      this.name = name;
      this.parent = parent;
    }
  }

  // How this works:
  // String:  Bone name
  // Integer: Parent index [-1 = last bone, less than -1 = no parent]
  ArrayList<Bone> bones = new ArrayList<Bone>();
  bones.add(new Bone("Spine1", -2));
  bones.add(new Bone("Spine2", -1));
  bones.add(new Bone("Neck", -1));
  bones.add(new Bone("Head", -1));
  bones.add(new Bone("LShoulder", 1));
  bones.add(new Bone("LUpper", -1));
  bones.add(new Bone("LLower", -1));
  bones.add(new Bone("LHand", -1));
  bones.add(new Bone("RShoulder", 1));
  bones.add(new Bone("RLUpper", -1));
  bones.add(new Bone("RLower", -1));
  bones.add(new Bone("RHand", -1));
  bones.add(new Bone("LHip", -2));
  bones.add(new Bone("LThigh", -1));
  bones.add(new Bone("LShin", -1));
  bones.add(new Bone("LFoot", -1));
  bones.add(new Bone("RHip", -2));
  bones.add(new Bone("RThigh", -1));
  bones.add(new Bone("RShin", -1));
  bones.add(new Bone("RFoot", -1));
  
  // Create joints and populate the array
  for (int i = 0; i < bones.size(); i++) {
    j = new IKJoint(5);
    j.name = bones.get(i).name;
    j.rotation.set(0, 0, 0);
    j.rotation.set(1, 0, 0);
    j.rotation.set(2, 0, 0);
    // Set the parents according to above rules
    if (bones.get(i).parent >= 0) {
      j.SetParent(out.get(bones.get(i).parent));
    } else if (bones.get(i).parent == -1) {
      j.SetParent(out.get(out.size() - 1));
    }
    out.add(j);
  }
}
