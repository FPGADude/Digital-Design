`timescale 1ns / 1ps
// Generates a once per frame (60Hz) synchronizing pulse
// Master timing signal for game logic synced with VGA display
module frame_tick(
    input  wire clk,
    input  wire reset,
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    output reg  tick
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            tick <= 1'b0;
        else if ((pix_x == 10'd0) && (pix_y == 10'd0))
            tick <= 1'b1;
        else
            tick <= 1'b0;
    end

endmodule
