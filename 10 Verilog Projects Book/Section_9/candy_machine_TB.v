
module candy_machine_TB;
	reg clk;
	reg reset;
	reg [2:0] coin;
	wire candy;
	wire [2:0] change;
	
	candy_machine DUT(.clk(clk), .reset(reset), .coin(coin), 
					  .candy(candy), .change(change));
	
	always #5 clk = ~clk;
	
	initial begin
		$dumpfile("candy_machine_TB.vcd");
		$dumpvars(0, candy_machine_TB);
	end
	
	initial begin
		clk = 0;
		reset = 1;
		coin = 3'b000;
		#12 reset = 0;	
		
		// CASE 1: 5 nickels
		#20 coin = 3'b001;
		#50 coin = 3'b000;
		
		// CASE 2: 3 dimes
		#20 coin = 3'b010;
		#30 coin = 3'b000;
		
		// CASE 3: 1 quarter
		#20 coin = 3'b100;
		#10 coin = 3'b000;
		
		// CASE 4: nickel * dime * dime
		#20 coin = 3'b001;
		#10 coin = 3'b010;
		#20 coin = 3'b000;
		
		// CASE 5: dime * dime * nickel
		#20 coin = 3'b010;
		#20 coin = 3'b001;
		#10 coin = 3'b000;
		
		// CASE 6: nickel * dime * quarter
		#20 coin = 3'b001;
		#10 coin = 3'b010;
		#10 coin = 3'b100;
		#10 coin = 3'b000;
		
		// CASE 7: dime * dime * quarter
		#20 coin = 3'b010;
		#20 coin = 3'b100;
		#10 coin = 3'b000;

		#10 $finish;
	end
endmodule


