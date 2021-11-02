module register_mux( mux_out, in0, in1, in2, in3, in4, in5, in6, in7, select);
  output reg [15:0]	mux_out; 
  input  [15:0] 	in0, in1, in2, in3, in4, in5, in6, in7;
  input  [2:0]  	select;
  

always @*
  begin
    case( select)
	3'b000: mux_out = in0;
	3'b001: mux_out = in1;
	3'b010: mux_out = in2;
	3'b011: mux_out = in3;
	3'b100: mux_out = in4;
	3'b101: mux_out = in5;
	3'b110: mux_out = in6;
	3'b111: mux_out = in7;
    endcase
  end
endmodule
