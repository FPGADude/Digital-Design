// ============================================================================
//
// Created by David J. Marion
// Completed on July 6, 2026
//
// top_vending_machine.v
// ----------------------------------------------------------------------------
// Top-level module for the Basys 3 VGA Vending Machine project.
//
// Hardware controls:
//   btnL  -> select CHIPS
//   btnC  -> select SODA
//   btnR  -> select CANDY
//   btnU  -> insert the coin selected by sw[3:0]
//   btnD  -> cancel / refund current credit
//   sw[0] -> nickel
//   sw[1] -> dime
//   sw[2] -> quarter
//   sw[3] -> dollar
//   reset -> reset system and restock products
//
// Outputs:
//   VGA monitor shows the vending machine UI and product drop animation.
//   Seven-segment display shows the current credit amount only.
//
// Design note:
//   The FSM/button logic runs from the 100 MHz Basys 3 clock.  The VGA timing
//   and renderer run from a divided 25 MHz pixel clock so the graphics logic
//   has a full 40 ns per pixel.
// ============================================================================
`timescale 1ns / 1ps

module top_vending_machine(
    input  wire       clk,
    input  wire       reset,
    input  wire       btnU,
    input  wire       btnD,
    input  wire       btnL,
    input  wire       btnR,
    input  wire       btnC,
    input  wire [3:0] sw,
    output wire       Hsync,
    output wire       Vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire [6:0] seg,
    output wire       dp,
    output wire [3:0] an
);

    // VGA timing signals produced by vga_640x480 and consumed by the renderer.
    // x/y are the current pixel coordinates. video_on is true only inside the
    // visible 640x480 area. frame_tick is one pixel-clock pulse per frame.
    wire video_on;
    wire [9:0] x, y;
    wire frame_tick;

    // --------------------------------------------------------------------
    // 25 MHz VGA pixel clock
    // --------------------------------------------------------------------
    // The Basys 3 board clock is 100 MHz. VGA 640x480 uses a 25 MHz pixel
    // clock, so this divider creates a 25 MHz clock for the VGA timing and
    // renderer. Running the renderer at 25 MHz avoids the timing problem that
    // happened when the large text/graphics logic had to feed an RGB register
    // at 100 MHz.
    reg [1:0] pix_div = 2'b00;
    always @(posedge clk) begin
        if (reset)
            pix_div <= 2'b00;
        else
            pix_div <= pix_div + 2'b01;
    end

    wire clk25_raw = pix_div[1];
    wire clk25;
    BUFG vga_clk_buf (.I(clk25_raw), .O(clk25));

    vga_640x480 vga_inst(
        .clk(clk25),
        .reset(reset),
        .hsync(Hsync),
        .vsync(Vsync),
        .video_on(video_on),
        .x(x),
        .y(y),
        .frame_tick(frame_tick)
    );

    // Debounced button outputs.
    // clean_* is the stable button level. p* is a one-clock pulse used by the FSM.
    wire pU, pD, pL, pR, pC;
    wire clean_u, clean_d, clean_l, clean_r, clean_c;

    debounce_onepulse db_u(.clk(clk), .reset(reset), .noisy(btnU), .clean(clean_u), .pulse(pU));
    debounce_onepulse db_d(.clk(clk), .reset(reset), .noisy(btnD), .clean(clean_d), .pulse(pD));
    debounce_onepulse db_l(.clk(clk), .reset(reset), .noisy(btnL), .clean(clean_l), .pulse(pL));
    debounce_onepulse db_r(.clk(clk), .reset(reset), .noisy(btnR), .clean(clean_r), .pulse(pR));
    debounce_onepulse db_c(.clk(clk), .reset(reset), .noisy(btnC), .clean(clean_c), .pulse(pC));

    wire [8:0] coin_value_cents;
    wire coin_valid;

    // Convert the current switch pattern into a coin value.
    // The FSM only inserts the coin when BTN-U creates pU.
    coin_input coin_inst(
        .sw(sw),
        .coin_value_cents(coin_value_cents),
        .coin_valid(coin_valid)
    );

    wire [2:0] state;
    wire [1:0] selected_product;
    wire [8:0] credit_cents;
    wire [8:0] price_cents;
    wire [8:0] change_cents;
    wire vend_pulse;
    wire invalid_coin_flash;
    wire [3:0] chips_count, soda_count, candy_count;

    // 60 Hz system-clock tick used only for FSM display timing.
    // This avoids using the VGA frame_tick across clock domains.
    reg [20:0] tick_count = 21'd0;
    reg tick_60hz = 1'b0;
    always @(posedge clk) begin
        if (reset) begin
            tick_count <= 21'd0;
            tick_60hz <= 1'b0;
        end else begin
            if (tick_count == 21'd1_666_666) begin
                tick_count <= 21'd0;
                tick_60hz <= 1'b1;
            end else begin
                tick_count <= tick_count + 21'd1;
                tick_60hz <= 1'b0;
            end
        end
    end

    // Main control system.
    // This FSM owns the selected product, credit, price, change, inventory,
    // and high-level state that the VGA renderer displays.
    vending_fsm fsm_inst(
        .clk(clk),
        .reset(reset),
        .tick_60hz(tick_60hz),
        .select_chips(pL),
        .select_soda(pC),
        .select_candy(pR),
        .insert_coin(pU),
        .cancel(pD),
        .coin_value_cents(coin_value_cents),
        .coin_valid(coin_valid),
        .state(state),
        .selected_product(selected_product),
        .credit_cents(credit_cents),
        .price_cents(price_cents),
        .change_cents(change_cents),
        .vend_pulse(vend_pulse),
        .invalid_coin_flash(invalid_coin_flash),
        .chips_count(chips_count),
        .soda_count(soda_count),
        .candy_count(candy_count)
    );

    wire [11:0] rgb;

    // Draw the VGA user interface.
    // This is clocked by clk25, not clk, so the large graphics/text logic only
    // needs to meet 25 MHz timing.
    vending_renderer render_inst(
        .clk(clk25),
        .video_on(video_on),
        .x(x),
        .y(y),
        .state(state),
        .selected_product(selected_product),
        .credit_cents(credit_cents),
        .price_cents(price_cents),
        .change_cents(change_cents),
        .invalid_coin_flash(invalid_coin_flash),
        .coin_sw(sw),
        .chips_count(chips_count),
        .soda_count(soda_count),
        .candy_count(candy_count),
        .rgb(rgb)
    );

    assign vgaRed   = rgb[11:8];
    assign vgaGreen = rgb[7:4];
    assign vgaBlue  = rgb[3:0];

    // Seven-seg mirrors the current credit, giving a second way to verify money input.
    sevenseg_money sevenseg_inst(
        .clk(clk),
        .reset(reset),
        .cents(credit_cents),
        .seg(seg),
        .dp(dp),
        .an(an)
    );
endmodule
