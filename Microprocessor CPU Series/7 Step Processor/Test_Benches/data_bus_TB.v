`timescale 1ns / 1ps
// TEST BENCH for data_bus.v
// Comments: Device Under Test (data_bus.v) is (** Verified **)
module data_bus_TB;
	reg [7:0] from_gpr, from_ram, from_acc, from_iar, from_io;
	reg [1:6] step;
	reg [0:3] instr;
	reg ir_io, flags_detected;
	wire [7:0] to_ir, to_iar, to_alua, to_gpr, to_mar, to_ram, to_io, to_tmp;

	data_bus DUT(
		// From components
		.i_gpr(from_gpr), .i_ram(from_ram), .i_acc(from_acc), .i_iar(from_iar), .i_io(from_io),
		// Control (routing) signals
		.step(step), .instr(instr), .ir_io(ir_io), .flags_detected(flags_detected),
		// To components
		.o_ir(to_ir), .o_iar(to_iar), .o_alua(to_alua), .o_gpr(to_gpr), 
		.o_mar(to_mar), .o_ram(to_ram), .o_io(to_io), .o_tmp(to_tmp)						);

	initial begin
		$dumpfile("data_bus.vcd");
		$dumpvars(0, data_bus_TB);
	end

	initial begin
		// Initialize reg values
		from_gpr = 8'hff;
		from_ram = 8'haa;
		from_acc = 8'h11;
		from_iar = 8'h55;
		from_io = 8'hdd;
		ir_io = 1'b0;
		flags_detected = 1'b0;
		instr = 4'h0;
		
		
		// Steps 1 thru 3, the fetch part of instr cycle
		step = 6'b10_0000;		// step 1
		#20;
		step = 6'b01_0000;		// step 2
		#20;
		step = 6'b00_1000;		// step 3
		#20;
		
		// Test some ALU operations for steps 4,5,6
		instr = 4'b1000;		// alu add
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		instr = 4'b1100;		// alu and
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		instr = 4'b1001;		// alu shr
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		instr = 4'b1111;		// alu cmp
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		// Test all non-ALU operations for steps 4,5,6
		instr = 4'b0000;		// load
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		instr = 4'b0001;		// store
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		instr = 4'b0010;		// data
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		instr = 4'b0011;		// jmpr
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		instr = 4'b0100;		// jmp
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		instr = 4'b0101;		// jmp if (no flag detected)
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		flags_detected = 1'b1;
		instr = 4'b0101;		// jmp if (flag detected)
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		// *** The clear flags instr 4'b0110 has nothing to do with data bus
		
		instr = 4'b0111;		// io (input)
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		ir_io = 1'b1;
		instr = 4'b0111;		// io (output)
		
		step = 6'b00_0100;		// step 4
		#20;
		step = 6'b00_0010;		// step 5
		#20;
		step = 6'b00_0001;		// step 6
		#20;
		
		
		$finish;	
	end
endmodule