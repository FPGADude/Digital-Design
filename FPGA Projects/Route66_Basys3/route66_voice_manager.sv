`timescale 1ns / 1ps
`include "route66_voice_defs.vh"

// Queues Route 66 speech events so one-clock game events are not lost while
// another phrase is speaking. Pending events are represented as a bit mask.
module route66_voice_manager #(
    parameter integer CLOCK_HZ = 100_000_000
)(
    input  logic clk,
    input  logic reset,
    input  logic voice_busy,

    input  logic ev_begin,
    input  logic ev_operation,
    input  logic operation_is_sub,
    input  logic ev_correct,
    input  logic ev_incorrect,
    input  logic ev_ten_seconds,
    input  logic ev_time_expired,
    input  logic ev_game_over,

    output logic       voice_start,
    output logic [3:0] voice_phrase_id
);
    localparam integer STARTUP_DELAY = CLOCK_HZ / 20; // 50 ms after reset
    logic [8:0] pending;
    logic [31:0] startup_count;
    logic startup_pending;

    always_ff @(posedge clk) begin
        if (reset) begin
            pending          <= 9'd0;
            startup_count    <= 32'd0;
            startup_pending  <= 1'b1;
            voice_start      <= 1'b0;
            voice_phrase_id  <= `PHRASE_ROUTE_66;
        end else begin
            voice_start <= 1'b0;

            if (startup_pending) begin
                if (startup_count >= STARTUP_DELAY-1) begin
                    pending[0] <= 1'b1;
                    startup_pending <= 1'b0;
                end else startup_count <= startup_count + 1'b1;
            end

            if (ev_begin)       pending[1] <= 1'b1;
            if (ev_operation) begin
                if (operation_is_sub) pending[3] <= 1'b1;
                else                  pending[2] <= 1'b1;
            end
            if (ev_correct)      pending[4] <= 1'b1;
            if (ev_incorrect)    pending[5] <= 1'b1;
            if (ev_ten_seconds)  pending[6] <= 1'b1;
            if (ev_time_expired) pending[7] <= 1'b1;
            if (ev_game_over)    pending[8] <= 1'b1;

            if (!voice_busy) begin
                // Priority favors immediate result/timing messages, then game flow.
                if (pending[7]) begin voice_phrase_id <= `PHRASE_TIME_EXPIRED; pending[7] <= 1'b0; voice_start <= 1'b1; end
                else if (pending[4]) begin voice_phrase_id <= `PHRASE_CORRECT; pending[4] <= 1'b0; voice_start <= 1'b1; end
                else if (pending[5]) begin voice_phrase_id <= `PHRASE_INCORRECT; pending[5] <= 1'b0; voice_start <= 1'b1; end
                else if (pending[8]) begin voice_phrase_id <= `PHRASE_GAME_OVER; pending[8] <= 1'b0; voice_start <= 1'b1; end
                else if (pending[6]) begin voice_phrase_id <= `PHRASE_TEN_SECONDS; pending[6] <= 1'b0; voice_start <= 1'b1; end
                else if (pending[1]) begin voice_phrase_id <= `PHRASE_BEGIN; pending[1] <= 1'b0; voice_start <= 1'b1; end
                else if (pending[2]) begin voice_phrase_id <= `PHRASE_ADDITION; pending[2] <= 1'b0; voice_start <= 1'b1; end
                else if (pending[3]) begin voice_phrase_id <= `PHRASE_SUBTRACTION; pending[3] <= 1'b0; voice_start <= 1'b1; end
                else if (pending[0]) begin voice_phrase_id <= `PHRASE_ROUTE_66; pending[0] <= 1'b0; voice_start <= 1'b1; end
            end
        end
    end
endmodule
