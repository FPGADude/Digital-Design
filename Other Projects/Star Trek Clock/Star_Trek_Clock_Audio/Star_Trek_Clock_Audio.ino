/*
* Sound System
* 
* For the Star Trek clock.
* 
*/
#include "SoftwareSerial.h"

SoftwareSerial mySerial(10, 11);

#define Start_Byte 0x7E
#define Version_Byte 0xFF
#define Command_Length 0x06
#define End_Byte 0xEF
#define Acknowledge 0x00 //Returns info with command 0x41 [0x01: info, 0x00: no info]

int play_audio1 = 8;  // signal to play opening theme
int play_audio2 = 13; // signal to play Spock quote

void setup () {

  pinMode(play_audio1, INPUT); // signals from clock
  pinMode(play_audio2, INPUT); // signals from clock

  mySerial.begin (9600);
  delay(1000);
  setVolume(20);  // set volume through function
}

void loop () {
  // Incoming signals from clock
  if(digitalRead(play_audio1) == HIGH){
    execute_CMD(0x03,0, 0001);
    delay(500);
  }
  if(digitalRead(play_audio2) == HIGH){
    execute_CMD(0x03,0,0002);
    delay(500);
  }
}

void setVolume(int volume)
{
  execute_CMD(0x06, 0, volume); // set the volume (0 - 30)
  delay(2000);
}

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
