`timescale 1ns / 1ps

module waveform_renderer (
    input  wire        active,
    input  wire [9:0]  x,
    input  wire [9:0]  y,

    input  wire [11:0] sample,

    input  wire [11:0] min_sample,
    input  wire [11:0] max_sample,
    input  wire [11:0] vpp_sample,

    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b
);

    // ============================================================
    // DISPLAY LAYOUT
    // ============================================================

    localparam PLOT_LEFT   = 70;
    localparam PLOT_RIGHT  = 619;
    localparam PLOT_TOP    = 55;
    localparam PLOT_BOTTOM = 414;


    // ============================================================
    // WAVEFORM Y POSITION
    // ============================================================

    wire [23:0] scaled_sample;
    wire [9:0] waveform_y;

    assign scaled_sample = sample * 24'd359;

    assign waveform_y =
        PLOT_BOTTOM -
        (scaled_sample / 12'd4095);

    wire in_plot;

    assign in_plot =
        (x >= PLOT_LEFT)  &&
        (x <= PLOT_RIGHT) &&
        (y >= PLOT_TOP)   &&
        (y <= PLOT_BOTTOM);


    wire waveform_pixel;

    assign waveform_pixel =
        in_plot &&
        (
            (y == waveform_y) ||
            (y + 1'b1 == waveform_y) ||
            (y == waveform_y + 1'b1)
        );


    // ============================================================
    // BORDER AND GRID
    // ============================================================

    wire plot_border;

    assign plot_border =
        (
            ((x == PLOT_LEFT) || (x == PLOT_RIGHT)) &&
            (y >= PLOT_TOP) && (y <= PLOT_BOTTOM)
        )
        ||
        (
            ((y == PLOT_TOP) || (y == PLOT_BOTTOM)) &&
            (x >= PLOT_LEFT) && (x <= PLOT_RIGHT)
        );


    wire vertical_grid;
    wire horizontal_grid;

    assign vertical_grid =
        in_plot &&
        (
            (x == 125) ||
            (x == 180) ||
            (x == 235) ||
            (x == 290) ||
            (x == 345) ||
            (x == 400) ||
            (x == 455) ||
            (x == 510) ||
            (x == 565)
        );

    assign horizontal_grid =
        in_plot &&
        (
            (y == 127) ||
            (y == 199) ||
            (y == 271) ||
            (y == 343)
        );


    wire center_line;

    assign center_line =
        in_plot &&
        (y == 235);


    // ============================================================
    // ADC CODE -> MILLIVOLTS
    // ============================================================

    wire [31:0] min_product;
    wire [31:0] max_product;
    wire [31:0] vpp_product;

    wire [11:0] min_mv;
    wire [11:0] max_mv;
    wire [11:0] vpp_mv;

    assign min_product = min_sample * 32'd1000;
    assign max_product = max_sample * 32'd1000;
    assign vpp_product = vpp_sample * 32'd1000;

    assign min_mv =
        (min_product + 32'd2047) / 32'd4095;

    assign max_mv =
        (max_product + 32'd2047) / 32'd4095;

    assign vpp_mv =
        (vpp_product + 32'd2047) / 32'd4095;


    // ============================================================
    // DECIMAL DIGITS
    // ============================================================

    wire [3:0] min_d0;
    wire [3:0] min_d1;
    wire [3:0] min_d2;
    wire [3:0] min_d3;

    wire [3:0] max_d0;
    wire [3:0] max_d1;
    wire [3:0] max_d2;
    wire [3:0] max_d3;

    wire [3:0] vpp_d0;
    wire [3:0] vpp_d1;
    wire [3:0] vpp_d2;
    wire [3:0] vpp_d3;

    assign min_d0 = min_mv / 1000;
    assign min_d1 = (min_mv % 1000) / 100;
    assign min_d2 = (min_mv % 100) / 10;
    assign min_d3 = min_mv % 10;

    assign max_d0 = max_mv / 1000;
    assign max_d1 = (max_mv % 1000) / 100;
    assign max_d2 = (max_mv % 100) / 10;
    assign max_d3 = max_mv % 10;

    assign vpp_d0 = vpp_mv / 1000;
    assign vpp_d1 = (vpp_mv % 1000) / 100;
    assign vpp_d2 = (vpp_mv % 100) / 10;
    assign vpp_d3 = vpp_mv % 10;


    // ============================================================
    // TEXT ENGINE
    // ============================================================

    reg  [7:0] text_char;
    reg  [9:0] text_origin_x;
    reg  [9:0] text_origin_y;
    reg        text_enable;

    wire [2:0] font_row;
    wire [2:0] font_col;
    wire [4:0] font_pixels;

    assign font_row =
        (y - text_origin_y) >> 1;

    assign font_col =
        (x - text_origin_x) >> 1;


    scope_font font_inst (
        .char_code (text_char),
        .row       (font_row),
        .pixels    (font_pixels)
    );


    wire text_pixel;

    assign text_pixel =
        text_enable &&
        (font_row < 7) &&
        (font_col < 5) &&
        font_pixels[4 - font_col];


    integer char_index;


    // ============================================================
    // TEXT CONTENT
    // ============================================================

    always @(*) begin

        text_char     = " ";
        text_origin_x = 10'd0;
        text_origin_y = 10'd0;
        text_enable   = 1'b0;
        char_index    = 0;


        // --------------------------------------------------------
        // TITLE
        // FPGA XADC OSCILLOSCOPE
        // --------------------------------------------------------

        if ((y >= 15) && (y < 29) &&
            (x >= 188) && (x < 452)) begin

            char_index = (x - 188) / 12;

            text_origin_x = 188 + char_index * 12;
            text_origin_y = 15;
            text_enable   = 1'b1;

            case (char_index)

                 0: text_char="F";
                 1: text_char="P";
                 2: text_char="G";
                 3: text_char="A";
                 4: text_char=" ";
                 5: text_char="X";
                 6: text_char="A";
                 7: text_char="D";
                 8: text_char="C";
                 9: text_char=" ";
                10: text_char="O";
                11: text_char="S";
                12: text_char="C";
                13: text_char="I";
                14: text_char="L";
                15: text_char="L";
                16: text_char="O";
                17: text_char="S";
                18: text_char="C";
                19: text_char="O";
                20: text_char="P";
                21: text_char="E";

                default:
                    text_char=" ";

            endcase

        end


        // --------------------------------------------------------
        // VOLTAGE SCALE
        // --------------------------------------------------------

        else if ((x >= 10) && (x < 58) &&
                 (y >= 50) && (y < 64)) begin

            char_index = (x - 10) / 12;
            text_origin_x = 10 + char_index * 12;
            text_origin_y = 50;
            text_enable = 1'b1;

            case (char_index)
                0: text_char="1";
                1: text_char=".";
                2: text_char="0";
                3: text_char="V";
                default: text_char=" ";
            endcase

        end

        else if ((x >= 10) && (x < 58) &&
                 (y >= 122) && (y < 136)) begin

            char_index = (x - 10) / 12;
            text_origin_x = 10 + char_index * 12;
            text_origin_y = 122;
            text_enable = 1'b1;

            case (char_index)
                0: text_char="0";
                1: text_char=".";
                2: text_char="8";
                3: text_char="V";
                default: text_char=" ";
            endcase

        end

        else if ((x >= 10) && (x < 58) &&
                 (y >= 194) && (y < 208)) begin

            char_index = (x - 10) / 12;
            text_origin_x = 10 + char_index * 12;
            text_origin_y = 194;
            text_enable = 1'b1;

            case (char_index)
                0: text_char="0";
                1: text_char=".";
                2: text_char="6";
                3: text_char="V";
                default: text_char=" ";
            endcase

        end

        else if ((x >= 10) && (x < 58) &&
                 (y >= 266) && (y < 280)) begin

            char_index = (x - 10) / 12;
            text_origin_x = 10 + char_index * 12;
            text_origin_y = 266;
            text_enable = 1'b1;

            case (char_index)
                0: text_char="0";
                1: text_char=".";
                2: text_char="4";
                3: text_char="V";
                default: text_char=" ";
            endcase

        end

        else if ((x >= 10) && (x < 58) &&
                 (y >= 338) && (y < 352)) begin

            char_index = (x - 10) / 12;
            text_origin_x = 10 + char_index * 12;
            text_origin_y = 338;
            text_enable = 1'b1;

            case (char_index)
                0: text_char="0";
                1: text_char=".";
                2: text_char="2";
                3: text_char="V";
                default: text_char=" ";
            endcase

        end

        else if ((x >= 10) && (x < 58) &&
                 (y >= 405) && (y < 419)) begin

            char_index = (x - 10) / 12;
            text_origin_x = 10 + char_index * 12;
            text_origin_y = 405;
            text_enable = 1'b1;

            case (char_index)
                0: text_char="0";
                1: text_char=".";
                2: text_char="0";
                3: text_char="V";
                default: text_char=" ";
            endcase

        end


        // --------------------------------------------------------
        // STATUS LINE
        // --------------------------------------------------------

        else if ((y >= 430) && (y < 444) &&
                 (x >= 20) && (x < 572)) begin

            char_index = (x - 20) / 12;

            text_origin_x = 20 + char_index * 12;
            text_origin_y = 430;
            text_enable   = 1'b1;

            case (char_index)

                 0: text_char="V";
                 1: text_char="A";
                 2: text_char="U";
                 3: text_char="X";
                 4: text_char="6";

                 5: text_char=" ";
                 6: text_char=" ";

                 7: text_char="1";
                 8: text_char="2";
                 9: text_char="-";
                10: text_char="B";
                11: text_char="I";
                12: text_char="T";

                13: text_char=" ";

                14: text_char="X";
                15: text_char="A";
                16: text_char="D";
                17: text_char="C";

                18: text_char=" ";
                19: text_char=" ";

                20: text_char="6";
                21: text_char="4";
                22: text_char=" ";
                23: text_char="K";
                24: text_char="S";
                25: text_char="P";
                26: text_char="S";

                27: text_char=" ";
                28: text_char=" ";

                29: text_char="W";
                30: text_char="I";
                31: text_char="N";
                32: text_char="D";
                33: text_char="O";
                34: text_char="W";
                35: text_char=" ";

                36: text_char="1";
                37: text_char="0";
                38: text_char=".";
                39: text_char="0";
                40: text_char=" ";
                41: text_char="M";
                42: text_char="S";

                default:
                    text_char=" ";

            endcase

        end


        // --------------------------------------------------------
        // MEASUREMENT LINE
        //
        // MIN 0.xxxV  MAX 0.xxxV  VPP 0.xxxV
        // --------------------------------------------------------

        else if ((y >= 454) && (y < 468) &&
                 (x >= 80) && (x < 560)) begin

            char_index = (x - 80) / 12;

            text_origin_x = 80 + char_index * 12;
            text_origin_y = 454;
            text_enable   = 1'b1;

            case (char_index)

                 0: text_char="M";
                 1: text_char="I";
                 2: text_char="N";
                 3: text_char=" ";
                 4: text_char=8'h30 + min_d0;
                 5: text_char=".";
                 6: text_char=8'h30 + min_d1;
                 7: text_char=8'h30 + min_d2;
                 8: text_char=8'h30 + min_d3;
                 9: text_char="V";

                10: text_char=" ";
                11: text_char=" ";

                12: text_char="M";
                13: text_char="A";
                14: text_char="X";
                15: text_char=" ";
                16: text_char=8'h30 + max_d0;
                17: text_char=".";
                18: text_char=8'h30 + max_d1;
                19: text_char=8'h30 + max_d2;
                20: text_char=8'h30 + max_d3;
                21: text_char="V";

                22: text_char=" ";
                23: text_char=" ";

                24: text_char="V";
                25: text_char="P";
                26: text_char="P";
                27: text_char=" ";
                28: text_char=8'h30 + vpp_d0;
                29: text_char=".";
                30: text_char=8'h30 + vpp_d1;
                31: text_char=8'h30 + vpp_d2;
                32: text_char=8'h30 + vpp_d3;
                33: text_char="V";

                default:
                    text_char=" ";

            endcase

        end

    end


    // ============================================================
    // PIXEL COLORS
    // ============================================================

    always @(*) begin

        // Dark blue background
        vga_r = 4'h0;
        vga_g = 4'h0;
        vga_b = 4'h2;

        if (!active) begin

            vga_r = 4'h0;
            vga_g = 4'h0;
            vga_b = 4'h0;

        end
        else begin

            if (vertical_grid || horizontal_grid) begin
                vga_r = 4'h1;
                vga_g = 4'h3;
                vga_b = 4'h4;
            end

            if (center_line) begin
                vga_r = 4'h3;
                vga_g = 4'h5;
                vga_b = 4'h6;
            end

            if (plot_border) begin
                vga_r = 4'h5;
                vga_g = 4'h7;
                vga_b = 4'h8;
            end

            if (text_pixel) begin
                vga_r = 4'hC;
                vga_g = 4'hD;
                vga_b = 4'hF;
            end

            // Waveform highest priority
            if (waveform_pixel) begin
                vga_r = 4'h0;
                vga_g = 4'hF;
                vga_b = 4'h5;
            end

        end

    end

endmodule
