

module control_unit( instr_reg, fam, opcode, src1_reg, src2_dest_reg, sys_enable, data_out );

input  reg [31:0]  instr_reg;

output [1:0]  fam 		= instr_reg[31:30];	// 2 bits for family operation
output [2:0]  opcode 		= instr_reg[29:27];	// 3 bits for opcode (ALU select, shifter select)
output [2:0]  src1_reg 		= instr_reg[26:24];	// 3 bits select which register
output [2:0]  src2_dest_reg	= instr_reg[23:21];	// 3 bits select which register
output [0]    sys_enable	= instr_reg[20];	// 0 = no operation, 1 = enable system ops
output [0]    			= instr_reg[19];	// 
output [0]			= instr_reg[18];
output [0]			= instr_reg[17];
output [0]			= instr_reg[16];


output [15:0] data_out		= instr_reg[15:0];


endmodule
	