`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: frogger_audio
//
// Simple FPGA-generated audio for Pmod AMP2.
//
// Sounds:
//   - start chime when leaving title screen
//   - low Space-Invaders-style thump loop during active gameplay only
//   - hop blip on frog movement
//   - low buzzy death sound
//   - pleasant confirmation ding when reaching a home
//
// This uses square-wave tone generation, not sampled audio.
//
// Detailed notes:
//   The module does not play stored samples. Instead, it synthesizes simple sound
//   directly in logic by toggling amp2_ain at different rates. This produces square
//   waves. Short timers choose how long each sound effect lasts, while a small LFSR
//   injects pseudo-random noise into the death sound.
//
//   Sound effect priority is intentional:
//       death > home > start > hop > background thump
//   This keeps important gameplay feedback from being hidden by the music.
//////////////////////////////////////////////////////////////////////////////////

module frogger_audio(
    input  wire clk,
    input  wire reset,

    input  wire game_music_enable,
    input  wire start_event,
    input  wire hop_event,
    input  wire death_event,
    input  wire home_event,

    output reg  amp2_ain,
    output wire amp2_gain,
    output wire amp2_shutdown_n
);

    // Pmod AMP2 control lines.
    // amp2_ain is the actual 1-bit audio waveform. The PMOD amplifier turns this
    // FPGA digital output into a speaker signal.
    // For Pmod AMP2:
    // 0 = lower gain, 1 = higher gain.
    // Low gain is better here because the speaker can get loud quickly.
    assign amp2_gain       = 1'b0;
    assign amp2_shutdown_n = 1'b1;

    // Tone divider constants.
    // The output square wave toggles every tone_div clock cycles. Larger divider
    // values produce lower notes. These are approximate because the goal is arcade
    // style sound effects, not musical tuning perfection.
    //
    // 100 MHz clock divider values for approximate square-wave pitches.
    // Frequency ~= 100 MHz / (2 * DIV)
    //
    // Width is 20 bits so the lower thump/buzz values fit without truncation.
    localparam [19:0] DIV_A4    = 20'd113636; // ~440 Hz
    localparam [19:0] DIV_C5    = 20'd95556;  // ~523 Hz
    localparam [19:0] DIV_E5    = 20'd75843;  // ~659 Hz
    localparam [19:0] DIV_G5    = 20'd63776;  // ~784 Hz
    localparam [19:0] DIV_C6    = 20'd47778;  // ~1046 Hz
    localparam [19:0] DIV_HOP   = 20'd52000;  // short hop blip
    localparam [19:0] DIV_LOW   = 20'd160000; // low death buzz

    // Background music notes.
    // Instead of a full melody, gameplay uses a low heartbeat/thump pattern.
    // This is less distracting than a constant arpeggio and feels closer to old
    // arcade games like Space Invaders.
    // Low thump notes. These are intentionally very low and short.
    localparam [19:0] DIV_THUMP0 = 20'd520000; // ~96 Hz
    localparam [19:0] DIV_THUMP1 = 20'd460000; // ~109 Hz
    localparam [19:0] DIV_THUMP2 = 20'd410000; // ~122 Hz
    localparam [19:0] DIV_THUMP3 = 20'd470000; // ~106 Hz

    // Sound effect durations.
    localparam [24:0] DUR_SHORT = 25'd2_500_000;   // ~25 ms
    localparam [24:0] DUR_MED   = 25'd7_500_000;   // ~75 ms
    localparam [24:0] DUR_LONG  = 25'd20_000_000;  // ~200 ms

    // Music timing.
    // One beat every ~0.42 seconds, but the thump only plays briefly.
    localparam [25:0] MUSIC_BEAT_PERIOD = 26'd42_000_000;
    localparam [25:0] MUSIC_THUMP_DUR   = 26'd4_000_000;  // ~40 ms

    // Sound-effect state encoding.
    // sfx_type selects which sound effect is currently overriding the background
    // music. SFX_NONE means no sound effect is active, so music may play.
    localparam [2:0] SFX_NONE  = 3'd0;
    localparam [2:0] SFX_START = 3'd1;
    localparam [2:0] SFX_HOP   = 3'd2;
    localparam [2:0] SFX_DEATH = 3'd3;
    localparam [2:0] SFX_HOME  = 3'd4;

    reg [2:0]  sfx_type;
    reg [24:0] sfx_timer;
    reg [1:0]  sfx_step;

    reg [19:0] tone_div;
    reg [19:0] tone_count;
    reg        tone_bit;

    reg [25:0] music_timer;
    reg [1:0]  music_step;

    // LFSR noise generator for the death sound.
    // This produces pseudo-random bits using XOR feedback taps. Mixing these bits
    // with the square wave makes the death sound buzzy/noisy instead of a clean tone.
    reg [14:0] noise_lfsr;
    wire noise_bit = noise_lfsr[0] ^ noise_lfsr[3] ^ noise_lfsr[5];

    reg use_noise;
    reg audio_enable;
    reg music_thump_active;

    // Combinational audio selection/mixing.
    // This block decides which tone should be generated right now. It does not
    // update timers; it simply maps the current state to tone_div, noise enable,
    // and audio_enable.
    always @(*) begin
        tone_div           = DIV_A4;
        use_noise          = 1'b0;
        audio_enable       = 1'b0;
        music_thump_active = 1'b0;

        // Sound effects override the background thump.
        if (sfx_type != SFX_NONE) begin
            audio_enable = 1'b1;

            case (sfx_type)
                SFX_START: begin
                    case (sfx_step)
                        2'd0: tone_div = DIV_C5;
                        2'd1: tone_div = DIV_E5;
                        default: tone_div = DIV_G5;
                    endcase
                end

                SFX_HOP: begin
                    tone_div = DIV_HOP;
                end

                SFX_DEATH: begin
                    // Death uses a low tone plus LFSR noise modulation.
                    // The changing divider makes the sound wobble downward/roughly.
                    tone_div  = DIV_LOW + {10'd0, sfx_timer[16:7]};
                    use_noise = 1'b1;
                end

                SFX_HOME: begin
                    case (sfx_step)
                        2'd0: tone_div = DIV_G5;
                        default: tone_div = DIV_C6;
                    endcase
                end

                default: begin
                    tone_div = DIV_A4;
                end
            endcase
        end
        else if (game_music_enable) begin
            // Background music is only allowed during active gameplay. Title and
            // game-over screens stay silent except for one-shot events.
            // Space-Invaders-style low heartbeat:
            // brief low thump, then silence until next beat.
            music_thump_active = (music_timer < MUSIC_THUMP_DUR);

            if (music_thump_active) begin
                audio_enable = 1'b1;

                case (music_step)
                    2'd0: tone_div = DIV_THUMP0;
                    2'd1: tone_div = DIV_THUMP1;
                    2'd2: tone_div = DIV_THUMP2;
                    default: tone_div = DIV_THUMP3;
                endcase
            end
        end
    end

    // Sequential audio engine.
    // This block stores current sound-effect state, runs the timers, advances the
    // background thump beat, updates the tone generator, advances the LFSR, and
    // drives the final amp2_ain output.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sfx_type    <= SFX_NONE;
            sfx_timer   <= 25'd0;
            sfx_step    <= 2'd0;

            tone_count  <= 20'd0;
            tone_bit    <= 1'b0;
            amp2_ain    <= 1'b0;

            music_timer <= 26'd0;
            music_step  <= 2'd0;
            noise_lfsr  <= 15'h4A3B;
        end
        else begin
            // Event priority: death > home > start > hop.
            // If two events happen close together, the more important one wins.
            if (death_event) begin
                sfx_type  <= SFX_DEATH;
                sfx_timer <= DUR_LONG;
                sfx_step  <= 2'd0;
            end
            else if (home_event) begin
                sfx_type  <= SFX_HOME;
                sfx_timer <= DUR_MED;
                sfx_step  <= 2'd0;
            end
            else if (start_event) begin
                sfx_type  <= SFX_START;
                sfx_timer <= DUR_MED;
                sfx_step  <= 2'd0;
            end
            else if (hop_event && (sfx_type == SFX_NONE)) begin
                sfx_type  <= SFX_HOP;
                sfx_timer <= DUR_SHORT;
                sfx_step  <= 2'd0;
            end

            // Sound effect timer.
            // Multi-step effects change pitch during playback using sfx_step.
            if (sfx_type != SFX_NONE) begin
                if (sfx_timer != 0) begin
                    sfx_timer <= sfx_timer - 1'b1;

                    if (sfx_type == SFX_START) begin
                        if (sfx_timer == (DUR_MED * 2 / 3))
                            sfx_step <= 2'd1;
                        else if (sfx_timer == (DUR_MED / 3))
                            sfx_step <= 2'd2;
                    end
                    else if (sfx_type == SFX_HOME) begin
                        if (sfx_timer == (DUR_MED / 2))
                            sfx_step <= 2'd1;
                    end
                end
                else begin
                    sfx_type <= SFX_NONE;
                    sfx_step <= 2'd0;
                end
            end

            // Background thump timing.
            // music_timer counts a beat period; music_step chooses which low thump
            // note to use on the next beat. Runs only during gameplay.
            if (game_music_enable && (sfx_type == SFX_NONE)) begin
                if (music_timer >= MUSIC_BEAT_PERIOD) begin
                    music_timer <= 26'd0;
                    music_step  <= music_step + 1'b1;
                end
                else begin
                    music_timer <= music_timer + 1'b1;
                end
            end
            else if (!game_music_enable) begin
                music_timer <= 26'd0;
                music_step  <= 2'd0;
            end

            // Tone generator.
            // A counter toggles tone_bit when it reaches tone_div. This is the
            // basic square-wave oscillator used by both music and sound effects.
            if (tone_count >= tone_div) begin
                tone_count <= 20'd0;
                tone_bit   <= ~tone_bit;
            end
            else begin
                tone_count <= tone_count + 1'b1;
            end

            // LFSR for death buzz modulation.
            // Shift left and insert the XOR feedback bit. The sequence looks random
            // enough for arcade noise but uses very little hardware.
            noise_lfsr <= {noise_lfsr[13:0], noise_bit};

            // Final output mux.
            // Normal sounds drive amp2_ain with tone_bit. The death sound XORs in
            // LFSR bits to create a rougher noisy waveform.
            if (audio_enable) begin
                if (use_noise)
                    amp2_ain <= tone_bit ^ noise_lfsr[0] ^ noise_lfsr[4];
                else
                    amp2_ain <= tone_bit;
            end
            else begin
                amp2_ain <= 1'b0;
            end
        end
    end

endmodule

