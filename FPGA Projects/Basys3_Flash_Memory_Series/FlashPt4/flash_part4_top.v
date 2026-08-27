`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - FPGA Flash From the Ground Up
// Part 4 Top Level
//
// Data path:
//
//   MX25L3273E Flash
//          |
//          v
//   flash_sprite_loader
//          |
//          v
//      Sprite BRAM
//          |
//          v
//    sprite_renderer
//          |
//          v
//         VGA
//
// The flash loader reads the 32x32 RGB332 sprite from external SPI flash
// once at startup. The sprite is stored in block RAM so the VGA renderer can
// access pixel data quickly and continuously.
// ============================================================================

module flash_part4_top (
    input  wire       clk,
    input  wire       btnC,

    output wire       qspi_cs_n,
    output wire       qspi_mosi,
    input  wire       qspi_miso,

    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire       Hsync,
    output wire       Vsync,

    output wire       led_done,
    output wire       led_pass
);

    // ========================================================================
    // FLASH LOADER CONNECTIONS
    //
    // The loader writes one byte at a time into sprite RAM.
    // ========================================================================

    wire       sprite_we;
    wire [9:0] sprite_waddr;
    wire [7:0] sprite_wdata;

    wire       sprite_loaded;
    wire       sprite_pass;

    flash_sprite_loader u_loader (
        .clk          (clk),
        .btnC         (btnC),

        .qspi_cs_n    (qspi_cs_n),
        .qspi_mosi    (qspi_mosi),
        .qspi_miso    (qspi_miso),

        .sprite_we    (sprite_we),
        .sprite_waddr (sprite_waddr),
        .sprite_wdata (sprite_wdata),

        .done         (sprite_loaded),
        .pass         (sprite_pass)
    );

    // LED0 indicates that the 1024-byte load is complete.
    // LED15 indicates that the received sprite checksum is correct.
    assign led_done = sprite_loaded;
    assign led_pass = sprite_pass;


    // ========================================================================
    // SPRITE BLOCK RAM
    //
    // 32 x 32 pixels = 1024 pixels
    // RGB332          = 1 byte per pixel
    //
    // Total storage   = 1024 x 8 = 8192 bits
    //
    // The synthesis attribute encourages Vivado to implement this memory
    // using FPGA block RAM rather than distributed LUT RAM.
    // ========================================================================

    (* ram_style = "block" *)
    reg [7:0] sprite_mem [0:1023];

    wire [9:0] sprite_raddr;
    reg  [7:0] sprite_rdata = 8'h00;

    // One write port is used by the flash loader.
    // One synchronous read port is used by the VGA renderer.
    always @(posedge clk) begin

        if (sprite_we) begin
            sprite_mem[sprite_waddr] <= sprite_wdata;
        end

        sprite_rdata <= sprite_mem[sprite_raddr];

    end


    // ========================================================================
    // VGA TIMING GENERATOR
    //
    // Generates 640x480 timing information and a 25 MHz pixel enable from
    // the Basys 3 100 MHz system clock.
    // ========================================================================

    wire       pixel_tick;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       video_active;
    wire       hsync_raw;
    wire       vsync_raw;

    vga_640x480 u_vga (
        .clk          (clk),

        .pixel_tick   (pixel_tick),
        .pixel_x      (pixel_x),
        .pixel_y      (pixel_y),
        .video_active (video_active),

        .hsync        (hsync_raw),
        .vsync        (vsync_raw)
    );


    // ========================================================================
    // SPRITE RENDERER
    //
    // Converts the current VGA screen coordinate into a sprite RAM address,
    // reads the RGB332 pixel, expands it to RGB444, and drives the VGA output.
    // ========================================================================

    sprite_renderer u_renderer (
        .clk           (clk),
        .pixel_tick    (pixel_tick),

        .pixel_x       (pixel_x),
        .pixel_y       (pixel_y),
        .video_active  (video_active),

        .hsync_in      (hsync_raw),
        .vsync_in      (vsync_raw),

        .sprite_loaded (sprite_loaded),

        .sprite_addr   (sprite_raddr),
        .sprite_data   (sprite_rdata),

        .vgaRed        (vgaRed),
        .vgaGreen      (vgaGreen),
        .vgaBlue       (vgaBlue),

        .Hsync         (Hsync),
        .Vsync         (Vsync)
    );

endmodule
