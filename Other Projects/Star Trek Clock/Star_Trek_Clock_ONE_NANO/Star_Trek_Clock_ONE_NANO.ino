/*
* Arduino Binary Clock 
* 
* Created By:  David J. Marion
* Last Edited: 6.5.2022
* 
* Purpose: For the Star Trek Clock. The circuit includes: 1 - Arduino Nano, 
*          1 - DF Player Mini, 1 - MicroSD Card, 1 - 8ohm Speaker, 12 - LEDs, 
*          1 - 1k ohm Resistor, 11 - 330 ohm Resistors, and 2 - Push Buttons.
*/

// For DF Player Mini
#include "SoftwareSerial.h"
SoftwareSerial mySerial(8, 13);             // RX/TX are pins D8 and D13
#define Start_Byte 0x7E
#define Version_Byte 0xFF
#define Command_Length 0x06
#define End_Byte 0xEF
#define Acknowledge 0x00                    //Returns info with command 0x41 [0x01: info, 0x00: no info]

// 4 bits of LEDs for the hour
const int h0 = 9;                           // bit[0] is pin D9
const int h1 = 10;                          // bit[1] is pin D10
const int h2 = 11;                          // bit[2] is pin D11
const int h3 = 12;                          // bit[3] is pin D12

// 6 bits of LEDs for the minute
const int m0 = 2;                           // bit[0] is pin D2
const int m1 = 3;                           // bit[1] is pin D3
const int m2 = 4;                           // bit[2] is pin D4
const int m3 = 5;                           // bit[3] is pin D5
const int m4 = 6;                           // bit[4] is pin D6
const int m5 = 7;                           // bit[5] is pin D7

// Variables used in the program
const unsigned long period = 1000;          //one second
const unsigned long led_period = 500;       //LED blink millisecond
unsigned long startMillis;
unsigned long led_startMillis;
unsigned long currentMillis;
unsigned long led_currentMillis;
const int hrs_btn = A0;                     // Increment Hours counter by button is pin A0
const int min_btn = A1;                     // Increment Minutes counter by button is pin A1
const int ledPin = A2;                      // seconds blinker is pin A2
int Hrs = 12;                               // Create and initialize the Hours counter to 12
int Min = 0;                                // Create and intialize the Minutes counter to 0
int Sec = 0;                                // Create and initialize the Seconds counter to 0
int ledState = LOW;                         // Create and initialize LED blinker state to OFF
bool PLAYED_HOURLY = false;                 // Boolean 1 for audio control
bool PLAYED_HALF = false;                   // Boolean 2 for audio control

void setup() {                              // Set up Arduino pins for I/O operations
  // For Clock
  pinMode(m0, OUTPUT);                      // LED
  pinMode(m1, OUTPUT);                      // LED
  pinMode(m2, OUTPUT);                      // LED
  pinMode(m3, OUTPUT);                      // LED
  pinMode(m4, OUTPUT);                      // LED
  pinMode(m5, OUTPUT);                      // LED
  pinMode(h0, OUTPUT);                      // LED
  pinMode(h1, OUTPUT);                      // LED
  pinMode(h2, OUTPUT);                      // LED
  pinMode(h3, OUTPUT);                      // LED
  pinMode(hrs_btn, INPUT_PULLUP);           // BUTTON
  pinMode(min_btn, INPUT_PULLUP);           // BUTTON
  pinMode(ledPin, OUTPUT);                  // 2 LEDs

  // For Audio
  mySerial.begin (9600);
  delay(1000);
  setVolume(20);                            // Set speaker volume using the function (0 - 30)
}

