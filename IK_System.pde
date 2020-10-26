// -----------------------------------------------------------------------------
//                The IK system itself, independent of graphics
// -----------------------------------------------------------------------------

import org.ejml.simple.*;
import java.util.ArrayList;

class IKJoint {
  public String name = "Joint";
  private IKJoint parent;
  private ArrayList<IKJoint> children;

  // Storing motion constraits for each DOF
  public SimpleMatrix limits;
  public boolean[] limit;

  // Need to store the original rotation so we can reset the chain
  public SimpleMatrix originalRotation;
  public SimpleMatrix rotation;
  public SimpleMatrix translation;
  public double scale;

  public double length;

  // Used when constructing the Jacobian Matrix
  private int dof = 3;
  private int paramIndex;

  private SimpleMatrix transform;

  public IKJoint(double length) {
    this.length = length;
    this.parent = null;
    this.children = new ArrayList<IKJoint>();
    this.scale = 1.0;
    this.rotation = new SimpleMatrix(3, 1);
    this.originalRotation = rotation.copy();
    this.translation = new SimpleMatrix(3, 1);

    this.limits = new SimpleMatrix(dof, 2);
    this.limit = new boolean[dof];
    for (int i = 0; i < dof; i++) { limit[i] = false; }
  }

  public boolean SetParent(IKJoint parent) {
    if (parent == this || this.parent == parent) { return false; }
    
    if (parent != null) {
      // Cycles are not allowed in the tree by definition
      for (IKJoint j = parent; j.parent != null; j = j.parent) {
        if (j.parent == this) { println("Cycle detected!"); return false; }
      }
      
      parent.AddChild(this);
    }
    
    // Make sure the joint is removed from its parent's children
    if (this.parent != null) {
      this.parent.RemoveChild(this);
    }


    // Finally set the parent
    this.parent = parent;
    return true;
  }

  private void AddChild(IKJoint child) {
    if (child.parent != this) { children.add(child); }
  }

  private void RemoveChild(IKJoint child) {
    if (child.parent == this) {
      children.remove(child);
      child.parent = null;  
    }
  }

  // Expose DOF
  public int GetDof() {
    return dof;
  }

  public double GetParameter(int n) {
    if (n < 3) {
      return rotation.get(n, 0);
    }
    return 0;
  }

  public void SetParameter(int n, double val) {
    if (n < 3) {
      // If constrained then clamp the value
      if (limit[n]) {
        val = clamp(val, limits.get(n, 0), limits.get(n, 1));
      }
      val %= Math.PI;
      rotation.set(n, 0, val);
    }
  }

  public SimpleMatrix WorldEnd() {
    SimpleMatrix point = new SimpleMatrix(4, 1);
    point.set(2, 0, length);
    point.set(3, 0, 1);
    point = GetTransform().mult(point);
    return point;
  }

  public SimpleMatrix WorldStart() {
    SimpleMatrix point = new SimpleMatrix(4, 1);
    point.set(3, 0, 1);
    point = GetTransform().mult(point);
    return point;
  }

  public SimpleMatrix GetTransform() {
    transform = SimpleMatrix.identity(4);

    // If the joint has a parent we need to apply it's transform first
    if (parent != null) {
      transform = transform.mult(parent.GetTransform());
      transform = transform.mult(CreateTranslationMatrix(0, 0, parent.length));
    }

    // Transform order: Scale -> Rotate -> Translate
    transform = transform.mult(CreateTranslationMatrix(translation));
    transform = transform.mult(CreateRotationMatrix(rotation));
    transform = transform.mult(CreateScaleMatrix(scale));

    return transform;
  }

  // Same as WorldEnd, but when in original pose
  public SimpleMatrix OriginalWorldEnd() {
    SimpleMatrix point = new SimpleMatrix(4, 1);
    point.set(2, 0, length);
    point.set(3, 0, 1);
    point = GetOriginalTransform().mult(point);
    return point;
  }

  // Same as WorldStart, but when in original pose
  public SimpleMatrix OriginalWorldStart() {
    SimpleMatrix point = new SimpleMatrix(4, 1);
    point.set(3, 0, 1);
    point = GetOriginalTransform().mult(point);
    return point;
  }

  // Same as GetTransform, but when in original pose
  public SimpleMatrix GetOriginalTransform() {
    transform = SimpleMatrix.identity(4);

    if (parent != null) {
      transform = transform.mult(parent.GetOriginalTransform());
      transform = transform.mult(CreateTranslationMatrix(0, 0, parent.length));
    }

    transform = transform.mult(CreateTranslationMatrix(translation));
    transform = transform.mult(CreateRotationMatrix(originalRotation));
    transform = transform.mult(CreateScaleMatrix(scale));

    return transform;
  }
}

class IKJacobianSolver {
  // The end joint we are trying to solve for
  public IKJoint endJoint;
  private SimpleMatrix target;

  private SimpleMatrix jacobian;
  private SimpleMatrix params;

  private boolean inverseMethod = false;
  private double error = 0;
  private double lastError = 0;

  // The number of iterations performed since the last target change
  // Also resets when continuous solving is disabled or chain is reset
  private int iterCount = 0;

  // Used to decide whether to start from the current
  // or original pose when the target is changed
  private boolean continuous = false;

  // Max depth to traverse through child joints when solving
  private int maxDepth;

