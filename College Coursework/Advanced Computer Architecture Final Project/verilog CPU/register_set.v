`include register.v
`include register_selector.v
`include register_mux.v

module register_set(clock, data_in, which_reg, enable, load, data_out);
  input		clock;
  input  [15:0] data_in;
  input  [2:0]  x_select;
  input  [2:0]  y_select;
  input		enable;
  input		load;
  output [15:0] data_out;
	

wire [7:0]  register_select;
wire [15:0] R0_out, R1_out, R2_out, R3_out, R4_out, R5_out, R6_out, R7_out;

register_selector reg_sel( register_select, which_reg );

register  R0(.clock(clock), .enable(register_select[0]), .data_in(data_in), .data_out(R0_out));
register  R1(.clock(clock), .enable(register_select[1]), .data_in(data_in), .data_out(R1_out));
register  R2(.clock(clock), .enable(register_select[2]), .data_in(data_in), .data_out(R2_out));
register  R3(.clock(clock), .enable(register_select[3]), .data_in(data_in), .data_out(R3_out));
register  R4(.clock(clock), .enable(register_select[4]), .data_in(data_in), .data_out(R4_out));
register  R5(.clock(clock), .enable(register_select[5]), .data_in(data_in), .data_out(R5_out));
register  R6(.clock(clock), .enable(register_select[6]), .data_in(data_in), .data_out(R6_out));
register  R7(.clock(clock), .enable(register_select[7]), .data_in(data_in), .data_out(R7_out));

register_mux src1( x, R0_out, R1_out, R2_out, R3_out, R4_out, R5_out, R6_out, R7_out, x_select );
					 
register_mux src2( y, R0_out, R1_out, R2_out, R3_out, R4_out, R5_out, R6_out, R7_out, y_select );

endmodule



