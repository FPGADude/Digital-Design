`timescale 1ns / 1ps

// ============================================================
// SIGNED PCM TO 1-BIT PWM AUDIO DAC
// ============================================================
// Converts signed 16-bit PCM into the single-bit PWM stream accepted by the
// Pmod AMP2.
//
// An 8-bit free-running counter produces a carrier of:
//
//     100 MHz / 256 = 390.625 kHz
//
// This is well above the 12.5 kHz speech sample rate. The AMP2 and speaker
// respond primarily to the average duty cycle, reconstructing the audio.
// ============================================================
module retro_pwm_dac (
    input  wire               clk,
    input  wire               reset,
    input  wire signed [15:0] pcm_sample,
    input  wire               sample_valid,
    output wire               pwm_out
);

    // Holds the most recent audio level until another PCM sample arrives.
    reg [7:0] held_unsigned_sample;
    
    // Free-running PWM ramp.
    reg [7:0] pwm_counter;
    
    // Convert signed two's-complement PCM to unsigned offset binary.
    // Signed silence 0 becomes unsigned midpoint 0x8000.
    wire [15:0] unsigned_sample = pcm_sample + 16'h8000;
    
    always @(posedge clk) begin
        if (reset) begin
            // 0x80 produces 50% duty cycle, representing audio silence.
            held_unsigned_sample <= 8'h80;
            pwm_counter          <= 8'd0;
        end else begin
            // PWM carrier runs continuously.
            pwm_counter <= pwm_counter + 1'b1;
    
            // Update the duty-cycle command only when a new sample is valid.
            if (sample_valid)
                held_unsigned_sample <= unsigned_sample[15:8];
        end
    end
    
    // Comparator converts the held sample magnitude into PWM duty cycle.
    assign pwm_out = (pwm_counter < held_unsigned_sample);

endmodule
