`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Module: vga_display_controller
// -----------------------------------------------------------------------------
// Purpose:
//   Generates the VGA timing and combines the pixel renderer with the text
//   renderer.
//
//   This module owns the VGA scan counters. The current pixel coordinate is sent
//   to:
//     - pixel_renderer.sv for the base intersection scene
//     - text_renderer.sv  for the countdown digit overlay
//
//   If text_on is asserted, the countdown digit color is drawn on top of the
//   base scene. Otherwise the base scene color is used.
//
// VGA Mode:
//   640x480 active display at 60 Hz.
//   The Basys 3 100 MHz clock is divided by 4 to create a 25 MHz pixel tick.
// -----------------------------------------------------------------------------

module vga_display_controller (
    input  logic       clk,
    input  logic       reset,
    input  logic [1:0] main_light,
    input  logic [1:0] cross_light,
    input  logic [1:0] main_ped,
    input  logic [1:0] cross_ped,
    input  logic       main_count_active,
    input  logic       cross_count_active,
    input  logic [3:0] main_count_digit,
    input  logic [3:0] cross_count_digit,
    output logic       hsync,
    output logic       vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);

    // Horizontal timing parameters for 640x480 VGA.
    localparam int H_DISPLAY = 640;
    localparam int H_FRONT   = 16;
    localparam int H_SYNC    = 96;
    localparam int H_BACK    = 48;
    localparam int H_TOTAL   = 800;

    // Vertical timing parameters for 640x480 VGA.
    localparam int V_DISPLAY = 480;
    localparam int V_FRONT   = 10;
    localparam int V_SYNC    = 2;
    localparam int V_BACK    = 33;
    localparam int V_TOTAL   = 525;

    // Clock divider and scan-position registers.
    logic [1:0] pix_div;
    logic       pix_tick;
    logic [9:0] pix_x, pix_y;
    logic       video_on;
    logic [5:0] frame_count;
    logic       blink_on;

    // Renderer outputs and final RGB selection signal.
    logic [11:0] scene_rgb;
    logic [11:0] text_rgb;
    logic        text_on;
    logic [11:0] rgb_next;

    // Generate a pixel enable every 4 input clock cycles: 100 MHz / 4 = 25 MHz.
    assign pix_tick = (pix_div == 2'd0);

    // Pixel-clock divider.
    // The design does not create a separate clock net; it uses pix_tick as an
    // enable so the whole design remains in the 100 MHz clock domain.
    always_ff @(posedge clk) begin
        if (reset) begin
            pix_div <= 2'd0;
        end else begin
            pix_div <= pix_div + 2'd1;
        end
    end

    // VGA scan counters.
    // pix_x advances across the full horizontal timing interval. At the end of
    // each line, pix_y advances. frame_count increments once per complete frame.
    always_ff @(posedge clk) begin
        if (reset) begin
            pix_x <= 10'd0;
            pix_y <= 10'd0;
            frame_count <= 6'd0;
        end else if (pix_tick) begin
            if (pix_x == H_TOTAL - 1) begin
                pix_x <= 10'd0;
                if (pix_y == V_TOTAL - 1) begin
                    pix_y <= 10'd0;
                    frame_count <= frame_count + 6'd1;
                end else begin
                    pix_y <= pix_y + 10'd1;
                end
            end else begin
                pix_x <= pix_x + 10'd1;
            end
        end
    end

    // Active-video flag and negative-polarity VGA sync pulses.
    assign video_on = (pix_x < H_DISPLAY) && (pix_y < V_DISPLAY);
    assign hsync = ~((pix_x >= H_DISPLAY + H_FRONT) && (pix_x < H_DISPLAY + H_FRONT + H_SYNC));
    assign vsync = ~((pix_y >= V_DISPLAY + V_FRONT) && (pix_y < V_DISPLAY + V_FRONT + V_SYNC));

    // About 2 Hz blink at 60 Hz refresh. Used only for countdown hand/digit visibility.
    assign blink_on = (frame_count < 6'd30);

    // Base intersection graphics: roads, sidewalks, signals, and icons.
    pixel_renderer m_pixel_renderer (
        .pix_x(pix_x),
        .pix_y(pix_y),
        .main_light(main_light),
        .cross_light(cross_light),
        .main_ped(main_ped),
        .cross_ped(cross_ped),
        .blink_on(blink_on),
        .rgb(scene_rgb)
    );

    // Countdown digit overlay. text_on controls whether this layer is visible.
    text_renderer m_text_renderer (
        .pix_x(pix_x),
        .pix_y(pix_y),
        .main_count_active(main_count_active),
        .cross_count_active(cross_count_active),
        .main_count_digit(main_count_digit),
        .cross_count_digit(cross_count_digit),
        .blink_on(blink_on),
        .text_on(text_on),
        .rgb(text_rgb)
    );

    // Final RGB mux.
    // Outside the active display area, output black. Inside the active display,
    // text pixels have priority over the base scene.
    always_comb begin
        if (!video_on) begin
            rgb_next = 12'h000;
        end else if (text_on) begin
            rgb_next = text_rgb;
        end else begin
            rgb_next = scene_rgb;
        end
    end

    // Registered VGA outputs.
    // RGB changes only on pix_tick so the color output stays aligned with the
    // generated 25 MHz pixel timing.
    always_ff @(posedge clk) begin
        if (reset) begin
            vgaRed   <= 4'h0;
            vgaGreen <= 4'h0;
            vgaBlue  <= 4'h0;
        end else if (pix_tick) begin
            vgaRed   <= rgb_next[11:8];
            vgaGreen <= rgb_next[7:4];
            vgaBlue  <= rgb_next[3:0];
        end
    end

endmodule


