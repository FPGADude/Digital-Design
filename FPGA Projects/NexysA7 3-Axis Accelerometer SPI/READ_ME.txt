This project did not work.

// Comments: THIS DOES NOT WORK!
//           Synthesis - GOOD
//           Implementation - GOOD
//           Generate Bitstream - GOOD
//           Functionality on Nexys - NOT GOOD
//              The six 7-Segment Displays being used light up with 00 00 00,
//              and no change from moving the Nexys around. In theory, this
//              module should work, and we should see the six segments change
//              as the Nexys board is moved around as the accelerometer is
//              reading accelerations in X, Y, Z directions.
//           - Without any way to see what is going on after the board has been
//             programmed, we can only guess at what the problem might be.
//           - The only solution is to try other things and see if it works and
//             hopefully find what works.
//           - A good place to start is with the SPI Master module. Maybe, the
//             timing is not quite right.

I spent alot of time studying the ADXL362 data sheet and developing the SPI Master module,
but in the end it did not work.

I am posting this here for anyone who would like a starting point for the 3-axis accelerometer
on the Nexys A7, and hopefully you can figure it out. I am moving on, for now.