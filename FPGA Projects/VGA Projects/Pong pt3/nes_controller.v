`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////////////
// Retrieved from https://github.com/jconenna/Yoshis-Nightmare/blob/master/source/nes_controller.v
// Provided by embeddedthoughts.com
//////////////////////////////////////////////////////////////////////////////////////////////////

module nes_controller
	(
		input wire clk, reset, 
		input wire data,                                        // input data from nes controller to FPGA
		output reg latch, nes_clk,                              // outputs from FPGA to nes controller
		output wire A, B, select, start, up, down, left, right  // output states of nes controller buttons
        );
	
	// FSM symbolic states
	localparam [3:0] latch_en     = 4'h0,  // assert latch for 12 us
			 read_A_wait  = 4'h1,  // read A / wait 6 us
			 read_B       = 4'h2,  // read B ...
			 read_select  = 4'h3,  
		         read_start   = 4'h4,
		         read_up      = 4'h5,
			 read_down    = 4'h6,
			 read_left    = 4'h7,
			 read_right   = 4'h8;

	// register to count clock cycles to time latch assertion, nes_clk state, and FSM state transitions		 
	reg [10:0] count_reg, count_next;
	
	// FSM state register, and button state regs
	reg [3:0] state_reg, state_next;
	reg A_reg, B_reg, select_reg, start_reg,
	    up_reg, down_reg, left_reg, right_reg;
	reg A_next, B_next, select_next, start_next,
	   up_next, down_next, left_next, right_next;
	
	// infer all the registers
	always @(posedge clk, posedge reset)
		if (reset)
			begin
			count_reg  <= 0;
			state_reg  <= 0;
			A_reg      <= 0;
			B_reg      <= 0;
			select_reg <= 0;
			start_reg  <= 0;
			up_reg     <= 0;
			down_reg   <= 0;
			left_reg   <= 0;
			right_reg  <= 0;
			end
	    else
			begin
		        count_reg  <= count_next;
			state_reg  <= state_next;
			A_reg      <= A_next;
			B_reg      <= B_next;
			select_reg <= select_next;
			start_reg  <= start_next;
			up_reg     <= up_next;
			down_reg   <= down_next;
			left_reg   <= left_next;
			right_reg  <= right_next;
			end
			
	// FSM next-state logic and data path
	always@*
		begin
		// defaults
		latch       = 0;
		nes_clk     = 0;
		count_next  = count_reg;
		A_next      = A_reg;
		B_next      = B_reg;
		select_next = select_reg;
		start_next  = start_reg;
		up_next     = up_reg;
		down_next   = down_reg;
		left_next   = left_reg;
		right_next  = right_reg;
		state_next  = state_reg;
		
		case(state_reg)
			
			latch_en: 
					begin
					// assert latch pin
					latch = 1;
					
					// count 12 us
					if(count_reg < 1200)
						count_next = count_reg + 1;
					
					// once 12 us passed
					else if(count_reg == 1200)
						begin
						count_next = 0; // reset latch_count
						state_next = read_A_wait; // go to read_A_wait state
						end
					end
			
			read_A_wait:
					begin
					A_next = data; // read A
					
					if(count_reg < 600) // count clk cycles for 6 us
						count_next = count_reg + 1;
						
					// once 6 us passed
					else if(count_reg == 600)
						begin
						count_next = 0; // reset latch_count
						state_next = read_B; // go to read_B state
						end
					end
			
			read_B:	
					begin
					// count clk cycles for 12 us
					if(count_reg < 1200)
						count_next = count_reg + 1;
					
					// nes_clk state
					if(count_reg <= 600)
						nes_clk = 1;
					else if(count_reg > 600)
						nes_clk = 0;
					
					// read B
					if(count_reg == 600)
						B_next = data;
					
					// state over
					if(count_reg == 1200)
						begin
						count_next = 0; // reset latch_count
						state_next = read_select; // go to read_select state
						end
					end
			
			read_select:	
					begin
					// count clk cycles for 12 us
					if(count_reg < 1200)
						count_next = count_reg + 1;
					
					// nes_clk state
					if(count_reg <= 600)
						nes_clk = 1;
					else if(count_reg > 600)
						nes_clk = 0;
					
					// read select
					if(count_reg == 600)
						select_next = data;
					
					// state over
					if(count_reg == 1200)
						begin
						count_next = 0; // reset latch_count
						state_next = read_start; // go to read_start state
						end
					end			
			
			read_start:	
					begin
					// count clk cycles for 12 us
					if(count_reg < 1200)
						count_next = count_reg + 1;
					
					// nes_clk state
					if(count_reg <= 600)
						nes_clk = 1;
					else if(count_reg > 600)
						nes_clk = 0;
					
					// read start
					if(count_reg == 600)
						start_next = data;
					
					// state over
					if(count_reg == 1200)
						begin
						count_next = 0; // reset latch_count
						state_next = read_up; // go to read_up state
						end
					end
			
			read_up:	
					begin
					// count clk cycles for 12 us
					if(count_reg < 1200)
						count_next = count_reg + 1;
					
					// nes_clk state
					if(count_reg <= 600)
						nes_clk = 1;
					else if(count_reg > 600)
						nes_clk = 0;
					
					// read up
					if(count_reg == 600)
						up_next = data;
					
					// state over
					if(count_reg == 1200)
						begin
						count_next = 0; // reset latch_count
						state_next = read_down; // go to read_down state
						end
					end
					
			read_down:	
					begin
					// count clk cycles for 12 us
					if(count_reg < 1200)
						count_next = count_reg + 1;
					
					// nes_clk state
					if(count_reg <= 600)
						nes_clk = 1;
					else if(count_reg > 600)
						nes_clk = 0;
					
					// read down
					if(count_reg == 600)
						down_next = data;
					
					// state over
					if(count_reg == 1200)
						begin
						count_next = 0; // reset latch_count
						state_next = read_left; // go to read_left state
						end
					end
					
			read_left:	
					begin
					// count clk cycles for 12 us
					if(count_reg < 1200)
						count_next = count_reg + 1;
					
					// nes_clk state
					if(count_reg <= 600)
						nes_clk = 1;
					else if(count_reg > 600)
						nes_clk = 0;
					
					// read left
					if(count_reg == 600)
						left_next = data;
					
					// state over
					if(count_reg == 1200)
						begin
						count_next = 0; // reset latch_count
						state_next = read_right; // go to read_right state
						end
					end
					
			read_right:	
					begin
					// count clk cycles for 12 us
					if(count_reg < 1200)
						count_next = count_reg + 1;
					
					// nes_clk state
					if(count_reg <= 600)
						nes_clk = 1;
					else if(count_reg > 600)
						nes_clk = 0;
					
					// read right
					if(count_reg == 600)
						right_next = data;
					
					// state over
					if(count_reg == 1200)
						begin
						count_next = 0; // reset latch_count
						state_next = latch_en; // go to latch_en state
						end
					end
		endcase
		end
		
	// assign outputs, *normally asserted when unpressed
	assign A      = ~A_reg;
	assign B      = ~B_reg;
	assign select = ~select_reg;
	assign start  = ~start_reg;
	assign up     = ~up_reg;
	assign down   = ~down_reg;
	assign left   = ~left_reg;
	assign right  = ~right_reg;
	
endmodule
