`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J Marion aka FPGA Dude
// Created on 4/29/2022
// Using Xilinx Vivado 2021.2
// Using Digilent Nexys A7-50T
// Using PicoBlaze microcontroller kcpsm6
//////////////////////////////////////////////////////////////////////////////////

module squares_top(
    input clk,          // 100MHz on Nexys A7
    input [7:0] SW,     // 8 switches
    output [7:0] LED    // 8 LEDs
    );
    
    reg [7:0] led_reg;
    
    // Signals for connection of KCPSM6 and Program Memory.
    wire	[11:0]	address;
    wire	[17:0]	instruction;
    wire			bram_enable;
    wire	[7:0]	port_id;
    wire	[7:0]	out_port;
    reg	    [7:0]   in_port;
    wire			write_strobe;
    wire			k_write_strobe;
    wire			read_strobe;
    reg			    interrupt;            
    wire			interrupt_ack;
    wire			kcpsm6_sleep;         
    reg			    kcpsm6_reset;         
    
    /////////////////////////////////////////////////////////////////////////////////////////
    // Instantiate KCPSM6 and connect to Program Memory
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
	   .reset 		    (kcpsm6_reset),
	   .sleep		    (kcpsm6_sleep),
	   .clk 			(clk));
    
   // Program Memory
   square #(    //Name to match your PSM file
	   .C_FAMILY		   ("V6"),   	  //Family 'S6' or 'V6'
	   .C_RAM_SIZE_KWORDS	(2),  	      //Program size '1', '2' or '4'
	   .C_JTAG_LOADER_ENABLE	(1))  	  //Include JTAG Loader when set to '1' 
  program_rom (    				      // Rename if using more than 1 ROM
 	   .rdl 			(),               // Try leaving it unconnected
 	//.rdl 			(kcpsm6_reset),   // Leaving this connected throws an error in synthesis
	   .enable 		    (bram_enable),
	   .address 		(address),
	   .instruction 	(instruction),
	   .clk 			(clk));
    
    // Logic for implementing switches and LEDs into design
    always @(posedge clk) begin
        in_port <= SW;
        if(write_strobe)
            led_reg <= out_port;
    end
    
    assign LED = led_reg;
    
endmodule
