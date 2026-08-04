`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: top_mmcm_scanner_demo
// Board : Digilent Basys 3
//
// Demonstration:
//   The Basys 3 onboard 100 MHz oscillator feeds a Vivado Clocking Wizard.
//   The wizard uses one MMCM to generate two managed clocks:
//
//       clk_out1 = 100 MHz
//       clk_out2 = 200 MHz
//
//   Two identical LED scanner modules use the same STEP_COUNT value. Because
//   one scanner receives 200 MHz and the other receives 100 MHz, the lower
//   scanner advances exactly twice as fast as the upper scanner.
//
// Controls:
//   btnC = active-high reset for the Clocking Wizard and both scanners.
//
// Required Clocking Wizard configuration:
//   Component name : clk_wiz_0
//   Primitive      : MMCM
//   Input clock    : 100.000 MHz
//   clk_out1       : 100.000 MHz
//   clk_out2       : 200.000 MHz
//   Reset          : active high
//   Locked output  : enabled
//////////////////////////////////////////////////////////////////////////////////

module top_mmcm_scanner_demo (
    input  wire        clk,
    input  wire        btnC,
    output wire [15:0] led
);

    wire clk_100mhz_managed;
    wire clk_200mhz_managed;
    wire mmcm_locked;

    // Both scanner circuits remain reset while the pushbutton is pressed or
    // while the MMCM output clocks have not yet stabilized.
    wire scanner_reset;
    assign scanner_reset = btnC | ~mmcm_locked;

    ////////////////////////////////////////////////////////////////////////////
    // Vivado Clocking Wizard IP
    //
    // The external board clock connects only to this block. The Clocking
    // Wizard owns the input clock buffer and creates both managed clocks.
    // This avoids two clock-buffer paths being inferred from the same pin.
    ////////////////////////////////////////////////////////////////////////////
    clk_wiz_0 clock_generator (
        .clk_out1 (clk_100mhz_managed),
        .clk_out2 (clk_200mhz_managed),
        .reset    (btnC),
        .locked   (mmcm_locked),
        .clk_in1  (clk)
    );

    ////////////////////////////////////////////////////////////////////////////
    // Upper eight LEDs: 100 MHz managed-clock scanner.
    ////////////////////////////////////////////////////////////////////////////
    led_scanner #(
        .STEP_COUNT(12_500_000)
    ) scanner_100mhz (
        .clk   (clk_100mhz_managed),
        .reset (scanner_reset),
        .leds  (led[15:8])
    );

    ////////////////////////////////////////////////////////////////////////////
    // Lower eight LEDs: 200 MHz managed-clock scanner.
    ////////////////////////////////////////////////////////////////////////////
    led_scanner #(
        .STEP_COUNT(12_500_000)
    ) scanner_200mhz (
        .clk   (clk_200mhz_managed),
        .reset (scanner_reset),
        .leds  (led[7:0])
    );

endmodule
