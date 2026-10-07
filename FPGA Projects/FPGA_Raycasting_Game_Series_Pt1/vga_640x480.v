`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// 640x480 VGA TIMING GENERATOR
//
// The Basys 3 clock is 100 MHz. This module derives the pixel timing used for
// standard 640x480 VGA and produces:
//   pixel_x / pixel_y : current raster location
//   video_active      : pixel lies in visible area
//   hsync / vsync     : monitor synchronization
//   frame_start       : one-frame scheduling pulse used by game logic
//
// Rendering modules should decide COLOR from pixel_x/pixel_y; timing remains
// isolated here so graphics logic does not have to know VGA porch/sync details.
///////////////////////////////////////////////////////////////////////////////

module vga_640x480 (
    input  wire       clk_100mhz,
    input  wire       reset,
    output reg  [9:0] pixel_x,
    output reg  [9:0] pixel_y,
    output wire       video_active,
    output wire       hsync,
    output wire       vsync,
    output wire       pixel_tick,
    output wire       frame_start
);

    // Divide 100 MHz by four to obtain the 25 MHz pixel-enable used by
    // the standard 640x480 timing. The logic itself remains in the 100 MHz
    // clock domain, which keeps the design simple and timing-friendly.
    reg [1:0] pixel_div;

    assign pixel_tick = (pixel_div == 2'b11);

    always @(posedge clk_100mhz) begin
        if (reset)
            pixel_div <= 2'b00;
        else
            pixel_div <= pixel_div + 2'b01;
    end

    // Horizontal timing: 640 visible, 16 front porch, 96 sync, 48 back porch.
    // Vertical timing:   480 visible, 10 front porch, 2 sync, 33 back porch.
    always @(posedge clk_100mhz) begin
        if (reset) begin
            pixel_x <= 10'd0;
            pixel_y <= 10'd0;
        end else if (pixel_tick) begin
            if (pixel_x == 10'd799) begin
                pixel_x <= 10'd0;
                if (pixel_y == 10'd524)
                    pixel_y <= 10'd0;
                else
                    pixel_y <= pixel_y + 10'd1;
            end else begin
                pixel_x <= pixel_x + 10'd1;
            end
        end
    end

    assign video_active = (pixel_x < 10'd640) && (pixel_y < 10'd480);
    assign hsync = ~((pixel_x >= 10'd656) && (pixel_x < 10'd752));
    assign vsync = ~((pixel_y >= 10'd490) && (pixel_y < 10'd492));

    // One-cycle marker at the first visible pixel of each frame.
    assign frame_start = pixel_tick && (pixel_x == 10'd0) && (pixel_y == 10'd0);

endmodule
