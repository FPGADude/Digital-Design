`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: vga_640x480
//
// Purpose:
//   Generates raster coordinates, visible-area status, and active-low sync
//   pulses for 640x480 VGA at approximately 60 Hz.
//
// A divide-by-four clock-enable produces a 25 MHz pixel rate while every
// register remains clocked by the original 100 MHz Basys 3 clock.
//
// Full raster:
//   Horizontal 0..799; visible 0..639.
//   Vertical   0..524; visible 0..479.
//
// 640x480 @ 60 Hz VGA Timing Generator
//
// Input clock: 100 MHz
// Pixel rate:  25 MHz generated with a clock enable
//
// Standard timing:
//   Horizontal: 640 visible, 16 front porch, 96 sync, 48 back porch
//   Vertical:   480 visible, 10 front porch, 2 sync, 33 back porch
//////////////////////////////////////////////////////////////////////////////////

(* keep_hierarchy = "yes" *) module vga_640x480 (
    input  wire       clk,
    input  wire       reset,

    output reg  [9:0] pixel_x,
    output reg  [9:0] pixel_y,
    output wire       video_active,
    output wire       hsync,
    output wire       vsync
);

    // Divide-by-four pixel-enable counter.
    reg [1:0] pixel_divider;

    wire pixel_tick = (pixel_divider == 2'd3);

    // Generate a 25 MHz-equivalent update pulse.
    always @(posedge clk) begin
        if (reset)
            pixel_divider <= 2'd0;
        else
            pixel_divider <= pixel_divider + 1'b1;
    end

    // Advance horizontal and vertical raster counters.
    always @(posedge clk) begin
        if (reset) begin
            pixel_x <= 10'd0;
            pixel_y <= 10'd0;
        end else if (pixel_tick) begin
            if (pixel_x == 10'd799) begin
                pixel_x <= 10'd0;

                if (pixel_y == 10'd524)
                    pixel_y <= 10'd0;
                else
                    pixel_y <= pixel_y + 1'b1;
            end else begin
                pixel_x <= pixel_x + 1'b1;
            end
        end
    end

    // Qualify the visible 640x480 drawing region.
    assign video_active = (pixel_x < 10'd640) && (pixel_y < 10'd480);

    // Standard VGA synchronization pulses are active-low.
    assign hsync = ~((pixel_x >= 10'd656) && (pixel_x < 10'd752));
    assign vsync = ~((pixel_y >= 10'd490) && (pixel_y < 10'd492));

endmodule
