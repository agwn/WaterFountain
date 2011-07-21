/* 
 * input: buttons
 * output: serial data stream of chars for each button pressed
 * licence: this code is too crap to own, have at it
 */

// pins defined
//
// const
int buttonInPin[] = {5, 4, 6};
int buttonOutPin[] = {7, 8, 10};
//
// tone vars defined
//
// const
char tones[] = {'a', 'b', 'c'};
int toneCount = 3;

//
// button vars
//
// const
int buttonCount = 3;
long debounceThreshold = 150; //ms


//loop vars
//
// globals
int state[] = {0, 0, 0};
int reading[] = {0, 0, 0};
long lastReading[] = {0, 0, 0}; //ms

// do this once
void setup () {
  Serial.begin(57600);
  for (int i = 0; i<buttonCount; i++) {
    pinMode(buttonInPin[i], INPUT);
    pinMode(buttonOutPin[i], OUTPUT);
    digitalWrite(buttonOutPin[i], HIGH);
  }
  
  return;
}

// do this everytime
void loop() {
  
  readButtons();
  writeButtons();
  saveReadings(); 

  return;  
}

//do this to read inputs into globals
void readButtons() {
  
  for (int i = 0; i<buttonCount; i++) {
    reading[i] = digitalRead(buttonInPin[i]);
    
    if (reading[i] != state[i]) {
      // reset the debouncing timer
      lastReading[i] = millis();
    } 
    
    if ((millis() - lastReading[i]) > debounceThreshold) {
      state[i] = reading[i];
      if (state[i]) {
        
        // output good stuff now
        Serial.println(tones[i % toneCount]);

      }
    }
  
  } // end button loop
  
  
  return;
}

// do this to react to latest settings
void writeButtons() {
  
  for (int i = 0; i<buttonCount; i++) {
    digitalWrite(buttonOutPin[i], state[i]); 
  }
  
  return;
}

// save state for next loop
void saveReadings() {
  
  for (int i = 0; i<buttonCount; i++) {
  // save the reading.  Next time through the loop,
  // it'll be the lastButtonState:
   state[i] = reading[i];
  }
  
  return; 
}
