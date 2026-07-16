`timescale 1ns / 1ps

//=============================================================================
// Module: ascii_converter
//
// Purpose:
//   Converts the 4-bit keypad code into the corresponding 8-bit ASCII value.
//
// Keypad code mapping:
//   0x0 through 0x9 -> ASCII '0' through '9'
//   0xA through 0xF -> ASCII 'A' through 'F'
//
// Examples:
//   key_code = 4'h5 -> ascii_data = 8'h35, ASCII character '5'
//   key_code = 4'hA -> ascii_data = 8'h41, ASCII character 'A'
//
// Notes:
//   This module is purely combinational. Any change on key_code immediately
//   produces the corresponding ASCII value on ascii_data.
//=============================================================================
module ascii_converter(
    input wire [3:0] key_code,   // Four-bit hexadecimal value from keypad scanner
    output reg [7:0] ascii_data  // Eight-bit ASCII character sent to the UART
);

    // Combinational hexadecimal-to-ASCII conversion.
    always @(*) begin

        // Numeric keypad values use the ASCII range 0x30 through 0x39.
        if (key_code <= 4'h9)
            ascii_data = 8'h30 + key_code;

        // Hexadecimal values A through F use the ASCII range 0x41 through 0x46.
        else
            ascii_data = 8'h41 + (key_code - 4'hA);
    end

endmodule