void loop() {
  // CLOCK CREATION
  currentMillis = millis();
  if (currentMillis - startMillis >= period)        // Greater than or equal to 1000ms(1 second)
  {
    Sec = Sec + 1;
    startMillis = currentMillis;
  }
  led_currentMillis = millis();
  if (led_currentMillis - led_startMillis >= led_period)  // Greater than or equal to 500ms(1/2 second)
  {
    led_startMillis = led_currentMillis;
    if (ledState == LOW)
    {
      ledState = HIGH;                              // Seconds blinker ON
      if (digitalRead(hrs_btn) == LOW)              // At Increment Hours Button Press
      {
        Hrs = Hrs + 1;                              // Increment Hours by 1
      }
      if (digitalRead(min_btn) == LOW)              // At Increment Minutes Button Press
      {
        Min = Min + 1;                              // Increment Minutes by 1
        Sec = 0;                                    // Reset Seconds to 0
      }
    }
    else
    {
      ledState = LOW;                               // Seconds blinker OFF
    }
    digitalWrite(ledPin, ledState);                 // Turn Seconds blinker ON/OFF based on ledState HIGH/LOW
  }
  
  // COUNTER CONTROL
  if (Sec == 60)                                    // At 60 Seconds
  {
    Sec = 0;                                        // Reset Seconds to 0
    Min = Min + 1;                                  // Increment Minutes by 1
  }
  if (Min == 60)                                    // At 60 Minutes
  {
    Min = 0;                                        // Reset Minutes to 0
    Hrs = Hrs + 1;                                  // Increment Hours by 1
  }
  if (Hrs == 13)                                    // At 13 Hours
  { 
    Hrs = 1;                                        // Reset Hours to 1
  }

  // MUSIC CONTROL
  if(Min == 59 && Sec == 0){                        // At 59 Minutes and 0 seconds
    PLAYED_HOURLY = false;                          // Set Boolean 1 to false to play audio track
  }
  if(Min == 29 && Sec == 0){                        // At 29 Minutes and 0 Seconds
    PLAYED_HALF = false;                            // Set Boolean 2 to false to play audio track
  }
  
  // Every hour on the hour play track 0001
  if(Min == 0 && Sec == 0 && !PLAYED_HOURLY){       // At 0 Minutes and 0 Seconds and Boolean 1 is false
    execute_CMD(0x03,0, 0001);                      // Play audio track 0001
    delay(250);                                     // Hold for 1/4 second
    PLAYED_HOURLY = true;                           // Set Boolean 1 to true so audio does not repeat
  }
  
  // Every half-hour play track 0002
  if(Min == 30 && Sec == 0 && !PLAYED_HALF){        // At 30 Minutes and 0 Seconds and Boolean 2 is false
    execute_CMD(0x03,0,0002);                       // Play audio track 0002
    delay(250);                                     // Hold for 1/4 second
    PLAYED_HALF = true;                             // Set Boolean 2 to true so audio does not repeat
  }

  // Slow down a fast running clock
  if(Min == 45 && Sec == 0){                        // At an arbitrary Minute value and 0 Seconds
    delay(5000);                                    // 5 seconds delay to slow down clock, without this delay clock runs a little fast
  }

  // HOURS LED CONTROL
  // switch-case to set LED value based on Hours decimal value
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
  // switch-case to set LED value based on Minutes decimal value 
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

// FUNCTION: To set speaker volume through DF Player Mini
void setVolume(int volume)  
{
  execute_CMD(0x06, 0, volume); // set the volume (0 - 30)
  delay(2000);
}

// FUNCTION: To send commands to DF Player Mini
void execute_CMD(byte CMD, byte Par1, byte Par2)
// Excecute the command and parameters
{

  // Calculate the checksum (2 bytes)
  word checksum = -(Version_Byte + Command_Length + CMD + Acknowledge + Par1 + Par2);

  // Build the command line
  byte Command_line[10] = { Start_Byte, Version_Byte, Command_Length, CMD, Acknowledge,
  Par1, Par2, highByte(checksum), lowByte(checksum), End_Byte};

  //Send the command line to the module
  for (byte k=0; k<10; k++)
  {
    mySerial.write( Command_line[k]);
  }
}
