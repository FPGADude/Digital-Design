`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Simple Arcade Audio Engine
//
// Input event codes are one-clock pulses:
//   0 = none
//   1 = menu move / UI tick
//   2 = select / start / restart
//   3 = wall bounce / movement tick
//   4 = good hit / score / food / brick / alien hit
//   5 = miss / game over
//   6 = fire / shoot
//
// Output:
//   buzzer = square-wave tone while a sound effect is active
//
// Hardware note:
//   A small piezo buzzer can usually be driven directly from an FPGA pin.
//   For a magnetic buzzer or speaker, use a transistor driver.
//////////////////////////////////////////////////////////////////////////////////

module audio_engine #(
    parameter int CLK_HZ = 12_000_000
)(
    input  logic clk,
    input  logic reset,

    input  logic [3:0] sfx_event,

    output logic buzzer
);

    logic [31:0] tone_divider;
    logic [31:0] tone_counter;
    logic [31:0] duration_counter;
    logic [1:0]  phase;
    logic        active;
    logic        square;

    function automatic logic [31:0] hz_to_half_period(input int hz);
        begin
            hz_to_half_period = CLK_HZ / (hz * 2);
        end
    endfunction

    task automatic start_sfx(input logic [3:0] ev);
        begin
            active <= 1'b1;
            square <= 1'b0;
            tone_counter <= 32'd0;
            phase <= 2'd0;

            case (ev)
                4'd1: begin // menu tick
                    tone_divider <= hz_to_half_period(1200);
                    duration_counter <= CLK_HZ / 30;     // ~33 ms
                end

                4'd2: begin // select/start
                    tone_divider <= hz_to_half_period(700);
                    duration_counter <= CLK_HZ / 8;      // ~125 ms
                end

                4'd3: begin // bounce / neutral
                    tone_divider <= hz_to_half_period(900);
                    duration_counter <= CLK_HZ / 25;     // ~40 ms
                end

                4'd4: begin // good hit / score
                    tone_divider <= hz_to_half_period(1500);
                    duration_counter <= CLK_HZ / 10;     // ~100 ms
                end

                4'd5: begin // miss / game over
                    tone_divider <= hz_to_half_period(300);
                    duration_counter <= CLK_HZ / 3;      // ~333 ms
                end

                4'd6: begin // laser / fire
                    tone_divider <= hz_to_half_period(2000);
                    duration_counter <= CLK_HZ / 20;     // ~50 ms
                end

                default: begin
                    active <= 1'b0;
                    tone_divider <= hz_to_half_period(1000);
                    duration_counter <= 32'd0;
                end
            endcase
        end
    endtask

    always_ff @(posedge clk) begin
        if (reset) begin
            tone_divider    <= hz_to_half_period(1000);
            tone_counter    <= 32'd0;
            duration_counter <= 32'd0;
            phase           <= 2'd0;
            active          <= 1'b0;
            square          <= 1'b0;
            buzzer          <= 1'b0;
        end else begin
            // New events restart the sound effect immediately.
            if (sfx_event != 4'd0) begin
                start_sfx(sfx_event);
            end else if (active) begin
                if (duration_counter == 32'd0) begin
                    active <= 1'b0;
                    square <= 1'b0;
                end else begin
                    duration_counter <= duration_counter - 1'b1;

                    // Simple descending effect for miss/game-over style sound.
                    // As duration runs down, the tone divider changes in two steps.
                    if (tone_counter >= tone_divider) begin
                        tone_counter <= 32'd0;
                        square <= ~square;
                    end else begin
                        tone_counter <= tone_counter + 1'b1;
                    end
                end
            end else begin
                square <= 1'b0;
                tone_counter <= 32'd0;
            end

            buzzer <= active ? square : 1'b0;
        end
    end

endmodule

