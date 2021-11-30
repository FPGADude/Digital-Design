
module fibonacci_p #(parameter W = 16)(
	input clock,
	input reset,
	output [W-1:0] fib_out
);

	reg [W-1:0] num0, num1;

	always @(posedge clock or negedge reset) begin
		if(~reset) begin
			num0 <= 0;
			num1 <= 1;
			end
		else begin
			num0 <= num1;
			num1 <= fib_out;
			end			
	end
	
	assign fib_out = num0 + num1;

endmodule

