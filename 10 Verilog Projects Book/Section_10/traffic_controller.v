
module traffic_controller(
	input clock,
	input reset,
	input sensor,
	output reg [2:0] major,
	output reg [2:0] minor
);

	parameter S0 = 2'b00;
	parameter S1 = 2'b01;
	parameter S2 = 2'b10;
	parameter S3 = 2'b11;
	
	reg [1:0] current_state, next_state;
	reg [3:0] light_timer;
	reg sensor_reg;

	always @(posedge clock or negedge reset)
		if(~reset) begin
			current_state <= S0;
			light_timer <= 4'b0000;
			sensor_reg <= 1'b0;
			end
		else
			current_state <= next_state;

	always @(posedge sensor)
		sensor_reg <= 1'b1;

	always @(posedge clock)
		if(sensor_reg == 1'b1)
			light_timer <= light_timer + 1;

	always @(*)
		case(current_state)
			S0: begin
					if(sensor_reg == 1'b1)
						next_state = S1;
					else
						next_state = S0;
				end
			S1: begin
					if(light_timer == 4'b0011)
						next_state = S2;
					else
						next_state = S1;
				end
			S2: begin
					if(light_timer == 4'b1100)
						next_state = S3;
					else
						next_state = S2;
				end
			S3: begin
					if(light_timer == 4'b1111) begin
						next_state = S0;
						sensor_reg = 1'b0;
						light_timer = 4'b0000;
						end
					else
						next_state = S3;
				end
			default: next_state = S0;
		endcase

	always @(*) begin
		if(current_state == S0) begin
			major = 3'b001;	// green
			minor = 3'b100;	// red
			end
		if(current_state == S1) begin
			major = 3'b010;	// yellow
			minor = 3'b100;	// red
			end
		if(current_state == S2) begin
			major = 3'b100;	// red
			minor = 3'b001;	// green
			end
		if(current_state == S3) begin
			major = 3'b100; // red
			minor = 3'b010; // yellow
			end
		end
endmodule



