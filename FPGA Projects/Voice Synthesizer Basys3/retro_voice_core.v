`timescale 1ns / 1ps

// ============================================================================
// REUSABLE RETRO VOICE PHRASE CONTROLLER
// ============================================================================
// Accepts a phrase_id and one-clock start pulse, then sequences complete PCM
// words until the phrase ROM returns WORD_END.
//
// The busy-high/busy-low handshake is intentional:
//   WAIT_BUSY_HIGH confirms that the word player accepted the command.
//   WAIT_BUSY_LOW waits for the complete word to finish.
// This prevents words from being skipped or cut short.
// ============================================================================

`include "retro_voice_defs.vh"

module retro_voice_core #(
    parameter CLOCK_HZ  = 100_000_000,
    parameter SAMPLE_HZ = 12_500
)(
    input  wire               clk,
    input  wire               reset,
    input  wire               start,
    input  wire [3:0]         phrase_id,
    output reg                busy,
    output wire signed [15:0] sample_out,
    output wire               sample_valid
);

    // State encoding for the phrase-sequencing finite-state machine.
    localparam ST_IDLE           = 3'd0;
    localparam ST_LOAD_WORD      = 3'd1;
    localparam ST_START_WORD     = 3'd2;
    localparam ST_WAIT_BUSY_HIGH = 3'd3;
    localparam ST_WAIT_BUSY_LOW  = 3'd4;
    localparam ST_WORD_GAP       = 3'd5;
    localparam ST_DONE           = 3'd6;
    
    // Insert 125 ms between complete words at the default 100 MHz clock.
    localparam integer WORD_GAP_CYCLES = CLOCK_HZ / 8;
    
    // Controller state and latched phrase progress.
    reg [2:0]  state;
    reg [3:0]  active_phrase;
    reg [3:0]  word_index;
    reg [31:0] gap_count;
    reg        word_start;
    
    // Current word selected by the phrase ROM and player busy feedback.
    wire [5:0] current_word;
    wire       word_busy;
    
    // Combinational sentence lookup.
    retro_phrase_rom phrase_rom_inst (
        .phrase_id  (active_phrase),
        .word_index (word_index),
        .word_id    (current_word)
    );
    
    // Complete-word PCM playback engine.
    retro_word_sample_player #(
        .CLOCK_HZ  (CLOCK_HZ),
        .SAMPLE_HZ (SAMPLE_HZ)
    ) word_player_inst (
        .clk          (clk),
        .reset        (reset),
        .start        (word_start),
        .word_id      (current_word),
        .busy         (word_busy),
        .sample_out   (sample_out),
        .sample_valid (sample_valid)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            state         <= ST_IDLE;
            active_phrase <= 4'd0;
            word_index    <= 4'd0;
            gap_count     <= 32'd0;
            word_start    <= 1'b0;
            busy          <= 1'b0;
        end else begin
            // word_start is asserted for one clock only.
            word_start <= 1'b0;
    
            case (state)
                // Wait for a phrase request and latch phrase_id.
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        active_phrase <= phrase_id;
                        word_index    <= 4'd0;
                        busy          <= 1'b1;
                        state         <= ST_LOAD_WORD;
                    end
                end
    
                // Read the next dictionary word from the phrase ROM.
                ST_LOAD_WORD: begin
                    if (current_word == `WORD_END)
                        state <= ST_DONE;
                    else
                        state <= ST_START_WORD;
                end
    
                // Pulse the word player's start input.
                ST_START_WORD: begin
                    if (!word_busy) begin
                        word_start <= 1'b1;
                        state      <= ST_WAIT_BUSY_HIGH;
                    end
                end
    
                // Confirm the player accepted the start command.
                ST_WAIT_BUSY_HIGH: begin
                    if (word_busy)
                        state <= ST_WAIT_BUSY_LOW;
                end
    
                // Wait until the complete word sample finishes.
                ST_WAIT_BUSY_LOW: begin
                    if (!word_busy) begin
                        gap_count <= 32'd0;
                        state     <= ST_WORD_GAP;
                    end
                end
    
                // Insert a short pause before requesting the next word.
                ST_WORD_GAP: begin
                    if (gap_count >= WORD_GAP_CYCLES - 1) begin
                        gap_count  <= 32'd0;
                        word_index <= word_index + 1'b1;
                        state      <= ST_LOAD_WORD;
                    end else begin
                        gap_count <= gap_count + 1'b1;
                    end
                end
    
                // Phrase terminator reached; return to idle.
                ST_DONE: begin
                    busy  <= 1'b0;
                    state <= ST_IDLE;
                end
    
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
