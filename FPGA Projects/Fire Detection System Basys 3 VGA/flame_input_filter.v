`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module: flame_input_filter
//
// Purpose:
//   Safely receives the asynchronous digital output from the flame sensor and
//   validates it before declaring a real flame detection.
//
// Processing stages:
//   1. Two-flop synchronizer reduces metastability risk.
//   2. A verification counter requires flame_d0 to remain active continuously.
//   3. flame_detected stays high until the synchronized sensor returns low.
//
// Default timing:
//   VERIFY_CYCLES = 5,000,000 at 100 MHz corresponds to 50 ms.
//////////////////////////////////////////////////////////////////////////////////
module flame_input_filter #(
    parameter integer VERIFY_CYCLES = 5_000_000
)(
    input  wire clk,
    input  wire reset,
    input  wire flame_d0,
    output reg  flame_detected,
    output wire flame_raw_sync
);

    // First and second synchronizer stages.
    reg flame_meta;
    reg flame_sync;

    // Width required to count through the selected verification interval.
    localparam integer COUNTER_WIDTH = $clog2(VERIFY_CYCLES + 1);
    reg [COUNTER_WIDTH-1:0] verify_counter;

    // Expose the synchronized raw state for LEDs and the VGA status display.
    assign flame_raw_sync = flame_sync;

    // Two-flop clock-domain synchronizer.
    always @(posedge clk) begin
        if (reset) begin
            flame_meta <= 1'b0;
            flame_sync <= 1'b0;
        end
        else begin
            flame_meta <= flame_d0;
            flame_sync <= flame_meta;
        end
    end

    // Require a continuous active sensor level before validating the event.
    always @(posedge clk) begin
        if (reset) begin
            verify_counter <= {COUNTER_WIDTH{1'b0}};
            flame_detected <= 1'b0;
        end
        // Any inactive sample immediately cancels verification and detection.
        else if (!flame_sync) begin
            verify_counter <= {COUNTER_WIDTH{1'b0}};
            flame_detected <= 1'b0;
        end
        // Stop counting after the event has been validated.
        else if (!flame_detected) begin
            if (verify_counter == VERIFY_CYCLES - 1) begin
                flame_detected <= 1'b1;
            end
            else begin
                verify_counter <= verify_counter + 1'b1;
            end
        end
    end

endmodule
