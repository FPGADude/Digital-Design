`timescale 1ns / 1ps

// ============================================================================
// 1024-Byte Sprite Block RAM
//
// Each sprite is 32 x 32 pixels in RGB332 format:
//
//   32 * 32 = 1024 pixels
//   1 byte per pixel
//
// The write port is used during the startup flash transfer. The synchronous
// read port supplies pixels to sprite_renderer_32x32 during VGA operation.
// ============================================================================
module sprite_bram (
    input  wire       clk,

    input  wire       we,
    input  wire [9:0] waddr,
    input  wire [7:0] wdata,

    input  wire [9:0] raddr,
    output reg  [7:0] rdata
);

    (* ram_style = "block" *)
    reg [7:0] mem [0:1023];

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;

        rdata <= mem[raddr];
    end

endmodule
