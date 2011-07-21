/* 
 * input: serial data stream of chars for each button pressed
 * output: a particular pulse for ~1ms at around 60hz 
 * licence: this code is too crap to own, have at it
 */
#include <TimerOne.h>

#define DEBUG false

// about the period of 60hz in usec
const long MAX_DUTY_CYCLE = 1024;
//const long SIXTY_HZ_INTERVAL = 16642;    // uS
const long PULSE_DURATION = 2000;    // uS

#define SIXTY_HZ_INTERVAL_MS 16643

#define SLOW_RISE  400
#define FAST_RISE  1000
#define SLOW_FALL  750
#define FAST_FALL  2000

// these are states for the screensaver
#define HOVER (SIXTY_HZ_INTERVAL_MS)
#define CREEP (SIXTY_HZ_INTERVAL_MS-SLOW_RISE)
#define SLOWFALL (SIXTY_HZ_INTERVAL_MS+SLOW_FALL)
#define FREEFALL (SIXTY_HZ_INTERVAL_MS+FAST_FALL)

// delay time for the control loop in ms. 
// timeouts will be in increments of this.
#define CTRL_DELAY 10

// start screensaver after 30s of inactivity
//#define SS_TIMEOUT (30000/CTRL_DELAY)
#define SS_TIMEOUT (5000/CTRL_DELAY)

// screensaver state timeouts
// freefall for 1s
#define FREEFALL_TIMEOUT (1000/CTRL_DELAY)
// hover for 7.5s
#define HOVER_TIMEOUT (6000/CTRL_DELAY)
// creep up for 5s
#define CREEP_TIMEOUT (16000/CTRL_DELAY)

//
// pins defined
//
const int ledPin = 13;
const int tonePin = 9;

//
// length of pulse in period over 1024
//
const int toneDutyCycle = 80;

// incoming serial byte
//
// temp var for storing incoming serial data
// acsii chars are really nice to 
// avoid colliding with the lower level transport protocols
//
int inByte = 0;       

int ss_timer = 0;

int ss_state = CREEP; // start in 

// do this once
void setup()
{
  // start serial port at 57600 bps bc thats how i roll 
  // it also aides in wireless programming with the Fio (pure sex)
  Serial.begin(57600);

  pinMode(tonePin, OUTPUT);
  pinMode(ledPin, OUTPUT);
  Timer1.initialize(SIXTY_HZ_INTERVAL_MS);         // initialize timer1, and set a 1/2 second period
  Timer1.pwm(tonePin, toneDutyCycle);                // setup pwm on pin 9, 50% duty cycle
  Timer1.attachInterrupt(callback);  // attaches callback() as a timer overflow interrupt  
}

// do this everytime
void loop()
{
  // should we start the screensaver?
  if (ss_timer >= SS_TIMEOUT) {
    setNewPwm(tonePin, toneDutyCycle, 54321);
    screenSaver(); // polls for serial data to return control
    setNewPwm(tonePin, toneDutyCycle, 12345);
  }

  // if we get a valid byte, read analog ins:
  if (Serial.available() > 0) {
    ss_timer = 0;
    reactToSerialInput();
  }

  delay(CTRL_DELAY);
  ss_timer++;
}

// this should be called with each pulse
void callback()
{
  digitalWrite(ledPin, digitalRead(ledPin) ^ 1);
}


void reactToSerialInput() {
  // get incoming byte:
  inByte = Serial.read();

  // i don't love this, but meh.
  switch (inByte) {
  case 'a':    
    setNewPwm(tonePin, toneDutyCycle, SIXTY_HZ_INTERVAL_MS-FAST_RISE);
    break;
  case 'b':    
    setNewPwm(tonePin, toneDutyCycle, SIXTY_HZ_INTERVAL_MS);
    break;
  case 'c':    
    setNewPwm(tonePin, toneDutyCycle, SIXTY_HZ_INTERVAL_MS+FAST_FALL);
    break;
  case 'r':    
    setNewPwm(tonePin, toneDutyCycle, SIXTY_HZ_INTERVAL_MS);
    break;
  }

}


// a little state machine
// must return control immediately on serial rx
void screenSaver() {
  static int timer = 0;
  
  while (Serial.available() <= 0) {
    switch(ss_state) {
    case FREEFALL:
      if (timer >= FREEFALL_TIMEOUT) {
        timer = 0;
        ss_state = HOVER;
        setNewPwm(tonePin, toneDutyCycle, HOVER);
      } 
      else {
        timer++;
      }
      break;
    case HOVER:
      if (timer >= HOVER_TIMEOUT) {
        timer = 0;
        ss_state = CREEP;
        setNewPwm(tonePin, toneDutyCycle, CREEP);
      } 
      else {
        timer++;
      }
      break;
    case CREEP:
      if (timer >= CREEP_TIMEOUT) {
        timer = 0;
        ss_state = FREEFALL;
        setNewPwm(tonePin, toneDutyCycle, FREEFALL);
      } 
      else {
        timer++;
      }
      break;
    default:
      // huh?
      timer = 0;
        setNewPwm(tonePin, toneDutyCycle, HOVER);
      ss_state = HOVER;
    }
    delay(CTRL_DELAY);
  }
}


void setNewPwm (int tonePin, int toneDutyCycle, int period) {
  
  if (DEBUG) {
    Serial.print("setting:" );
    Serial.println(period );
  }
  
  Timer1.pwm(tonePin, toneDutyCycle, period);
}

