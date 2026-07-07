// ============================================================================
// vending_renderer.v
// ----------------------------------------------------------------------------
// VGA graphics renderer for the vending machine screen.
//
// The renderer receives the current VGA pixel coordinate from vga_640x480.v and
// decides what 12-bit RGB color that pixel should be.  It draws:
//   * vending machine cabinet
//   * three product rows
//   * selected-product highlight
//   * status panel with credit, price, change, coin, and state
//   * inventory counts
//   * bottom instruction panel
//   * collection tray
//   * simple falling product animation
//
// The final RGB value is registered on the 25 MHz pixel clock.  Registering the
// output prevents visible combinational glitches from reaching the VGA pins.
// ============================================================================
`timescale 1ns / 1ps

module vending_renderer(
    input  wire       clk,
    input  wire       video_on,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [2:0] state,
    input  wire [1:0] selected_product,
    input  wire [8:0] credit_cents,
    input  wire [8:0] price_cents,
    input  wire [8:0] change_cents,
    input  wire       invalid_coin_flash,
    input  wire [3:0] coin_sw,
    input  wire [3:0] chips_count,
    input  wire [3:0] soda_count,
    input  wire [3:0] candy_count,
    output reg  [11:0] rgb
);

    // Final registered VGA color. This module is clocked by the 25 MHz
    // VGA pixel clock from the top module.
    reg [11:0] rgb_next;

    localparam ST_SELECT   = 3'd0;
    localparam ST_INSERT   = 3'd1;
    localparam ST_DISPENSE = 3'd2;
    localparam ST_CHANGE   = 3'd3;
    localparam ST_THANKS   = 3'd4;
    localparam ST_SOLDOUT  = 3'd5;
    localparam ST_REFUND   = 3'd6;

    localparam PROD_CHIPS = 2'd0;
    localparam PROD_SODA  = 2'd1;
    localparam PROD_CANDY = 2'd2;

    // 12-bit RGB color constants: {red[3:0], green[3:0], blue[3:0]}.
    // These are intentionally simple, bright colors that show up well on VGA.
    localparam C_BLACK  = 12'h000;
    localparam C_WHITE  = 12'hFFF;
    localparam C_GRAY   = 12'h666;
    localparam C_DGRAY  = 12'h222;
    localparam C_BLUE   = 12'h06A;
    localparam C_PANEL  = 12'h123;
    localparam C_YELLOW = 12'hFF0;
    localparam C_GREEN  = 12'h0F4;
    localparam C_RED    = 12'hF22;
    localparam C_ORANGE = 12'hFA0;
    localparam C_CYAN   = 12'h0FF;

    // Product and tray geometry. All three product graphics are centered
    // over the same tray, so the dispense animation falls straight down.
    localparam [9:0] PROD_X0 = 10'd216;
    localparam [9:0] PROD_X1 = 10'd256;
    localparam [9:0] PROD_CX0 = 10'd220;
    localparam [9:0] PROD_CX1 = 10'd252;
    localparam [9:0] CHIPS_Y0 = 10'd100;
    localparam [9:0] SODA_Y0  = 10'd170;
    localparam [9:0] CANDY_Y0 = 10'd240;
    localparam [9:0] TRAY_X0  = 10'd140;
    localparam [9:0] TRAY_X1  = 10'd344;
    localparam [9:0] TRAY_Y0  = 10'd300;
    localparam [9:0] TRAY_Y1  = 10'd360;
    localparam [9:0] LAND_Y0  = 10'd332;

    // True when the current pixel lies inside a rectangular area.
    // Rectangle coordinates use x0/y0 inclusive and x1/y1 exclusive.
    function in_rect;
        input [9:0] px, py, x0, y0, x1, y1;
        begin
            in_rect = (px >= x0) && (px < x1) && (py >= y0) && (py < y1);
        end
    endfunction

    // True only on the border region of a rectangle.
    // Used for product boxes, status panel, controls panel, and tray outline.
    function rect_border;
        input [9:0] px, py, x0, y0, x1, y1;
        input [3:0] thick;
        begin
            rect_border = in_rect(px, py, x0, y0, x1, y1) &&
                          ((px < x0 + thick) || (px >= x1 - thick) ||
                           (py < y0 + thick) || (py >= y1 - thick));
        end
    endfunction

    // --------------------------------------------------------------------
    // Local animation counter.
    // A new dispense state resets the animation. While dispensing, the
    // product advances one step per VGA frame. This avoids adding another
    // signal from the FSM just for display animation.
    // --------------------------------------------------------------------
    reg [2:0] state_d = ST_SELECT;
    reg [7:0] drop_frame = 8'd0;
    wire new_frame = (x == 10'd0) && (y == 10'd0);

    always @(posedge clk) begin
        state_d <= state;

        if (state != state_d) begin
            drop_frame <= 8'd0;
        end else if ((state == ST_DISPENSE) && new_frame && (drop_frame < 8'd60)) begin
            drop_frame <= drop_frame + 8'd1;
        end else if (state != ST_DISPENSE) begin
            drop_frame <= 8'd0;
        end
    end

    function [9:0] product_start_y;
        input [1:0] product;
        begin
            case (product)
                PROD_CHIPS: product_start_y = CHIPS_Y0;
                PROD_SODA : product_start_y = SODA_Y0;
                PROD_CANDY: product_start_y = CANDY_Y0;
                default   : product_start_y = CHIPS_Y0;
            endcase
        end
    endfunction

    // Piecewise drop animation. No multiply/divide needed; this keeps the
    // VGA renderer simple and timing friendly.
    reg [9:0] drop_y;
    always @(*) begin
        drop_y = product_start_y(selected_product);
        if (state == ST_DISPENSE) begin
            case (selected_product)
                PROD_CHIPS: begin
                    if      (drop_frame < 8'd10) drop_y = 10'd104;
                    else if (drop_frame < 8'd20) drop_y = 10'd144;
                    else if (drop_frame < 8'd30) drop_y = 10'd184;
                    else if (drop_frame < 8'd40) drop_y = 10'd224;
                    else if (drop_frame < 8'd50) drop_y = 10'd272;
                    else                         drop_y = LAND_Y0;
                end
                PROD_SODA: begin
                    if      (drop_frame < 8'd10) drop_y = 10'd174;
                    else if (drop_frame < 8'd20) drop_y = 10'd208;
                    else if (drop_frame < 8'd30) drop_y = 10'd242;
                    else if (drop_frame < 8'd40) drop_y = 10'd276;
                    else                         drop_y = LAND_Y0;
                end
                default: begin
                    if      (drop_frame < 8'd10) drop_y = 10'd244;
                    else if (drop_frame < 8'd20) drop_y = 10'd270;
                    else if (drop_frame < 8'd30) drop_y = 10'd296;
                    else                         drop_y = LAND_Y0;
                end
            endcase
        end else if ((state == ST_CHANGE) || (state == ST_THANKS)) begin
            drop_y = LAND_Y0;
        end
    end

    // --------------------------------------------------------------------
    // Text
    // --------------------------------------------------------------------
    wire title_on;
    text_pixel #(.X0(112), .Y0(18), .SCALE(2), .LEN(20), .TEXT("FPGA VENDING MACHINE"))
        txt_title(.x(x), .y(y), .on(title_on));

    // Product shelf labels. The product graphics are centered vertically over
    // the tray, while the text remains at the left side of each row.
    wire chips_on, soda_on, candy_on;
    text_pixel #(.X0(52), .Y0(88),  .SCALE(1), .LEN(18), .TEXT("BTNL CHIPS  $1.25"))
        txt_chips(.x(x), .y(y), .on(chips_on));
    text_pixel #(.X0(52), .Y0(158), .SCALE(1), .LEN(18), .TEXT("BTNC SODA   $1.50"))
        txt_soda(.x(x), .y(y), .on(soda_on));
    text_pixel #(.X0(52), .Y0(228), .SCALE(1), .LEN(18), .TEXT("BTNR CANDY  $0.75"))
        txt_candy(.x(x), .y(y), .on(candy_on));

    wire stock1_on, stock2_on, stock3_on;
    text_pixel #(.X0(286), .Y0(88),  .SCALE(1), .LEN(6), .TEXT("STOCK")) txt_stock1(.x(x), .y(y), .on(stock1_on));
    text_pixel #(.X0(286), .Y0(158), .SCALE(1), .LEN(6), .TEXT("STOCK")) txt_stock2(.x(x), .y(y), .on(stock2_on));
    text_pixel #(.X0(286), .Y0(228), .SCALE(1), .LEN(6), .TEXT("STOCK")) txt_stock3(.x(x), .y(y), .on(stock3_on));

    wire chips_stock_on, soda_stock_on, candy_stock_on;
    char_pixel #(.X0(342), .Y0(88),  .SCALE(1)) chips_stock(.x(x), .y(y), .char_code("0" + chips_count), .on(chips_stock_on));
    char_pixel #(.X0(342), .Y0(158), .SCALE(1)) soda_stock (.x(x), .y(y), .char_code("0" + soda_count ), .on(soda_stock_on));
    char_pixel #(.X0(342), .Y0(228), .SCALE(1)) candy_stock(.x(x), .y(y), .char_code("0" + candy_count), .on(candy_stock_on));

    // Right status panel.
    wire panel_title_on, sel_lbl_on, credit_lbl_on, price_lbl_on, change_lbl_on, coin_lbl_on, status_lbl_on;
    text_pixel #(.X0(412), .Y0(82),  .SCALE(1), .LEN(12), .TEXT("STATUS PANEL")) txt_panel(.x(x), .y(y), .on(panel_title_on));
    text_pixel #(.X0(412), .Y0(112), .SCALE(1), .LEN(8),  .TEXT("ITEM"))         txt_sel_lbl(.x(x), .y(y), .on(sel_lbl_on));
    text_pixel #(.X0(412), .Y0(150), .SCALE(1), .LEN(8),  .TEXT("CREDIT"))       txt_credit_lbl(.x(x), .y(y), .on(credit_lbl_on));
    text_pixel #(.X0(412), .Y0(196), .SCALE(1), .LEN(8),  .TEXT("PRICE"))        txt_price_lbl(.x(x), .y(y), .on(price_lbl_on));
    text_pixel #(.X0(412), .Y0(242), .SCALE(1), .LEN(8),  .TEXT("CHANGE"))       txt_change_lbl(.x(x), .y(y), .on(change_lbl_on));
    text_pixel #(.X0(412), .Y0(288), .SCALE(1), .LEN(8),  .TEXT("COIN"))         txt_coin_lbl(.x(x), .y(y), .on(coin_lbl_on));
    text_pixel #(.X0(412), .Y0(326), .SCALE(1), .LEN(8),  .TEXT("STATE"))        txt_status_lbl(.x(x), .y(y), .on(status_lbl_on));

    wire pchips_on, psoda_on, pcandy_on;
    text_pixel #(.X0(488), .Y0(112), .SCALE(1), .LEN(8), .TEXT("CHIPS")) txt_pchips(.x(x), .y(y), .on(pchips_on));
    text_pixel #(.X0(488), .Y0(112), .SCALE(1), .LEN(8), .TEXT("SODA"))  txt_psoda (.x(x), .y(y), .on(psoda_on));
    text_pixel #(.X0(488), .Y0(112), .SCALE(1), .LEN(8), .TEXT("CANDY")) txt_pcandy(.x(x), .y(y), .on(pcandy_on));

    wire selected_name_on = ((selected_product == PROD_CHIPS) && pchips_on) |
                            ((selected_product == PROD_SODA ) && psoda_on ) |
                            ((selected_product == PROD_CANDY) && pcandy_on);

    wire credit_money_on, price_money_on, change_money_on;
    money_text #(.X0(488), .Y0(144), .SCALE(2)) credit_money(.x(x), .y(y), .cents(credit_cents), .on(credit_money_on));
    money_text #(.X0(488), .Y0(190), .SCALE(2)) price_money (.x(x), .y(y), .cents(price_cents ), .on(price_money_on));
    money_text #(.X0(488), .Y0(236), .SCALE(2)) change_money(.x(x), .y(y), .cents(change_cents), .on(change_money_on));

    wire coin0_on, coin1_on, coin2_on, coin3_on, coin4_on, coinbad_on;
    text_pixel #(.X0(488), .Y0(288), .SCALE(1), .LEN(9), .TEXT("NONE"))     txt_coin0(.x(x), .y(y), .on(coin0_on));
    text_pixel #(.X0(488), .Y0(288), .SCALE(1), .LEN(9), .TEXT("NICKEL"))   txt_coin1(.x(x), .y(y), .on(coin1_on));
    text_pixel #(.X0(488), .Y0(288), .SCALE(1), .LEN(9), .TEXT("DIME"))     txt_coin2(.x(x), .y(y), .on(coin2_on));
    text_pixel #(.X0(488), .Y0(288), .SCALE(1), .LEN(9), .TEXT("QUARTER"))  txt_coin3(.x(x), .y(y), .on(coin3_on));
    text_pixel #(.X0(488), .Y0(288), .SCALE(1), .LEN(9), .TEXT("DOLLAR"))   txt_coin4(.x(x), .y(y), .on(coin4_on));
    text_pixel #(.X0(488), .Y0(288), .SCALE(1), .LEN(9), .TEXT("ONE ONLY")) txt_coinbad(.x(x), .y(y), .on(coinbad_on));

    wire coin_name_on = ((coin_sw == 4'b0000) && coin0_on) |
                        ((coin_sw == 4'b0001) && coin1_on) |
                        ((coin_sw == 4'b0010) && coin2_on) |
                        ((coin_sw == 4'b0100) && coin3_on) |
                        ((coin_sw == 4'b1000) && coin4_on) |
                        ((coin_sw != 4'b0000) && (coin_sw != 4'b0001) &&
                         (coin_sw != 4'b0010) && (coin_sw != 4'b0100) &&
                         (coin_sw != 4'b1000) && coinbad_on);

    wire sselect_on, sinsert_on, sdisp_on, schange_on, sthanks_on, ssold_on, srefund_on;
    text_pixel #(.X0(412), .Y0(344), .SCALE(1), .LEN(14), .TEXT("SELECT ITEM"))  txt_sselect(.x(x), .y(y), .on(sselect_on));
    text_pixel #(.X0(412), .Y0(344), .SCALE(1), .LEN(14), .TEXT("INSERT MONEY")) txt_sinsert(.x(x), .y(y), .on(sinsert_on));
    text_pixel #(.X0(412), .Y0(344), .SCALE(1), .LEN(14), .TEXT("DISPENSING"))   txt_sdisp(.x(x), .y(y), .on(sdisp_on));
    text_pixel #(.X0(412), .Y0(344), .SCALE(1), .LEN(14), .TEXT("CHANGE"))       txt_schange(.x(x), .y(y), .on(schange_on));
    text_pixel #(.X0(412), .Y0(344), .SCALE(1), .LEN(14), .TEXT("THANK YOU"))    txt_sthanks(.x(x), .y(y), .on(sthanks_on));
    text_pixel #(.X0(412), .Y0(344), .SCALE(1), .LEN(14), .TEXT("SOLD OUT"))     txt_ssold(.x(x), .y(y), .on(ssold_on));
    text_pixel #(.X0(412), .Y0(344), .SCALE(1), .LEN(14), .TEXT("REFUND"))       txt_srefund(.x(x), .y(y), .on(srefund_on));

    wire status_on = ((state == ST_SELECT  ) && sselect_on) |
                     ((state == ST_INSERT  ) && sinsert_on) |
                     ((state == ST_DISPENSE) && sdisp_on  ) |
                     ((state == ST_CHANGE  ) && schange_on) |
                     ((state == ST_THANKS  ) && sthanks_on) |
                     ((state == ST_SOLDOUT ) && ssold_on ) |
                     ((state == ST_REFUND  ) && srefund_on);

    wire ctrl1_on, ctrl2_on, ctrl3_on;
    text_pixel #(.X0(36), .Y0(392), .SCALE(1), .LEN(51), .TEXT("SELECT PRODUCT: BTNL CHIPS  BTNC SODA  BTNR CANDY")) txt_ctrl1(.x(x), .y(y), .on(ctrl1_on));
    text_pixel #(.X0(36), .Y0(414), .SCALE(1), .LEN(64), .TEXT("COIN SWITCHES: SW0 NICKEL  SW1 DIME  SW2 QUARTER  SW3 DOLLAR")) txt_ctrl2(.x(x), .y(y), .on(ctrl2_on));
    text_pixel #(.X0(36), .Y0(436), .SCALE(1), .LEN(64), .TEXT("INSERT: TURN ON ONE COIN SWITCH THEN PRESS BTNU   CANCEL: BTND")) txt_ctrl3(.x(x), .y(y), .on(ctrl3_on));

    // any_text is a combined mask for all white text. Later in the color
    // priority chain, text is drawn on top of background shapes.
    wire any_text = title_on | chips_on | soda_on | candy_on |
                    stock1_on | stock2_on | stock3_on |
                    chips_stock_on | soda_stock_on | candy_stock_on |
                    panel_title_on | sel_lbl_on | credit_lbl_on | price_lbl_on |
                    change_lbl_on | coin_lbl_on | status_lbl_on |
                    selected_name_on | credit_money_on | price_money_on |
                    change_money_on | coin_name_on | status_on |
                    ctrl1_on | ctrl2_on | ctrl3_on;

    // --------------------------------------------------------------------
    // Shapes
    // --------------------------------------------------------------------
    wire chips_border = rect_border(x, y, 38, 76, 372, 134, 3);
    wire soda_border  = rect_border(x, y, 38, 146, 372, 204, 3);
    wire candy_border = rect_border(x, y, 38, 216, 372, 274, 3);

    wire selected_border = ((selected_product == PROD_CHIPS) && chips_border) |
                           ((selected_product == PROD_SODA ) && soda_border ) |
                           ((selected_product == PROD_CANDY) && candy_border);

    wire product_box = in_rect(x,y,38,76,372,134) |
                       in_rect(x,y,38,146,372,204) |
                       in_rect(x,y,38,216,372,274);

    wire cabinet_border = rect_border(x,y,24,54,624,372,3);
    wire panel_box      = in_rect(x,y,396,70,610,366);
    wire panel_border   = rect_border(x,y,396,70,610,366,2);

    wire controls_box    = in_rect(x,y,28,382,612,462);
    wire controls_border = rect_border(x,y,28,382,612,462,2);

    // Product artwork sitting on each row, centered above the tray.
    wire chips_pack = in_rect(x,y,PROD_X0,CHIPS_Y0,PROD_X1,CHIPS_Y0+10'd24);
    wire soda_can   = in_rect(x,y,PROD_CX0,SODA_Y0, PROD_CX1,SODA_Y0+10'd24);
    wire candy_bar  = in_rect(x,y,PROD_X0,CANDY_Y0,PROD_X1,CANDY_Y0+10'd18);

    // Small chute/gate marks directly below each product.
    wire chute_chips = in_rect(x,y,232,130,240,140);
    wire chute_soda  = in_rect(x,y,232,200,240,210);
    wire chute_candy = in_rect(x,y,232,270,240,282);

    // Collection tray. No label is drawn; the shape and animation explain it.
    wire tray_inside = in_rect(x,y,TRAY_X0+10'd4,TRAY_Y0+10'd4,TRAY_X1-10'd4,TRAY_Y1-10'd8);
    wire tray_border = rect_border(x,y,TRAY_X0,TRAY_Y0,TRAY_X1,TRAY_Y1,2);
    wire tray_lip    = in_rect(x,y,TRAY_X0+10'd10,TRAY_Y1-10'd10,TRAY_X1-10'd10,TRAY_Y1-10'd6);

    wire show_falling_product = (state == ST_DISPENSE) || (state == ST_CHANGE) || (state == ST_THANKS);
    wire drop_chips = show_falling_product && (selected_product == PROD_CHIPS) && in_rect(x,y,PROD_X0,drop_y,PROD_X1,drop_y+10'd24);
    wire drop_soda  = show_falling_product && (selected_product == PROD_SODA ) && in_rect(x,y,PROD_CX0,drop_y,PROD_CX1,drop_y+10'd24);
    wire drop_candy = show_falling_product && (selected_product == PROD_CANDY) && in_rect(x,y,PROD_X0,drop_y,PROD_X1,drop_y+10'd18);

    // Main pixel-color decision block.
    // The order matters: later tests have higher priority and overwrite
    // earlier background colors. This is how text and borders appear on top
    // of the cabinet, panel, tray, and product boxes.
    always @(*) begin
        rgb_next = C_BLACK;

        if (!video_on) begin
            rgb_next = C_BLACK;
        end else begin
            rgb_next = C_DGRAY;

            if (in_rect(x,y,24,54,624,372)) rgb_next = C_BLUE;
            if (product_box)                rgb_next = C_PANEL;
            if (panel_box)                  rgb_next = C_BLACK;
            if (controls_box)               rgb_next = 12'h111;
            if (tray_inside)                rgb_next = C_BLACK;

            // Static product artwork.
            if (chips_pack)                 rgb_next = C_ORANGE;
            if (soda_can)                   rgb_next = C_CYAN;
            if (candy_bar)                  rgb_next = C_RED;

            // Chutes and tray depth.
            if (chute_chips || chute_soda || chute_candy) rgb_next = C_GRAY;
            if (tray_lip)                   rgb_next = C_GRAY;

            // Falling/landed product. This is drawn after the static product
            // artwork so it is visible during the transaction.
            if (drop_chips)                 rgb_next = C_ORANGE;
            if (drop_soda)                  rgb_next = C_CYAN;
            if (drop_candy)                 rgb_next = C_RED;

            // Borders.
            if (cabinet_border || panel_border || controls_border ||
                chips_border || soda_border || candy_border || tray_border)
                rgb_next = C_GRAY;

            if (selected_border)
                rgb_next = C_YELLOW;

            if (invalid_coin_flash && in_rect(x,y,484,284,590,304))
                rgb_next = C_RED;

            if (any_text)
                rgb_next = C_WHITE;

            if (status_on)
                rgb_next = (state == ST_DISPENSE || state == ST_THANKS) ? C_GREEN : C_YELLOW;

            if (coin_name_on)
                rgb_next = invalid_coin_flash ? C_RED : C_CYAN;
        end
    end

    // Register the final color at the pixel clock.
    // This keeps the VGA output stable for the whole pixel period.
    always @(posedge clk) begin
        rgb <= rgb_next;
    end
endmodule
