/******************************************************/
/****************** Interface_final *******************/
/******************************************************/

import grafica.*;
import processing.serial.*;

//Serial data
Serial myPort;        // The serial port
float inByte;         // Incoming serial data
boolean newData = false;
boolean new_data_freq = false;
int xPos = 420;       // horizontal position of the graph 
int new_freq=0;
int freq_tot=0;
float value_read=0.0;
float new_point=0.0;
char flag_freq=0;
char flag_freq_tot=0;
char flag_threshold = 0;
int lastxPos=420;
int lastheight=590;
float threshold=0.0;
float threshold_line=0.0;

GPlot plot;
PImage polimi;

//Mouse inputs
float positionX;
float positionY;

//Flags
char flag_on = 0;
char flag_calibration = 0;        //determines wheter calibration is in process or not
char send_calibration = 0;
char flag_end_calibration = 0;    //determines when calibration has ended to display 'END'
char flag_reset = 0;
char flag_anomaly = 0;
char flag_apnea = 0;
char flag_milli = 0;
char flag_milli_cal = 0;
char flag_new_screen = 0;
char flag_arrival=0;
char check_border=0;
int x=60;
int y=0;
int z=0;
char flag_change=0;
char first_refresh=0;

//Numerical variables
int previousTime = 0;
int elapsedMillis = 1000;
int previousTime_cal = 0;
int milli = 0;           //milliseconds
int s = 0;               //seconds
int m = 0;               //minutes
int h = 0;               //hours
int s_cal = 10;
int i = 0;
int [] vect_freq = new int[8];

void setup() {
  size(1500, 900);
  layout();
  
  //Setup for serial communication
  myPort = new Serial(this, "COM6", 9600);  

  // A serialEvent() is generated when a newline character is received :
  myPort.bufferUntil('\n');


  // Create a new plot and set its position on the screen
  plot_setting();
  
}

