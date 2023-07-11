// Created by David J. Marion
// Date: 5.2.2023
// Updated: 6.7.2023 for CPU_B (added a reset input)
// Purpose: testing the 7-Step Processor by loading the RAM from a ROM
//
// Total nanoseconds to complete data transfer for sum5.asm = 
// --------------------------------------------------------------------------------------------------------

`timescale 1ns / 1ps
module fsm_load_ram(
// Inputs
	input step_clk,							// stepper clock from CPU clock gen
	input reset,							// hold state machine at state 0
	input clk_e,							// enable clock from CPU clock gen
	input clk_s,							// set clock from CPU clock gen
	input [7:0] noi,						// number of instructions from ROM
// Outputs
	output loading_ram,						// loading RAM in progress
	output set_address,						// signal ROM and RAM to set address
	output enable_rom,						// signal ROM to enable instruction onto data bus
	output set_ram,							// signal RAM to set instruction on data bus from ROM
	output reg [7:0] address = 8'h00		// 8-bit address to set in ROM and RAM
);
	
	// State Parameters
	parameter INIT 		= 2'b00,			// initialize instruction count
			  SET_ADDR  = 2'b01,			// set addresses of RAM and ROM
			  SET_RAM 	= 2'b10,			// transfer data from ROM to RAM
			  DONE		= 2'b11;			// RAM loading complete

	reg [7:0] instr_count;					// number of instructions to load into RAM
	reg [1:0] state_reg = INIT;				// state register
	
	// State Logic
	always @(posedge step_clk or posedge reset) begin	// asynchronous reset
		if(reset)
			state_reg <= INIT;
		else
			case(state_reg)
				INIT :
					begin
						instr_count <= noi;			// initialize count with the number of instructions in ROM
						state_reg <= SET_ADDR;		// go to set address state
					end
					
				SET_ADDR : 
					state_reg <= SET_RAM;			// go to set ram state
				
				SET_RAM : 
					begin
						instr_count = instr_count - 1;			// decrement instruction count
						address = address + 1;					// increment ROM/RAM address
						if(instr_count == 0)					// no more instructions?
							state_reg <= DONE;					// we're done.
						else									// otherwise,
							state_reg <= SET_ADDR;				// go to the next address for next instruction.
					end

				DONE : 
					begin
						address = 8'h00;
						state_reg <= DONE;			// stay here and do nothing
					end
			endcase
	end
	
	assign loading_ram = !(state_reg == DONE);			// Output = 1 to signal RAM loading in progress, except when DONE
	assign set_address = (state_reg == SET_ADDR) & clk_s;// Set ROM/RAM address during clk s time of SET_ADDR state
	assign enable_rom = (state_reg == SET_RAM) & clk_e;	// Enable data from ROM during clk e time of SET_RAM state
	assign set_ram = (state_reg == SET_RAM) & clk_s;	// Set RAM with data from ROM during clk s time of SET_RAM state
	
endmodule