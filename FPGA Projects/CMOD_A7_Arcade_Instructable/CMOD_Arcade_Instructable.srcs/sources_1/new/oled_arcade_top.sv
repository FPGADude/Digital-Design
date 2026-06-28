`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// CMOD A7 + SSD1306 OLED - Modular FPGA Arcade Top
//
// Buttons:
//   FPGA input -> button -> GND
//   XDC PULLUP true
//   Not pressed = 1
//   Pressed     = 0
//
// Controls:
//   UP/DOWN move menu cursor
//   A or START selects current item
//   SELECT returns to menu
//////////////////////////////////////////////////////////////////////////////////

module oled_arcade_top (
    input  logic clk_12mhz,
    input  logic rst_btn,

    input  logic btn_A,
    input  logic btn_B,
    input  logic btn_start,
    input  logic btn_select,
    input  logic btn_down,
    input  logic btn_up,
    input  logic btn_left,
    input  logic btn_right,

    output logic oled_scl,
    inout  wire  oled_sda,

    output logic led0,
    output logic buzzer
);

    logic reset;
    assign reset = ~rst_btn;

    logic a_pressed, b_pressed, start_pressed, select_pressed;
    logic up_pressed, down_pressed, left_pressed, right_pressed;

    button_debounce_active_low #(.CLK_HZ(12_000_000), .DEBOUNCE_MS(5)) db_a (
        .clk(clk_12mhz), .reset(reset), .btn_n(btn_A), .pressed(a_pressed)
    );

    button_debounce_active_low #(.CLK_HZ(12_000_000), .DEBOUNCE_MS(5)) db_b (
        .clk(clk_12mhz), .reset(reset), .btn_n(btn_B), .pressed(b_pressed)
    );

    button_debounce_active_low #(.CLK_HZ(12_000_000), .DEBOUNCE_MS(5)) db_start (
        .clk(clk_12mhz), .reset(reset), .btn_n(btn_start), .pressed(start_pressed)
    );

    button_debounce_active_low #(.CLK_HZ(12_000_000), .DEBOUNCE_MS(5)) db_select (
        .clk(clk_12mhz), .reset(reset), .btn_n(btn_select), .pressed(select_pressed)
    );

    button_debounce_active_low #(.CLK_HZ(12_000_000), .DEBOUNCE_MS(5)) db_up (
        .clk(clk_12mhz), .reset(reset), .btn_n(btn_up), .pressed(up_pressed)
    );

    button_debounce_active_low #(.CLK_HZ(12_000_000), .DEBOUNCE_MS(5)) db_down (
        .clk(clk_12mhz), .reset(reset), .btn_n(btn_down), .pressed(down_pressed)
    );

    button_debounce_active_low #(.CLK_HZ(12_000_000), .DEBOUNCE_MS(5)) db_left (
        .clk(clk_12mhz), .reset(reset), .btn_n(btn_left), .pressed(left_pressed)
    );

    button_debounce_active_low #(.CLK_HZ(12_000_000), .DEBOUNCE_MS(5)) db_right (
        .clk(clk_12mhz), .reset(reset), .btn_n(btn_right), .pressed(right_pressed)
    );

    logic a_pulse, start_pulse, select_pulse;
    logic up_pulse, down_pulse;

    edge_pulse ep_a      (.clk(clk_12mhz), .reset(reset), .level(a_pressed),      .pulse(a_pulse));
    edge_pulse ep_start  (.clk(clk_12mhz), .reset(reset), .level(start_pressed),  .pulse(start_pulse));
    edge_pulse ep_select (.clk(clk_12mhz), .reset(reset), .level(select_pressed), .pulse(select_pulse));
    edge_pulse ep_up     (.clk(clk_12mhz), .reset(reset), .level(up_pressed),     .pulse(up_pulse));
    edge_pulse ep_down   (.clk(clk_12mhz), .reset(reset), .level(down_pressed),   .pulse(down_pulse));

    logic [1:0] menu_index;
    logic selected_mode;

    menu_controller menu (
        .clk(clk_12mhz),
        .reset(reset),
        .up_pulse(up_pulse),
        .down_pulse(down_pulse),
        .select_pulse(a_pulse | start_pulse),
        .back_pulse(select_pulse),
        .menu_index(menu_index),
        .selected_mode(selected_mode)
    );

    logic frame_tick;
    logic [3:0] game_sfx_event;
    logic [3:0] ui_sfx_event;
    logic [3:0] sfx_event;

    always_comb begin
        ui_sfx_event = 4'd0;
        if (up_pulse || down_pulse) begin
            ui_sfx_event = 4'd1;   // menu cursor tick
        end else if (a_pulse || start_pulse || select_pulse) begin
            ui_sfx_event = 4'd2;   // select/back/start
        end
    end

    assign sfx_event = (ui_sfx_event != 4'd0) ? ui_sfx_event : game_sfx_event;

    audio_engine #(
        .CLK_HZ(12_000_000)
    ) audio (
        .clk(clk_12mhz),
        .reset(reset),
        .sfx_event(sfx_event),
        .buzzer(buzzer)
    );

    // This is the ONLY OLED driver in the system.
    // Do not instantiate ssd1306_menu_driver at the same time.
    ssd1306_arcade_driver #(
        .CLK_HZ(12_000_000),
        .I2C_HZ(100_000),
        .OLED_ADDR_WR(8'h78),
        .FRAME_WAIT_CLKS(600_000),
        .SNAKE_HZ(2)
    ) oled_arcade (
        .clk(clk_12mhz),
        .reset(reset),
        .menu_index(menu_index),
        .selected_mode(selected_mode),
        .btn_up(up_pressed),
        .btn_down(down_pressed),
        .btn_left(left_pressed),
        .btn_right(right_pressed),
        .btn_a(a_pressed),
        .btn_start(start_pressed),
        .oled_scl(oled_scl),
        .oled_sda(oled_sda),
        .frame_tick(frame_tick),
        .audio_event(game_sfx_event)
    );

    logic [23:0] led_counter;

    always_ff @(posedge clk_12mhz) begin
        if (reset)
            led_counter <= 24'd0;
        else if (frame_tick)
            led_counter <= led_counter + 1'b1;
    end

    assign led0 = reset ? 1'b0 : led_counter[0];

endmodule