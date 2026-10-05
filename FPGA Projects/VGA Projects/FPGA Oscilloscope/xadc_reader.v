`timescale 1ns / 1ps

module xadc_reader (
    input  wire        clk,
    input  wire        vauxp6,
    input  wire        vauxn6,

    output reg  [11:0] adc_sample = 12'h000,
    output reg         sample_valid = 1'b0
);

    wire [15:0] xadc_do;
    wire        xadc_drdy;
    wire        xadc_eoc;

    wire [4:0]  xadc_channel;
    wire        xadc_busy;
    wire        xadc_eos;

    // ============================================================
    // XADC WIZARD
    //
    // Configuration:
    //   Single Channel
    //   VAUX6
    //   Continuous Mode
    //   Unipolar
    //   No averaging
    //
    // VAUX6 result register = DRP address 0x16
    // ============================================================

    xadc_wiz_0 xadc_inst (
        .daddr_in             (7'h16),
        .dclk_in              (clk),
        .den_in               (xadc_eoc),
        .di_in                (16'h0000),
        .dwe_in               (1'b0),
        .reset_in             (1'b0),

        .vauxp6               (vauxp6),
        .vauxn6               (vauxn6),

        .busy_out             (xadc_busy),
        .channel_out          (xadc_channel),
        .do_out               (xadc_do),
        .drdy_out             (xadc_drdy),
        .eoc_out              (xadc_eoc),
        .eos_out              (xadc_eos),

        .ot_out               (),
        .vccaux_alarm_out     (),
        .vccint_alarm_out     (),
        .user_temp_alarm_out  (),
        .alarm_out            (),

        .vp_in                (1'b0),
        .vn_in                (1'b0)
    );

    // ============================================================
    // CAPTURE LATEST ADC RESULT
    //
    // 12-bit ADC data occupies DO[15:4].
    // ============================================================

    always @(posedge clk) begin

        sample_valid <= 1'b0;

        if (xadc_drdy) begin
            adc_sample  <= xadc_do[15:4];
            sample_valid <= 1'b1;
        end

    end

endmodule