void draw() {
  
  // Axis labels
  fill(0);
  textSize(20);
  textAlign(CENTER, CENTER);
  text("time", 750, 620);
  
  fill(0);
  textSize(20);
  pushMatrix();
  translate(370 , 400);
  rotate(radians(270.0));
  text("Voltage", 0 , 0);
  popMatrix();
  
  //Plot border
  stroke(255);
  rectMode(CENTER);
  noFill();
  rect(750, 400, 800, 500);
  
  //Data drawing
  if (newData && flag_on == 1) 
  {
    //Drawing a line from Last inByte to the new one.
    stroke(0);     //stroke color
    strokeWeight(2);        //stroke wider
    line(lastxPos, lastheight, xPos, (590-new_point)+190); 
    lastxPos= xPos;
    lastheight= int(590-new_point+190);
    
    newData =false;
  }
  
  //At the edge of the window, go back to the beginning:
  if (xPos== 1120) 
  {
      xPos = 420;
      lastxPos= 420;  //Clear the screen.
      
      plot.setPos(350,150);
      plot.setOuterDim(800,500);
      plot.setMar(60, 70, 40, 30);
    
      // Settings for the plot
      plot.beginDraw();
 
      plot.setYLim(0.0, 5.0);
      plot.setTicksLength(1);
      plot.setBoxLineWidth(3);
      plot.setAxesOffset(1);
      plot.setBoxLineColor(255);
      plot.setBgColor(200);
      plot.setBoxBgColor(255);
      plot.getXAxis().setNTicks(0);
      plot.getYAxis().setNTicks(10);
      plot.getYAxis().setRotateTickLabels(false);
    
      plot.drawBackground();
      plot.drawBox();
      plot.drawXAxis();
      plot.drawYAxis();
      plot.drawTopAxis();
      plot.drawRightAxis();
      plot.drawTitle();
      plot.drawGridLines(GPlot.HORIZONTAL);
      plot.endDraw();
    
    } else {
      // increment the horizontal position:
      xPos++;
    }
  
  //Processing to Arduino comunication for calibration button and reset button
  if(flag_on == 1 && send_calibration == 1)
  {
    myPort.write('L');
    myPort.write('L');
    myPort.write('L');
    myPort.write('L');
    send_calibration = 0;
  }
  
  if(flag_on == 1 && flag_reset == 1)
  {
    myPort.write('M');
    myPort.write('M');
    myPort.write('M');
    myPort.write('M');
    flag_reset = 0;
  }

  //Elapsed Time
  if (flag_on == 0)
  {
    flag_milli = 0;
    flag_calibration = 0;
  }

  if (flag_on == 1 && flag_milli == 0)
  {
    flag_milli = 1;
    previousTime = millis();
  }

  if (millis()-previousTime > elapsedMillis && flag_milli == 1)
  {
    previousTime = millis();
    s++;
  }

  if (s == 60)
  {
    s = 0;
    m++;
  }

  if (m == 60)
  {
    m = 0;
    h++;
  }
  
  //Remaining Time for calibration
  if(flag_calibration == 1 && flag_on == 1 && flag_milli_cal == 0)
  {
    flag_milli_cal = 1;
    flag_end_calibration = 0;
    previousTime_cal = millis();
  }
  
  if (millis()-previousTime_cal > elapsedMillis && flag_milli_cal == 1 && flag_on == 1)
  {
    previousTime_cal = millis();
    s_cal--;
  }
  
  if(s_cal==0)
  {
    s_cal = 10;
    flag_calibration = 0;
    flag_milli_cal = 0;
    flag_end_calibration = 1;
  }
  
  //Text placement
  strokeWeight(1);    //lower white box
  fill(255);
  stroke(2, 44, 148);
  rectMode(CENTER);
  rect(width/2,height-15,width,33);
  
  rectMode(RIGHT);          //blue upper box
  fill(2, 44, 148);
  stroke(2, 44, 148);
  rect(0, 0, width, 80);

  fill(255);
  textSize(50);
  textAlign(CENTER, CENTER);
  text("BREATH ANALYSIS", width/2, 35);

  textSize(35);
  fill(253, 217, 151);
  text("Breathing pattern", width/2, 110);
  text("PARAMETERS", 170, 150);
  text("STATUS", 1330, 150);

  fill(2, 44, 148);
  textSize(15);
  textAlign(RIGHT);
  text("Developed by Group 35", 1490, 890);
  textAlign(LEFT);
  text("Technologies for sensors and clinical instrumentation", 10, 890);

  //Process display
  textSize(30);
  textAlign(CENTER, CENTER);
  text("Process on course", 1330, 200);
  text("Respiratory rate [bpm]", 170, 200);
  text("Elapsed time [s]", 1330, 340);
  text("Threshold [V]", 170, 340);
  text("Remaining time [s]", 1330, 480);
  text("RR in 1 min [bpm]", 170, 480);

  fill(0, 90, 0);
  stroke(255);
  rectMode(CENTER);
  rect(1330, 260, 330, 60, 20, 20, 20, 20);    //Process
  rect(170, 260, 330, 60, 20, 20, 20, 20);     //Respiratoy rate
  rect(1330, 400, 330, 60, 20, 20, 20, 20);      //Time elapsed
  rect(170, 400, 330, 60, 20, 20, 20, 20);     //Maximum
  rect(1330, 540, 330, 60, 20, 20, 20, 20);      //Time remaining
  rect(170, 540, 330, 60, 20, 20, 20, 20);     //Minimum

  if (flag_calibration == 0)
  {
    fill(0, 255, 0);
    text("Measurement", 1330, 255);
  }
  if(flag_calibration == 1)
  {
    fill(0, 255, 0);
    text("Calibration", 1330, 255);
  }

  // DISPLAY OF THE PARAMETERS

  if(flag_apnea==1){
    text("NULL", 170, 255);
  }else{
    text(new_freq, 170, 255);           //Respiratory rate
  }
  text(threshold, 170, 395);                  // Threshold
  text(freq_tot, 170, 535);              // RR over 1 minute
  textAlign(RIGHT, CENTER);
  text(s, 1400, 395);             //Elapsed time
  text(":", 1360, 393);
  text(m, 1346, 395);
  text(":", 1306, 393);
  text(h, 1292, 395);
  
  //Plotting of a line corresponding to the threshold
  if(threshold != 0.0){
    threshold_line= map(threshold, 0, 5.0, 190 , 590);
    stroke(255, 0, 0);
    strokeWeight(1);
    line(420, 590-threshold_line+190, 1120, 590-threshold_line+190);
  }
  
  
  if(flag_end_calibration == 0)
  {
    textAlign(CENTER, CENTER);
    text(s_cal, 1330, 535);                //Remaining time
  }
  
  if(flag_end_calibration==1)
  {
    textAlign(CENTER, CENTER);
    text("END", 1330, 535);
  }

  //On button design and animation
  if (flag_on == 0)
  {
    strokeWeight(3);
    stroke(255);
    fill(255, 0, 0);
    rectMode(CENTER);
    rect (60, 40, 70, 70, 20, 20, 20, 20);

    circle(60, 40, 40);
    stroke(255);
    line(60, 13, 60, 33);
  }

  if (flag_on==0 && mouseX<95 && mouseX>25 && mouseY<75 && mouseY>5)
  {
    strokeWeight(3);
    stroke(255);
    fill(200, 0, 0);
    rectMode(CENTER);
    rect (60, 40, 70, 70, 20, 20, 20, 20);

    circle(60, 40, 40);
    stroke(255);
    line(60, 13, 60, 33);

    if (positionX<95 && positionX>25 && positionY<75 && positionY>5)
    {
      flag_on = 1;
      positionX = 0;
      positionY = 0;
    }
  }

  if (flag_on==1)
  {
    strokeWeight(3);
    stroke(255);
    fill(0, 255, 0);
    rectMode(CENTER);
    rect (60, 40, 70, 70, 20, 20, 20, 20);

    circle(60, 40, 40);
    stroke(255);
    line(60, 13, 60, 33);
  }

  if (flag_on==1 && mouseX<95 && mouseX>25 && mouseY<75 && mouseY>5)
  {
    strokeWeight(3);
    stroke(255);
    fill(0, 200, 0);
    rectMode(CENTER);
    rect (60, 40, 70, 70, 20, 20, 20, 20);

    circle(60, 40, 40);
    stroke(255);
    line(60, 13, 60, 33);

    if (positionX<95 && positionX>25 && positionY<75 && positionY>5)
    {
      flag_on = 0;
      positionX = 0;
      positionY = 0;
    }
  }

  //Clear data button
  stroke(255);
  fill(100, 100, 100);
  rectMode(CENTER);
  rect (1440, 40, 70, 70, 20, 20, 20, 20);
  circle(1440, 40, 40);
  stroke(255);
  line(60, 13, 60, 33);

  if (flag_on == 1 && mouseX<1475 && mouseX>1405 && mouseY<75 && mouseY>5)
  {
    stroke(255);
    fill(50, 50, 50);
    rectMode(CENTER);
    rect (1440, 40, 70, 70, 20, 20, 20, 20);
    circle(1440, 40, 40);
    stroke(255);
    line(60, 13, 60, 33);
  }

  if (positionX<1475 && positionX>1405 && positionY<75 && positionY>15)
  {
    flag_reset = 1;
    clearData();
  }

  //Calibration button: drawing of the button and animation
  fill(253, 217, 151);
  stroke(222, 144, 4);
  rect(width/2, 750, 400, 100, 30, 30, 30, 30);

  fill(222, 144, 4);
  textAlign(CENTER, CENTER);
  textSize(50);
  text("CALIBRATION", width/2, 745);

  if (flag_on == 1 && mouseX<width/2+200 && mouseX>width/2-200 && mouseY<750+50 && mouseY>750-50)
  {
    fill(222, 144, 4);
    stroke(253, 217, 151);
    rect(width/2, 750, 400, 100, 30, 30, 30, 30);

    fill(253, 217, 151);
    textAlign(CENTER, CENTER);
    textSize(50);
    text("CALIBRATION", width/2, 745);
  }

  //Flag to change status if mouse pressed in the button
  if (flag_on == 1 && positionX<width/2+200 && positionX>width/2-200 && positionY<750+50 && positionY>750-50)
  {
    flag_calibration = 1;
    send_calibration = 1;
    flag_apnea = 0;
    positionX = 0;
    positionY = 0;
    threshold=0.0;
    new_freq=0;
    plot_setting();
  }

  //Apnea animation
  if (flag_apnea==1 && flag_on == 1)
  {
    if (second()%2 == 0)
    {
      fill(255, 0, 0);
      stroke(255, 0, 0);
      rect(1200, 745, 330, 80, 10, 10, 10, 10);
      rect(300, 745, 330, 80, 10, 10, 10, 10);
      fill(255);
      textSize(50);
      text("APNEA", 1200, 737);
      text("APNEA", 300, 737);
    } else {
      fill(103, 185, 247);
      stroke(103, 185, 247);
      rect(1200, 745, 330, 80, 10, 10, 10, 10);
      rect(300, 745, 330, 80, 10, 10, 10, 10);
      fill(255);
    }
  }
  
  if(flag_apnea==0 || flag_on == 0)
  {
    fill(103, 185, 247);
    stroke(103, 185, 247);
    rect(1200, 745, 330, 80, 10, 10, 10, 10);
    rect(300, 745, 330, 80, 10, 10, 10, 10);
    fill(255);
  }

  
  //Polimi logo
  imageMode(CENTER);
  polimi = loadImage("polimilogo.jpg");
  image(polimi, width/2, height-15, 130, 30);

  //Parameters display button
  if(flag_on == 0)
  {
    rectMode(CENTER);
    stroke(255);
    strokeWeight(2);
    fill(2, 44, 148);
    rect(1400,830,180,50,10,10,10,10);
    textSize(18);
    textAlign(CENTER);
    fill(255);
    text("Parameters display", 1400, 835);
  }
  
  if(flag_on == 1 && mouseX<1400+90 && mouseX>1400-90 && mouseY<830+25 && mouseY>830-25)
  {
    rectMode(CENTER);
    stroke(255);
    strokeWeight(2);
    fill(2, 44, 148);
    rect(1400,830,180,50,10,10,10,10);
    textSize(18);
    textAlign(CENTER);
    fill(255);
    text("Parameters display", 1400, 835);
  } else {
    rectMode(CENTER);
    stroke(255);
    strokeWeight(2);
    fill(10, 100, 160);
    rect(1400,830,180,50,10,10,10,10);
    textSize(18);
    textAlign(CENTER);
    fill(255);
    text("Parameters display", 1400, 835);
  }
  
  // NEW SCREEN 
  if(flag_on == 1 && positionX<1400+90 && positionX>1400-90 && positionY<830+25 && positionY>830-25)
  {
    positionX = 0;
    positionY = 0;
    flag_new_screen = 1;
  }
  
  // VALUES ARE SAVED AND THEN DISPLAYED IN THE TABLE
   if(flag_arrival==1){
      flag_arrival=0;
      flag_change=1;
    }
    
    if(flag_change==1){
      if(check_border<=7 && first_refresh==0){
        vect_freq[check_border]=new_freq;  
      }
      if(check_border<=6 && first_refresh==1){
        vect_freq[check_border+1]=new_freq;
      }
      check_border++;
      flag_change=0;
      if (check_border==9 && first_refresh==0){
        first_refresh=1;
        check_border=0;
        y=y+8;
        
        for(z=0; z<8; z++){
          vect_freq[z]=0;
        }
        vect_freq[0]=new_freq;
      }
      
      if (check_border==8 && first_refresh==1){
        check_border=0;
        y=y+8;
        
        for(z=0; z<8; z++){
          vect_freq[z]=0;
        }
        vect_freq[0]=new_freq;
      }
    }
  
  //New screen
  if(flag_new_screen == 1)
  {
    layout();
    table();
    
    if(mouseX<130+100 && mouseX>130-100 && mouseY<60+25 && mouseY>60-25)
    {
      strokeWeight(3);
      stroke(255);
      fill(2, 44, 148);
      rectMode(CENTER);
      rect(130, 60, 200, 50, 20, 20, 20, 20);
      textSize(30);
      textAlign(CENTER);
      fill(255);
      text("RETURN",130,70);
    }
    
    if(positionX<130+100 && positionX>130-100 && positionY<60+25 && positionY>60-25)
    {
      positionX = 0;
      positionY = 0;
      flag_new_screen = 0;
      flag_on=1;
      layout();
      plot_setting();
    }
  }
}


