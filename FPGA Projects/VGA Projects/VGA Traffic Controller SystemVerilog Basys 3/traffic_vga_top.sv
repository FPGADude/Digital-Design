`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Module: traffic_vga_top
// -----------------------------------------------------------------------------
// Purpose:
//   Top-level module for the VGA traffic controller demonstration.
//
//   This module connects the three major blocks shown in the project block
//   diagram:
//
//       tick_gen_1s  ->  traffic_light_fsm  ->  vga_display_controller
//
//   The timing values are parameters at the top level so they can be changed in
//   one place and passed directly into the FSM.
//
// Basys 3 Interface:
//   - clk_100MHz is the board clock.
//   - reset is an external reset input.
//   - Hsync, Vsync, and RGB outputs connect to the VGA port.
// -----------------------------------------------------------------------------

module traffic_vga_top #(
    parameter int CLK_FREQ_HZ       = 100_000_000,
    parameter int MAIN_WALK_SEC     = 10,
    parameter int MAIN_COUNT_SEC    = 5,
    parameter int MAIN_STEADY_SEC   = 5,
    parameter int MAIN_YELLOW_SEC   = 3,
    parameter int ALL_RED_1_SEC     = 2,
    parameter int CROSS_WALK_SEC    = 10,
    parameter int CROSS_COUNT_SEC   = 5,
    parameter int CROSS_STEADY_SEC  = 5,
    parameter int CROSS_YELLOW_SEC  = 3,
    parameter int ALL_RED_2_SEC     = 2
)(
    input  logic       clk,
    input  logic       reset,
    output logic       Hsync,
    output logic       Vsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue
);

    // One-clock-cycle enable pulse generated once per second.
    logic tick_1s;

    // FSM outputs that describe the current traffic and pedestrian state.
    logic [1:0] main_light;
    logic [1:0] cross_light;
    logic [1:0] main_ped;
    logic [1:0] cross_ped;
    logic       main_count_active;
    logic       cross_count_active;
    logic [3:0] main_count_digit;
    logic [3:0] cross_count_digit;

    // Convert the 100 MHz board clock into a 1-second tick enable.
    tick_gen_1s #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ)
    ) m_tick_gen_1s (
        .clk(clk),
        .reset(reset),
        .tick_1s(tick_1s)
    );

    // Main traffic controller FSM. All timing parameters are passed in here.
    traffic_light_fsm #(
        .MAIN_WALK_SEC(MAIN_WALK_SEC),
        .MAIN_COUNT_SEC(MAIN_COUNT_SEC),
        .MAIN_STEADY_SEC(MAIN_STEADY_SEC),
        .MAIN_YELLOW_SEC(MAIN_YELLOW_SEC),
        .ALL_RED_1_SEC(ALL_RED_1_SEC),
        .CROSS_WALK_SEC(CROSS_WALK_SEC),
        .CROSS_COUNT_SEC(CROSS_COUNT_SEC),
        .CROSS_STEADY_SEC(CROSS_STEADY_SEC),
        .CROSS_YELLOW_SEC(CROSS_YELLOW_SEC),
        .ALL_RED_2_SEC(ALL_RED_2_SEC)
    ) m_traffic_light_fsm (
        .clk(clk),
        .reset(reset),
        .tick_1s(tick_1s),
        .main_light(main_light),
        .cross_light(cross_light),
        .main_ped(main_ped),
        .cross_ped(cross_ped),
        .main_count_active(main_count_active),
        .cross_count_active(cross_count_active),
        .main_count_digit(main_count_digit),
        .cross_count_digit(cross_count_digit)
    );

    // VGA timing and rendering block. It turns FSM states into pixels.
    vga_display_controller m_vga_display_controller (
        .clk(clk),
        .reset(reset),
        .main_light(main_light),
        .cross_light(cross_light),
        .main_ped(main_ped),
        .cross_ped(cross_ped),
        .main_count_active(main_count_active),
        .cross_count_active(cross_count_active),
        .main_count_digit(main_count_digit),
        .cross_count_digit(cross_count_digit),
        .hsync(Hsync),
        .vsync(Vsync),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)
    );

endmodule

