/***********************************************************************
 ------------------------------------------------------------------------
 for BEANIA_VSVU
 (c) 2012, Igor Rjabinin, Matej Fandl	
 ------------------------------------------------------------------------
 
 r         -> zobrazi v rohu aktualne FPS 
 1,2...0   -> prepinanie stavov: 1=kasiopea++, 2=lowii, 3=kasiopea--
 s         -> Show video
 b         -> blur pre smooth cut
 t         -> roTate on/off
 z         -> random z-axis on/off
 F         -> "wannabe" Flocking on/off
 

*************************************************************************/

import processing.video.*;
import processing.opengl.*;
import ddf.minim.*;
import ddf.minim.analysis.*;



/**************************** NASTAVENIA **********************************/

float maxLife = 150;
int triggerThreshold = 200;  // prah citlivosti na pohyb ( hodnoty 0 az 1 )

int channel = 0;                // midi channel
int knobX = 1;                  // knob id
int knobY = 2;                  // knob id
int knobI = 3;                  // knob id

int minWeight = 1;
int maxWeight = 7;
float changeSpeed = 0.6;

int lowii_state = 0; // available states - 0-w / 1-stars / 
int keyNumber;
float x = 0; // scale

char symbol = 's';


/**************************** GLOB. PREMENNE ***********************************/
ArrayList stars;

int numPixels;
Capture video;

float totalMovement;

PImage img;
PFont font;

float angleX = 0;
float angleY = 0;

int step = 3;

int maxBrightness;
float maxX; 
float maxY;

float neighborhood = 700;


/************************** BEATDETECT *********************************/

AudioInput song;
BeatDetect beat;
BeatListener bl;
Minim minim;

float kickSize, snareSize, hatSize;
WConstellation w;

/**************************** BOOLEAN **********************************/

boolean camera_on = true;     // vypnut/zapnut posielnie midi z kamery
boolean lock = false;  // po kliknuti zamkne az do mouseReleased()
boolean fullscreen = false; // zapinanie/vypinanie fullscreen
boolean show_fps = false;     // vypnut/zapnut zobrazovanie framerat-u
boolean knob = false;
boolean makeBlur = false;
boolean rotation = false;
boolean autoRotation = false;
boolean randZ = false;
boolean show_video = false;
boolean flocking = false;

/**************************** SETUP ***********************************/

void setup() {
  size(800, 600, P3D);
  frameRate(20);
  smooth();
  
  video = new Capture(this, width , height);
    video.settings();

//  video.settings();
  numPixels = video.width * video.height;

  img = createImage(video.width, video.height, RGB);

  background(0);
  
  stars = new ArrayList();
  
  // ***** BEAT DETECTION
  minim = new Minim(this);
  song = minim.getLineIn(Minim.STEREO, 512);
  beat = new BeatDetect(song.bufferSize(), song.sampleRate());
  beat.setSensitivity(300);
  kickSize = snareSize = hatSize = minWeight;
  bl = new BeatListener(beat, song);
  // **** / BEAT DETECTION
  
  w = new WConstellation();

}


void draw() {  
  if ( beat.isKick() ) kickSize = maxWeight;
  if ( beat.isSnare() ) snareSize = maxWeight;
  if ( beat.isHat() ) hatSize = maxWeight;
  
  if (autoRotation) {
    angleX +=kickSize;
    angleY +=snareSize;
  }

  if (makeBlur) {
    makeBlur();
  }
  else if (video.available()) {

    switch (lowii_state) {
      case 1: 
        w.display(x);
        x = x + 0.005;
        break;
      case 3: 
        w.display(x);
        x = x - 0.005;
        break;
       case 2:
       case 7:
       case 8:
       case 9:
       

    if (!makeBlur) {
      video.read(); // citaj novy snimok z kamery
      mirrorFrame(); // zrkadlovo prevrati obraz
     }
     
    background(0);
    if (show_video) image(img, 0, 0, width, height);

    findLightPosition();
    
    translate(width/2, height/2);
    
    if (rotation) {
      // Rotate around y and x axes
  //    rotateY(radians(mouseX));
  //    rotateX(radians(mouseY));
      angleX = mouseX;
      angleY = mouseY;
    }
  
    rotateY(radians(angleX));
    rotateX(radians(angleY));  
  
    float prevX = 0; float prevY = 0; float prevZ = 0;
    for(int i = 0; i < stars.size(); i++) {
      Star star = (Star) stars.get(i);
      if (i > 0) {
          if (autoRotation) { strokeWeight(hatSize);  }
          star.lineTo(prevX, prevY, prevZ);
      }
//      strokeWeight(kickSize);
//      float starSize = (kickSize==1) ? 4 : kickSize;
      float starSize = 4;
      if (flocking) star.applyFlockingForce();
      star.display(starSize);
      prevX = star.x; prevY = star.y; prevZ = star.z;
      
      if (star.dead()) {
          stars.remove(i);
      }
  
    }
    
    break; //end normal
    }// end switch
 
  } // end video available  
  showFps();

  kickSize = constrain(kickSize * changeSpeed, minWeight, maxWeight);
  snareSize = constrain(snareSize * changeSpeed, minWeight, maxWeight);
  hatSize = constrain(hatSize * changeSpeed, minWeight, maxWeight);

}

