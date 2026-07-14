`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
//
//  Creator: David J. Marion
//  Date completed: 7.12.2026
//
// File: top_pmod_acl_vga.v
// Project: Pmod ACL VGA Display for Basys 3
//
// Top-level module that connects the Basys 3 clock/reset, Pmod ACL SPI controller, 
// VGA timing generator, display-preparation pipeline, VGA renderer, and debug LEDs.
//
// Notes:
// - This project reads the ADXL345 accelerometer on the Digilent Pmod ACL.
// - The design displays the three signed acceleration axes on a 640x480 VGA
//   screen as decimal values and center-referenced bar graphs.
// -----------------------------------------------------------------------------

// Top-level wrapper for the complete demo.
// The external ports match the Basys 3 board, Pmod ACL pins, VGA connector,
// and a small set of status LEDs.
module top_pmod_acl_vga(
    input  wire        clk,      // Basys 3 100 MHz
    input  wire        btnC,            // reset button

    // Pmod ACL SPI signals
    output wire        acl_cs,
    output wire        acl_sclk,
    output wire        acl_mosi,
    input  wire        acl_miso,

    // VGA output
    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
    output wire        Hsync,
    output wire        Vsync
);

    // Use the center pushbutton as a synchronous reset source for this demo.
    wire reset = btnC;

    // VGA timing outputs. video_on is high only inside the visible 640x480 area.
    wire        video_on;
    wire        p_tick;
    wire [9:0]  x;
    wire [9:0]  y;

    // Raw signed 16-bit acceleration values from the ADXL345 controller.
    // These are full-resolution sensor readings before display scaling.
    wire signed [15:0] acl_x_raw;
    wire signed [15:0] acl_y_raw;
    wire signed [15:0] acl_z_raw;
    wire        acl_data_valid;
    wire        acl_init_done;
    wire [2:0]  acl_state_dbg;

    // Internal 12-bit RGB bus: 4 bits red, 4 bits green, 4 bits blue.
    wire [11:0] rgb;

    // Generate pixel coordinates, sync pulses, and visible-area enable.
    vga_timing_640x480 u_vga_timing (
        .clk(clk),
        .reset(reset),
        .video_on(video_on),
        .p_tick(p_tick),
        .hsync(Hsync),
        .vsync(Vsync),
        .x(x),
        .y(y)
    );

    // Configure and continuously read the Pmod ACL over SPI.
    // The controller asserts acl_data_valid for one clock when a fresh X/Y/Z
    // sample has been captured.
    adxl345_controller u_acl (
        .clk(clk),
        .reset(reset),
        .spi_cs(acl_cs),
        .spi_sclk(acl_sclk),
        .spi_mosi(acl_mosi),
        .spi_miso(acl_miso),
        .x_data(acl_x_raw),
        .y_data(acl_y_raw),
        .z_data(acl_z_raw),
        .data_valid(acl_data_valid),
        .init_done(acl_init_done),
        .state_dbg(acl_state_dbg)
    );

    // ------------------------------------------------------------------------
    // Display-value preparation
    // ------------------------------------------------------------------------
    // The ADXL345 is configured for full-resolution operation, where its
    // nominal scale factor is approximately 256 raw counts per g. The display
    // therefore converts the filtered raw values into hundredths of a g:
    //
    //     g x 100 = raw x 100 / 256 = raw x 25 / 64
    //
    // A first-order low-pass filter is applied before the conversion. The
    // filter updates at the full 100 Hz sensor rate and removes much of the
    // small sample-to-sample jitter without changing the physical units.

    reg signed [16:0] x_filtered = 17'sd0;
    reg signed [16:0] y_filtered = 17'sd0;
    reg signed [16:0] z_filtered = 17'sd0;
    reg               filter_initialized = 1'b0;
    reg               prep_pending = 1'b0;
    reg               display_data_valid = 1'b0;

    // Precomputed values passed into the pixel renderer.
    reg        x_neg = 1'b0, y_neg = 1'b0, z_neg = 1'b0;
    reg [9:0]  x_len = 10'd0, y_len = 10'd0, z_len = 10'd0;
    reg [3:0]  x_d3 = 4'd0, x_d2 = 4'd0, x_d1 = 4'd0, x_d0 = 4'd0;
    reg [3:0]  y_d3 = 4'd0, y_d2 = 4'd0, y_d1 = 4'd0, y_d0 = 4'd0;
    reg [3:0]  z_d3 = 4'd0, z_d2 = 4'd0, z_d1 = 4'd0, z_d0 = 4'd0;

    function [16:0] abs17;
        input signed [16:0] v;
        begin
            abs17 = v[16] ? (~v + 17'd1) : v;
        end
    endfunction

    // Convert filtered raw magnitude to a bar length. At 256 counts per g,
    // 120 pixels per g is raw * 120 / 256 = raw * 15 / 32.
    function [9:0] make_bar_len;
        input [16:0] raw_mag;
        reg [21:0] scaled;
        begin
            scaled = raw_mag * 5'd15;
            scaled = scaled + 22'd16; // round before dividing by 32
            scaled = scaled >> 5;
            if (scaled > 22'd240)
                make_bar_len = 10'd240;
            else
                make_bar_len = scaled[9:0];
        end
    endfunction

    // Convert filtered raw magnitude into hundredths of a g. The result is
    // clamped to 9.99g so it always fits the +0.00g display format.
    function [9:0] raw_to_centi_g;
        input [16:0] raw_mag;
        reg [22:0] scaled;
        begin
            scaled = raw_mag * 5'd25;
            scaled = scaled + 23'd32; // round before dividing by 64
            scaled = scaled >> 6;
            if (scaled > 23'd999)
                raw_to_centi_g = 10'd999;
            else
                raw_to_centi_g = scaled[9:0];
        end
    endfunction

    // Shift-and-add-3 binary-to-BCD conversion for a 10-bit value (0-999).
    task bcd_3digit;
        input  [9:0] value;
        output [3:0] hundreds;
        output [3:0] tens;
        output [3:0] ones;
        integer i;
        reg [21:0] shift;
        begin
            shift = 22'd0;
            shift[9:0] = value;
            for (i = 0; i < 10; i = i + 1) begin
                if (shift[13:10] >= 5) shift[13:10] = shift[13:10] + 3;
                if (shift[17:14] >= 5) shift[17:14] = shift[17:14] + 3;
                if (shift[21:18] >= 5) shift[21:18] = shift[21:18] + 3;
                shift = shift << 1;
            end
            hundreds = shift[21:18];
            tens     = shift[17:14];
            ones     = shift[13:10];
        end
    endtask

    // Prepare sign, accurate g digits, and bar length for one filtered axis.
    // Digits are stored as d3.d2d1; d0 is retained only to keep the renderer
    // interface simple and is set to zero.
    task prep_axis;
        input signed [16:0] val;
        output              neg;
        output [9:0]        len;
        output [3:0]        d3;
        output [3:0]        d2;
        output [3:0]        d1;
        output [3:0]        d0;
        reg [16:0] mag;
        reg [9:0] centi_g;
        begin
            neg = val[16];
            mag = abs17(val);
            len = make_bar_len(mag);
            centi_g = raw_to_centi_g(mag);
            bcd_3digit(centi_g, d3, d2, d1);
            d0 = 4'd0;
        end
    endtask

    // Filter and display-preparation pipeline. The low-pass equation is:
    // filtered = filtered + (raw - filtered) / 4
    // This keeps the 100 Hz update rate while smoothing the VGA bars.
    always @(posedge clk) begin
        if (reset) begin
            x_filtered <= 17'sd0;
            y_filtered <= 17'sd0;
            z_filtered <= 17'sd0;
            filter_initialized <= 1'b0;
            prep_pending <= 1'b0;
            display_data_valid <= 1'b0;
            x_neg <= 1'b0; y_neg <= 1'b0; z_neg <= 1'b0;
            x_len <= 10'd0; y_len <= 10'd0; z_len <= 10'd0;
            x_d3 <= 4'd0; x_d2 <= 4'd0; x_d1 <= 4'd0; x_d0 <= 4'd0;
            y_d3 <= 4'd0; y_d2 <= 4'd0; y_d1 <= 4'd0; y_d0 <= 4'd0;
            z_d3 <= 4'd0; z_d2 <= 4'd0; z_d1 <= 4'd0; z_d0 <= 4'd0;
        end else begin
            prep_pending <= acl_data_valid;

            if (acl_data_valid) begin
                if (!filter_initialized) begin
                    x_filtered <= {{1{acl_x_raw[15]}}, acl_x_raw};
                    y_filtered <= {{1{acl_y_raw[15]}}, acl_y_raw};
                    z_filtered <= {{1{acl_z_raw[15]}}, acl_z_raw};
                    filter_initialized <= 1'b1;
                end else begin
                    x_filtered <= x_filtered +
                        (($signed({{1{acl_x_raw[15]}}, acl_x_raw}) - x_filtered) >>> 2);
                    y_filtered <= y_filtered +
                        (($signed({{1{acl_y_raw[15]}}, acl_y_raw}) - y_filtered) >>> 2);
                    z_filtered <= z_filtered +
                        (($signed({{1{acl_z_raw[15]}}, acl_z_raw}) - z_filtered) >>> 2);
                end
                display_data_valid <= 1'b1;
            end

            if (prep_pending) begin
                prep_axis(x_filtered, x_neg, x_len, x_d3, x_d2, x_d1, x_d0);
                prep_axis(y_filtered, y_neg, y_len, y_d3, y_d2, y_d1, y_d0);
                prep_axis(z_filtered, z_neg, z_len, z_d3, z_d2, z_d1, z_d0);
            end
        end
    end

    // Draw the final VGA scene using only precomputed signs, digits, bar
    // lengths, and status flags.
    acl_vga_renderer u_render (
        .video_on(video_on),
        .x(x),
        .y(y),
        .x_neg(x_neg),
        .y_neg(y_neg),
        .z_neg(z_neg),
        .x_len(x_len),
        .y_len(y_len),
        .z_len(z_len),
        .x_d3(x_d3), .x_d2(x_d2), .x_d1(x_d1), .x_d0(x_d0),
        .y_d3(y_d3), .y_d2(y_d2), .y_d1(y_d1), .y_d0(y_d0),
        .z_d3(z_d3), .z_d2(z_d2), .z_d1(z_d1), .z_d0(z_d0),
        .data_valid(display_data_valid),
        .init_done(acl_init_done),
        .rgb(rgb)
    );

    // Split the internal 12-bit RGB value into the Basys 3 VGA outputs.
    assign vgaRed   = rgb[11:8];
    assign vgaGreen = rgb[7:4];
    assign vgaBlue  = rgb[3:0];

endmodule