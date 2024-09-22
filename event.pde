// Event class to represent a MIDI event
class Event {
  int track;
  float tickTime; // Tick time of the event
  String event;
  int channel;
  int midiNote; // MIDI note of the event
  int velocity;
  float noteOffTime;

  Event(int track, float tickTime, String event, int channel, int midiNote, int velocity) {
    this.track = track;
    this.tickTime = tickTime;
    this.event = event;
    this.channel = channel;
    this.midiNote = midiNote;
    this.velocity = velocity;
    this.noteOffTime = -1;
  }


  // Calculate the duration of the note (noteOffTime - tickTime)
  float duration() {
    if (noteOffTime > 0) {
      return noteOffTime - tickTime; // Return the duration if noteOffTime is set
    } else {
      return 0; // Return 0 if the noteOffTime hasn't been set yet
    }
  }
}
