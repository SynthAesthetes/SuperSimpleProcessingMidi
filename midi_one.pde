import processing.sound.*;
import java.util.Set;
import java.util.HashSet;
import processing.sound.*;

Table csv;
ArrayList<Event> events = new ArrayList<Event>(); // Store events sorted by time
float lastProcessedMillis = 0; // Track the last processed millis
ArrayList<Circle> circles = new ArrayList<Circle>(); // ArrayList to store circles
PShape heart1;
ArrayList<Circle> hearts = new ArrayList<Circle>();// arraylist to store kick drum heart circles
color backgroundColor = 0;
SoundFile soundFile;
SoundFile kickFile;
SoundFile bassFile;

int nextEventIndex = 0; // Index to track the next event
float setupMillis = 0;
int filterLevel = 0;
int pitchBend = 0;
float pitchMovement = 0;
Waveform waveform;
Waveform kickform;
Waveform bassform;

FFT fft;
int bufferSize = 4096 * 4;
float[] samples = new float[bufferSize];
float[] kickSamples = new float[bufferSize];
float[] bassSamples = new float[bufferSize];

float[] adjustedSamples = new float[bufferSize]; // New array for adjusted samples
float[] samplesToVisualize = new float[bufferSize];
int bands = 256;
float[] spectrum = new float[bands];
//int radius = 400;
//int value = 0;
boolean increment = true;
Amplitude amp;
float inst_amp;


// Global variables to manage particle effect
boolean triggerParticleEffect = false;
float effectX, effectY;

PImage sprite;

int npartTotal = 10000;
int npartPerFrame = 25;
float speed = 1.0;
float gravity = 0.05;
float wind = -0.10;
float partSize = 20;

int partLifetime;
PVector positions[];
PVector velocities[];
int lifetimes[];

int fcount, lastm;
float frate;
int fint = 3;

color effectColor; // Add this line
color[] colors; // Add this line

ArrayList<Particle> particles = new ArrayList<Particle>();

