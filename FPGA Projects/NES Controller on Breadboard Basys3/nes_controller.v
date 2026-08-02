`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// NES Controller Interface
//
// Platform:
//   Digilent Basys 3
//
// Compatible Controllers:
//   - Nintendo NES controller
//   - NES-compatible clone controllers
//   - CD4021 breadboard controller
//
// Interface:
//   data  <- controller serial output
//   latch -> controller latch
//   clk   -> controller shift clock
//
// Button Outputs:
//
//   A
//   B
//   Select
//   Start
//   Up
//   Down
//   Left
//   Right
//
// Author:
//   FPGA Discovery
///////////////////////////////////////////////////////////////////////////////
module nes_controller #(
    parameter integer CLK_FREQ_HZ   = 100_000_000,
    parameter integer LATCH_US      = 12,
    parameter integer SETTLE_US     = 6,
    parameter integer CLOCK_HALF_US = 6,
    parameter integer POLL_DELAY_US = 5000
)(
    input  wire clk,
    input  wire reset,
    input  wire data,

    output reg  latch,
    output reg  nes_clk,

    output wire A,
    output wire B,
    output wire select,
    output wire start,
    output wire up,
    output wire down,
    output wire left,
    output wire right
);

    ////////////////////////////////////////////////////////////////////////////
    // Timing constants
    ////////////////////////////////////////////////////////////////////////////

    localparam integer CYCLES_PER_US =
        CLK_FREQ_HZ / 1_000_000;

    localparam integer LATCH_CYCLES =
        CYCLES_PER_US * LATCH_US;

    localparam integer SETTLE_CYCLES =
        CYCLES_PER_US * SETTLE_US;

    localparam integer HALF_CYCLES =
        CYCLES_PER_US * CLOCK_HALF_US;

    localparam integer POLL_DELAY_CYCLES =
        CYCLES_PER_US * POLL_DELAY_US;

    ////////////////////////////////////////////////////////////////////////////
    // State encoding
    ////////////////////////////////////////////////////////////////////////////

    localparam [3:0]
        ST_IDLE        = 4'd0,
        ST_LATCH       = 4'd1,
        ST_SETTLE      = 4'd2,
        ST_SAMPLE_BIT  = 4'd3,
        ST_CLOCK_HIGH  = 4'd4,
        ST_CLOCK_LOW   = 4'd5,
        ST_PUBLISH     = 4'd6;

    reg [3:0]  state;
    reg [31:0] timer;
    reg [3:0]  sample_index;

    ////////////////////////////////////////////////////////////////////////////
    // Synchronize asynchronous DATA input
    ////////////////////////////////////////////////////////////////////////////

    reg data_meta;
    reg data_sync;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_meta <= 1'b1;
            data_sync <= 1'b1;
        end else begin
            data_meta <= data;
            data_sync <= data_meta;
        end
    end

    ////////////////////////////////////////////////////////////////////////////
    // Captured serial data
    ////////////////////////////////////////////////////////////////////////////

    // Bits 0 through 7 are the actual controller buttons.
    // Bit 8 is the trailing bit and is intentionally discarded.
    reg [8:0] raw_shift;

    // Stable active-high button output vector.
    reg [7:0] buttons;

    function [7:0] decode_active_low;
        input [7:0] raw_value;
        begin
            decode_active_low = ~raw_value;
        end
    endfunction

    assign A      = buttons[0];
    assign B      = buttons[1];
    assign select = buttons[2];
    assign start  = buttons[3];
    assign up     = buttons[4];
    assign down   = buttons[5];
    assign left   = buttons[6];
    assign right  = buttons[7];

    ////////////////////////////////////////////////////////////////////////////
    // Controller scan state machine
    ////////////////////////////////////////////////////////////////////////////

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= ST_IDLE;
            timer        <= 32'd0;
            sample_index <= 4'd0;
            raw_shift    <= 9'h1FF;
            buttons      <= 8'h00;
            latch        <= 1'b0;
            nes_clk      <= 1'b0;
        end else begin
            case (state)

                ////////////////////////////////////////////////////////////////
                // Quiet interval between complete controller transactions.
                ////////////////////////////////////////////////////////////////
                ST_IDLE: begin
                    latch   <= 1'b0;
                    nes_clk <= 1'b0;

                    if (timer == POLL_DELAY_CYCLES - 1) begin
                        timer        <= 32'd0;
                        sample_index <= 4'd0;
                        raw_shift    <= 9'h1FF;
                        state        <= ST_LATCH;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                ////////////////////////////////////////////////////////////////
                // Parallel-load all physical button states.
                ////////////////////////////////////////////////////////////////
                ST_LATCH: begin
                    latch   <= 1'b1;
                    nes_clk <= 1'b0;

                    if (timer == LATCH_CYCLES - 1) begin
                        timer <= 32'd0;
                        latch <= 1'b0;
                        state <= ST_SETTLE;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                ////////////////////////////////////////////////////////////////
                // Allow the first serial bit, A, to settle.
                ////////////////////////////////////////////////////////////////
                ST_SETTLE: begin
                    latch   <= 1'b0;
                    nes_clk <= 1'b0;

                    if (timer == SETTLE_CYCLES - 1) begin
                        timer <= 32'd0;
                        state <= ST_SAMPLE_BIT;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                ////////////////////////////////////////////////////////////////
                // Capture:
                //   index 0 = A
                //   index 1 = B
                //   index 2 = Select
                //   index 3 = Start
                //   index 4 = Up
                //   index 5 = Down
                //   index 6 = Left
                //   index 7 = Right
                //   index 8 = trailing bit, discarded
                ////////////////////////////////////////////////////////////////
                ST_SAMPLE_BIT: begin
                    raw_shift[sample_index] <= data_sync;

                    if (sample_index == 4'd8) begin
                        state <= ST_PUBLISH;
                    end else begin
                        state <= ST_CLOCK_HIGH;
                    end
                end

                ////////////////////////////////////////////////////////////////
                // Rising edge shifts the next serial bit onto DATA.
                ////////////////////////////////////////////////////////////////
                ST_CLOCK_HIGH: begin
                    latch   <= 1'b0;
                    nes_clk <= 1'b1;

                    if (timer == HALF_CYCLES - 1) begin
                        timer   <= 32'd0;
                        nes_clk <= 1'b0;
                        state   <= ST_CLOCK_LOW;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                ////////////////////////////////////////////////////////////////
                // Hold CLOCK low while the shifted bit settles.
                ////////////////////////////////////////////////////////////////
                ST_CLOCK_LOW: begin
                    latch   <= 1'b0;
                    nes_clk <= 1'b0;

                    if (timer == HALF_CYCLES - 1) begin
                        timer        <= 32'd0;
                        sample_index <= sample_index + 1'b1;
                        state        <= ST_SAMPLE_BIT;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                ////////////////////////////////////////////////////////////////
                // Publish only the eight real button bits.
                // raw_shift[8] is deliberately ignored.
                ////////////////////////////////////////////////////////////////
                ST_PUBLISH: begin
                    buttons      <= decode_active_low(raw_shift[7:0]);
                    timer        <= 32'd0;
                    sample_index <= 4'd0;
                    latch        <= 1'b0;
                    nes_clk      <= 1'b0;
                    state        <= ST_IDLE;
                end

                default: begin
                    state        <= ST_IDLE;
                    timer        <= 32'd0;
                    sample_index <= 4'd0;
                    raw_shift    <= 9'h1FF;
                    buttons      <= 8'h00;
                    latch        <= 1'b0;
                    nes_clk      <= 1'b0;
                end
            endcase
        end
    end

endmodule
