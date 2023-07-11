// TEST BENCH for ram.v
// Comments: Device Under Test (ram.v) is (** VERIFIED **)
// --------------------------------------------------------------------------------------
`timescale 1ns / 1ps
module ram_TB;
	reg [7:0] a;
	reg sa, s, e;
	reg [7:0] d_in;
	wire [7:0] d_out;
	integer i, j;
	
	ram RAM(
		.a(a),				// memory address
		.sa(sa),			// set memory address in memory address register
		.s(s),				// set data in memory at address in memory address register
		.e(e),				// enable data out from memory at address in memory address register
		.d_in(d_in),		// incoming data to be stored into memory
		.d_out(d_out)		// outgoing data to be loaded from memory
	);
	
	initial begin
		$dumpfile("ram.vcd");
		$dumpvars(0, ram_TB);
	end
	
	initial begin
		a = 8'h00;
		sa = 1'b0;
		s = 1'b0;
		e = 1'b0;
		d_in = 8'h00;
		i = 0;				// addressing begins at hex 00
		j = 255;			// data begins at the highest value, hex FF
		#20;
		
		// Set all memory locations with input data
		for(i=0; i<256; i++) begin
			a = i;			// set address input with i
			d_in = j;		// set data input with j
			sa = 1'b1;		// addr_reg <= a
			#20;
			sa = 1'b0;
			#20;
			s = 1'b1;		// mem_reg[addr_reg] <= d_in
			#20;
			s = 1'b0;
			#20;
			j--;			// decrement j
			#20;
		end
		
		// Enable all memory locations to output data
		for(i=0; i<256; i++) begin
			a = i;			// set address input with i
			sa = 1'b1;		// addr_reg <= a
			#20;
			sa = 1'b0;
			#20;
			e = 1'b1;		// d_out = mem_reg[addr_reg]
			#20;
			e = 1'b0;
			#20;
		end
		
		$finish;
	end
	
endmodule