void setup() {
  //size(800, 800); // Set the size of the canvas
  fullScreen(P3D);
  frameRate(60);



  sprite = loadImage("sprite.png");

  partLifetime = npartTotal / npartPerFrame;
  initPositions();
  initVelocities();
  initLifetimes();
  colors = new color[npartTotal];
  for (int n = 0; n < colors.length; n++) {
    colors[n] = color(255); // Default color
  }

  // Writing to the depth buffer is disabled to avoid rendering
  // artifacts due to the fact that the particles are semi-transparent
  // but not z-sorted.
  hint(DISABLE_DEPTH_MASK);

  heart1 = loadShape("heart1.svg"); // Load the heart SVG from the data folder

  // notes are basically in the c2 to c6 range for the melody / harmony

  csv = loadTable("ssm-2-std.csv", "csv");

  float ticksPerQuarterNote = 15360; // Pulses per quarter note (PPQ) from MIDI file header
  float tempo = 468749; // Microseconds per quarter note (120 beats per minute)  really ought to read this out of the midi file
  float microsecondsPerTick = tempo / ticksPerQuarterNote; // Calculate microseconds per tick
  println("MicrosecondsPerTick", microsecondsPerTick);

  int lowest_midi_note = 127;
  int highest_midi_note = 0;
  int highestPitchBend = -99999;
  int lowestPitchBend  =  99999;

  int beat = 0; // to keep track of which beat we're on

  // Iterate over each row in the csv
  for (TableRow row : csv.rows()) {
    String event = row.getString(2);
    int track = row.getInt(0);
    float tickTime = row.getFloat(1);
    int channel = row.getInt(3);
    int midiNote = row.getInt(4); // Extract MIDI note from the row
    if (event.equals("Note_on_c")) {
      float millisTime = convertTicksToMillis(tickTime, microsecondsPerTick);
      millisTime = millisTime + 50;
      if (track == 3) {
        if (midiNote > highest_midi_note) {
          highest_midi_note = midiNote;
        }
        if (midiNote < lowest_midi_note) {
          lowest_midi_note = midiNote;
        }
      }
      int velocity = row.getInt(5);

      events.add(new Event(track, millisTime, event, channel, midiNote, velocity)); // Store events with time and MIDI note
    } else if (event.equals("Note_off_c")) {  // Capture only Note_off events
      float millisTime = convertTicksToMillis(tickTime, microsecondsPerTick);
      millisTime = millisTime + 50;

      // Search for the most recent Note_on_c event in the `events` list
      for (int i = events.size() - 1; i >= 0; i--) {
        Event e = events.get(i);
        if (e.track == track && e.channel == channel && e.midiNote == midiNote && e.noteOffTime == -1) {
          // Found the matching Note_on event, set the noteOffTime
          e.noteOffTime = millisTime;
          // println("Found event matching track", track, "channel", channel, "note", midiNote, "set noteOffTime to ", millisTime, "giving duration", e.duration());
          break;
        }
      }
    } else if (event.equals("Pitch_bend_c")) {
      //3, 2666842, Pitch_bend_c, 0, 14249
      //3, 2667322, Pitch_bend_c, 0, 14136

      //Track, Time, Pitch_bend_c, Channel, Value
      //Send a pitch bend command of the specified Value to the given Channel.
      //The pitch bend Value is a 14 bit unsigned integer and hence must be in the inclusive range from 0 to 16383.
      //The value 8192 indicates no pitch bend; 0 the lowest pitch bend, and 16383 the highest.
      //The actual change in pitch these values produce is unspecified.
      float millisTime = convertTicksToMillis(tickTime, microsecondsPerTick);
      millisTime = millisTime ;
      int velocity = row.getInt(4);
      if (velocity > highestPitchBend) {
        highestPitchBend = velocity;
      }
      if (velocity < lowestPitchBend) {
        lowestPitchBend = velocity;
      }
      events.add(new Event(track, millisTime, event, channel, -1, velocity)); // Store events with time and MIDI note
    }



    if (event.equals("Control_c")) {

      float millisTime = convertTicksToMillis(tickTime, microsecondsPerTick);
      millisTime = millisTime + 50;
      //int channel = row.getInt(3);
      //int midiNote = row.getInt(4); // Extract MIDI note from the row
      if (track == 3) {
        if (midiNote > highest_midi_note) {
          highest_midi_note = midiNote;
        }
        if (midiNote < lowest_midi_note) {
          lowest_midi_note = midiNote;
        }
      }
      int velocity = row.getInt(5);

      events.add(new Event(track, millisTime, event, channel, midiNote, velocity)); // Store events with time and MIDI note
    }
  }

  println("Lowest Midi Note", lowest_midi_note, "Highest Midi Note", highest_midi_note);
  println("LowestPitchBend", lowestPitchBend, "HighestPitchBend", highestPitchBend);
  // Sort events by their time
  events.sort((a, b) -> Float.compare(a.tickTime, b.tickTime));

  soundFile = new SoundFile(this, "super-simple-midi-2.wav");

  kickFile = new SoundFile(this, "super-simple-midi-kick-only-1.wav");
  bassFile = new SoundFile(this, "super-simple-midi-bass-only-1.wav");


  // Create a Set to store unique combinations
  Set<String> uniqueCombinations = new HashSet<String>();

  // Iterate over the events ArrayList
  for (Event e : events) {
    // Create a unique identifier for each combination including midiNote
    String combination = e.track + " " + e.event + " " + e.channel + " " + e.midiNote;

    // Add the combination to the Set
    uniqueCombinations.add(combination);
  }

  // Print each unique combination
  for (String combination : uniqueCombinations) {
    println("Unique combination: " + combination);
  }

  //waveform = new Waveform(this, bufferSize);
  //waveform.input(soundFile);

  kickform = new Waveform(this, bufferSize);
  kickform.input(kickFile);

  bassform = new Waveform(this, bufferSize);
  bassform.input(bassFile);


  //fft = new FFT(this, bands);
  //fft.input(soundFile);
  amp = new Amplitude(this);
  amp.input(soundFile);
}










boolean somethingPlaying = false;


