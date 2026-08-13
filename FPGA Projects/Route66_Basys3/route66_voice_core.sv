`timescale 1ns / 1ps
`include "route66_voice_defs.vh"
module route66_voice_core #(
    parameter integer CLOCK_HZ  = 100_000_000,
    parameter integer SAMPLE_HZ = 12_500
)(
    input  logic               clk,
    input  logic               reset,
    input  logic               start,
    input  logic [3:0]         phrase_id,
    output logic               busy,
    output logic signed [15:0] sample_out,
    output logic               sample_valid
);
    typedef enum logic [2:0] {
        ST_IDLE, ST_LOAD_WORD, ST_START_WORD, ST_WAIT_BUSY_HIGH,
        ST_WAIT_BUSY_LOW, ST_WORD_GAP, ST_DONE
    } state_t;
    localparam integer WORD_GAP_CYCLES = CLOCK_HZ / 10; // 100 ms
    state_t state;
    logic [3:0] active_phrase, word_index;
    logic [31:0] gap_count;
    logic word_start;
    logic [5:0] current_word;
    logic word_busy;

    route66_phrase_rom u_phrase_rom (
        .phrase_id(active_phrase), .word_index(word_index), .word_id(current_word)
    );
    route66_word_sample_player #(.CLOCK_HZ(CLOCK_HZ), .SAMPLE_HZ(SAMPLE_HZ)) u_player (
        .clk(clk), .reset(reset), .start(word_start), .word_id(current_word),
        .busy(word_busy), .sample_out(sample_out), .sample_valid(sample_valid)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= ST_IDLE; active_phrase <= 4'd0; word_index <= 4'd0;
            gap_count <= 32'd0; word_start <= 1'b0; busy <= 1'b0;
        end else begin
            word_start <= 1'b0;
            unique case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        active_phrase <= phrase_id; word_index <= 4'd0;
                        busy <= 1'b1; state <= ST_LOAD_WORD;
                    end
                end
                ST_LOAD_WORD: state <= (current_word == `WORD_END) ? ST_DONE : ST_START_WORD;
                ST_START_WORD: if (!word_busy) begin word_start <= 1'b1; state <= ST_WAIT_BUSY_HIGH; end
                ST_WAIT_BUSY_HIGH: if (word_busy) state <= ST_WAIT_BUSY_LOW;
                ST_WAIT_BUSY_LOW: if (!word_busy) begin gap_count <= 32'd0; state <= ST_WORD_GAP; end
                ST_WORD_GAP: begin
                    if (gap_count >= WORD_GAP_CYCLES-1) begin
                        gap_count <= 32'd0; word_index <= word_index + 1'b1; state <= ST_LOAD_WORD;
                    end else gap_count <= gap_count + 1'b1;
                end
                ST_DONE: begin busy <= 1'b0; state <= ST_IDLE; end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