void mousePressed() 
{
  positionX = mouseX;
  positionY = mouseY;
}

void serialEvent (Serial myPort) {
  // get the ASCII string:
  String inString = myPort.readStringUntil('\n');
  if (inString != null) {
    
  
    if(inString.charAt(0) == 'A'){
      flag_freq=1; 
      
    }else if (flag_freq == 1){
      inString = trim(inString);// trim off whitespaces.
      value_read = float(inString);   
      new_freq= (int)value_read;
      flag_freq=0;
      flag_arrival=1;
      
    }else if(inString.charAt(0) == 'B'){
      flag_freq_tot=1; 
      
    }else if (flag_freq_tot == 1){
      inString = trim(inString);// trim off whitespaces.
      value_read = float(inString);   
      freq_tot= (int)value_read;
      flag_freq_tot=0;
      
    }else if(inString.charAt(0) == 'C'){
      flag_apnea = 1;
      
    }else if(inString.charAt(0) == 'E'){
      flag_apnea = 0;
      new_freq=0;
      
    }else if(inString.charAt(0) == 'G'){
      flag_threshold=1; 
      
    }else if (flag_threshold == 1){
      inString = trim(inString);       // trim off whitespaces.
      value_read = float(inString);   
      threshold= value_read;
      flag_threshold=0;
      
    }else{
    value_read = float(inString);
    if(value_read>5.0 || value_read<0.0)
    {} else {
        new_point= map(value_read, 0, 5.0, 190 , 590);
        newData=true;
      }
    }
  }
}


