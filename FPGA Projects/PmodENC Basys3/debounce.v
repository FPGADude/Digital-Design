`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineers: Michelle Yu
//				  Josh Sackos
// 
// Create Date:    16:54:39 06/11/2012 
// Design Name: 
// Module Name:    Debouncer 
// Project Name: 	 PmodENC
// Target Devices: Nexys 3 
// Tool versions: Xilinx ISE Design Suite 14.1
//
// Description: 
//	This file defines a debouncer for eliminating the logic noise presented when the shaft is rotated.
//
// Revision: 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
module debounce(
    input clk,
    input Ain,
    input Bin,
    output Aout,
    output Bout
    );

	 // ===========================================================================
	 // 							  Parameters, Regsiters, and Wires
	 // ===========================================================================
	 reg r_Aout = 0;
	 reg r_Bout = 0;

	 reg [6:0] sclk = 0;
	 reg sampledA = 0;
	 reg sampledB = 0;
	 
	 // ===========================================================================
	 // 										Implementation
	 // ===========================================================================
	 always @(posedge clk) begin
			sampledA <= Ain;
			sampledB <= Bin;
			// clock is divided to 1MHz
			// samples every 1uS to check if the input is the same as the sample
			// if the signal is stable, the debouncer should output the signal
			
			if(sclk == 100) begin
					if(sampledA == Ain) begin
							r_Aout <= Ain;
					end
					
					if(sampledB == Bin) begin
							r_Bout <= Bin;
					end
					
					sclk <= 0;
			end
			else begin
					sclk <= sclk + 1;
			end
	 end

    assign Aout = r_Aout;
    assign Bout = r_Bout;

endmodule
