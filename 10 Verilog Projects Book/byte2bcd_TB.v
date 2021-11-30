module byte2bcd_TB;

	reg  [7:0] bin_in;
	wire [11:0] bcd_out;

	byte2bcd DUT(.bin_in(bin_in), .bcd_out(bcd_out));

	integer i;
	
	initial begin
		for(i = 0; i < 256; i = i + 1) begin
			bin_in = i;
			#2;
		end
	end

	initial begin
		$dumpfile("byte2bcd_TB.vcd") ;
		$dumpvars(0, byte2bcd_TB) ;
    end

endmodule


