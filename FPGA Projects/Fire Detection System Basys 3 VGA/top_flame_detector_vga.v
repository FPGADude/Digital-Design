`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: top_flame_detector_vga
//
// Purpose:
//   Top-level integration for the Basys 3 flame detection demonstration.
//   It connects the sensor input, validation filter, alarm controller, button
//   debouncer, seven-segment display, VGA timing generator, VGA renderer, and
//   diagnostic LEDs.
//
// User controls:
//   sw[15] - synchronous system reset and event-count clear
//   btnC   - acknowledge a latched alarm after the flame is gone
//
// LED map:
//   led[0]  - synchronized raw sensor input
//   led[1]  - validated flame detection
//   led[14] - latched alarm
//   led[15] - heartbeat generated from the 100 MHz clock
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
// Basys 3 Flame Detection System - VGA Phase
//////////////////////////////////////////////////////////////////////////////////

module top_flame_detector_vga (
    input  wire        clk,             // 100MHz
    input  wire        flame_d0,        // JC1
    input  wire        clear_alarm,     // btnC
    input  wire        reset,           // sw[15]
    output wire        flame_raw_sync,  // LED[0]
    output wire        flame_detected,  // LED[1]
    output wire        alarm_active,    // LED[14
    output wire        heartbeat,       // LED[15]
    output wire        buzzer,          // JA1
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp,
    output wire        Hsync,
    output wire        Vsync,
    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue
);

    // Inter-module status and control signals.
    wire acknowledge_pulse;
    wire [15:0] detection_count;

    // VGA timing coordinates and active-video qualifier.
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire video_on;
    wire pixel_tick;

    // Visible clock-alive indicator; bit 26 changes slowly enough to see.
    reg [26:0] heartbeat_counter;

    // Synchronize the sensor and reject pulses shorter than 50 ms.
    flame_input_filter #(
        .VERIFY_CYCLES(5_000_000)
    ) input_filter (
        .clk(clk),
        .reset(reset),
        .flame_d0(flame_d0),
        .flame_detected(flame_detected),
        .flame_raw_sync(flame_raw_sync)
    );

    // Convert BTNC into one clean acknowledge pulse per press.
    button_debouncer acknowledge_button (
        .clk(clk),
        .reset(reset),
        .button_in(clear_alarm),
        .button_pulse(acknowledge_pulse)
    );

    // Latch alarms and count separate validated flame events.
    flame_alarm_controller alarm_controller (
        .clk(clk),
        .reset(reset),
        .acknowledge(acknowledge_pulse),
        .flame_detected(flame_detected),
        .alarm_active(alarm_active),
        .detection_count(detection_count)
    );

    // Show the 16-bit event count on the four-digit display.
    seven_segment_hex display_driver (
        .clk(clk),
        .reset(reset),
        .value(detection_count),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

    // Generate VGA scan coordinates and synchronization signals.
    vga_timing_640x480 timing (
        .clk(clk),
        .reset(reset),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .hsync(Hsync),
        .vsync(Vsync),
        .video_on(video_on),
        .pixel_tick(pixel_tick)
    );

    // Convert system status and scan coordinates into RGB pixel values.
    flame_vga_renderer renderer (
        .clk(clk),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .flame_raw_sync(flame_raw_sync),
        .flame_detected(flame_detected),
        .alarm_active(alarm_active),
        .detection_count(detection_count),
        .vga_r(vgaRed),
        .vga_g(vgaGreen),
        .vga_b(vgaBlue),
        .alarm_flash(buzzer)
    );

    // Free-running heartbeat counter. Reset also restarts the blink phase.
    always @(posedge clk) begin
        if (reset)
            heartbeat_counter <= 27'd0;
        else
            heartbeat_counter <= heartbeat_counter + 1'b1;
    end

    // Board-level diagnostic LED assignments.
    assign heartbeat = heartbeat_counter[26];

endmodule

