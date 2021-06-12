/*****************************************************************************/
/***************************** Test Code ver_final ***************************/
/*****************************************************************************/
/******* In questa versione campionamento a 40Hz e conteggio del tempo *******/
/*****************************************************************************/
/* Si ritrovano invece: - Controllo massimi/minimi su delta temporale e soglia
 *                      - Controllo apnea    
 *                      - Controllo malfunzionamento sensore
 *                      - Reset (con pulsante)
 *                      - Calibrazione
/*****************************************************************************/
#include<SoftwareSerial.h>

#define TX 8
#define RX 9

SoftwareSerial bt = SoftwareSerial(RX, TX);

#define LED_CALIBRATION 1<<PORTB0
#define RESET_BUTTON 1<<PORTB1
#define BUZZER 1<<PORTD0     //Pin for arduino MICRO
//#define BUZZER 1<<PORTD7      // Pin for arduino UNO (digital pin n°7)
#define delta_time 80           //Incremental minimum distance between singularities (2seconds)
#define count_seconds 40        //Number of counts in the ISR to reach 1 second

//--GLOBAL VARIABLES--
//Time varaibles
long int count = 0;
int second = 0;
int minute = 0;
int hour = 0;
long int time_max, time_min = 0;

//Data variables
int dato = 0;
float val = 0;
float val_2 = 0;
float val_1 = 0;
float maxi, mini = 0;
float max_rel, min_rel = 0;
int check_apnea = 0;
int check_anomaly = 0;
int resp_rate=0;
long int first_max=0;
float max_calibration, threshold=0;
int num_max=0;
int count_max, count_min = 0;
char calibration = -1;
float reference=0.0;

char command = 0;
char command_read = 0;

//Flags
//char flag_on = 0;
char flag = 0;
char flag_max = 0;
char flag_min = 0;
char flag_max_rel=0;
char flag_min_rel=0;
char stamp_max = 0;
char flag_waiting_action = 0;
char flag_wait=0;
char flag_buzzer = 0;
char flag_cal=0;
char reset_flag=0;

//--FUNCTIONS--
void setPORT();
void setTIMER();
int test_apnea();
int test_anomaly();
void reset();

void setup() {
  cli();                  //Disabling global interrupts
  bt.begin(9600);
  setTIMER();
  setPORT();
  sei();                  //Enabling global interrupts
}     

void loop() {
  bt.println(val);
  delay(10);

  if(bt.available())
  {
    command_read = bt.read();

    if(command_read == 'L'){               //a: code for calibration from processing
      flag_cal++;
      if(flag_cal==2){
        flag_cal=0;
        calibration = 0;
        max_calibration = 0;
        count=0;
        second=0;
        threshold=0;
        first_max=0;
        command_read = 'z';
      }
    }
    if(command_read == 'M'){               //b: code for Reset button pressed in Processing. It is used to clear data or to stop an anomaly or apnea event
      reset_flag++;
      if(reset_flag==2){
        reset_flag=0;
        reset();
        command_read = 'z';
      }
    }
  }

  switch(command)
  {
    case 'c':                   //c: value to send if apnea has occurred
      bt.println('C');
      command = 'z';
      break;
      
    case 'e':                   //e: value to stop the alarm for anomaly or apnea in processing
      bt.println('E');
      command = 'z';
      break;
  }

  //Reset button
  /*If the button is pressed, the reset() function is called and a new
   * calibration begins
   */
  if(PINB & RESET_BUTTON)
  {
   while(PINB & RESET_BUTTON);          //waiting for the button to be released
   command = 'e';
   first_max=0;
   calibration=2;
   flag_buzzer=0;
   check_apnea=0;
  }

  //-------- CALIBRATION ---------
  /* The patient has to breath normally for 10 seconds 
   *  and the maximum value reached in this calibration window is used for the
   *  definition of a threshold. Moreover a LED is switched on for 10 seconds
   */
  if(second<=10 && calibration == 0)
  {
    PORTB |= LED_CALIBRATION;
    if(val>max_calibration)
    {
      max_calibration = val;
    }
  }

  //Defining a calibration threshold on the 50% of the maximum
  if(second == 10 && calibration == 0)
  {
    threshold = max_calibration*0.5;
    bt.println('G');
    bt.println(threshold);
    calibration = 1;
    PORTB &=~ LED_CALIBRATION; 
  }
  
  //------ PEAK DETECTION ---------
  /* The algorithm to detect the peak is based on the simultaneous usage
   *  of a time threshold (to prevent 'false respiration') and a numerical
   *  threshold (determined during the calibration phase)
   */
  //Maximum
  if (calibration == 2)                    // calibration has finished. The search for maxima begins
  {                     
    if (val_1 >= threshold && time_max >= delta_time)
    {              
      if(val_2 <= val_1 && val_1 >= val && flag_max_rel == 0)
      {
          max_rel = val_1;
          flag_max_rel = 1;
          flag_max = 1;
      }
    }
    
    if(max_rel>=val && flag_max==1)
    {                 
      count_max++;
      if(count_max == 10)
      {
        first_max++;
        if(first_max >= 2)                //we need to detect 2 absolute maxima before starting to provide a respiratory frequency
        {                    
          resp_rate= 60/(time_max*0.025);
          bt.println('A');
          bt.println(resp_rate);
        }
        num_max++;                             // counter used in the ISR in order to provide the frequency by counting the number of maxima in 1 minute
        maxi = max_rel;
        time_max = 0;
        flag_max_rel = 0;
        flag_max=0;
        count_max=0;
      }
    }else{
      count_max = 0;
      max_rel = val;
    }
  }

  if(stamp_max)                       //flag to print the number of found maxima, according to the minute passed in the ISR
  {
    bt.println('B');        //the number of maxima is printed every minute
    bt.println(num_max);
    stamp_max = 0;
    num_max=0;
  }
}

