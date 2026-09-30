`timescale 1ns / 1ps

// ============================================================================
// 8-Bit PWM Audio DAC
//
// The unsigned PCM sample directly controls PWM duty cycle.
//
//   sample = 8'h00 ->   0/256 duty cycle
//   sample = 8'h80 -> 128/256 duty cycle, the audio center level
//   sample = 8'hFF -> 255/256 duty cycle
//
// A free-running 8-bit counter clocked at 100 MHz produces:
//
//   100 MHz / 256 = 390.625 kHz PWM carrier
//
// The Pmod AMP2 input filtering reconstructs the audio waveform from this PWM.
// ============================================================================
module audio_pwm (
    input  wire       clk,
    input  wire       reset,
    input  wire [7:0] sample,
    output wire       pwm_out
);

    reg [7:0] pwm_counter;

    always @(posedge clk) begin
        if (reset)
            pwm_counter <= 8'h00;
        else
            pwm_counter <= pwm_counter + 1'b1;
    end

    assign pwm_out = (pwm_counter < sample);

endmodule
