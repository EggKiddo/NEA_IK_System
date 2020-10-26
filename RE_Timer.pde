// -----------------------------------------------------------------------------
//                       Simple timer class for graphics
// -----------------------------------------------------------------------------

// A very basic Timer class for UI and animation
// Not intended for use in time-critical situations
class Timer {
  private float startTime;
  private float duration;

  public Timer(float duration) {
    startTime = millis();
    this.duration = duration;
  }

  public boolean IsRunning() {
    return millis() < startTime + duration;
  }

  public float TimeLeft() {
    return constrain(duration - (millis() - startTime), 0, duration);
  }
}
