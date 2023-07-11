// ***** Expected Control Unit Behavior *******************************
		// 		Stimulus Signals:
		//			-sys_clk
		//			-instruction[0:7]
		//			-flags[3:0]
		//
		// For all instructions:
		// Step 1:
		//		- Enables: Bus 1, IAR
		//		- Sets: MAR, ACC
		// Step 2:
		//		- Enables: RAM
		//		- Sets: IR
		// Step 3:
		//		- Enables: ACC
		//		- Sets: IAR
		//
		// For ALU instructions:
		// Step 4:
		//		- Enables: Reg B
		//		- Sets: TMP
		// Step 5:
		//		- Enables: Reg A
		//		- Sets: ACC
		//		* Opcode is driven to ALU.
		// Step 6: 
		//		if not CMP operation:
		//			Enable: ACC
		//			Set: Reg B
		//		else:
		//			Do nothing.
		//
		// For non-ALU operations:
		// Load:
		//	Step 4:
		//		- Enables: Reg A
		//		- Sets: MAR
		// 	Step 5:
		//		- Enables: RAM
		//		- Sets: Reg B
		//	Step 6:
		//		- Do nothing.
		//
		// Store:
		//	Step 4:
		//		- Enables: Reg A
		//		- Sets: MAR
		//	Step 5:
		//		- Enables: Reg B
		//		- Sets: RAM
		//	Step 6:
		//		- Do nothing.
		//
		// Data:
		//	Step 4:
		//		- Enables: IAR, Bus 1
		//		- Sets: MAR, ACC
		// 	Step 5:
		//		- Enables: RAM
		//		- Sets: Reg B
		//	Step 6:
		//		- Enables: ACC
		//		- Sets: IAR
		//
		// Jump Register:
		//  Step 4:
		//		- Enables: Reg B
		//		- Sets: IAR
		//	Step 5:
		//		- Do nothing.
		//	Step 6:
		//		- Do nothing.
		//
		// Jump:
		//	Step 4:
		//		- Enables: IAR
		//		- Sets: MAR
		//	Step 5:
		//		- Enables: RAM
		//		- Sets: IAR
		//	Step 6:
		//		- Do nothing.
		//
		// Jump If:
		//	Step 4:
		//		- Enables: IAR, Bus 1
		//		- Sets: MAR, ACC
		//	Step 5:
		//		- Enables: ACC
		//		- Sets: IAR
		//	Step 6:
		//		if a tested flag is detected:
		//			- Enable: RAM
		//			- Set: IAR
		//		else:
		//			- Do nothing.
		//
		// Clear Flags:
		// 	Step 4: 
		//		- Enables: Bus 1
		//		- Sets: Flags register
		// 	Step 5:
		//		- Do nothing.
		//	Step 6:
		//		- Do nothing.
		//
		// I/O Instructions:
		// IN:
		//	Step 4:
		//		- Do nothing.
		//	Step 5:
		//		- Enables: I/O clk e
		//		- Sets: Reg B
		// 	Step 6:
		//		- Do nothing.
		// OUT:
		//	Step 4:
		//		- Enables: Reg B
		//		- Sets: I/O clk s
		// 	Step 5:
		//		- Do nothing.
		//  Step 6:
		//		- Do nothing.
		// ***********************************************************

// Revised TEST BENCH for control.v (*Changes based on CPU_B design)
// Comments: Device Under Test (control.v) is (** VERIFIED **) 6.6.2023
// ---------------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module control_TB;
// Signals to and from the DUT
	// For inputs
	reg sys_clk;
	reg reset;
	reg [0:7] instruction;
	reg [3:0] flags;
	// For outputs
	wire s_R0, s_R1, s_R2, s_R3, s_MAR, s_RAM, s_IR, s_IAR, s_ACC, s_FLAGS, BUS1, s_TMP;
	wire [2:0] alu_op;
	wire e_R0, e_R1, e_R2, e_R3, e_RAM, e_IAR, e_ACC;
	wire IO_clk_e, IO_clk_s, IO_data_or_address, IO_input_or_output;
	// Added for CPU_B
	wire [1:6] step;
	wire flags_detected;
	