void draw() {
  //noStroke();
  textSize(24);

  //if (!soundFile.isPlaying() && millis() >= 6000.0 ) {
  //  println("Hit soundfile play");
  //  //soundFile.play();
  //  setupMillis = millis();
  //  somethingPlaying = true;
  //}

  if (!kickFile.isPlaying() && millis() >= 6000.0 ) {
    println("hit kickfile play");
    kickFile.play();
    setupMillis = millis();
    somethingPlaying = true;
  }

  if (!bassFile.isPlaying() && millis() >= 6000.0 ) {
    println("Hit bassfile play");
    bassFile.play();
    setupMillis = millis();
    somethingPlaying = true;
  }

  background(backgroundColor); // Clear the canvas
  //background(0); // Clear the canvas


  //waveform.analyze(samples);

  kickform.analyze(kickSamples);
  bassform.analyze(bassSamples);


  //fft.analyze(spectrum);
  //inst_amp = amp.analyze();






  //fill(0, 10);
  //rect(0, 0, width, height);
  float currentMillis = millis(); // Get the current millis
  //println("setupMillis", setupMillis, currentMillis);
  currentMillis = currentMillis - setupMillis;
  //println("setupMillis", setupMillis, currentMillis);
  if (nextEventIndex >= events.size()) {
    // we're out of stuff to do, let sketch wrap up
  } else {
    Event nextEvent = events.get(nextEventIndex);
    float timeToNextEvent = nextEvent.tickTime - currentMillis;
    //text("currentMillis: " + str(currentMillis), 10, 100);
    //text("nextEvent.tickTime: " + str(nextEvent.tickTime), 10, 120);
    //text("timeToNextEvent: " + str(timeToNextEvent), 10, 140);
    //text("nextEventIndex: " + str(nextEventIndex), 10, 160);
    //text("filterLevel:" + str(filterLevel), 180, 30);
  }

  int scrob = 1;
  // Process events up to the current time
  //boolean nindex = nextEventIndex < events.size();
  //boolean ticky = events.get(nextEventIndex).tickTime <= currentMillis;
  //println("nindex", nindex, "ticky", ticky, "somethingPlaying", somethingPlaying);
  //println("nextEventIndex", nextEventIndex, "events.size", events.size(), "currentMillis", currentMillis);
  while (nextEventIndex < events.size() && events.get(nextEventIndex).tickTime <= currentMillis && somethingPlaying) {
    Event event = events.get(nextEventIndex);
    //String nextInfo = "Note " + str(event.midiNote) + " " + "time " + str(event.tickTime);
    //text(nextInfo, 10, 160 + (scrob * 20));
    scrob = scrob + 1;

    float x = 0;
    float y = 0;
    
    //println("In here");


    if (event.track == 2) {
      if (event.midiNote == 36) {
        // do nothing, this is the kick
        // the circle class will draw it?
      } else if (event.midiNote == 37) {
        x = width * 1 / 4;
        y = height / 2;
        // another kick
      } else if (event.midiNote == 41) {
        // bells
        x = random(width);
        y = random(height);
        //x = width / 2;
        //y = height / 3 * 4;
      } else if (event.midiNote == 42) {
        // snare
        x = width * 3 / 4;
        y = height / 2;
      } else {
        x = random(width);
        y = random(height);
      }
    }

    if (event.track == 3) {
      // bass guitar
      //Lowest Midi Note 47 Highest Midi Note 88
      if (event.midiNote < 60) {
        x = map(event.midiNote, 47, 88, 0, width/2);
        y = map(event.midiNote, 47, 60, height, 0);
      } else {
        // if greater than middle c ?
        //        x = map(event.midiNote, 47, 88, width/2, width);
        x = (width * 3) / 4;
        y = map(event.midiNote, 60, 88, height, 0);
      }
      //y = height - ((event.midiNote / 127.0) * height);
    }

    if (event.event.equals("Note_on_c")) {
      if ((event.track == 2) && (event.midiNote == 36)) {
        // kick drum hits separate so i can draw them last on top of everything else
        Circle circle = new Circle(x, y, getColor(event.midiNote), event);
        hearts.add(circle);
      } else {
        Circle circle = new Circle(x, y, getColor(event.midiNote), event); // Create a new circle object with color based on the MIDI note
        circles.add(circle); // Add the circle to the ArrayList
      }
    } else if ((event.event.equals("Control_c")) && (event.midiNote == 74)) {
      // //  Track, Time, Control_c, Channel, Control_num, Value
      // //  Set the controller Control_num on the given Channel to the specified Value.
      // //  Control_num and Value must be in the inclusive range 0 to 127.
      // // The assignment of Control_num values to effects differs from instrument to instrument.
      // // The General MIDI specification defines the meaning of controllers 1 (modulation), 7 (volume), 10 (pan), 11 (expression), and 64 (sustain), but not all instruments and patches respond to these controllers.
      // // Instruments which support those capabilities usually assign reverberation to controller 91 and chorus to controller 93.
      // 74 is the filter i think control_num aka midiNote
      // 71 is the resonance?
      // // what i'm calling velocity is the value above
      filterLevel = event.velocity;
      //println("filterLevel", filterLevel);
      backgroundColor = int(map(event.velocity, 32, 120, 0, 255));  // actual range of values is basically 32 to 120
      // fade the background?
    } else if (event.event.equals("Pitch_bend_c")) {
      // 8192 is effectivly zero, so max is that times two
      // so range is from
      pitchBend = event.velocity;
      //println("pitchBend", pitchBend);
    }
    //println(event.midiNote);
    nextEventIndex++; // Move to the next event
  }

  pitchMovement = map(pitchBend, 8191, 16383, 0, 127);

  // Iterate over circles and draw them
  for (int i = circles.size() - 1; i >= 0; i--) {
    Circle circle = circles.get(i);
    circle.update(); // Update the circle (shrink)
    circle.display(); // Display the circle
    if (circle.radius <= 0) {
      circles.remove(i); // Remove the circle from the ArrayList if its radius is less than or equal to 0
    }
  }




  //noFill();
  //stroke(255, 0, 123);
  //strokeWeight(3);
  //beginShape();
  //for (int i = 0; i < samples.length; i+=16) {
  //  float x = map(i, 0, samples.length, 0, width);
  //  float y = height / 2 + samples[i] * height/2;
  //  vertex(x, y);
  //}
  //endShape();
  //noStroke();

  noFill();
  stroke(255, 0, 123);
  strokeWeight(3);
  beginShape();
  for (int i = 0; i < kickSamples.length; i+=16) {
    float x = map(i, 0, kickSamples.length, 0, width);
    float y = height / 4 + kickSamples[i] * height/4;
    vertex(x, y);
  }
  endShape();
  noStroke();

  noFill();
  stroke(0, 255, 103);
  strokeWeight(3);
  beginShape();
  for (int i = 0; i < bassSamples.length; i+=16) {
    float x = map(i, 0, bassSamples.length, 0, width);
    float y = (height * 3 / 4) + bassSamples[i] * height/4;
    vertex(x, y);
  }
  endShape();
  noStroke();


  //if (triggerParticleEffect) {
  //  // Set the particle emitter position
  //  for (int i = 0; i < npartPerFrame; i++) {
  //    int idx = (npartTotal - npartPerFrame) + i;
  //    positions[idx].x = effectX;
  //    positions[idx].y = effectY;

  //    float angle = random(0, TWO_PI);
  //    float s = random(0.5 * speed, 0.5 * speed);
  //    velocities[idx].x = s * cos(angle);
  //    velocities[idx].y = s * sin(angle);
  //    lifetimes[idx] = 0; // Reset lifetime for new particles
  //    colors[idx] = effectColor; // Assign the color
  //  }
  //  triggerParticleEffect = false; // Reset the trigger flag
  //}

  //for (int n = 0; n < npartTotal; n++) {
  //  lifetimes[n]++;
  //  if (lifetimes[n] >= partLifetime) {
  //    lifetimes[n] = 0;
  //    colors[n] = effectColor; // Assign the color
  //  }

  //  if (lifetimes[n] >= 0) {
  //    float opacity = 1.0 - float(lifetimes[n]) / partLifetime;

  //    if (lifetimes[n] == 0) {
  //      // Re-spawn dead particle
  //      positions[n].x = mouseX;
  //      positions[n].y = mouseY;

  //      float angle = random(0, TWO_PI);
  //      float s = random(0.5 * speed, 0.5 * speed);
  //      velocities[n].x = s * cos(angle);
  //      velocities[n].y = s * sin(angle);
  //    } else {
  //      positions[n].x += velocities[n].x;
  //      positions[n].y += velocities[n].y;

  //      velocities[n].x += wind;
  //      // velocities[n].y += gravity;
  //    }
  //    drawParticle(positions[n], opacity, colors[n]);
  //  }
  //}


  // Update and display particles
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    if (p.isAlive()) {
      p.display();
    } else {
      particles.remove(i);
    }
  }


  // TODO: Cool idea, have each note that plays on the right hand side, any note greater than midinote 60
  /// should have a comet trail coming off the left edge of the rect (or circle, or whatever) and have the comet trail be the
  // same color as the note







  // Iterate over hearts and draw them last so they're always on top of the rest of the stuff
  for (int i = hearts.size() - 1; i >= 0; i--) {
    Circle circle = hearts.get(i);
    circle.update(); // Update the circle (shrink)
    circle.display(); // Display the circle
    if (circle.radius <= 0) {
      hearts.remove(i); // Remove the circle from the ArrayList if its radius is less than or equal to 0
    }
  }
}

