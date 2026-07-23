`timescale 1ns / 1ps

// ============================================================================
// Module: heartbeat_led
// Project: FPGA Motion Security System
//
// Purpose:
//   Drives LED15 as a compact physical indication of the security-system state.
//
// LED behavior:
//   - WARMUP and DISARMED: off
//   - ARMING: slow square-wave blink
//   - ARMED: short heartbeat pulse during each counter cycle
//   - ALARM: rapid blink
//
// The free-running counter is intentionally shared by all patterns. Different
// counter bits or comparisons create different visible blink rates.
// ============================================================================
module heartbeat_led (
    input  logic       clk,
    input  logic [2:0] system_state,
    output logic       heartbeat
);

    // State encodings match security_fsm.
    localparam logic [2:0]
        ST_WARMUP   = 3'd0,
        ST_DISARMED = 3'd1,
        ST_ARMING   = 3'd2,
        ST_ARMED    = 3'd3,
        ST_ALARM    = 3'd4;

    // Free-running divider counter used to derive visible blink patterns.
    logic [26:0] counter = 27'd0;

    // Counter wraps naturally; no explicit reset is required.
    always_ff @(posedge clk) begin
        counter <= counter + 1'b1;
    end

    // Select the LED pattern associated with the current system state.
    always_comb begin
        case (system_state)
            ST_ARMING: heartbeat = counter[26];
            ST_ARMED:  heartbeat = (counter < 27'd16_000_000);
            ST_ALARM:  heartbeat = counter[23];
            default:   heartbeat = 1'b0;
        endcase
    end

endmodule
