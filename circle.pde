// Circle class to represent a circle object
color white = color(255,255,255);
class Circle {
  float x, y; // Position of the circle
  float radius = 200; // Initial radius of the circle
  float radiusMover = 10;
  color circleColor; // Color of the circle
  Event event;

  Circle(float x, float y, color circleColor, Event event) {
    this.x = x;
    this.y = y;
    this.circleColor = circleColor;
    this.event = event;
    if ((this.event.track == 2) && (this.event.midiNote == 36)) {
      this.radius = 750;
      this.radiusMover = this.radius * 0.025;
    } else {
      //  this is not that interesting, circles are too small... //this.radius = 300 * (event.velocity / 127.0);
    }

    if ((this.event.track == 3) && (this.event.midiNote < 60)) {
      radius = ((this.event.duration() / 1000.0) * frameRate) * 5;
      radiusMover = 5;
    }
    if ((this.event.track == 3)&& (this.event.midiNote >= 60)) {
      radius = ((this.event.duration() / 1000.0) * frameRate) * 10;
      radiusMover = 5;
    }
  }

  // Update method to shrink the circle
  void update() {
    radius -= radiusMover; // Reduce the radius

  }

  // Display method to draw the circle
  void display() {
    //color fillColor = applyFilterLevel(circleColor, filterLevel);
    color fillColor = circleColor;
    fill(fillColor); // Set fill color to circleColor

    if (this.event.track == 2) {
      if (this.event.midiNote == 36) {
        // the kick, the heart
        pushMatrix();
        translate(width/2, height - height/2);
        shape(heart1, -radius / 2, -radius / 2, radius, radius); // Draw the heart at the center
        popMatrix();
        //triggerParticleEffect(width/2, height/2, fillColor);
      } else if (this.event.midiNote == 41) {
        triggerParticleEffect(this.x, this.y, white);
      } else {
        ellipse(x, y, radius * 2, radius * 2); // Draw the circle
      }
    }

    int lowestNote = 38;
    int highestNote = 88;
    float xnoteStep = width / (highestNote - lowestNote);
    float ynoteStep = height / (highestNote - 60); // with the arbitrary cutoff of 60 for left and right notes

    if ((this.event.track == 3)) {
      this.y = height / 2;
      if (this.event.midiNote < 60) {
        this.x =  map(this.event.midiNote, lowestNote, highestNote, 0 + xnoteStep, width - xnoteStep);
        this.x = this.x + (pitchMovement * 2);
        rectMode(CENTER);
        rect(x, y, xnoteStep + radius, height);
      } else {
        //this.x = map(this.event.midiNote, lowestNote, highestNote, (width / 2) - 200, width - noteStep);
        //this.y = map(this.event.midiNote, lowestNote, highestNote, height-noteStep, 0 + noteStep);
        //rect(x, y, noteStep + radius, height * (this.event.velocity / 127.0));
        rectMode(CORNER);



        this.x = (width * 7 / 12) + (pitchMovement * 2);
        this.y = map(this.event.midiNote, 60, highestNote, height - ynoteStep, 0 + ynoteStep) - (pitchMovement * 2);
        triggerParticleEffect(x,y + (0.5 * ynoteStep), fillColor);
        rect(x, y, ((width / 1.5) * (this.event.velocity / 127.0)) , ynoteStep + radius);
      }
    }

  } // end display
} // end class














// hiyo
