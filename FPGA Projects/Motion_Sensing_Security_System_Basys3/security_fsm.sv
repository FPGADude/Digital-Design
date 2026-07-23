`timescale 1ns / 1ps

// ============================================================================
// Module: security_fsm
// Project: FPGA Motion Security System
//
// Purpose:
//   Implements the complete operating sequence of the PIR security system.
//
// States:
//   ST_WARMUP
//      Waits for the PIR sensor to stabilize after power-up or system reset.
//
//   ST_DISARMED
//      Sensor is ready, but motion does not trigger an alarm.
//      BTNC begins arming. BTND clears the intrusion count.
//
//   ST_ARMING
//      Three-second exit countdown. BTND cancels and returns to DISARMED.
//
//   ST_ARMED
//      Monitors motion_event. A new event increments the intrusion count and
//      latches the system in ST_ALARM.
//
//   ST_ALARM
//      Alarm remains active until BTND disarms the system.
//      BTNU toggles the audio mute state.
//
// Reset controls:
//   reset_pulse        - normal cancel/disarm/alarm acknowledgement.
//   system_reset_pulse - complete restart through the PIR warm-up sequence.
//
// Timing:
//   A free-running counter produces one_second_tick for warm-up and arming
//   countdown timing.
// ============================================================================
module security_fsm #(
    parameter int CLK_FREQ_HZ   = 100_000_000,
    parameter int WARMUP_TIME_S = 30,
    parameter int ARMING_TIME_S = 3
)(
    input  logic clk,
    input  logic arm_pulse,
    input  logic reset_pulse,
    input  logic system_reset_pulse,
    input  logic mute_pulse,
    input  logic motion_event,

    output logic [2:0]  system_state,
    output logic [5:0]  warmup_seconds,
    output logic [2:0]  arming_seconds,
    output logic [15:0] intrusion_count,
    output logic        alarm_muted
);

    // Shared numeric state encoding used throughout the project.
    localparam logic [2:0]
        ST_WARMUP   = 3'd0,
        ST_DISARMED = 3'd1,
        ST_ARMING   = 3'd2,
        ST_ARMED    = 3'd3,
        ST_ALARM    = 3'd4;

    // 100 MHz-to-1 Hz divider and one-clock timing pulse.
    logic [26:0] second_counter = '0;
    logic one_second_tick = 1'b0;

    // Initial FPGA power-up state.
    initial begin
        system_state    = ST_WARMUP;
        warmup_seconds  = WARMUP_TIME_S;
        arming_seconds  = ARMING_TIME_S;
        intrusion_count = 16'd0;
        alarm_muted     = 1'b0;
    end

    // Generate one_second_tick; full reset also restarts the timebase.
    always_ff @(posedge clk) begin
        one_second_tick <= 1'b0;

        if (system_reset_pulse) begin
            second_counter <= '0;
        end
        else if (second_counter == CLK_FREQ_HZ - 1) begin
            second_counter <= '0;
            one_second_tick <= 1'b1;
        end
        else begin
            second_counter <= second_counter + 1'b1;
        end
    end

    always_ff @(posedge clk) begin

        // BTNR is a complete system reset. It has priority over every state
        // transition and restores the same conditions used at FPGA power-up.
        if (system_reset_pulse) begin
            system_state    <= ST_WARMUP;
            warmup_seconds  <= WARMUP_TIME_S;
            arming_seconds  <= ARMING_TIME_S;
            intrusion_count <= 16'd0;
            alarm_muted     <= 1'b0;
        end
        else begin
            // Main state-transition and output-register logic.
            case (system_state)

            // PIR stabilization countdown.
            ST_WARMUP: begin
                alarm_muted <= 1'b0;

                if (one_second_tick) begin
                    if (warmup_seconds > 1) begin
                        warmup_seconds <= warmup_seconds - 1'b1;
                    end
                    else begin
                        warmup_seconds <= 6'd0;
                        system_state   <= ST_DISARMED;
                    end
                end
            end

            // Ready state: arm with BTNC or clear count with BTND.
            ST_DISARMED: begin
                alarm_muted    <= 1'b0;
                arming_seconds <= ARMING_TIME_S;

                if (reset_pulse) begin
                    intrusion_count <= 16'd0;
                end
                else if (arm_pulse) begin
                    system_state   <= ST_ARMING;
                    arming_seconds <= ARMING_TIME_S;
                end
            end

            // Exit countdown before motion monitoring becomes active.
            ST_ARMING: begin
                if (reset_pulse) begin
                    system_state <= ST_DISARMED;
                end
                else if (one_second_tick) begin
                    if (arming_seconds > 1) begin
                        arming_seconds <= arming_seconds - 1'b1;
                    end
                    else begin
                        arming_seconds <= 3'd0;
                        system_state   <= ST_ARMED;
                    end
                end
            end

            // Motion event increments the count and latches the alarm.
            ST_ARMED: begin
                if (reset_pulse) begin
                    system_state <= ST_DISARMED;
                end
                else if (motion_event) begin
                    intrusion_count <= intrusion_count + 1'b1;
                    alarm_muted     <= 1'b0;
                    system_state    <= ST_ALARM;
                end
            end

            // Alarm remains latched; BTNU controls mute and BTND disarms.
            ST_ALARM: begin
                if (mute_pulse) begin
                    alarm_muted <= ~alarm_muted;
                end

                if (reset_pulse) begin
                    alarm_muted  <= 1'b0;
                    system_state <= ST_DISARMED;
                end
            end

                default: begin
                    system_state    <= ST_WARMUP;
                    warmup_seconds  <= WARMUP_TIME_S;
                    arming_seconds  <= ARMING_TIME_S;
                    intrusion_count <= 16'd0;
                    alarm_muted     <= 1'b0;
                end

            endcase
        end
    end

endmodule
