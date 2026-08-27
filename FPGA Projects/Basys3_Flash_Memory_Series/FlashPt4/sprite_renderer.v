`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - FPGA Flash From the Ground Up
// Part 4 Sprite Renderer
//
// Displays the 32x32 RGB332 sprite stored in BRAM.
//
// The source sprite is enlarged by 4x in both dimensions:
//
//   32 x 32 source pixels
//        |
//        v
//   128 x 128 VGA pixels
//
// RGB332 format:
//
//   [7:5] = Red   (3 bits)
//   [4:2] = Green (3 bits)
//   [1:0] = Blue  (2 bits)
//
// Pixel value 0x00 is reserved for transparency.
//
// The BRAM read is synchronous, so sprite_data arrives one clock after
// sprite_addr is presented. The renderer therefore delays its control signals
// by one pixel to keep the BRAM data aligned with the correct VGA location.
// ============================================================================

module sprite_renderer (
    input  wire       clk,
    input  wire       pixel_tick,

    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire       video_active,

    input  wire       hsync_in,
    input  wire       vsync_in,

    input  wire       sprite_loaded,

    output wire [9:0] sprite_addr,
    input  wire [7:0] sprite_data,

    output reg  [3:0] vgaRed   = 4'h0,
    output reg  [3:0] vgaGreen = 4'h0,
    output reg  [3:0] vgaBlue  = 4'h0,

    output reg        Hsync    = 1'b1,
    output reg        Vsync    = 1'b1
);

    // ========================================================================
    // SPRITE SCREEN POSITION
    //
    // 128x128 displayed sprite centered in a 640x480 active image:
    //
    //   X = (640 - 128) / 2 = 256
    //   Y = (480 - 128) / 2 = 176
    // ========================================================================

    localparam [9:0] SPRITE_X = 10'd256;
    localparam [9:0] SPRITE_Y = 10'd176;

    localparam [9:0] DISPLAY_SIZE = 10'd128;


    // ========================================================================
    // DETERMINE WHETHER CURRENT VGA PIXEL IS INSIDE THE SPRITE
    // ========================================================================

    wire inside_now;

    assign inside_now =
        sprite_loaded &&
        video_active &&
        (pixel_x >= SPRITE_X) &&
        (pixel_x <  SPRITE_X + DISPLAY_SIZE) &&
        (pixel_y >= SPRITE_Y) &&
        (pixel_y <  SPRITE_Y + DISPLAY_SIZE);


    // ========================================================================
    // MAP VGA COORDINATES TO 32x32 SOURCE COORDINATES
    //
    // Dividing by 4 performs nearest-neighbor 4x scaling:
    //
    //   four VGA pixels horizontally use one source pixel
    //   four VGA rows vertically use one source row
    // ========================================================================

    wire [4:0] src_x;
    wire [4:0] src_y;

    assign src_x = (pixel_x - SPRITE_X) >> 2;
    assign src_y = (pixel_y - SPRITE_Y) >> 2;


    // ========================================================================
    // CONVERT (X,Y) SOURCE COORDINATE INTO LINEAR BRAM ADDRESS
    //
    // Row-major sprite storage:
    //
    //   address = (src_y * 32) + src_x
    //
    // Multiplication by 32 is simply a left shift by 5 bits.
    // ========================================================================

    assign sprite_addr = {src_y, 5'b00000} + src_x;


    // ========================================================================
    // ONE-PIXEL PIPELINE FOR SYNCHRONOUS BRAM
    // ========================================================================

    reg inside_d = 1'b0;
    reg active_d = 1'b0;
    reg hsync_d  = 1'b1;
    reg vsync_d  = 1'b1;


    // ========================================================================
    // RGB332 COMPONENTS
    // ========================================================================

    wire [2:0] pixel_red;
    wire [2:0] pixel_green;
    wire [1:0] pixel_blue;

    assign pixel_red   = sprite_data[7:5];
    assign pixel_green = sprite_data[4:2];
    assign pixel_blue  = sprite_data[1:0];


    // ========================================================================
    // VGA PIXEL OUTPUT
    // ========================================================================

    always @(posedge clk) begin

        if (pixel_tick) begin

            // Sync signals are delayed by the same pipeline stage used for
            // the synchronous BRAM pixel data.
            Hsync <= hsync_d;
            Vsync <= vsync_d;

            if (!active_d) begin

                // Outside the visible 640x480 region: output black.
                vgaRed   <= 4'h0;
                vgaGreen <= 4'h0;
                vgaBlue  <= 4'h0;

            end
            else if (inside_d && (sprite_data != 8'h00)) begin

                // ------------------------------------------------------------
                // Visible non-transparent sprite pixel.
                //
                // Expand RGB332 to the Basys 3 RGB444 VGA outputs by
                // replicating the most significant source bits.
                // ------------------------------------------------------------

                vgaRed   <= {pixel_red,   pixel_red[2]};
                vgaGreen <= {pixel_green, pixel_green[2]};
                vgaBlue  <= {pixel_blue,  pixel_blue};

            end
            else begin

                // Transparent sprite pixels and all other active-screen pixels
                // show the background color.
                vgaRed   <= 4'h0;
                vgaGreen <= 4'h0;
                vgaBlue  <= 4'h2;

            end

            // Save current timing/location information for the next pixel,
            // when the corresponding BRAM data becomes available.
            inside_d <= inside_now;
            active_d <= video_active;
            hsync_d  <= hsync_in;
            vsync_d  <= vsync_in;

        end

    end

endmodule
