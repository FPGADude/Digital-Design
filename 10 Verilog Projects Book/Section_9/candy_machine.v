
module candy_machine(
	input reset,		
	input clk,			
	input [2:0] coin,						
	output reg [2:0] change,				
	output reg candy	
);									

	parameter S0 = 3'b000;	//  0 cents - candy = 0
	parameter S1 = 3'b001;	//  5 cents - candy = 0
	parameter S2 = 3'b010;	// 10 cents - candy = 0
	parameter S3 = 3'b011;	// 15 cents - candy = 0
	parameter S4 = 3'b100;	// 20 cents - candy = 0
	parameter S5 = 3'b101;	// 25 cents - candy = 1

	reg [2:0] current_state, next_state;			
	reg [5:0] coin_count;
	
	always @(posedge clk or posedge reset)
		if(reset)
			current_state <= S0;
		else
			current_state <= next_state;
	
	always @(*) begin
		case(current_state)
			S0 : begin	// 0 cents
					candy = 1'b0;
					change = 3'b000;
					coin_count = 0;
					if(coin == 3'b000)
						next_state = S0;
					if(coin == 3'b001) begin
						next_state = S1;
						coin_count = 5;
						end
					if(coin == 3'b010) begin
						next_state = S2;
						coin_count = 10;
						end
					if(coin == 3'b100) begin
						next_state = S5;
						coin_count = 25;
						end
				 end
			S1 : begin	// 5 cents
					candy = 1'b0;
					if(coin == 3'b000)
						next_state = S1;
					if(coin == 3'b001) begin
						next_state = S2;
						coin_count = 10;
						end
					if(coin == 3'b010) begin
						next_state = S3;
						coin_count = 15;
						end
					if(coin == 3'b100) begin
						next_state = S5;
						coin_count = 30;
						end
				 end
			S2 : begin	// 10 cents
					candy = 1'b0;
					if(coin == 3'b000)
						next_state = S2;
					if(coin == 3'b001) begin
						next_state = S3;
						coin_count = 15;
						end
					if(coin == 3'b010) begin
						next_state = S4;
						coin_count = 20;
						end
					if(coin == 3'b100) begin
						next_state = S5;
						coin_count = 35;
						end
				 end 
			S3 : begin	// 15 cents
					candy = 1'b0;
					if(coin == 3'b000)
						next_state = S3;
					if(coin == 3'b001) begin
						next_state = S4;
						coin_count = 20;
						end
					if(coin == 3'b010) begin
						next_state = S5;
						coin_count = 25;
						end
					if(coin == 3'b100) begin
						next_state = S5;
						coin_count = 40;
						end
				 end 
			S4 : begin	// 20 cents
					candy = 1'b0;
					if(coin == 3'b000)
						next_state = S4;
					if(coin == 3'b001) begin
						next_state = S5;
						coin_count = 25;
						end
					if(coin == 3'b010) begin
						next_state = S5;
						coin_count = 30;
						end
					if(coin == 3'b100) begin
						next_state = S5;
						coin_count = 45;
						end		
				 end
			S5 : begin	// 25+ cents
					candy = 1'b1;
					next_state = S0;
					case(coin_count)
						30 : change = 3'b001;		// return nickel
						35 : change = 3'b010;		// return dime
						40 : change = 3'b011;		// return nickel + dime
						45 : change = 3'b110; 		// return dime + dime
						default : change = 3'b000;	// no change due
					endcase
				 end 
			default : begin
						candy = 1'b0;
						change = 3'b000;
						coin_count = 0;
						next_state = S0;		
					  end	
		endcase
	end
endmodule

