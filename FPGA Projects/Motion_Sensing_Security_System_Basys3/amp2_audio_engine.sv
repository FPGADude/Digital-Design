`timescale 1ns / 1ps

// ============================================================================
// Module: amp2_audio_engine
// Project: FPGA Motion Security System
//
// Purpose:
//   Generates all one-bit PWM audio sent to the Digilent Pmod AMP2.
//
// Audio behavior:
//   - WARMUP and DISARMED: silence
//   - ARMING: a short 900 Hz beep whenever the countdown value changes
//   - ARMED: a short 1450 Hz confirmation chirp
//   - ALARM: a continuous siren that sweeps between approximately
//            650 Hz and 1500 Hz
//   - MUTED ALARM: silence while the alarm state remains latched
//
// Architecture:
//   1. A 1 ms clock-enable pulse controls event timing and siren sweeping.
//   2. State transitions and countdown changes start timed event tones.
//   3. A phase accumulator acts as a numerically controlled oscillator.
//   4. The oscillator produces an 8-bit bipolar audio sample around midpoint.
//   5. An 8-bit PWM stage converts that sample into a one-bit AMP2 waveform.
//
// Important:
//   The Pmod AMP2 input includes filtering that reconstructs the average value
//   of this high-frequency PWM stream as an analog audio waveform.
// ============================================================================
module amp2_audio_engine #(
    parameter int CLK_FREQ_HZ = 100_000_000
)(
    input  logic       clk,
    input  logic [2:0] system_state,
    input  logic [2:0] arming_seconds,
    input  logic       alarm_muted,
    output logic       audio_pwm
);

    // State encodings must match security_fsm and the VGA renderer.
    localparam logic [2:0]
        ST_WARMUP   = 3'd0,
        ST_DISARMED = 3'd1,
        ST_ARMING   = 3'd2,
        ST_ARMED    = 3'd3,
        ST_ALARM    = 3'd4;

    // ------------------------------------------------------------------------
    // Millisecond timebase used for beep duration and siren sweep timing
    // ------------------------------------------------------------------------

    localparam int MS_CYCLES = CLK_FREQ_HZ / 1000;
    localparam int MS_WIDTH  = $clog2(MS_CYCLES);

    logic [MS_WIDTH-1:0] ms_counter = '0;
    logic ms_tick = 1'b0;

    // Previous values allow detection of state/countdown transitions.
    logic [2:0] previous_state = ST_WARMUP;
    logic [2:0] previous_arming_seconds = 3'd0;

    // Timed event-tone controls.
    logic [9:0]  beep_time_ms = 10'd0;
    logic [15:0] event_frequency = 16'd900;

    // Current sweeping-siren frequency and sweep direction.
    logic [15:0] siren_frequency = 16'd650;
    logic        siren_rising = 1'b1;

    logic        tone_enable;
    logic [15:0] active_frequency;

    // Numerically controlled oscillator state.
    logic [31:0] phase_accumulator = 32'd0;
    logic [31:0] phase_increment;

    // PWM conversion registers.
    logic [7:0] audio_sample;
    logic [7:0] pwm_counter = 8'd0;

    // Generate a one-clock pulse every millisecond.
    always_ff @(posedge clk) begin
        ms_tick <= 1'b0;

        if (ms_counter == MS_CYCLES - 1) begin
            ms_counter <= '0;
            ms_tick    <= 1'b1;
        end
        else begin
            ms_counter <= ms_counter + 1'b1;
        end
    end

    // Detect audio events and update the alarm sweep once per millisecond.
    always_ff @(posedge clk) begin
        previous_state          <= system_state;
        previous_arming_seconds <= arming_seconds;

        if (ms_tick) begin
            if (beep_time_ms != 0) begin
                beep_time_ms <= beep_time_ms - 1'b1;
            end

            if ((system_state == ST_ARMING) &&
                ((previous_state != ST_ARMING) ||
                 (arming_seconds != previous_arming_seconds))) begin

                beep_time_ms    <= 10'd150;
                event_frequency <= 16'd900;
            end

            if ((system_state == ST_ARMED) &&
                (previous_state != ST_ARMED)) begin

                beep_time_ms    <= 10'd280;
                event_frequency <= 16'd1450;
            end

            if (system_state == ST_ALARM) begin
                if (siren_rising) begin
                    if (siren_frequency >= 1500) begin
                        siren_rising    <= 1'b0;
                        siren_frequency <= 16'd1496;
                    end
                    else begin
                        siren_frequency <= siren_frequency + 16'd4;
                    end
                end
                else begin
                    if (siren_frequency <= 650) begin
                        siren_rising    <= 1'b1;
                        siren_frequency <= 16'd654;
                    end
                    else begin
                        siren_frequency <= siren_frequency - 16'd4;
                    end
                end
            end
            else begin
                siren_frequency <= 16'd650;
                siren_rising    <= 1'b1;
            end
        end
    end

    // Select either the continuous alarm tone or a temporary event tone.
    always_comb begin
        tone_enable     = 1'b0;
        active_frequency = event_frequency;

        if ((system_state == ST_ALARM) && !alarm_muted) begin
            tone_enable      = 1'b1;
            active_frequency = siren_frequency;
        end
        else if (beep_time_ms != 0) begin
            tone_enable = 1'b1;
        end
    end

    // Phase increment approximation for the 32-bit oscillator.
    // 2^32 / 100 MHz is approximately 42.95.
    assign phase_increment = active_frequency * 32'd43;

    // Advance the oscillator only while a tone is active.
    always_ff @(posedge clk) begin
        if (tone_enable) begin
            phase_accumulator <= phase_accumulator + phase_increment;
        end
        else begin
            phase_accumulator <= 32'd0;
        end

        pwm_counter <= pwm_counter + 1'b1;
    end

    // Create a modest-amplitude square-wave sample centered at 128.
    always_comb begin
        if (!tone_enable) begin
            audio_sample = 8'd128;
        end
        else if (phase_accumulator[31]) begin
            audio_sample = 8'd188;
        end
        else begin
            audio_sample = 8'd68;
        end
    end

    // Compare the sample against a free-running PWM ramp.
    assign audio_pwm = (pwm_counter < audio_sample);

endmodule
