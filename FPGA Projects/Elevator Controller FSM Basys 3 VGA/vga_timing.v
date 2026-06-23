// ================================================================
// vga_timing.v
// ================================================================
// Creator : David J. Marion
// Date    : 6.20.2026
// Project : Basys 3 FPGA Elevator Controller
// Purpose : Generates 640x480 VGA timing, sync pulses, and pixel 
//           coordinates.
//
// Notes   : Uses a 100 MHz board clock and a simple divide-by-4 
//           tick for an approximate 25 MHz pixel rate.
//
// Board   : Digilent Basys 3, 100 MHz system clock
// Language: Verilog HDL
// ================================================================

module vga_timing(
    input  wire clk,
    output wire hsync,
    output wire vsync,
    output wire video_on,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y
);

    // 640x480 @ 60 Hz VGA nominally uses a 25.175 MHz pixel clock.
    // For this classroom/demo project, the 100 MHz Basys 3 clock is divided
    // by 4 to create a 25 MHz pixel enable. Most VGA monitors accept this.
    reg [1:0] pix_div = 0;
    wire pix_tick = (pix_div == 2'b00);

    always @(posedge clk)
        pix_div <= pix_div + 1;

    // Horizontal timing values: display, front porch, sync, back porch, total.
    localparam HD = 640;
    localparam HF = 16;
    localparam HS = 96;
    localparam HB = 48;
    localparam HT = 800;

    // Vertical timing values: display, front porch, sync, back porch, total.
    localparam VD = 480;
    localparam VF = 10;
    localparam VS = 2;
    localparam VB = 33;
    localparam VT = 525;

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    // Pixel counters advance only on pix_tick. h_count tracks the current
    // column in the full VGA frame; v_count tracks the current row.
    always @(posedge clk) begin
        if (pix_tick) begin
            if (h_count == HT-1) begin
                h_count <= 0;
                if (v_count == VT-1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // video_on is high only during the visible 640x480 region.
    // hsync/vsync are active-low for standard VGA timing.
    assign video_on = (h_count < HD) && (v_count < VD);
    assign hsync = ~((h_count >= HD + HF) && (h_count < HD + HF + HS));
    assign vsync = ~((v_count >= VD + VF) && (v_count < VD + VF + VS));
    assign pixel_x = h_count;
    assign pixel_y = v_count;

endmodule