void layout()
{
  background(103, 185, 247);
  
  //White box below
  strokeWeight(1);
  fill(255);
  stroke(2, 44, 148);
  rectMode(CENTER);
  rect(width/2,height-15,width,33);
  
  fill(2, 44, 148);
  textSize(15);
  textAlign(RIGHT);
  text("Developed by Group 35", 1490, 890);
  textAlign(LEFT);
  text("Technologies for sensors and clinical instrumentation", 10, 890);
  
  imageMode(CENTER);
  polimi = loadImage("polimilogo.jpg");
  image(polimi, width/2, height-15, 130, 30);
}


void clearData()
{
  positionX = 0;
  positionY = 0;
  flag_apnea = 0;
  s = 0;
  m = 0;
  h = 0;
  xPos = 420;
  lastxPos= 420;
  //lastheight=590;
  value_read=0;
  new_freq=0;
  freq_tot=0;
  y=0;
  check_border=0;
  first_refresh=0;
  flag_apnea=0;
  
  for(z=0; z<8; z++){
    vect_freq[z]=0;
  }
  
  
  plot_setting();
}


void plot_setting()
{
  // Create a new plot and set its position on the screen
  plot = new GPlot(this);
  plot.setMar(60, 70, 40, 30);
  plot.setPos(350,150);
  plot.setOuterDim(800,500);

  // Set the plot title and the axis labels
  plot.beginDraw();

  plot.setYLim(0.0, 5.0);
  plot.setTicksLength(1);
  plot.setBoxLineWidth(3);
  plot.setAxesOffset(1);
  plot.setBoxLineColor(255);
  plot.setBgColor(200);
  plot.setBoxBgColor(255);
  plot.getXAxis().setNTicks(0);
  plot.getYAxis().setNTicks(10);
  plot.getYAxis().setRotateTickLabels(false);

  plot.drawBackground();
  plot.drawBox();
  plot.drawXAxis();
  plot.drawYAxis();
  plot.drawTopAxis();
  plot.drawRightAxis();
  plot.drawTitle();
  plot.drawGridLines(GPlot.HORIZONTAL);
}