ISR(TIMER1_OVF_vect)
{
  int dato = 0;
  count++;                //Overall Time
  time_min++;             //Time between minima
  time_max++;             //Time between maxima
  
  
  TCNT1 = 59285;
  if (count >= count_seconds)
  {
    count = 0;
    second++;             //Counting seconds
    flag = 0;             //flag for serial comunication in setup
  }
  
  if(calibration == 1){
    count=0;
    second=0;             //After 10 seconds of calibration, the counter for seconds restarts 
    calibration = 2;
  }
  
  //Counting minutes
  if(second>=60)
  {
      second=0;
      minute++;
      stamp_max = 1;
  }

  //Counting hours
  if(minute>=60)
  {
    minute=0;
    hour++;
  }
 

  //Data acquisition via ADC on pin A5
  val_2 = val_1;
  val_1 = val;
  dato = analogRead(A5);
  val = (float) (dato*5)/1023;

  if(test_apnea() && calibration == 2)
  {
    command = 'c';
    check_apnea = 0;
    flag_buzzer = 1;
    calibration=-1;
  }

  if(flag_buzzer)
  {
    tone(3, 1000);     // for arduino MICRO
//    tone(7, 2000);     // for arduino UNO
  } else {
    noTone(3);     // for arduino MICRO
//    noTone(7);     // for arduino UNO
  }
}

//--FUNCTIONS IMPLEMENTATION--
void setPORT()
{
  DDRB |= (1<<DDB0);      //Setting LED_CALIBRATION as output
  DDRB &=~ (1<<DDB1);     //Setting RESET_BUTTON as input
  DDRF &=~ (1<<DDF0);     //Setting FSR input for arduino MICRO
//  DDRC &= (1<<DDC5);    //Setting of FSR input for arduino UNO
  DDRD |= (1<<DDD0);      //Setting buzzer output for arduino MICRO
//  DDRD |= (1<<DDD7);      //Setting buzzer output for arduino UNO
  PORTB &=~ LED_CALIBRATION;
}

void setTIMER()
{
  TIMSK1 |= (1<<TOIE1);       //Enabling overflow interrupt
  TCCR1B = 0x00;              //Clearing the register for normal mode
  TCCR1A = 0x00;
  TCCR1B |= (1<<CS10)|(1<<CS11);    //Setting timer prescaler @64
  TCNT1 = 59285;              //Initializing the timer to count @40Hz (63035 @ 100Hz)
}

/*TEST APNEA 
 * This function controls if the sampled value varies. If it doesn't vary for more than 3 seconds,
 * an alarm is set
 */
int test_apnea()              
{                     
  float tol = 0.1;

  if(val<=val_1+tol && val>=val_1-tol && flag_wait==0){
    reference= val;
    flag_wait=1;
  }

  if(val<=val_1+tol && val>=val_1-tol && flag_wait==1){
    check_apnea ++;

    if(check_apnea % (count_seconds/10)==0){         // we check every tenth of second if the value we read is 
      if(abs(val - reference) > tol * 2){            // is still in a range of +- tol with respect to the initial reference
        check_apnea=0;
        flag_wait=0;
      }
    }
  }
  
  if((check_apnea>=4*count_seconds-10) && (check_apnea<=4*count_seconds))    //4 seconds of apnea
  {
    check_apnea=0;
    return 1;
  } else {
    return 0;
  } 
}


void reset()
{
  setPORT();
  setTIMER();
  time_max = 0;
//  val = 0;
//  val_1 = 0;
//  val_2 = 0;
  count = 0;
  second = 0;
  minute = 0;
  hour = 0;
  check_apnea = 0;
  calibration = 2;
  num_max = 0;
  count_max = 0;
  max_rel = 0;
  min_rel = 0;
  resp_rate = 0;
  flag_max_rel = 0;
  flag_max = 0;
  stamp_max = 0;
  command = 0;
  command_read=0;
  flag_buzzer=0;
}