float convertTicksToMillis(float ticks, float microsecondsPerTick) {
  float microseconds = ticks * microsecondsPerTick;
  return microseconds / 1000; // Convert microseconds to milliseconds
}




color getColor(int midiNote) {
  // Map MIDI note to color
  // using the colors from https://chromatone.center/theory/color/names/

  switch (midiNote % 12) {
  case 0:
    return color(102, 204, 0); // Lime for C
  case 1:
    return color(0, 204, 0); // Green for C#
  case 2:
    return color(0, 204, 102); // Mint for D
  case 3:
    return color(0, 204, 204); // Cyan for D#
  case 4:
    return color(0, 102, 204); // Azure for E
  case 5:
    return color(0, 0, 204); // Blue for F
  case 6:
    return color(102, 0, 204); // Violet for F#
  case 7:
    return color(204, 0, 204); // Magenta for G
  case 8:
    return color(204, 0, 102); // Rose for G#
  case 9:
    return color(204, 0, 0); // Red for A
  case 10:
    return color(204, 102, 0); // Orange for A#
  case 11:
    return color(204, 204, 0); // Yellow for B
  default:
    return color(255); // White (fallback)
  }
}





// Function to lighten or darken a color based on filterLevel
color applyFilterLevel(color inputColor, int filterLevel) {
  // Map filterLevel from 0 to 127 to a brightness scale between 0.0 and 1.0
  float brightnessScale = map(filterLevel, 0, 127, 0.1, 1.0);

  // Extract RGB components from the input color
  float r = red(inputColor);
  float g = green(inputColor);
  float b = blue(inputColor);

  // Adjust each RGB component by the brightnessScale
  r = constrain(r * brightnessScale, 0, 255);
  g = constrain(g * brightnessScale, 0, 255);
  b = constrain(b * brightnessScale, 0, 255);

  // Return the new color with adjusted brightness
  return color(r, g, b);
}