void table(){
  
  textAlign(CENTER);
    textSize(100);
    fill(253, 217, 151);
    text("VALUES COLLECTED",width/2,100);  
    
    fill(0, 90, 0);
    stroke(255);
    strokeWeight(3);
    rectMode(CENTER);
    rect(750, 480, 800, 580);
    
    int x = 60;
    stroke(255);
    strokeWeight(3);
    line(350, 290, 1150, 290);
    line(350, 290+x, 1150, 290+x);
    line(350, 290+2*x, 1150, 290+2*x);
    line(350, 290+3*x, 1150, 290+3*x);
    line(350, 290+4*x, 1150, 290+4*x);
    line(350, 290+5*x, 1150, 290+5*x);
    line(350, 290+6*x, 1150, 290+6*x);
    line(350, 290+7*x, 1150, 290+7*x);
    line(650, 190, 650, 770);
    
    textSize(35);
    textAlign(CENTER, CENTER);
    fill(0,255,0);
    text("Respiratory frequencies", 900, 240);
    textSize(35);
    text("N° of interval", 500, 240);
    
    
    textSize(25);
    text( 1+y, 500, 320);
    text( 2+y, 500, 320+1*x); 
    text( 3+y, 500, 320+2*x); 
    text( 4+y, 500, 320+3*x); 
    text( 5+y, 500, 320+4*x); 
    text( 6+y, 500, 320+5*x); 
    text( 7+y, 500, 320+6*x); 
    text( 8+y, 500, 320+7*x); 
    
    text( vect_freq[0] , 900, 320);
    text( vect_freq[1], 900, 320+1*x); 
    text( vect_freq[2], 900, 320+2*x); 
    text( vect_freq[3], 900, 320+3*x); 
    text( vect_freq[4], 900, 320+4*x); 
    text( vect_freq[5], 900, 320+5*x); 
    text( vect_freq[6], 900, 320+6*x); 
    text( vect_freq[7], 900, 320+7*x);
    
    //Return Button
    strokeWeight(3);
    stroke(255);
    fill(10, 100, 160);
    rectMode(CENTER);
    rect(130, 60, 200, 50, 20, 20, 20, 20);
    textSize(30);
    textAlign(CENTER);
    fill(255);
    text("RETURN",130,70);    
}
  
  
