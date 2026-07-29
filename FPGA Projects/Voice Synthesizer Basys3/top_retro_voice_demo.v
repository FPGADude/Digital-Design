`timescale 1ns / 1ps
`include "retro_voice_defs.vh"

// ============================================================
// BASYS 3 RETRO VOICE CORE + PMOD AMP2 DEMONSTRATION
// ============================================================
//
// Controls:
//   SW15      = reset
//   SW[2:0]   = phrase selection
//   BTNC      = speak selected phrase
//
// Outputs:
//   LED[2:0]  = synchronized selected phrase
//   LED15     = voice busy
//   AMP2 audio output, gain, and shutdown signals
//
// The pushbutton and switches are asynchronous to the 100 MHz clock, so they
// pass through two-register synchronizers before entering the speech logic.
//
// Audio path:
//   word PCM -> signed 16-bit sample -> PWM DAC -> Pmod AMP2 -> speaker
// ============================================================
module top_retro_voice_demo (
    input  wire       clk,             // 100MHz
    input  wire       sw15,            // system reset
    input  wire [2:0] phrase_select,    // choose between 8 phrases
    input  wire       play,            // play the selected phrase

    output wire [2:0] led,              // mirror phrase select switches
    output wire       led15,            // player busy indicator
    output wire       amp2_audio,       
    output wire       amp2_gain,
    output wire       amp2_shutdown_n
);

    // ------------------------------------------------------------
    // ASYNCHRONOUS INPUT SYNCHRONIZERS
    // ------------------------------------------------------------
    reg [1:0] reset_sync;
    reg [1:0] button_sync;
    reg [2:0] phrase_meta;
    reg [2:0] phrase_sync;
    
    // Two-stage synchronizers reduce metastability risk.
    always @(posedge clk) begin
        reset_sync  <= {reset_sync[0], sw15};
        button_sync <= {button_sync[0], play};
    
        phrase_meta <= phrase_select[2:0];
        phrase_sync <= phrase_meta;
    end
    
    wire reset = reset_sync[1];
    
    // Rising-edge detector creates the one-clock speech request pulse after the
    // pushbutton has been synchronized.
    reg button_d;
    wire speak_pulse = button_sync[1] & ~button_d;
    
    always @(posedge clk) begin
        if (reset)
            button_d <= 1'b0;
        else
            button_d <= button_sync[1];
    end
    
    // SW[2:0] directly selects phrase IDs 0 through 7.
    wire [3:0] phrase_id = {1'b0, phrase_sync};
    
    wire               voice_busy;
    wire signed [15:0] voice_sample;
    wire               voice_sample_valid;
    
    // Reusable phrase sequencer and complete-word PCM playback core.
    retro_voice_core voice_core_inst (
        .clk          (clk),
        .reset        (reset),
        .start        (speak_pulse),
        .phrase_id    (phrase_id),
        .busy         (voice_busy),
        .sample_out   (voice_sample),
        .sample_valid (voice_sample_valid)
    );
    
    // Convert signed PCM into the AMP2's single-bit digital audio stream.
    retro_pwm_dac pwm_dac_inst (
        .clk          (clk),
        .reset        (reset),
        .pcm_sample   (voice_sample),
        .sample_valid (voice_sample_valid),
        .pwm_out      (amp2_audio)
    );
    
    // Pmod AMP2 control pins used by the proven hardware configuration:
    //
    //   amp2_gain = 0
    //       Selects the louder gain mode used during testing.
    //
    //   amp2_shutdown_n = 1
    //       Deasserts active-low shutdown and enables the amplifier.
    assign amp2_gain       = 1'b0;
    assign amp2_shutdown_n = 1'b1;
    
    // Mirror phrase selection and indicate active speech.
    assign led[2:0] = phrase_sync;
    assign led15    = voice_busy;

endmodule
