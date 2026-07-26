`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: top_pmod_hygro_vga
//
// Purpose:
//   Integrates HDC1080 acquisition, fixed-point conversion, VGA timing,
//   dashboard rendering, seven-segment output, and diagnostic LEDs.
//
// Data flow:
//   Pmod HYGRO -> controller -> converted measurements -> VGA and 7-segment
//
// Basys 3 Pmod HYGRO Environmental Monitor
//
// Hardware assignments:
//   JB: Pmod HYGRO
//   VGA: built-in Basys 3 VGA connector
//
// Controls:
//   BTNC: reset
//   SW0: seven-segment selection
//        0 = temperature in Fahrenheit
//        1 = relative humidity
//
// VGA always displays both temperature and humidity.
//////////////////////////////////////////////////////////////////////////////////

module top_pmod_hygro_vga (
    input  wire        clk,
    input  wire        btnC,
    input  wire        sw0,

    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire        dp,
    output wire [3:0]  an,

    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
    output wire        Hsync,
    output wire        Vsync,

    output wire        hyg_scl,
    inout  wire        hyg_sda
);

    // Raw HDC1080 measurement registers.
    wire [15:0] raw_temperature;
    wire [15:0] raw_humidity;

    // Fixed-point engineering values; 724 means 72.4.
    wire signed [15:0] temperature_c_tenths;
    wire signed [15:0] temperature_f_tenths;
    wire        [15:0] humidity_tenths;

    // Measurement status signals.
    wire data_valid;
    wire sensor_error;
    wire measurement_pulse;

    // Toggles once per completed sample for a visible activity LED.
    reg measurement_toggle;

    // Current VGA raster coordinates.
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       video_active;

    // SW0 selects the auxiliary seven-segment measurement.
    wire [15:0] selected_display_value =
        sw0 ? humidity_tenths :
        (temperature_f_tenths[15] ? 16'd0 :
                                         temperature_f_tenths[15:0]);

    always @(posedge clk) begin
        if (btnC)
            measurement_toggle <= 1'b0;
        else if (measurement_pulse)
            measurement_toggle <= ~measurement_toggle;
    end

    // Acquire and convert sensor data.
    (* keep_hierarchy = "yes" *)
    pmod_hygro_controller #(
        .CLOCK_FREQ_HZ(100_000_000)
    ) sensor_controller (
        .clk(clk),
        .reset(btnC),
        .hyg_scl(hyg_scl),
        .hyg_sda(hyg_sda),
        .raw_temperature(raw_temperature),
        .raw_humidity(raw_humidity),
        .temperature_c_tenths(temperature_c_tenths),
        .temperature_f_tenths(temperature_f_tenths),
        .humidity_tenths(humidity_tenths),
        .data_valid(data_valid),
        .sensor_error(sensor_error),
        .measurement_pulse(measurement_pulse)
    );

    // Generate VGA timing and coordinates.
    (* keep_hierarchy = "yes" *)
    vga_640x480 timing (
        .clk(clk),
        .reset(btnC),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_active(video_active),
        .hsync(Hsync),
        .vsync(Vsync)
    );

    // Produce RGB data for the current pixel.
    hygro_vga_renderer renderer (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_active(video_active),
        .temperature_c_tenths(temperature_c_tenths),
        .temperature_f_tenths(temperature_f_tenths),
        .humidity_tenths(humidity_tenths),
        .data_valid(data_valid),
        .sensor_error(sensor_error),
        .vga_red(vgaRed),
        .vga_green(vgaGreen),
        .vga_blue(vgaBlue)
    );

    // Drive the Basys 3 four-digit display.
    seven_segment_display display (
        .clk(clk),
        .reset(btnC),
        .value_tenths(selected_display_value),
        .blank(!data_valid),
        .seg(seg),
        .dp(dp),
        .an(an)
    );

    // Diagnostic LEDs show validity, errors, activity, and raw data.
    assign led[15] = data_valid;
    assign led[14] = sensor_error;
    assign led[13] = sw0;
    assign led[12] = ~sw0;
    assign led[11] = measurement_toggle;
    assign led[10] = data_valid & ~sensor_error;
    assign led[9]  = measurement_toggle;
    assign led[8]  = measurement_pulse;
    assign led[7:0] = sw0 ? raw_humidity[15:8]
                          : raw_temperature[15:8];

endmodule
