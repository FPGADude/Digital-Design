module alu(x, y, opcode, result, CCR);

  parameter WIDTH = 16;  

  input  [WIDTH-1:0]    x;				// X from register file
  input  [WIDTH-1:0]    y;				// Y from register file
  input  [2:0] 	   	opcode;				// opcode from control unit
  output reg	   	result;				// result of ALU operation
  output reg [7:0] 	CCR;				// condition code register

  reg    [WIDTH:0]	sub_result;			// extra bit to capture flags

always @*
  begin
    case
	if( opcode == 3'b000 ) sub_result <=    !x;	// NOT
	if( opcode == 3'b001 ) sub_result <= x & y;	// AND
	if( opcode == 3'b000 ) sub_result <= x | y;	// OR
	if( opcode == 3'b001 ) sub_result <= x ^ y;	// XOR
	if( opcode == 3'b010 ) sub_result <= x + y;	// ADD
	if( opcode == 3'b011 ) sub_result <= x - y;	// SUBTRACT
    endcase
		
	CCR[0] = sub_result[WIDTH];			// carry flag set if 1
	CCR[1] = result[WIDTH-1];			// negative flag set if MSB is 1
        CCR[2] = result==0 ? 1 : 0;			// zero flag set if result is 16'h0000	
	CCR[3] = x > y  ? 1 : 0;			// COMPARE: 1 = TRUE
	CCR[4] = x < y  ? 1 : 0;			// "
	CCR[5] = x = y  ? 1 : 0;			// "
	CCR[6] = x >= y ? 1 : 0;			// "
	CCR[7] = x <= y ? 1 : 0;			// "
	
	result 	= sub_result[WIDTH-1:0];		// result of ALU operation		

  end
endmodule