`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: vga_timing_640x480
//
// Purpose:
//   Generates horizontal and vertical pixel coordinates plus synchronization
//   signals for a standard 640x480 VGA display at approximately 60 Hz.
//
// Timing totals:
//   Horizontal: 640 visible + 16 front porch + 96 sync + 48 back porch = 800
//   Vertical:   480 visible + 10 front porch +  2 sync + 33 back porch = 525
//
// Clocking:
//   The Basys 3 100 MHz clock is divided by four with pixel_div, producing a
//   25 MHz pixel enable. hsync and vsync are active-low.
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// 640x480 @ 60 Hz VGA Timing Generator
//
// Input clock: 100 MHz
// Pixel clock: 25 MHz, created with a divide-by-4 counter
//////////////////////////////////////////////////////////////////////////////////

module vga_timing_640x480 (
    input  wire       clk,
    input  wire       reset,
    output reg  [9:0] pixel_x,
    output reg  [9:0] pixel_y,
    output wire       hsync,
    output wire       vsync,
    output wire       video_on,
    output wire       pixel_tick
);

    // Modulo-four divider. The counters advance only when pixel_tick is high.
    reg [1:0] pixel_div;

    // One-cycle enable every fourth 100 MHz clock period.
    assign pixel_tick = (pixel_div == 2'b11);

    // Pixel-enable divider.
    always @(posedge clk) begin
        if (reset)
            pixel_div <= 2'b00;
        else
            pixel_div <= pixel_div + 1'b1;
    end

    // Raster counters scan all 800 x 525 timing positions.
    always @(posedge clk) begin
        if (reset) begin
            pixel_x <= 10'd0;
            pixel_y <= 10'd0;
        end
        else if (pixel_tick) begin
            if (pixel_x == 10'd799) begin
                pixel_x <= 10'd0;

                if (pixel_y == 10'd524)
                    pixel_y <= 10'd0;
                else
                    pixel_y <= pixel_y + 1'b1;
            end
            else begin
                pixel_x <= pixel_x + 1'b1;
            end
        end
    end

    // Active-low synchronization pulses and visible-region qualifier.
    assign hsync = ~((pixel_x >= 10'd656) && (pixel_x < 10'd752));
    assign vsync = ~((pixel_y >= 10'd490) && (pixel_y < 10'd492));
    assign video_on = (pixel_x < 10'd640) && (pixel_y < 10'd480);

endmodule
