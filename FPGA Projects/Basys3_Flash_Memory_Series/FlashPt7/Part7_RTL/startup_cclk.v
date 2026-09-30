`timescale 1ns / 1ps

// ============================================================================
// STARTUPE2 CCLK Wrapper
//
// The Basys 3 configuration flash clock (CCLK) is not a normal FPGA I/O.
// STARTUPE2 allows our user logic to drive CCLK after configuration completes.
// ============================================================================

module startup_cclk (
    input  wire user_cclk,
    output wire eos
);

    STARTUPE2 #(
        .PROG_USR("FALSE"),
        .SIM_CCLK_FREQ(0.0)
    ) u_startupe2 (
        .CFGCLK     (),
        .CFGMCLK    (),
        .EOS        (eos),
        .PREQ       (),

        .CLK        (1'b0),
        .GSR        (1'b0),
        .GTS        (1'b0),
        .KEYCLEARB  (1'b1),
        .PACK       (1'b0),

        .USRCCLKO   (user_cclk),
        .USRCCLKTS  (1'b0),

        .USRDONEO   (1'b1),
        .USRDONETS  (1'b1)
    );

endmodule
