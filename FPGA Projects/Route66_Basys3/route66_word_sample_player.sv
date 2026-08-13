`timescale 1ns / 1ps
`include "route66_voice_defs.vh"
module route66_word_sample_player #(
    parameter integer CLOCK_HZ  = 100_000_000,
    parameter integer SAMPLE_HZ = 12_500
)(
    input  logic               clk,
    input  logic               reset,
    input  logic               start,
    input  logic [5:0]         word_id,
    output logic               busy,
    output logic signed [15:0] sample_out,
    output logic               sample_valid
);
    localparam integer SAMPLE_DIV = CLOCK_HZ / SAMPLE_HZ;
    logic [17:0] start_address, sample_length;
    logic [17:0] rom_address;
    logic [7:0]  rom_sample;
    logic [15:0] sample_div_count;
    logic [17:0] samples_played;
    logic        rom_primed;
    wire sample_tick = (sample_div_count == SAMPLE_DIV - 1);

    route66_word_sample_table u_table (
        .word_id(word_id), .start_address(start_address), .sample_length(sample_length)
    );
    route66_word_sample_rom u_rom (
        .clk(clk), .address(rom_address), .sample(rom_sample)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            sample_div_count <= 16'd0;
            samples_played   <= 18'd0;
            rom_address      <= 18'd0;
            rom_primed       <= 1'b0;
            busy             <= 1'b0;
            sample_out       <= 16'sd0;
            sample_valid     <= 1'b0;
        end else begin
            sample_valid <= 1'b0;
            if (sample_tick) sample_div_count <= 16'd0;
            else             sample_div_count <= sample_div_count + 1'b1;

            if (start && !busy) begin
                rom_address    <= start_address;
                samples_played <= 18'd0;
                rom_primed     <= 1'b0;
                busy           <= (word_id != `WORD_END);
            end

            if (sample_tick && busy) begin
                if (!rom_primed) begin
                    rom_primed <= 1'b1;
                end else begin
                    sample_out   <= {rom_sample, 8'h00} - 16'sh8000;
                    sample_valid <= 1'b1;
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