// The device under test DUT
	control DUT(
	// Inputs
		.sys_clk(sys_clk),						// main system input clock
		.reset(reset),		  					// reset system back to program start address and step 1
		.instruction(instruction),				// 8-bit data from IR
		.flags(flags),							// from Flags Register [3:0] -> 3:C 2:A 1:E 0:Z
	// Outputs
		// All sets
		.s_R0(s_RO), .s_R1(s_R1), .s_R2(s_R2), .s_R3(s_R3),	// gp registers set inputs
	
		.s_MAR(s_MAR), .s_RAM(s_RAM),						// main memory inputs
	
		.s_IR(s_IR), .s_IAR(s_IAR), .s_ACC(s_ACC), 			// registers set inputs
		
		.s_FLAGS(s_FLAGS),									// flag register set input
	
		.OPCODE(alu_op),									// alu input
	
		.BUS1(BUS1), .s_TMP(s_TMP),							// alu operand b data path inputs
	
		// All enables
		.e_R0(e_R0), .e_R1(e_R1), .e_R2(e_R2), .e_R3(e_R3),	// gp register enable inputs
	
		.e_RAM(e_RAM), .e_IAR(e_IAR), .e_ACC(e_ACC),		// memory, registers enable inputs
	
		// I/O Bus
		.IO_clk_e(IO_clk_e), .IO_clk_s(IO_clk_s), 
		.IO_data_or_address(IO_data_or_address), .IO_input_or_output(IO_input_or_output),
		
		// Added for CPU_B
		.step(step), .flags_detected(flags_detected)
	);

// Icarus Verilog setup for GTKWave
	initial begin
		$dumpfile("control.vcd");
		$dumpvars(0, control_TB);
	end

// System Clock
	always #1 sys_clk = ~sys_clk;

// Simulation Block
	initial begin
		// Initialization
		// ALU Instructions
		instruction = 8'b1000_0001;			// ADD from R0 and R1
		sys_clk = 0;
		flags = 4'h0;
		reset = 1;
		#48;								// simulation period of an instruction cycle
		reset = 0;							// 8 ticks of sys_clk * 6 steps = 48 sim ticks
		#48;								// the ADD instruction is carried out
			
		instruction = 8'b1001_0110;			// SHL contents of R1 into R2
		#48;
		
		instruction = 8'b1010_1011;			// SHR contents of R2 into R3
		#48;
		
		instruction = 8'b1011_1100;			// NOT contents of R3 into R0
		#48;
		
		instruction = 8'b1100_0001;			// AND R0 with R1 into R1
		#48;
		
		instruction = 8'b1101_0110;			// OR R1 with R2 into R2
		#48;
		
		instruction = 8'b1110_1011;			// XOR R2 with R3 into R3
		#48;
		
		instruction = 8'b1111_1100;			// CMP R3 with R0 to set flags
		#48;
	
	
	// Non-ALU Instructions
		instruction = 8'b0000_1011;			// Load R3 with RAM address from R2
		#48;
		
		instruction = 8'b0001_0001;			// Store R1 with RAM address from R0
		#48;
		
		instruction = 8'b0010_0010;			// Data, load next byte in RAM into R2
		#48;
		
		instruction = 8'b0011_1100;			// Jump Register, jump to address in R0
		#48;
		
		instruction = 8'b0100_0011;			// Jump, jump to address in next RAM byte
		#48;
		
		
		// Jump If, special instruction with multiple cases involving the Flags Register
		instruction = 8'b0101_1000;			// Jump if C flag set (Carry out from add or shift)
		#48;								// No jump should occur
			
		flags = 4'b0110;
		instruction = 8'b0101_0100;			// Jump if A flag set (A > B)
		#48;
			
		instruction = 8'b0101_0010;			// Jump if E flag set (A == B)
		#48;
			
		flags = 4'b1001;
		instruction = 8'b0101_0001;			// Jump if Z flag set (ALU result = 0)
		#48;
			
		instruction = 8'b0101_0110;			// Jump if A and E flags set (A >= B)
		#48;								// No jump should occur
			
		instruction = 8'b0101_1001;			// Jump if C and Z flags set
		#48;
		// End of Jump If instructions
		
		
		instruction = 8'b0110_0000;			// Clear Flags --> ADD 0 + 1 in ALU and set flags to 4'b0000
		#48;
		
		
		// I/O, special instruction with multiple cases
		instruction = 8'b0111_0000;			// Input I/O Data to R0
		#48;
			
		instruction = 8'b0111_0101;			// Input I/O Address to R1
		#48;
			
		instruction = 8'b0111_1010;			// Output R2 to I/O as Data
		#48;
			
		instruction = 8'b0111_1111;			// Output R3 to I/O as Address
		#48;
		// End of I/O instructions
		
		$finish;
	end

endmodule