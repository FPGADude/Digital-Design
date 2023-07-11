# Written by David J. Marion
# Date: 6.9.2023
#
# Purpose: To generate a Verilog ROM file from a .bin file.
# --------------------------------------------------------------------------------------------------------
def bin_to_v(bin_file_path, v_file_path, program_name):
    rom_name = program_name + "_rom"
    with open(bin_file_path, "rb") as bin_file:
        binary_data = bin_file.read()

    # Generate the Verilog code
    verilog_code = "`timescale 1ns / 1ps\n"
    verilog_code += f"module {rom_name}(\n"
    verilog_code += "    input [7:0] addr,\n"
    verilog_code += "    input set_addr,\n"
    verilog_code += "    input en_data,\n"
    verilog_code += f"    output reg [7:0] noi = 8'd{len(binary_data)},\n"
    verilog_code += "    output reg [7:0] data = 8'b0\n"
    verilog_code += ");\n\n"
    verilog_code += f"    reg [7:0] addr_reg = 8'b0;\n\n"
    verilog_code += "    always @(*) begin\n"
    verilog_code += "        if(set_addr)\n"
    verilog_code += "            addr_reg <= addr;\n"
    verilog_code += "        else if(en_data)\n"
    verilog_code += "            case(addr_reg)\n"

    for i in range(len(binary_data)):
        instruction = int.from_bytes(binary_data[i:i+1], byteorder="big")
        verilog_code += f"                8'd{i}: data = 8'b{bin(instruction)[2:].zfill(8)};\n"

    verilog_code += "                default: data = 8'b0;\n"
    verilog_code += "            endcase\n"
    verilog_code += "    end\n\n"
    verilog_code += "endmodule"

    # Write the Verilog code to the output file
    with open(v_file_path, "w") as v_file:
        v_file.write(verilog_code)

    print(f"Conversion complete. ROM file '{v_file_path}' generated.")
# -------------------------------------------------------------------------------------------------------
program_name = "sum5"      # Set program_name equal to the name of the CPU program, without extension                   
bin_file_path = program_name + ".bin"
v_file_path = program_name + "_rom" + ".v"
bin_to_v(bin_file_path, v_file_path, program_name)