void mirrorFrame() {

      video.loadPixels();

      for (int i=0; i<numPixels; i++) {
        int posX = i % video.width;	     // x coordinate of pixel
        int posY = floor(i / video.width);   // y coordinate of pixel

        posX = video.width - posX - 1;       // flip x coordinate if we want to flip
        img.pixels[posY * video.width + posX] = video.pixels[i];
      }

      img.updatePixels();
}

void findLightPosition() {

      maxX = 0; 
      maxY=0; 
      maxBrightness = 0; 
      // pre kazdy pixel z aktualneho frame-u ho porovname s tym istym pixlom
      // v predchadzajucom frame-e -> a ziskany rozdiel (diff) scitujem pre kazdy jeden pad
      for (int i=0; i<numPixels; i++) {
        int posX = i % img.width;
        int posY = floor(i / img.width);

        // pouzitie zabudovanej funckie brightness() sa neosvedcilo - je strasne pomale (fps ~15)
        //int curBrightness = (int)brightness(video.pixels[i]);
        // nasiel som taketo riesenie -> napokon (fps ~24)

        color curColor = img.pixels[i];

        // ziskam cervenu, zelenu a modru zlozku aktualneho pixelu
        int currR = (curColor >> 16) & 0xFF; // v dokumentacii sa odporuca ako rychlejsia verzia funkcie red()
        int currG = (curColor >> 8) & 0xFF;
        int currB = curColor & 0xFF;

        float currBrightness =  (currR + currG + currB) / 3; // toto neni hodnota rozdielu v brightness - ale je to pre nas ucel lepsia hodnota
        if (currBrightness > maxBrightness) {
          maxBrightness = (int)currBrightness;
          maxX = posX;
          maxY = posY;
        }
      }

      // funkcia na vyhodnotenie a posielanie midi signalu
      if (maxBrightness > triggerThreshold)  playGrid();
}

void playGrid() {

  if(camera_on) {

	maxX =  maxX - (width / 2);
	maxY = maxY - (height / 2);

        stars.add(new Star());
        Star last = (Star) stars.get(stars.size() - 1);
        float osZ = (randZ) ? int(random(-200, 200)) : 0;
        last.setValues(maxX, maxY, osZ);

  }
}


void showFps() {
    if (show_fps) { 
      println(frameRate);
    }
}

void showVideo() {
  image(img, -(width /2), -(height /2), width, height);
}


void makeBlur() {
  filter(BLUR, 1);
}

void mousePressed() {
  stars.add(new Star());
  Star last = (Star) stars.get(stars.size() - 1);
  float osZ = (randZ) ? int(random(-200, 200)) : 0;
  last.setValues(mouseX - width/2, mouseY  - height/2, osZ);
}

void keyPressed() {
  // vypnutie/zapnutie posielania midi na zaklade pohybu pred kamerou
  keyNumber = key-48;
  if (keyNumber > 0 && keyNumber < 10) {
    lowii_state = keyNumber;
    if (keyNumber == 8) symbol = 's';
    else if (keyNumber == 9) symbol = 't';
    else if (keyNumber == 7) symbol = 'r';    
    println("lowii_state: " + lowii_state + symbol);
  } else {
    switch(key) {
      case ' ':
        if (camera_on==true) camera_on = false;
        else camera_on = true;
        println("cam input " + camera_on );
        break; 
      case 's':
        if (show_video==true) show_video = false;
        else show_video = true;
        println("show video: " + show_video );
        break;
      case 'b':
        if (camera_on==true) {
          camera_on = false;
          makeBlur = true;
          stars = new ArrayList();
        } 
        else {
          camera_on = true;
          makeBlur = false;
        }
        println("cam input " + camera_on );
        break;
      case 'F':
        if (!flocking) {
          flocking=true;
          println("started flocking");
        } 
        else {
          flocking=false;
          println("leaving flocking");
        }
        break;
      case 'r':
        if (show_fps==true) show_fps = false;
        else show_fps = true;
        break;
      case '-':
        if (triggerThreshold < 255) triggerThreshold += step;
        println("threshold: " + triggerThreshold + "/255");
        break;
      case '+':
        if (triggerThreshold > 0) triggerThreshold -= step;
        println("threshold: " + triggerThreshold + "/255");
        break;
      case 'k':
        if (knob==true) knob = false;
        else knob = true;
        println("knob " + knob );
        break;
      case  't':
        if (autoRotation==true) autoRotation = false;
        else autoRotation = true;
        println("rotation " + autoRotation );
        break;
      // reset view
      case  'a':
        angleX = 0;
        angleY = 0;
        println("reset view");
        break;
      case  'z':
        if (randZ==true) randZ = false;
        else randZ = true;
        println("random Z " + randZ );
        break;
      case  'o':
        x = 0;
        break;
      case  'O':
        x = 20;
        break;
      case CODED:
        if (keyCode == UP) {
          angleY += 7;
        } else if (keyCode == DOWN) {
          angleY -= 7;
        }
        if (keyCode == LEFT) {
          angleX -= 7;
        } else if (keyCode == RIGHT) {
          angleX += 7;
        }         
        break; // end CODED
    } // end switch  
  } // end else 
}
