`timescale 1ns / 1ps

// ============================================================================
// Module: top_pir_security_system
// Project: FPGA Motion Security System
// Target: Digilent Basys 3
// Language: SystemVerilog
//
// Hardware:
//   - Pmod PIR connected to JB
//   - Pmod AMP2 connected to JC and driving an 8-ohm speaker
//   - VGA monitor connected to the Basys 3 VGA port
//   - LED15 used as the single physical status indicator
//
// Controls:
//   BTNC - arm the security system
//   BTND - cancel arming, disarm, or acknowledge an alarm
//   BTNU - mute or unmute the active siren
//   BTNR - complete system reset and restart PIR warm-up
//
// Module hierarchy:
//   button_onepulse          - conditions each pushbutton
//   pir_input_conditioner    - synchronizes and qualifies PIR motion
//   security_fsm             - controls the system operating states
//   amp2_audio_engine        - creates beeps, chirp, and sweeping siren
//   heartbeat_led            - drives LED15 according to system state
//   vga_640x480              - generates VGA timing and pixel coordinates
//   security_vga_renderer    - draws the full security-console interface
// ============================================================================
module top_pir_security_system (
    input  logic       clk,
    input  logic       btnC,
    input  logic       btnD,
    input  logic       btnU,
    input  logic       btnR,
    input  logic       pir_motion_in,

    output logic       amp2_audio,
    output logic       amp2_gain,
    output logic       amp2_shutdown_n,
    output logic       led15,

    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    output logic       Hsync,
    output logic       Vsync
);

    // Debounced, one-clock button events.
    logic arm_pulse;
    logic reset_pulse;
    logic mute_pulse;
    logic system_reset_pulse;

    // Conditioned PIR level and rising-edge motion event.
    logic pir_level;
    logic motion_event;

    // State and status information shared by the major subsystems.
    logic [2:0]  system_state;
    logic [5:0]  warmup_seconds;
    logic [2:0]  arming_seconds;
    logic [15:0] intrusion_count;
    logic        alarm_muted;

    // VGA timing coordinates and final packed RGB color.
    logic        video_on;
    logic [9:0]  pixel_x;
    logic [9:0]  pixel_y;
    logic [11:0] rgb;

    // ------------------------------------------------------------------------
    // Pushbutton conditioning
    // ------------------------------------------------------------------------

    button_onepulse arm (
        .clk       (clk),
        .button_in (btnC),
        .pulse_out (arm_pulse)
    );

    button_onepulse reset (
        .clk       (clk),
        .button_in (btnD),
        .pulse_out (reset_pulse)
    );

    button_onepulse mute (
        .clk       (clk),
        .button_in (btnU),
        .pulse_out (mute_pulse)
    );

    // BTNR performs a complete system reset. Unlike BTND, which is used for
    // normal disarm/alarm acknowledgement, this reset returns the design to
    // the original PIR warm-up state and clears all recorded intrusions.
    button_onepulse system_reset (
        .clk       (clk),
        .button_in (btnR),
        .pulse_out (system_reset_pulse)
    );

    // ------------------------------------------------------------------------
    // PIR sensor input path
    // ------------------------------------------------------------------------

    pir_input_conditioner pir (
        .clk          (clk),
        .pir_async    (pir_motion_in),
        .pir_level    (pir_level),
        .motion_event (motion_event)
    );

    // ------------------------------------------------------------------------
    // Security-system control state machine
    // ------------------------------------------------------------------------

    security_fsm fsm (
        .clk             (clk),
        .arm_pulse       (arm_pulse),
        .reset_pulse        (reset_pulse),
        .system_reset_pulse (system_reset_pulse),
        .mute_pulse         (mute_pulse),
        .motion_event       (motion_event),
        .system_state    (system_state),
        .warmup_seconds  (warmup_seconds),
        .arming_seconds  (arming_seconds),
        .intrusion_count (intrusion_count),
        .alarm_muted     (alarm_muted)
    );

    // ------------------------------------------------------------------------
    // Pmod AMP2 audio generation and control pins
    // ------------------------------------------------------------------------

    amp2_audio_engine audio (
        .clk             (clk),
        .system_state    (system_state),
        .arming_seconds  (arming_seconds),
        .alarm_muted     (alarm_muted),
        .audio_pwm       (amp2_audio)
    );

    // Lower 6 dB gain setting and amplifier enabled.
    assign amp2_gain       = 1'b1;
    assign amp2_shutdown_n = 1'b1;

    // LED15 provides the only physical board-status indication.
    heartbeat_led heartbeat (
        .clk          (clk),
        .system_state (system_state),
        .heartbeat    (led15)
    );

    // ------------------------------------------------------------------------
    // VGA timing and rendering
    // ------------------------------------------------------------------------

    vga_640x480 vga (
        .clk      (clk),
        .hsync    (Hsync),
        .vsync    (Vsync),
        .video_on (video_on),
        .pixel_x  (pixel_x),
        .pixel_y  (pixel_y)
    );

    security_vga_renderer renderer (
        .clk             (clk),
        .pixel_x         (pixel_x),
        .pixel_y         (pixel_y),
        .video_on        (video_on),
        .system_state    (system_state),
        .pir_level       (pir_level),
        .warmup_seconds  (warmup_seconds),
        .arming_seconds  (arming_seconds),
        .intrusion_count (intrusion_count),
        .alarm_muted     (alarm_muted),
        .rgb             (rgb)
    );

    // Split the packed 12-bit color into the Basys 3 VGA buses.
    assign vgaRed   = rgb[11:8];
    assign vgaGreen = rgb[7:4];
    assign vgaBlue  = rgb[3:0];

endmodule
