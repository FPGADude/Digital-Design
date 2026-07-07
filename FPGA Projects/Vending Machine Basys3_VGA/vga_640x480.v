// ============================================================================
// vga_640x480.v
// ----------------------------------------------------------------------------
// Standard 640x480 VGA timing generator.
//
// Input clock: 25 MHz pixel clock
// Output: hsync, vsync, video_on, current pixel x/y, and frame_tick.
//
// The Basys 3 VGA connector uses separate 4-bit red, green, and blue outputs.
// This module does not create color; it only creates the timing and pixel
// coordinates used by vending_renderer.v.
// ============================================================================
`timescale 1ns / 1ps

module vga_640x480(
    input  wire       clk,      // 25 MHz VGA pixel clock
    input  wire       reset,
    output reg        hsync,
    output reg        vsync,
    output wire       video_on,
    output wire [9:0] x,
    output wire [9:0] y,
    output wire       frame_tick
);

    // 640x480 @ ~60 Hz using a true 25 MHz pixel clock.
    // V8 intentionally moves the VGA timing and renderer into the 25 MHz
    // pixel-clock domain. This gives the graphics logic 40 ns per pixel,
    // which is much easier to meet than forcing the large renderer to close
    // timing at the 100 MHz Basys 3 system clock.

    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    reg [9:0] h_count;
    reg [9:0] v_count;

    always @(posedge clk) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            hsync <= ~((h_count >= H_DISPLAY + H_FRONT) &&
                       (h_count <  H_DISPLAY + H_FRONT + H_SYNC));
            vsync <= ~((v_count >= V_DISPLAY + V_FRONT) &&
                       (v_count <  V_DISPLAY + V_FRONT + V_SYNC));
        end
    end

    assign video_on   = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
    assign x          = h_count;
    assign y          = v_count;
    assign frame_tick = (h_count == 10'd0) && (v_count == 10'd0);

endmodule
