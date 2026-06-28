`timescale 1ns / 1ps

module edge_pulse (
    input  logic clk,
    input  logic reset,
    input  logic level,
    output logic pulse
);

    logic level_d;

    always_ff @(posedge clk) begin
        if (reset) begin
            level_d <= 1'b0;
            pulse   <= 1'b0;
        end else begin
            level_d <= level;
            pulse   <= level & ~level_d;
        end
    end

endmodule

