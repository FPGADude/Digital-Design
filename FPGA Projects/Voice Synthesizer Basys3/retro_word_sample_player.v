`timescale 1ns / 1ps
`include "retro_voice_defs.vh"

// ============================================================
// COMPLETE-WORD PCM PLAYER
// ============================================================
// Plays one complete dictionary word from registered block ROM.
//
// Handshake:
//   start pulses for one clock while busy is low.
//   busy remains high until every PCM sample for the word is emitted.
//
// At 100 MHz and 12.5 kHz, one new PCM sample is produced every 8,000 clocks.
// The first sample interval primes the two-cycle registered XPM ROM.
// ============================================================
module retro_word_sample_player #(
    parameter CLOCK_HZ  = 100_000_000,
    parameter SAMPLE_HZ = 12_500
)(
    input  wire              clk,
    input  wire              reset,
    input  wire              start,
    input  wire [5:0]        word_id,

    output reg               busy,
    output reg signed [15:0] sample_out,
    output reg               sample_valid
);

    // Number of system clocks between PCM samples.
    localparam integer SAMPLE_DIV = CLOCK_HZ / SAMPLE_HZ;
    
    // Address range returned by the word lookup table.
    wire [17:0] start_address;
    wire [17:0] sample_length;
    reg  [17:0] rom_address;
    wire [7:0]  rom_sample;
    
    // Sample-rate divider, playback counter, and ROM pipeline flag.
    reg [15:0] sample_div_count;
    reg [17:0] samples_played;
    reg        rom_primed;
    
    // One-clock enable at the requested audio sample rate.
    wire sample_tick = (sample_div_count == SAMPLE_DIV - 1);
    
    // Convert word_id into ROM start address and sample count.
    retro_word_sample_table table_inst (
        .word_id       (word_id),
        .start_address (start_address),
        .sample_length (sample_length)
    );
    
    // Registered XPM block ROM containing unsigned 8-bit PCM.
    retro_word_sample_rom rom_inst (
        .clk     (clk),
        .address (rom_address),
        .sample  (rom_sample)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            sample_div_count <= 16'd0;
            samples_played   <= 18'd0;
            rom_address      <= 18'd0;
            rom_primed       <= 1'b0;
            busy             <= 1'b0;
            sample_out       <= 16'sd0;
            sample_valid     <= 1'b0;
        end else begin
            // sample_valid is a one-clock pulse.
            sample_valid <= 1'b0;
    
            // Generate the 12.5 kHz clock-enable pulse.
            if (sample_tick)
                sample_div_count <= 16'd0;
            else
                sample_div_count <= sample_div_count + 1'b1;
    
            // Accept a new word request only while idle.
            if (start && !busy) begin
                rom_address    <= start_address;
                samples_played <= 18'd0;
                rom_primed     <= 1'b0;
                busy           <= (word_id != `WORD_END);
            end
    
            // Advance through ROM only at the PCM sample rate.
            if (sample_tick && busy) begin
                if (!rom_primed) begin
                    // Allow the registered block-ROM output to become valid.
                    rom_primed <= 1'b1;
                end else begin
                    // Convert unsigned 8-bit PCM to signed 16-bit PCM.
                    sample_out   <= {rom_sample, 8'h00} - 16'sh8000;
                    sample_valid <= 1'b1;
    
                    // End playback after the final byte in the selected word.
                    if (samples_played >= sample_length - 1'b1) begin
                        busy       <= 1'b0;
                        sample_out <= 16'sd0;
                    end else begin
                        samples_played <= samples_played + 1'b1;
                        rom_address    <= rom_address + 1'b1;
                    end
                end
            end
        end
    end

endmodule
