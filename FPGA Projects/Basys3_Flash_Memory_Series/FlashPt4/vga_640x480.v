`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - FPGA Flash From the Ground Up
// Part 4 VGA Timing Generator
//
// Generates standard 640x480 VGA timing at approximately 60 Hz.
//
// Basys 3 system clock : 100 MHz
// Pixel rate used here : 25 MHz
//
// Horizontal timing (pixels):
//
//   Active Video = 640
//   Front Porch  = 16
//   Sync Pulse   = 96
//   Back Porch   = 48
//   Total        = 800
//
// Vertical timing (lines):
//
//   Active Video = 480
//   Front Porch  = 10
//   Sync Pulse   = 2
//   Back Porch   = 33
//   Total        = 525
//
// Hsync and Vsync are active LOW for standard 640x480 VGA timing.
// ============================================================================

module vga_640x480 (
    input  wire       clk,

    output wire       pixel_tick,

    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y,

    output wire       video_active,
    output wire       hsync,
    output wire       vsync
);

    // ========================================================================
    // PIXEL CLOCK ENABLE
    //
    // Divide the 100 MHz Basys 3 clock by four to obtain a 25 MHz pixel
    // enable. The entire design remains in the 100 MHz clock domain; pixel
    // counters advance only when pixel_tick is asserted.
    // ========================================================================

    reg [1:0] pix_div = 2'd0;

    assign pixel_tick = (pix_div == 2'd3);


    // ========================================================================
    // VGA POSITION COUNTERS
    // ========================================================================

    reg [9:0] h_count = 10'd0;
    reg [9:0] v_count = 10'd0;

    always @(posedge clk) begin

        // Free-running divide-by-four counter.
        pix_div <= pix_div + 1'b1;

        if (pixel_tick) begin

            if (h_count == 10'd799) begin

                // End of one VGA line.
                h_count <= 10'd0;

                if (v_count == 10'd524) begin

                    // End of one complete VGA frame.
                    v_count <= 10'd0;

                end
                else begin

                    v_count <= v_count + 1'b1;

                end

            end
            else begin

                h_count <= h_count + 1'b1;

            end

        end

    end


    // Current raster position.
    assign pixel_x = h_count;
    assign pixel_y = v_count;


    // ========================================================================
    // ACTIVE VIDEO REGION
    //
    // RGB data is visible only during the first 640 pixels of each line and
    // the first 480 lines of each frame.
    // ========================================================================

    assign video_active =
        (h_count < 10'd640) &&
        (v_count < 10'd480);


    // ========================================================================
    // HORIZONTAL / VERTICAL SYNC
    // ========================================================================

    // Horizontal sync pulse:
    // 640 active + 16 front porch = 656
    // 656 through 751 = 96-clock active-low sync interval
    assign hsync =
        ~((h_count >= 10'd656) &&
          (h_count <  10'd752));

    // Vertical sync pulse:
    // 480 active + 10 front porch = 490
    // lines 490 and 491 = 2-line active-low sync interval
    assign vsync =
        ~((v_count >= 10'd490) &&
          (v_count <  10'd492));

endmodule
