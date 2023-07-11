`timescale 1ns / 1ps
module rom_TB;

	reg [7:0] addr;
	reg set_addr, en_data;
	wire [7:0] noi, data;
	integer i;

	sum5_rom DUT(
		.addr(addr),
		.set_addr(set_addr),
		.en_data(en_data),
		.noi(noi),
		.data(data)
	);
	
	initial begin
		$dumpfile("rom.vcd");
		$dumpvars(0, rom_TB);
	end
	
	initial begin
		addr = 8'h00;
		set_addr = 1'b0;
		en_data = 1'b0;
		
		for(i = 0; i < noi; i = i + 1) begin
			addr = i;
			#20;
			set_addr = 1'b1;
			#20;
			set_addr = 1'b0;
			#20;
			en_data = 1'b1;
			#20;
			en_data = 1'b0;
			#20;
		end
	
		$finish;
	end

endmodule