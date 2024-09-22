class Particle {
  PVector position;
  PVector velocity;
  float lifetime;
  float initialLifetime;
  color c;

  Particle(float x, float y, color c) {
    this.position = new PVector(x, y);
    float angle = random(TWO_PI);
    float s = random(0.5 * 1.0, 0.5 * 1.0);
    float speed = random(1.0);// random(1, 3); // Adjust speed as needed
    this.velocity = new PVector(cos(angle) * speed, sin(angle) * speed);
    this.lifetime = 260; // Particle lives for 60 frames
    this.initialLifetime = lifetime;
    this.c = c;
  }

  void update() {
    // Apply wind to the left
    float windStrength = -0.1; // Negative value for leftward wind
    velocity.x += windStrength;
    
    position.add(velocity);
    lifetime -= 1;
  }

  boolean isAlive() {
    return lifetime > 0;
  }

  void display() {
    float opacity = map(lifetime, 0, initialLifetime, 0, 255);
    tint(c, opacity);
    imageMode(CENTER);
    image(sprite, position.x, position.y);
  }
}
