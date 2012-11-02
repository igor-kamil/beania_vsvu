class Star {
  float x, y, z;
  float timer;
  boolean die = true;
  boolean nextShape = false;
  
  Star() {
    timer = maxLife;
  }
  
  Star(boolean death) {
    timer = maxLife;
    die = death;
  }
  
  void setValues(float xpos, float ypos, float zpos) {
    x = xpos;
    y = ypos;
    z = zpos;
  }
  
  void display(float starSize) {
    float starXSize = starSize - 1;
    float opacity = map(timer, 0, maxLife, 0, 255);
    stroke(255, opacity);

//test***
//    float distanceToFocalPlane = abs(z);
//    distanceToFocalPlane *= 1 / 40;
//    distanceToFocalPlane = constrain(distanceToFocalPlane, 1, 15);
//    strokeWeight(distanceToFocalPlane);
//    stroke(255, constrain(400 / distanceToFocalPlane, 1, 255));
//test***

    switch (symbol) {
      case 't':
        //triangle
        line(x - starSize, y + starSize, z,  x,  y - starSize, z);
        line(x,  y - starSize, z, x+ starSize, y + starSize, z);
        line(x+ starSize, y + starSize, z, x - starSize, y + starSize, z);
        break;
      case 'r':
        //triangle
        line(x - starSize, y - starSize, z,  x,  y + starSize, z);
        line(x,  y + starSize, z, x+ starSize, y - starSize, z);
        line(x+ starSize, y - starSize, z, x - starSize, y - starSize, z);
        break;
      default:
        //star
        line(x - starXSize, y + starSize, z, x + starXSize, y - starSize, z);
        line(x + starXSize, y + starSize, z, x - starXSize, y - starSize, z);
        line(x - starSize, y, z, x + starSize, y, z);
        break;
    }
    //dying
    if (die) timer -= 0.5;
  }
  
  void lineTo(float prevX, float prevY, float prevZ) {
    float opacity = map(timer, 0, maxLife, 0, 100);
    stroke(255,opacity); // white + alpha
    line(prevX, prevY, prevZ, x, y, z);
  }
  
  boolean dead() {
    if (timer <= 0.0) {
      return true;
    } else {
      return false;
    }
  }
  
  void applyFlockingForce() {
    float offset = 10;
    timer = maxLife;
//    x += noise(x / neighborhood + offset, y / neighborhood,  z / neighborhood) - 0.5;
//    y += noise(x / neighborhood, y / neighborhood + offset, z / neighborhood) - 0.5;
//    z += noise( x / neighborhood, y / neighborhood, z / neighborhood + offset) - 0.5;
    x += (noise(x,y,z) - 0.5) * offset;
    y += (noise(x,y,z) - 0.5) * offset;
    z += (noise(x,y,z) - 0.5) * offset;
//    x += noise(-1, 1);
//    y += noise(-1, 1);
//    z += noise(-1, 1);

    }


}
