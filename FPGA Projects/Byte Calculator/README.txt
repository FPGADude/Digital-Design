*** Byte Calculator on BASYS 3 FPGA ***
*** Created by: David J. Marion
*** Creation date: 1/26/2022

- Set two 8 bit values in switches and perform 5 different mathematical operations on them 
  with buttons, and the outcome of the operation is displayed in binary on 16 LEDs.

Basys 3 Components and purpose:
	16 - switches - 8 of them for byte operand A
		      - 8 of them for byte operand B
	16 - LEDs - to display outcome of math operation on operands A and B
	5 - buttons - one for each math operation:
			- addition
			- subtraction
			- multiplication
			- division
			- modulus