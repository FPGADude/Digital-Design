module bin2bcd_TB;

	reg  [7:0] bin_in;
	wire [7:0] bcd_out;

	bin2bcd DUT(.bin_in(bin_in), .bcd_out(bcd_out));

	integer i;
	
	initial begin
		for(i = 0; i < 60; i = i + 1) begin
			bin_in = i;
			#2;
		end
	end

	initial begin
		$dumpfile("bin2bcd_TB.vcd") ;
		$dumpvars(0, bin2bcd_TB) ;
    end

endmodule


