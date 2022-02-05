*** Coffee Machine Simulator on Basys 3 FPGA ***
*** Created by: David J. Marion
*** Creation date: 2/4/2022

Simulates a Keurig machine:
	BASYS 3 Components and their purpose:
	1 - switch - for simulating opening the top, placing a k-cup in, and shutting the top
	4 - 7-segment displays - informing how much water remains for coffee making, in unit of cups
			       - informing when filling a cup with coffee is done
			       - informing when the water needs filled 				
	16 - LEDs - one LED blinks after putting in a k-cup in a ready state
		  - all 16 LEDs simulate the cup filling up with coffee
	3 - buttons - one for reset
		    - one to make the cup of coffee once in the ready state after inserting a k-cup
		    - one to simulate filling the machine with water
	1 - clock signal - 100MHz clock from Basys 3 for system synchronization