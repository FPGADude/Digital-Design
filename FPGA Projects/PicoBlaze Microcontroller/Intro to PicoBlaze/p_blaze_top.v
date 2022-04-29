`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Create Date: 04/17/2022 01:15:23 PM
// Module Name: p_blaze_top
// Target Devices: Basys 3 w/ Artix-7 35T
// Tool Versions: Vivado 2021.2
// Description: First attempt at using PicoBlaze microcontroller.
//////////////////////////////////////////////////////////////////////////////////

module p_blaze_top(
    input clk,          // 100MHz from Basys 3
    input [7:0] sw,     // 8 switches
    output [7:0] LED    // 8 LEDs
    
    );
    
    // Signals for connection of KCPSM6 and Program Memory.
    wire	[11:0]	address;
    wire	[17:0]	instruction;
    wire			bram_enable;
    wire	[7:0]		port_id;
    wire	[7:0]		out_port;
    reg	[7:0]		in_port;
    wire			write_strobe;
    wire			k_write_strobe;
    wire			read_strobe;
    reg			interrupt;            //See note above
    wire			interrupt_ack;
    wire			kcpsm6_sleep;         //See note above
    reg			kcpsm6_reset;         //See note above
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // Instantiate KCPSM6 and connect to Program Memory
    /////////////////////////////////////////////////////////////////////////////////////////
    //
    // The KCPSM6 parameters can be defined as required but the default values are shown below
    // and these would be adequate for most designs.
    /////////////////////////////////////////////////////////////////////////////////////////

    // The PicoBlaze microcontroller
    kcpsm6 #(
	   .interrupt_vector	(12'h3FF),
	   .scratch_pad_memory_size(64),
	   .hwbuild		(8'h00))
    processor (
	   .address 		(address),
	   .instruction 	(instruction),
	   .bram_enable 	(bram_enable),
	   .port_id 		(port_id),
	   .write_strobe 	(write_strobe),
	   .k_write_strobe 	(k_write_strobe),
	   .out_port 		(out_port),
	   .read_strobe 	(read_strobe),
	   .in_port 		(in_port),
	   .interrupt 		(interrupt),
	   .interrupt_ack 	(interrupt_ack),
	   .reset 		(kcpsm6_reset),
	   //.reset 		(kcpsm6_reset),
	   .sleep		(kcpsm6_sleep),
	   .clk 			(clk));
    
   // Program Memory with my assy program in it 
   First_PicoBlaze_assy_program #(    //Name to match your PSM file
	.C_FAMILY		   ("V6"),   	  //Family 'S6' or 'V6'
	.C_RAM_SIZE_KWORDS	(2),  	      //Program size '1', '2' or '4'
	.C_JTAG_LOADER_ENABLE	(1))  	  //Include JTAG Loader when set to '1' 
  program_rom (    				      // Rename if using more than 1 ROM
 	.rdl 			(),               // Try leaving it unconnected
 	//.rdl 			(kcpsm6_reset),   // Leaving this connected throws an error in synthesis
	.enable 		(bram_enable),
	.address 		(address),
	.instruction 	(instruction),
	.clk 			(clk));
    
    // My design logic
    // Set Pblaze input port to the value of switches
    always @(posedge clk)
        in_port = sw;
    
    // Set LEDs to the value of Pblaze output port
    assign LED = out_port;
    
endmodule
