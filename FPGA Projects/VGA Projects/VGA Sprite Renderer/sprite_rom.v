`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// 32x32 RGB332 sprite ROM.
// Address range: 0..1023
// Transparent color: 8'h00
//
// The ROM contents are loaded from spaceship_rgb332.mem.
// Add the .mem file to the Vivado project as a Memory Initialization File.
// -----------------------------------------------------------------------------
module sprite_rom (
    input  wire [9:0] addr,
    output wire [7:0] data
);

    reg [7:0] rom [0:1023];

    initial begin
        $readmemh("spaceship_rgb332.mem", rom);
    end

    assign data = rom[addr];

endmodule