  public double h = 0.00000000001;
  
  // If the error falls below this value, we stop iterating
  public double tolerance = 0.01;

  public IKJacobianSolver(IKJoint joint, SimpleMatrix target) {
    endJoint = joint;
    this.target = target.copy();
    maxDepth = 0;
    this.params = new SimpleMatrix(1, 1);
    this.jacobian = new SimpleMatrix(3, 1);
  }

  // Enables/disables inverse method (uses transpose by default)
  public void InverseMethodEnabled(boolean value) {
    if (value != this.inverseMethod && !continuous) {
      ResetChain();
    }
    this.inverseMethod = value;
  }

  public boolean InverseMethodEnabled() {
    return this.inverseMethod;
  }

  public int Iterations() {
    return this.iterCount;
  }

  public void ContinuousEnabled(boolean value) {
    continuous = value;
    if (!value) { ResetChain(); }
  }

  public boolean ContinuousEnabled() {
    return continuous;
  }

  // Returns the actual error between the end point an the target
  // When iterating, the square of this is used
  public double Error() {
    return dst(target, endJoint.WorldEnd());
  }

  public void Target(SimpleMatrix target) {
    if (!continuous) {
      ResetChain();
    }
    this.target = target.copy();
    iterCount = 0;
  }

  public SimpleMatrix Target() {
    return this.target.copy();
  }

  public void ResetChain() {
    for (IKJoint j = endJoint; j != null; j = j.parent) {
      j.rotation = j.originalRotation.copy();
    }
    iterCount = 0;
    
  }

  // Set the max number of joints involved including this joint
  // 0 or less means every joint in the chain is used
  public void MaxDepth(int depth) {
    this.maxDepth = depth;
    if (!continuous) {
      ResetChain();
    }
  }
  public int MaxDepth() { return this.maxDepth; }

  public void Iterate() {
    // The end position before iteration, not the original pose
    SimpleMatrix originalEnd = endJoint.WorldEnd();

    // If we are within tolerance, or the error has
    // not improved then there is no need to iterate
    error = dstSqr(target, originalEnd);
    if (
      error == lastError ||
      error < tolerance * tolerance
    ) { return; }
    lastError = error;

    // For stability reasons, we need to make delta p smaller
    // smaller when using the transpose method
    float f = inverseMethod ? 1 : 0.0001;

    int depth = 0;
    int dof = 0;

    // Need to count total DOF of the chain
    for (IKJoint j = endJoint;
         j != null && (maxDepth <= 0 || depth < maxDepth);
         j = j.parent, depth++)
    {
      j.paramIndex = dof;
      dof += j.GetDof();
    }

    jacobian = new SimpleMatrix(3, dof);
    params = new SimpleMatrix(dof, 1);

    SimpleMatrix end = originalEnd.copy();

    depth = 0;

    // Calculating the derivatives of each joint
    for (IKJoint j = endJoint;
         j != null && (maxDepth <= 0 || depth < maxDepth);
         j = j.parent, depth++)
    {
      for (int i = 0; i < j.GetDof(); i++) {
        params.set(j.paramIndex + i, 0, j.GetParameter(i));
        j.SetParameter(i, j.GetParameter(i) + h);
        end = endJoint.WorldEnd();
        j.SetParameter(i, params.get(j.paramIndex + i, 0));
        // Populate the Jacobian
        jacobian.set(0, j.paramIndex+i, (end.get(0,0)-originalEnd.get(0, 0))/h);
        jacobian.set(1, j.paramIndex+i, (end.get(1,0)-originalEnd.get(1, 0))/h);
        jacobian.set(2, j.paramIndex+i, (end.get(2,0)-originalEnd.get(2, 0))/h);
      }
    }

    // We multiply this with the Inverse to get the new parameters
    SimpleMatrix endDelta = new SimpleMatrix(3, 1);
    endDelta.set(0, 0, (target.get(0, 0) - originalEnd.get(0, 0)) * f);
    endDelta.set(1, 0, (target.get(1, 0) - originalEnd.get(1, 0)) * f);
    endDelta.set(2, 0, (target.get(2, 0) - originalEnd.get(2, 0)) * f);

    SimpleMatrix paramDeltas;
    if (inverseMethod) {
      // J -> U x S x V Transpose
      SimpleSVD<SimpleMatrix> svd = jacobian.svd();
      SimpleMatrix S = svd.getW();
      int maxSize = min(S.numRows(), S.numCols());
      for (int i = 0; i < maxSize; i++) {
        if (S.get(i,i) != 0) { S.set(i, i, 1.0 / S.get(i,i)); }
      }
      // Inverse = V x S Inverse x U Transpose
      paramDeltas = svd.getV().mult(S.transpose()).mult(svd.getU().transpose());
    } else {
      // Inverse = J Transpose
      paramDeltas = jacobian.transpose();
    }

    // New prameters = Inverse x End Delta
    paramDeltas = paramDeltas.mult(endDelta);

    depth = 0;
    // Set parameters to the new values
    for (IKJoint j = endJoint;
         j != null && (maxDepth <= 0 || depth < maxDepth);
         j = j.parent, depth++)
    {
      for (int i = 0; i < j.GetDof(); i++) {
        j.SetParameter(i, j.GetParameter(i)+paramDeltas.get(j.paramIndex+i, 0));
      }
    }

    iterCount++;
  }
}
