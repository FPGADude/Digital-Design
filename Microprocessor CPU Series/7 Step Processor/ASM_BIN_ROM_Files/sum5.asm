;Written by David J. Marion
;6.10.2023
;Updated: 6.14.2023
;A simple program that adds the decimal numbers 0 through 5 and outputs the result (decimal 15).
;NOTE: The result of adding 0xFF (8'b1111_1111) to any 8-bit value is the same as subtracting 1 from the 8-bit value.
;      This is very useful in a loop that you want to run only a certain number of times.

top_label:                      ;This label will have the value of 0x00.
		DATA  R0,0              ;Opcode and operands to load 0 into R0, which is the accumulator for the sum.
		DATA  R1,0x05           ;Opcode and operands to load 0x05 (decimal 5) into R1.
		DATA  R2,0xFF           ;Opcode and operands to load 0xFF (-1 for signed bytes) into R2.

loop_top:                       ;This label marks the location in memory to be the top of the loop.
        ADD   R1,R0             ;Opcode and operands to add R1 to R0, result is in R0.
        ADD   R2,R1             ;Add -1 (stored in R2) to the value currently in R1.  NOTE: if R1 is now zero, the Z flag is set
        JZ    loop_exit         ;If Z flag is set, jump out of loop to "loop_exit"
        JMP   loop_top          ;Since Z flag is not set, jump to top of loop and continue through next pass.
 
loop_exit:                      ;This label marks where to go when the program exits the loop.
        OUT	  R0				;Output the result in R0 (should be 0x0F) to the CPU interface.

loop_forever:                   ;This label will be the top of the forever loop.
       JMP   loop_forever      ;Hold the processor in this infinite loop.
	   .BYTE 0