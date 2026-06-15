`timescale 1ns / 1ps
module vga_timing(
    input  wire clk,
    input  wire reset,
    output reg  hsync,
    output reg  vsync,
    output wire video_on,
    output reg  [9:0] pix_x,
    output reg  [9:0] pix_y
);

    // 640x480 @ 60 Hz timing
    // Horizontal:
    // visible area = 640
    // front porch  = 16
    // sync pulse   = 96
    // back porch   = 48
    // total        = 800
    localparam H_DISPLAY = 640;
    localparam H_FP      = 16;
    localparam H_SYNC    = 96;
    localparam H_BP      = 48;
    localparam H_TOTAL   = 800;

    // Vertical:
    // visible area = 480
    // front porch  = 10
    // sync pulse   = 2
    // back porch   = 33
    // total        = 525
    localparam V_DISPLAY = 480;
    localparam V_FP      = 10;
    localparam V_SYNC    = 2;
    localparam V_BP      = 33;
    localparam V_TOTAL   = 525;

    reg [9:0] h_count;
    reg [9:0] v_count;

    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;

                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end
            else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
            pix_x <= 10'd0;
            pix_y <= 10'd0;
        end
        else begin
            pix_x <= h_count;
            pix_y <= v_count;

            // VGA syncs are active low
            if ((h_count >= H_DISPLAY + H_FP) &&
                (h_count <  H_DISPLAY + H_FP + H_SYNC))
                hsync <= 1'b0;
            else
                hsync <= 1'b1;

            if ((v_count >= V_DISPLAY + V_FP) &&
                (v_count <  V_DISPLAY + V_FP + V_SYNC))
                vsync <= 1'b0;
            else
                vsync <= 1'b1;
        end
    end

endmodule