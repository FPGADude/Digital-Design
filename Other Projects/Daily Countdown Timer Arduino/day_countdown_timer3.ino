/*
* A 4-digit 7-segment display daily countdown timer.
* Created for my brother, Keith Marion.
* 
* Created for the Nano. Prototyped on the Uno.
*
* By David J. Marion
* 8.11.2023
*/

// Define the pins for the seven-segment display segments
const int segmentPins[7] = {6, 7, 8, 9, 10, 11, 12};

// Define the common pins for each display
const int commonPins[4] = {5, 4, 3, 2};

// Define the patterns for each digit (0-9)
const byte digitPatterns[10] = {
  B11000000,  // 0
  B11111001,  // 1
  B10100100,  // 2
  B10110000,  // 3
  B10011001,  // 4
  B10010010,  // 5
  B10000010,  // 6
  B11111000,  // 7
  B10000000,  // 8
  B10010000   // 9
};

// 4 buttons to increment each digit
const int b0 = A3;
const int b1 = A2;
const int b2 = A1;
const int b3 = A0;

long day_count = 0;
int ones;
int tens;
int hundreds;
int thousands;
int dbState = LOW;

// The following is for test and demonstration purposes
//const int t_interval = 10000;   // 10000 ms = 10 seconds

const unsigned long interval = 24UL * 60UL * 60UL * 1000UL; // 24 hours in milliseconds
const unsigned long db_period = 500;

unsigned long previousMillis = 0;
unsigned long currentMillis = 0;
unsigned long db_startMillis;
unsigned long db_currentMillis;

void setup() {
  for (int i = 0; i < 7; i++) {
    pinMode(segmentPins[i], OUTPUT);
  }
  for (int i = 0; i < 4; i++) {
    pinMode(commonPins[i], OUTPUT);
    digitalWrite(commonPins[i], HIGH); // Turn off all displays initially
  }

  pinMode(b0, INPUT_PULLUP);
  pinMode(b1, INPUT_PULLUP);
  pinMode(b2, INPUT_PULLUP);
  pinMode(b3, INPUT_PULLUP);
}

void loop() {
  currentMillis = millis();

  if ((currentMillis - previousMillis) >= interval) {
    previousMillis = currentMillis - ((currentMillis - previousMillis) % interval);
    if (day_count > 0){
      day_count--; 
    }    
  }

  db_currentMillis = millis();
  if (db_currentMillis - db_startMillis >= db_period){
    db_startMillis = db_currentMillis;
    if (dbState == LOW){
      dbState = HIGH;
      if (digitalRead(b0) == LOW) {
        day_count += 1000;
        if (day_count >= 10000) {
          day_count -= 10000;
        }
      }
      if (digitalRead(b1) == LOW) {
        day_count += 100;
      }
      if (digitalRead(b2) == LOW) {
        day_count += 10;
      }
      if (digitalRead(b3) == LOW) {
        day_count += 1;
      }
    }
    else {
      dbState = LOW;
    }
  }
  
  // Break out digit values
  thousands = day_count / 1000;
  hundreds = (day_count / 100) % 10;
  tens = (day_count / 10) % 10;
  ones = day_count % 10;
  
  // Display each digit value
  displayDigit(thousands, 0);
  displayDigit(hundreds, 1);
  displayDigit(tens, 2);
  displayDigit(ones, 3);
}

// User Function - sets the segment pattern and toggles digit on/off
void displayDigit(int digit, int position) {
  for (int i = 0; i < 7; i++) {
    digitalWrite(segmentPins[i], (digitPatterns[digit] >> i) & 1);
  }
  digitalWrite(commonPins[position], HIGH);
  delay(1);
  digitalWrite(commonPins[position], LOW);
}