void triggerParticleEffect(float x, float y, color c) {
  for (int i = 0; i < 12; i++) {
    Particle p = new Particle(x, y, c);
    particles.add(p);
  }
}




void drawParticle(PVector center, float opacity, color c) {
  beginShape(QUAD);
  noStroke();
  tint(c, opacity * 255);
  texture(sprite);
  normal(0, 0, 1);
  vertex(center.x - partSize/2, center.y - partSize/2, 0, 0);
  vertex(center.x + partSize/2, center.y - partSize/2, sprite.width, 0);
  vertex(center.x + partSize/2, center.y + partSize/2, sprite.width, sprite.height);
  vertex(center.x - partSize/2, center.y + partSize/2, 0, sprite.height);
  endShape();
}

void initPositions() {
  positions = new PVector[npartTotal];
  for (int n = 0; n < positions.length; n++) {
    positions[n] = new PVector();
  }
}

void initVelocities() {
  velocities = new PVector[npartTotal];
  for (int n = 0; n < velocities.length; n++) {
    velocities[n] = new PVector();
  }
}

void initLifetimes() {
  // Initializing particles with negative lifetimes so they are added
  // progressively into the screen during the first frames of the sketch
  lifetimes = new int[npartTotal];
  int t = -1;
  for (int n = 0; n < lifetimes.length; n++) {
    if (n % npartPerFrame == 0) {
      t++;
    }
    lifetimes[n] = -t;
  }
}
