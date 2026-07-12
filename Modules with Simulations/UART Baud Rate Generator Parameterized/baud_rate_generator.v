`timescale 1ns / 1ps

module baud_rate_generator #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer BAUD_RATE     = 115200
)(
    input  wire clk,
    input  wire reset,
    output reg  baud_tick
);

    // Rounded number of input-clock cycles per baud tick.
    localparam integer CLKS_PER_TICK = 
            (CLOCK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;

    reg [31:0] clock_count;

    always @(posedge clk) begin
        if (reset) begin
            clock_count <= 32'd0;
            baud_tick   <= 1'b0;
        end else begin
            // Default: tick remains low.
            baud_tick <= 1'b0;

            // Generate a one-clock pulse, then restart the counter.
            if (clock_count >= CLKS_PER_TICK - 1) begin
                clock_count <= 32'd0;
                baud_tick   <= 1'b1;
            end else begin
                clock_count <= clock_count + 1'b1;
            end
        end
    end

endmodule

