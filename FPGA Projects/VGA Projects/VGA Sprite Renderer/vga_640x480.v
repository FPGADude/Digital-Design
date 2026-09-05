`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// VGA timing generator for 640x480.
// Uses a 25 MHz pixel clock, which is widely accepted by VGA monitors for
// 640x480 operation (nominal VGA pixel clock is 25.175 MHz).
//
// Outputs:
//   pixel_x, pixel_y : current active-area coordinate
//   video_on         : 1 while pixel_x/pixel_y are in the visible 640x480 area
//   hsync, vsync     : active-low VGA sync pulses
//   frame_tick       : one-pixel-clock pulse at the start of vertical blanking
// -----------------------------------------------------------------------------
module vga_640x480 (
    input  wire       pix_clk,
    input  wire       reset,
    output wire       hsync,
    output wire       vsync,
    output wire       video_on,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y,
    output wire       frame_tick
);

    // 640x480 @ ~60 Hz timing using a 25 MHz pixel clock.
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 800

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 525

    reg [9:0] h_count = 10'd0;
    reg [9:0] v_count = 10'd0;

    always @(posedge pix_clk) begin
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

    assign video_on = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    assign hsync = ~((h_count >= H_VISIBLE + H_FRONT) &&
                     (h_count <  H_VISIBLE + H_FRONT + H_SYNC));

    assign vsync = ~((v_count >= V_VISIBLE + V_FRONT) &&
                     (v_count <  V_VISIBLE + V_FRONT + V_SYNC));

    assign pixel_x = h_count;
    assign pixel_y = v_count;

    // Pulse once at the first pixel of vertical blanking.
    // Sprite positions are updated only here so an entire frame uses one
    // consistent position.
    assign frame_tick = (h_count == 10'd0) && (v_count == V_VISIBLE);

endmodule
