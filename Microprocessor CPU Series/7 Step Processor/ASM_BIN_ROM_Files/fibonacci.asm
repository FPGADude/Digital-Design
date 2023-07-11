;Written by David J. Marion
;6.17.2023
;A program that outputs the first 12 numbers of the Fibonacci Sequence.

top_label:                      ;This label will have the value of 0x00.
		DATA  R0,0x00           ;Opcode and operands to load 0 into R0.	This is RB.
		DATA  R1,0x01           ;Opcode and operands to load decimal 1 into R1. This is RA.
		DATA  R2,0xFF           ;Opcode and operands to load 0xFF (-1 for signed bytes) into R2.
		DATA  R3,0x06			;Opcode and operands to load decimal 6 into R3. This is the loop variable.

loop_top:                       ;This label marks the location in memory to be the top of the loop.
        ADD   R1,R0             ;Opcode and operands to add R1 to R0, result is in R0.
		OUT   R0				;Opcode and operands to output the sum in R0.
		ADD   R0,R1				;Opcode and operands to add R0 to R1, result is in R1.
		OUT	  R1				;Opcode and operands to output the sum in R1.
		
        ADD   R2,R3             ;Add -1 (stored in R2) to the value currently in R3.  NOTE: if R3 is now zero, the Z flag is set
        JZ    loop_forever      ;If Z flag is set, jump out of loop to "loop_forever"
        JMP   loop_top          ;Since Z flag is not set, jump to top of loop and continue through next pass.

loop_forever:                   ;This label will be the top of the forever loop.
        JMP   loop_forever      ;Hold the processor in this infinite loop.
	    .BYTE 0