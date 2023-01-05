/*
* Basic Binary Clock Program
* 
* By David J. Marion
* 
*/

// 4 bits (LEDs) for the hour
const int h0 = 9;
const int h1 = 10;
const int h2 = 11;
const int h3 = 12;

// 6 bits (LEDs) for the minute
const int m0 = 2;
const int m1 = 3;
const int m2 = 4;
const int m3 = 5;
const int m4 = 6;
const int m5 = 7;

// 1 bit (LED) for the seconds blinker
const int ledPin = A2;

// 2 buttons (1 to set hours, 1 to set minutes)
const int hrs_btn = A0;
const int min_btn = A1;

// Everything needed to create an internal 12 hour clock
const unsigned long period = 1000;          // 1000 milliseconds (ms) = 1 second
const unsigned long led_period = 500;       // LED blink period, 500 ms = 1/2 second
unsigned long startMillis;
unsigned long led_startMillis;
unsigned long currentMillis;
unsigned long led_currentMillis;

// On power up the clock is set to 12:00
int Hrs = 12;
int Min = 0;
int Sec = 0;
int ledState = LOW;

void setup() {
  pinMode(m0, OUTPUT);
  pinMode(m1, OUTPUT);
  pinMode(m2, OUTPUT);
  pinMode(m3, OUTPUT);
  pinMode(m4, OUTPUT);
  pinMode(m5, OUTPUT);
  pinMode(h0, OUTPUT);
  pinMode(h1, OUTPUT);
  pinMode(h2, OUTPUT);
  pinMode(h3, OUTPUT);
  pinMode(hrs_btn, INPUT_PULLUP);
  pinMode(min_btn, INPUT_PULLUP);
  pinMode(ledPin, OUTPUT);
}

void loop() {
  // CLOCK CREATION
  currentMillis = millis();
  if (currentMillis - startMillis >= period)
  {
    Sec = Sec + 1;
    startMillis = currentMillis;
  }
  led_currentMillis = millis();
  if (led_currentMillis - led_startMillis >= led_period)
  {
    led_startMillis = led_currentMillis;
    if (ledState == LOW)
    {
      ledState = HIGH;
      if (digitalRead(hrs_btn) == LOW)
      {
        Hrs = Hrs + 1;
      }
      if (digitalRead(min_btn) == LOW)
      {
        Min = Min + 1;
        Sec = 0;
      }
    }
    else
    {
      ledState = LOW;
    }
    digitalWrite(ledPin, ledState);
  }
  
  // COUNTER CONTROL
  if (Sec == 60)
  {
    Sec = 0;
    Min = Min + 1;
  }
  if (Min == 60)
  {
    Min = 0;
    Hrs = Hrs + 1;
  }
  if (Hrs == 13)
  {
    Hrs = 1;
  }

  // HOURS LED CONTROL
  switch(Hrs){
    case 1 :  
      digitalWrite(h0, HIGH);
      digitalWrite(h1, LOW);
      digitalWrite(h2, LOW);
      digitalWrite(h3, LOW);
      break;
    case 2 :  
      digitalWrite(h0, LOW);
      digitalWrite(h1, HIGH);
      digitalWrite(h2, LOW);
      digitalWrite(h3, LOW);
      break;
    case 3 :  
      digitalWrite(h0, HIGH);
      digitalWrite(h1, HIGH);
      digitalWrite(h2, LOW);
      digitalWrite(h3, LOW);
      break;
    case 4 :  
      digitalWrite(h0, LOW);
      digitalWrite(h1, LOW);
      digitalWrite(h2, HIGH);
      digitalWrite(h3, LOW);
      break;
    case 5 :  
      digitalWrite(h0, HIGH);
      digitalWrite(h1, LOW);
      digitalWrite(h2, HIGH);
      digitalWrite(h3, LOW);
      break;
    case 6 :  
      digitalWrite(h0, LOW);
      digitalWrite(h1, HIGH);
      digitalWrite(h2, HIGH);
      digitalWrite(h3, LOW);
      break;
    case 7 :  
      digitalWrite(h0, HIGH);
      digitalWrite(h1, HIGH);
      digitalWrite(h2, HIGH);
      digitalWrite(h3, LOW);
      break;
    case 8 :  
      digitalWrite(h0, LOW);
      digitalWrite(h1, LOW);
      digitalWrite(h2, LOW);
      digitalWrite(h3, HIGH);
      break;
    case 9 :  
      digitalWrite(h0, HIGH);
      digitalWrite(h1, LOW);
      digitalWrite(h2, LOW);
      digitalWrite(h3, HIGH);
      break;
    case 10 :  
      digitalWrite(h0, LOW);
      digitalWrite(h1, HIGH);
      digitalWrite(h2, LOW);
      digitalWrite(h3, HIGH);
      break;
    case 11 :  
      digitalWrite(h0, HIGH);
      digitalWrite(h1, HIGH);
      digitalWrite(h2, LOW);
      digitalWrite(h3, HIGH);
      break;
    case 12 :  
      digitalWrite(h0, LOW);
      digitalWrite(h1, LOW);
      digitalWrite(h2, HIGH);
      digitalWrite(h3, HIGH);
      break;      
    }
    
  // MINUTES LED CONTROL  
  switch(Min){
    case 0 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 1 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 2 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 3 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 4 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 5 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 6 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 7 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 8 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 9 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 10 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 11 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 12 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 13 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 14 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 15 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, LOW);
      break;
    case 16 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 17 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 18 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 19 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 20 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 21 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 22 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 23 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 24 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 25 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 26 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 27 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 28 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 29 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 30 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 31 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, LOW);
      break;
    case 32 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 33 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 34 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 35 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 36 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 37 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 38 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 39 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 40 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 41 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 42 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 43 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 44 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 45 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 46 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 47 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, LOW);
      digitalWrite(m5, HIGH);
      break;
    case 48 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 49 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 50 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 51 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 52 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 53 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 54 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 55 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, HIGH);
      digitalWrite(m3, LOW);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 56 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 57 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, LOW);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 58 :
      digitalWrite(m0, LOW);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    case 59 :
      digitalWrite(m0, HIGH);
      digitalWrite(m1, HIGH);
      digitalWrite(m2, LOW);
      digitalWrite(m3, HIGH);
      digitalWrite(m4, HIGH);
      digitalWrite(m5, HIGH);
      break;
    }
}
