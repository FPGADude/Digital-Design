`timescale 1ns / 1ps

// ============================================================================
// Module: vga_640x480
// Project: FPGA Motion Security System
//
// Purpose:
//   Generates standard 640x480 VGA timing from the Basys 3 100 MHz clock.
//
// Timing:
//   The 100 MHz clock is divided by four to obtain an effective 25 MHz pixel
//   update rate. Horizontal and vertical counters step through the complete
//   visible area, front porch, synchronization pulse, and back porch.
//
// Outputs:
//   hsync/video synchronization signals are active LOW.
//   video_on is HIGH only inside the 640x480 visible region.
//   pixel_x and pixel_y identify the current raster position.
// ============================================================================
module vga_640x480 (
    input  logic       clk,
    output logic       hsync,
    output logic       vsync,
    output logic       video_on,
    output logic [9:0] pixel_x,
    output logic [9:0] pixel_y
);

    // Horizontal timing intervals, measured in pixel clocks.
    localparam int H_VISIBLE = 640;
    localparam int H_FRONT   = 16;
    localparam int H_SYNC    = 96;
    localparam int H_BACK    = 48;
    localparam int H_TOTAL   = 800;

    // Vertical timing intervals, measured in scan lines.
    localparam int V_VISIBLE = 480;
    localparam int V_FRONT   = 10;
    localparam int V_SYNC    = 2;
    localparam int V_BACK    = 33;
    localparam int V_TOTAL   = 525;

    // Pixel-clock divider and raster-position counters.
    logic [1:0] clk_div = 2'd0;
    logic [9:0] h_count = 10'd0;
    logic [9:0] v_count = 10'd0;

    // Advance one VGA pixel every fourth 100 MHz clock cycle.
    always_ff @(posedge clk) begin
        clk_div <= clk_div + 1'b1;

        if (clk_div == 2'd3) begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;

                if (v_count == V_TOTAL - 1) begin
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

    // Current raster coordinates are exported directly to the renderer.
    assign pixel_x = h_count;
    assign pixel_y = v_count;

    // Visible video is limited to the active 640x480 image region.
    assign video_on =
        (h_count < H_VISIBLE) &&
        (v_count < V_VISIBLE);

    // VGA horizontal and vertical synchronization pulses are active LOW.
    assign hsync = ~(
        (h_count >= H_VISIBLE + H_FRONT) &&
        (h_count <  H_VISIBLE + H_FRONT + H_SYNC)
    );

    assign vsync = ~(
        (v_count >= V_VISIBLE + V_FRONT) &&
        (v_count <  V_VISIBLE + V_FRONT + V_SYNC)
    );

endmodule
