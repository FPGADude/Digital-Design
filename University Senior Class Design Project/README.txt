For Colorado Technical University Senior Design Project.

SYNOPSIS
	The system was called the Sewer R.A.T.(Reconnaissance and Telemetry) and was designed to be used
	as a device that would traverse the inside of a residential sewer pipe in order to obtain a 
	3-dimensional image of the interior of the pipe. The purpose is to provide property owners with
	full visual image of the condition of their sewer pipe, versus a camera feed.

	The device, shaped like a small submarine, housed a 360 degree LiDAR(Light detection and ranging) 
	unit, an IMU(inertial measurement unit), and a microcontroller(Raspberry Pico) that would be used
	in capturing 3-dimensional data and transmitting the data to a laptop PC where a software program
	would take the 3D information and generate the image on the screen.

	A prototype was assembled and tested but ultimately the design did not work. The problem lied in 
	the UART communication between the LiDAR sensor and IMU sensor and the microcontroller. The LiDAR 
	and IMU sensors transmitted at different baud rates and their packetized serial information was of 
	different lengths. This presented a difficult hurdle to overcome during the short duration of the
	course. 

ASIC DESIGN
	The Verilog design files in this directory were created as an alternate solution in an attempt to 
	solve the UART communication issues for the LiDAR and IMU. The files herein contain only the modules
	created for capturing LiDAR data, which is packetized in 47 bytes of information and transmitted at
	a baud rate of 230,400. 

	The essence of the design is using a shift register to receive the LiDAR data packet in serial and
	then transfer the data in parallel to another register than would combine LiDAR and IMU data so as
	to obtain two sets of data within the same time frame for accurate 3D representation.

	The design files for the IMU data receiver were never created but would have included a state machine
	in order to configure the IMU for data transmission and a shift register to capture serial data from 
	the IMU. The IMU data would then have been parallel shifted to the register that would combine the 
	LiDAR and IMU data and then shift this data out serially to the laptop PC. 

David J Marion