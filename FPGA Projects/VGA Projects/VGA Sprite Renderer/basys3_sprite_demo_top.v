`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// FPGA Discovery
// Basys 3 Sprite Renderer Demo
//
// Demonstrates:
//   - 640x480 VGA timing
//   - 32x32 RGB332 sprite ROM
//   - reusable sprite_renderer
//   - transparency
//   - frame-synchronized motion
//   - edge bouncing
//
// Controls:
//   SW[3:0]   speed
//   SW[4]     pause
//   SW[15:14] motion mode
//   BTNC      reset to center
//   LED[3:0]  mirrors speed selection
// -----------------------------------------------------------------------------
module basys3_sprite_demo_top (
    input  wire        clk,
    input  wire        btnC,
    input  wire [15:0] sw,
    output wire [15:0] led,

    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
    output wire        Hsync,
    output wire        Vsync
);

    // -------------------------------------------------------------------------
    // 100 MHz -> 25 MHz pixel clock by divide-by-4.
    // -------------------------------------------------------------------------
    reg [1:0] clk_div = 2'b00;

    always @(posedge clk)
        clk_div <= clk_div + 2'b01;

    wire pix_clk = clk_div[1];

    // Synchronize pushbutton into the pixel-clock domain.
    reg rst_ff1 = 1'b0;
    reg rst_ff2 = 1'b0;

    always @(posedge pix_clk) begin
        rst_ff1 <= btnC;
        rst_ff2 <= rst_ff1;
    end

    wire reset = rst_ff2;

    // -------------------------------------------------------------------------
    // VGA timing
    // -------------------------------------------------------------------------
    wire       video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       frame_tick;

    vga_640x480 u_vga (
        .pix_clk    (pix_clk),
        .reset      (reset),
        .hsync      (Hsync),
        .vsync      (Vsync),
        .video_on   (video_on),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .frame_tick (frame_tick)
    );

    // -------------------------------------------------------------------------
    // Frame-synchronized sprite motion
    // -------------------------------------------------------------------------
    wire [9:0] sprite_x;
    wire [8:0] sprite_y;

    sprite_motion u_motion (
        .pix_clk   (pix_clk),
        .reset     (reset),
        .frame_tick(frame_tick),
        .speed_sel (sw[3:0]),
        .pause     (sw[4]),
        .mode      (sw[15:14]),
        .sprite_x  (sprite_x),
        .sprite_y  (sprite_y)
    );

    // -------------------------------------------------------------------------
    // Sprite renderer
    // -------------------------------------------------------------------------
    wire       sprite_on;
    wire [7:0] sprite_rgb;

    sprite_renderer u_renderer (
        .pixel_x   (pixel_x),
        .pixel_y   (pixel_y),
        .sprite_x  (sprite_x),
        .sprite_y  (sprite_y),
        .sprite_on (sprite_on),
        .sprite_rgb(sprite_rgb)
    );

    // -------------------------------------------------------------------------
    // Simple background so transparency is obvious:
    // sky above y=400, green ground below y=400.
    // RGB332:
    //   sky    = 8'b001_100_11
    //   ground = 8'b001_110_00
    // -------------------------------------------------------------------------
    wire [7:0] bg_rgb =
        (pixel_y < 10'd400) ? 8'b001_100_11 :
                              8'b001_110_00;

    wire [7:0] final_rgb332 =
        !video_on ? 8'h00 :
        sprite_on ? sprite_rgb :
                    bg_rgb;

    // RGB332 -> Basys 3 RGB444.
    // Expand by repeating the MSB(s) into the extra DAC bit(s).
    assign vgaRed   = video_on ? {final_rgb332[7:5], final_rgb332[7]} : 4'h0;
    assign vgaGreen = video_on ? {final_rgb332[4:2], final_rgb332[4]} : 4'h0;
    assign vgaBlue  = video_on ? {final_rgb332[1:0], final_rgb332[1:0]} : 4'h0;

    // LEDs: mirror speed value, show pause and motion mode.
    assign led[3:0]   = sw[3:0];
    assign led[4]     = sw[4];
    assign led[13:5]  = 9'b0;
    assign led[15:14] = sw[15:14];

endmodule
