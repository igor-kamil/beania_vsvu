Star s1;
Star s2;
Star s3;
Star s4;
Star s5;

class WConstellation {

//  float x = 0;
  float distance = 5;
  
  WConstellation() {
    boolean die = false;
    s1 = new Star(die);
    s2 = new Star(die);
    s3 = new Star(die);
    s4 = new Star(die);
    s5 = new Star(die);
  }
  

   void display(float x) {
    background(0);
    translate(width/2, height/2);
    rectMode(CENTER);
    scale(x);

    stroke(100);   
    line(0* distance, distance * -1, -2* distance, distance * 0);
    line(0* distance, distance * -1, 2* distance, distance * 0);
    line(-2* distance, distance * 0, -4* distance, distance * -3);
    line(2* distance, distance * 0, 4* distance, distance * -3 );

    s1.setValues(0* distance, distance * -1,0);
    s2.setValues(-2* distance, distance * 0,0);
    s3.setValues(2* distance, distance * 0,0);
    s4.setValues(-4* distance, distance * -3,0);
    s5.setValues(4* distance, distance * -3,0);
        
    float starSize = 2;
    s1.display(starSize);
    s2.display(starSize);
    s3.display(starSize);
    s4.display(starSize);
    s5.display(starSize);


  } 
}
