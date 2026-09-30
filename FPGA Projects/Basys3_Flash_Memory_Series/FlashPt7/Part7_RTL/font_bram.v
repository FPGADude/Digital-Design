`timescale 1ns / 1ps

// ============================================================================
// 4096-Byte Font Block RAM
//
// The font contains 256 possible character slots, with 16 bytes per character:
//   256 characters * 16 rows = 4096 bytes
//
// Write port:
//   Used only during startup while font bytes are copied from QSPI flash.
//
// Read port:
//   Used continuously by text_renderer. The synchronous read style allows
//   Vivado to infer block RAM on the Artix-7.
// ============================================================================
module font_bram (
    input  wire        clk,

    input  wire        we,
    input  wire [11:0] waddr,
    input  wire [7:0]  wdata,

    input  wire [11:0] raddr,
    output reg  [7:0]  rdata
);

    (* ram_style = "block" *)
    reg [7:0] mem [0:4095];

    always @(posedge clk) begin
        if (we)
            mem[waddr] <= wdata;

        rdata <= mem[raddr];
    end

endmodule
