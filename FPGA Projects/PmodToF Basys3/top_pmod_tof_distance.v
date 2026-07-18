`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: top_pmod_tof_distance
//
// Basys 3 + Pmod ToF standalone distance/proximity project
//
// Pmod ToF connection: upper row of Pmod JB
//   Pin 1 IRQ -> JB1
//   Pin 2 SS  -> JB2
//   Pin 3 SCL -> JB3
//   Pin 4 SDA -> JB4
//
// Outputs:
//   Four-digit seven-segment display = distance in centimeters
//   Sixteen LEDs = proximity bar
//
// btnC resets and repeats the complete initialization sequence.
//
// During initialization, the seven-segment display shows stage codes.
// After the first valid reading, the display changes to decimal centimeters.
// If an error occurs, the display remains on a specific hexadecimal E-code.
//
// System data flow:
//   Pmod ToF
//      -> i2c_register_master
//      -> pmod_tof_distance_controller
//      -> distance_filter
//      -> sevenseg_decimal_or_status
//      -> proximity_led_bar
//
// The top module contains no sensor algorithm itself. It connects reusable
// modules and selects whether the display shows status information or a valid,
// filtered centimeter measurement.
//////////////////////////////////////////////////////////////////////////////////

module top_pmod_tof_distance(
    input  wire        clk,
    input  wire        btnC,

    input  wire        tof_irq_n,
    output wire        tof_ss,
    inout  wire        tof_scl,
    inout  wire        tof_sda,

    output wire [15:0] led,
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp
);

    // Command and response signals connecting the sensor controller to the
    // reusable register-oriented I2C master.
    wire       i2c_start;
    wire       i2c_rw;
    wire [6:0] i2c_device_addr;
    wire [7:0] i2c_register_addr;
    wire [7:0] i2c_write_data;
    wire [7:0] i2c_read_data;
    wire       i2c_busy;
    wire       i2c_done;
    wire       i2c_ack_error;

    // Sensor measurement, filtering, status, and presentation signals.
    wire [15:0] raw_distance;
    wire [13:0] distance_cm;
    wire        measurement_valid;
    wire        sample_strobe;
    wire [15:0] status_code;
    wire        controller_error;
    wire [15:0] proximity_leds;
    wire [13:0] filtered_distance_cm;
    wire        filtered_valid;

    // ---------------------------------------------------------------------
    // I2C bus engine
    // ---------------------------------------------------------------------
    // Executes the individual byte-level register reads and writes requested
    // by the Pmod ToF controller.
    i2c_register_master #(
        .CLK_FREQ_HZ(100_000_000),
        .I2C_FREQ_HZ(100_000)
    ) i2c_master_inst (
        .clk(clk),
        .reset(btnC),
        .start(i2c_start),
        .rw(i2c_rw),
        .device_addr(i2c_device_addr),
        .register_addr(i2c_register_addr),
        .write_data(i2c_write_data),
        .read_data(i2c_read_data),
        .busy(i2c_busy),
        .done(i2c_done),
        .ack_error(i2c_ack_error),
        .i2c_scl(tof_scl),
        .i2c_sda(tof_sda)
    );

    // ---------------------------------------------------------------------
    // Pmod ToF sensor controller
    // ---------------------------------------------------------------------
    // Performs initialization, EEPROM calibration loading, SS/IRQ measurement
    // handshaking, distance-register reads, and raw-to-centimeter conversion.
    pmod_tof_distance_controller controller_inst (
        .clk(clk),
        .reset(btnC),
        .irq_n(tof_irq_n),
        .ss(tof_ss),
        .i2c_start(i2c_start),
        .i2c_rw(i2c_rw),
        .i2c_device_addr(i2c_device_addr),
        .i2c_register_addr(i2c_register_addr),
        .i2c_write_data(i2c_write_data),
        .i2c_read_data(i2c_read_data),
        .i2c_busy(i2c_busy),
        .i2c_done(i2c_done),
        .i2c_ack_error(i2c_ack_error),
        .raw_distance(raw_distance),
        .distance_cm(distance_cm),
        .measurement_valid(measurement_valid),
        .sample_strobe(sample_strobe),
        .status_code(status_code),
        .error(controller_error)
    );

    // ---------------------------------------------------------------------
    // Measurement smoothing
    // ---------------------------------------------------------------------
    // Averages the latest eight centimeter samples before presentation.
    distance_filter filter_inst (
        .clk(clk),
        .reset(btnC),
        .sample_strobe(sample_strobe),
        .distance_in_cm(distance_cm),
        .distance_out_cm(filtered_distance_cm),
        .filtered_valid(filtered_valid)
    );

    // ---------------------------------------------------------------------
    // Seven-segment presentation
    // ---------------------------------------------------------------------
    // Initialization and error states appear as hexadecimal codes. Once a
    // filtered result is valid, the display changes to decimal centimeters.
    sevenseg_decimal_or_status display_inst (
        .clk(clk),
        .reset(btnC),
        .show_status(!filtered_valid || controller_error),
        .decimal_value(filtered_distance_cm),
        .status_value(status_code),
        .seg(seg),
        .an(an)
    );

    // ---------------------------------------------------------------------
    // LED proximity presentation
    // ---------------------------------------------------------------------
    // More LEDs illuminate as the measured object approaches the sensor.
    proximity_led_bar led_bar_inst (
        .distance_cm(filtered_distance_cm),
        .valid(filtered_valid && !controller_error),
        .led_bar(proximity_leds)
    );

    // Direct board-level output assignments. The decimal point remains off
    // because the project displays whole centimeters.
    assign led = proximity_leds;
    assign dp  = 1'b1;

endmodule
