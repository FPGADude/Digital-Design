`timescale 1ns / 1ps
module button_input(
    input  wire clk,
    input  wire reset,
    input  wire btnU,
    input  wire btnD,
    input  wire btnL,
    input  wire btnR,

    output reg  up_pressed,
    output reg  down_pressed,
    output reg  left_pressed,
    output reg  right_pressed
);

    reg btnU_sync0, btnU_sync1;
    reg btnD_sync0, btnD_sync1;
    reg btnL_sync0, btnL_sync1;
    reg btnR_sync0, btnR_sync1;

    reg btnU_prev;
    reg btnD_prev;
    reg btnL_prev;
    reg btnR_prev;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            btnU_sync0 <= 1'b0;
            btnU_sync1 <= 1'b0;
            btnD_sync0 <= 1'b0;
            btnD_sync1 <= 1'b0;
            btnL_sync0 <= 1'b0;
            btnL_sync1 <= 1'b0;
            btnR_sync0 <= 1'b0;
            btnR_sync1 <= 1'b0;

            btnU_prev <= 1'b0;
            btnD_prev <= 1'b0;
            btnL_prev <= 1'b0;
            btnR_prev <= 1'b0;

            up_pressed    <= 1'b0;
            down_pressed  <= 1'b0;
            left_pressed  <= 1'b0;
            right_pressed <= 1'b0;
        end
        else begin
            // 2-stage synchronizers
            btnU_sync0 <= btnU;
            btnU_sync1 <= btnU_sync0;

            btnD_sync0 <= btnD;
            btnD_sync1 <= btnD_sync0;

            btnL_sync0 <= btnL;
            btnL_sync1 <= btnL_sync0;

            btnR_sync0 <= btnR;
            btnR_sync1 <= btnR_sync0;

            // rising-edge detect
            up_pressed    <= btnU_sync1 & ~btnU_prev;
            down_pressed  <= btnD_sync1 & ~btnD_prev;
            left_pressed  <= btnL_sync1 & ~btnL_prev;
            right_pressed <= btnR_sync1 & ~btnR_prev;

            // save previous stable states
            btnU_prev <= btnU_sync1;
            btnD_prev <= btnD_sync1;
            btnL_prev <= btnL_sync1;
            btnR_prev <= btnR_sync1;
        end
    end

endmodule
