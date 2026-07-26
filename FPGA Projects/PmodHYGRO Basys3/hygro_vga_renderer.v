`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: hygro_vga_renderer
//
// Purpose:
//   Combinational pixel renderer for the environmental-monitor dashboard.
//   The current coordinate and sensor values determine one 12-bit RGB output.
//
// Drawing priority:
//   Background is selected first. Panels, borders, labels, numbers, gauges,
//   classifications, and status indicators overwrite it in sequence.
//
// Timing note:
//   Bottom status text uses scale 2. Power-of-two scaling produces shallow shift
//   logic and avoids the visible artifacts previously observed with scale 3.
//
// Pmod HYGRO Environmental Monitor VGA Renderer
//
// Display features:
//   * Temperature in Fahrenheit and Celsius
//   * Relative humidity
//   * Segmented temperature and humidity gauges
//   * Temperature classification
//   * Humidity classification
//   * Combined environmental status
//   * Sensor-valid and I2C-error indicators
//
// All sensor values are scaled by ten:
//   724 = 72.4 degrees F
//   223 = 22.3 degrees C
//   386 = 38.6 percent RH
//////////////////////////////////////////////////////////////////////////////////

module hygro_vga_renderer (
    input  wire [9:0]         pixel_x,
    input  wire [9:0]         pixel_y,
    input  wire               video_active,

    input  wire signed [15:0] temperature_c_tenths,
    input  wire signed [15:0] temperature_f_tenths,
    input  wire        [15:0] humidity_tenths,
    input  wire               data_valid,
    input  wire               sensor_error,

    output reg  [3:0]         vga_red,
    output reg  [3:0]         vga_green,
    output reg  [3:0]         vga_blue
);

    // Twelve-bit palette: four bits per RGB channel.
    localparam [11:0] COLOR_BLACK      = 12'h012;
    localparam [11:0] COLOR_PANEL      = 12'h124;
    localparam [11:0] COLOR_PANEL_EDGE = 12'h58A;
    localparam [11:0] COLOR_WHITE      = 12'hFFF;
    localparam [11:0] COLOR_DIM        = 12'h9BC;
    localparam [11:0] COLOR_CYAN       = 12'h0DF;
    localparam [11:0] COLOR_BLUE       = 12'h27F;
    localparam [11:0] COLOR_GREEN      = 12'h2E5;
    localparam [11:0] COLOR_YELLOW     = 12'hFE2;
    localparam [11:0] COLOR_ORANGE     = 12'hF82;
    localparam [11:0] COLOR_RED        = 12'hF24;
    localparam [11:0] COLOR_BAR_OFF    = 12'h246;

    // ----------------------------------------------------------------------
    // 5x7 bitmap font; row bits [4:0] map left to right.
    // ----------------------------------------------------------------------
    // ----------------------------------------------------------------------
    function [4:0] glyph_row;
        input [7:0] ascii;
        input [2:0] row;
        begin
            glyph_row = 5'b00000;

            case (ascii)
                "A": case(row) 0:glyph_row=5'b01110;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b11111;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b10001; endcase
                "B": case(row) 0:glyph_row=5'b11110;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b11110;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b11110; endcase
                "C": case(row) 0:glyph_row=5'b01111;1:glyph_row=5'b10000;2:glyph_row=5'b10000;3:glyph_row=5'b10000;4:glyph_row=5'b10000;5:glyph_row=5'b10000;6:glyph_row=5'b01111; endcase
                "D": case(row) 0:glyph_row=5'b11110;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b10001;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b11110; endcase
                "E": case(row) 0:glyph_row=5'b11111;1:glyph_row=5'b10000;2:glyph_row=5'b10000;3:glyph_row=5'b11110;4:glyph_row=5'b10000;5:glyph_row=5'b10000;6:glyph_row=5'b11111; endcase
                "F": case(row) 0:glyph_row=5'b11111;1:glyph_row=5'b10000;2:glyph_row=5'b10000;3:glyph_row=5'b11110;4:glyph_row=5'b10000;5:glyph_row=5'b10000;6:glyph_row=5'b10000; endcase
                "G": case(row) 0:glyph_row=5'b01111;1:glyph_row=5'b10000;2:glyph_row=5'b10000;3:glyph_row=5'b10111;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b01111; endcase
                "H": case(row) 0:glyph_row=5'b10001;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b11111;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b10001; endcase
                "I": case(row) 0:glyph_row=5'b11111;1:glyph_row=5'b00100;2:glyph_row=5'b00100;3:glyph_row=5'b00100;4:glyph_row=5'b00100;5:glyph_row=5'b00100;6:glyph_row=5'b11111; endcase
                "J": case(row) 0:glyph_row=5'b00111;1:glyph_row=5'b00010;2:glyph_row=5'b00010;3:glyph_row=5'b00010;4:glyph_row=5'b10010;5:glyph_row=5'b10010;6:glyph_row=5'b01100; endcase
                "K": case(row) 0:glyph_row=5'b10001;1:glyph_row=5'b10010;2:glyph_row=5'b10100;3:glyph_row=5'b11000;4:glyph_row=5'b10100;5:glyph_row=5'b10010;6:glyph_row=5'b10001; endcase
                "L": case(row) 0:glyph_row=5'b10000;1:glyph_row=5'b10000;2:glyph_row=5'b10000;3:glyph_row=5'b10000;4:glyph_row=5'b10000;5:glyph_row=5'b10000;6:glyph_row=5'b11111; endcase
                "M": case(row) 0:glyph_row=5'b10001;1:glyph_row=5'b11011;2:glyph_row=5'b10101;3:glyph_row=5'b10101;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b10001; endcase
                "N": case(row) 0:glyph_row=5'b10001;1:glyph_row=5'b11001;2:glyph_row=5'b10101;3:glyph_row=5'b10011;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b10001; endcase
                "O": case(row) 0:glyph_row=5'b01110;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b10001;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b01110; endcase
                "P": case(row) 0:glyph_row=5'b11110;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b11110;4:glyph_row=5'b10000;5:glyph_row=5'b10000;6:glyph_row=5'b10000; endcase
                "Q": case(row) 0:glyph_row=5'b01110;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b10001;4:glyph_row=5'b10101;5:glyph_row=5'b10010;6:glyph_row=5'b01101; endcase
                "R": case(row) 0:glyph_row=5'b11110;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b11110;4:glyph_row=5'b10100;5:glyph_row=5'b10010;6:glyph_row=5'b10001; endcase
                "S": case(row) 0:glyph_row=5'b01111;1:glyph_row=5'b10000;2:glyph_row=5'b10000;3:glyph_row=5'b01110;4:glyph_row=5'b00001;5:glyph_row=5'b00001;6:glyph_row=5'b11110; endcase
                "T": case(row) 0:glyph_row=5'b11111;1:glyph_row=5'b00100;2:glyph_row=5'b00100;3:glyph_row=5'b00100;4:glyph_row=5'b00100;5:glyph_row=5'b00100;6:glyph_row=5'b00100; endcase
                "U": case(row) 0:glyph_row=5'b10001;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b10001;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b01110; endcase
                "V": case(row) 0:glyph_row=5'b10001;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b10001;4:glyph_row=5'b10001;5:glyph_row=5'b01010;6:glyph_row=5'b00100; endcase
                "W": case(row) 0:glyph_row=5'b10001;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b10101;4:glyph_row=5'b10101;5:glyph_row=5'b10101;6:glyph_row=5'b01010; endcase
                "X": case(row) 0:glyph_row=5'b10001;1:glyph_row=5'b10001;2:glyph_row=5'b01010;3:glyph_row=5'b00100;4:glyph_row=5'b01010;5:glyph_row=5'b10001;6:glyph_row=5'b10001; endcase
                "Y": case(row) 0:glyph_row=5'b10001;1:glyph_row=5'b10001;2:glyph_row=5'b01010;3:glyph_row=5'b00100;4:glyph_row=5'b00100;5:glyph_row=5'b00100;6:glyph_row=5'b00100; endcase
                "Z": case(row) 0:glyph_row=5'b11111;1:glyph_row=5'b00001;2:glyph_row=5'b00010;3:glyph_row=5'b00100;4:glyph_row=5'b01000;5:glyph_row=5'b10000;6:glyph_row=5'b11111; endcase

                "0": case(row) 0:glyph_row=5'b01110;1:glyph_row=5'b10001;2:glyph_row=5'b10011;3:glyph_row=5'b10101;4:glyph_row=5'b11001;5:glyph_row=5'b10001;6:glyph_row=5'b01110; endcase
                "1": case(row) 0:glyph_row=5'b00100;1:glyph_row=5'b01100;2:glyph_row=5'b00100;3:glyph_row=5'b00100;4:glyph_row=5'b00100;5:glyph_row=5'b00100;6:glyph_row=5'b01110; endcase
                "2": case(row) 0:glyph_row=5'b01110;1:glyph_row=5'b10001;2:glyph_row=5'b00001;3:glyph_row=5'b00010;4:glyph_row=5'b00100;5:glyph_row=5'b01000;6:glyph_row=5'b11111; endcase
                "3": case(row) 0:glyph_row=5'b11110;1:glyph_row=5'b00001;2:glyph_row=5'b00001;3:glyph_row=5'b01110;4:glyph_row=5'b00001;5:glyph_row=5'b00001;6:glyph_row=5'b11110; endcase
                "4": case(row) 0:glyph_row=5'b00010;1:glyph_row=5'b00110;2:glyph_row=5'b01010;3:glyph_row=5'b10010;4:glyph_row=5'b11111;5:glyph_row=5'b00010;6:glyph_row=5'b00010; endcase
                "5": case(row) 0:glyph_row=5'b11111;1:glyph_row=5'b10000;2:glyph_row=5'b10000;3:glyph_row=5'b11110;4:glyph_row=5'b00001;5:glyph_row=5'b00001;6:glyph_row=5'b11110; endcase
                "6": case(row) 0:glyph_row=5'b01110;1:glyph_row=5'b10000;2:glyph_row=5'b10000;3:glyph_row=5'b11110;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b01110; endcase
                "7": case(row) 0:glyph_row=5'b11111;1:glyph_row=5'b00001;2:glyph_row=5'b00010;3:glyph_row=5'b00100;4:glyph_row=5'b01000;5:glyph_row=5'b01000;6:glyph_row=5'b01000; endcase
                "8": case(row) 0:glyph_row=5'b01110;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b01110;4:glyph_row=5'b10001;5:glyph_row=5'b10001;6:glyph_row=5'b01110; endcase
                "9": case(row) 0:glyph_row=5'b01110;1:glyph_row=5'b10001;2:glyph_row=5'b10001;3:glyph_row=5'b01111;4:glyph_row=5'b00001;5:glyph_row=5'b00001;6:glyph_row=5'b01110; endcase

                ".": case(row) 5:glyph_row=5'b00110;6:glyph_row=5'b00110; endcase
                "%": case(row) 0:glyph_row=5'b11001;1:glyph_row=5'b11010;2:glyph_row=5'b00100;3:glyph_row=5'b01000;4:glyph_row=5'b10110;5:glyph_row=5'b00110; endcase
                "&": case(row) 0:glyph_row=5'b01100;1:glyph_row=5'b10010;2:glyph_row=5'b10100;3:glyph_row=5'b01000;4:glyph_row=5'b10101;5:glyph_row=5'b10010;6:glyph_row=5'b01101; endcase
                "-": case(row) 3:glyph_row=5'b11111; endcase
                ":": case(row) 2:glyph_row=5'b00100;4:glyph_row=5'b00100; endcase
                "/": case(row) 0:glyph_row=5'b00001;1:glyph_row=5'b00010;2:glyph_row=5'b00100;3:glyph_row=5'b01000;4:glyph_row=5'b10000; endcase
                default: glyph_row = 5'b00000;
            endcase
        end
    endfunction

    // Return one when the current pixel lies on a lit glyph pixel.
    function char_pixel;
        input [9:0] px;
        input [9:0] py;
        input integer x0;
        input integer y0;
        input integer scale;
        input [7:0] ascii;
        integer local_x;
        integer local_y;
        integer col;
        integer row;
        reg [4:0] glyph_bits;
        begin
            char_pixel = 1'b0;
            glyph_bits = 5'b00000;

            if ((px >= x0) && (px < x0 + 6*scale) &&
                (py >= y0) && (py < y0 + 8*scale)) begin

                local_x = px - x0;
                local_y = py - y0;
                col = local_x / scale;
                row = local_y / scale;

                if ((col < 5) && (row < 7)) begin
                    glyph_bits = glyph_row(ascii, row);
                    char_pixel = glyph_bits[4-col];
                end
            end
        end
    endfunction

    // Text ROM: select a phrase and one character within it.
    function [7:0] text_character;
        input integer text_id;
        input integer index;
        begin
            text_character = " ";

            case (text_id)
                0: case(index)
                    0:text_character="P"; 1:text_character="M"; 2:text_character="O";
                    3:text_character="D"; 4:text_character=" "; 5:text_character="H";
                    6:text_character="Y"; 7:text_character="G"; 8:text_character="R";
                    9:text_character="O"; 10:text_character=" "; 11:text_character="E";
                    12:text_character="N"; 13:text_character="V"; 14:text_character="I";
                    15:text_character="R"; 16:text_character="O"; 17:text_character="N";
                    18:text_character="M"; 19:text_character="E"; 20:text_character="N";
                    21:text_character="T"; 22:text_character=" "; 23:text_character="M";
                    24:text_character="O"; 25:text_character="N"; 26:text_character="I";
                    27:text_character="T"; 28:text_character="O"; 29:text_character="R";
                endcase

                1: case(index)
                    0:text_character="T";1:text_character="E";2:text_character="M";
                    3:text_character="P";4:text_character="E";5:text_character="R";
                    6:text_character="A";7:text_character="T";8:text_character="U";
                    9:text_character="R";10:text_character="E";
                endcase

                2: case(index)
                    0:text_character="R";1:text_character="E";2:text_character="L";
                    3:text_character="A";4:text_character="T";5:text_character="I";
                    6:text_character="V";7:text_character="E";8:text_character=" ";
                    9:text_character="H";10:text_character="U";11:text_character="M";
                    12:text_character="I";13:text_character="D";14:text_character="I";
                    15:text_character="T";16:text_character="Y";
                endcase

                3: case(index)
                    0:text_character="S";1:text_character="E";2:text_character="N";
                    3:text_character="S";4:text_character="O";5:text_character="R";
                    6:text_character=" ";7:text_character="S";8:text_character="T";
                    9:text_character="A";10:text_character="T";11:text_character="U";
                    12:text_character="S";
                endcase

                4: case(index)
                    0:text_character="E";1:text_character="N";2:text_character="V";
                    3:text_character="I";4:text_character="R";5:text_character="O";
                    6:text_character="N";7:text_character="M";8:text_character="E";
                    9:text_character="N";10:text_character="T";
                endcase

                5: case(index)
                    0:text_character="S";1:text_character="E";2:text_character="N";
                    3:text_character="S";4:text_character="O";5:text_character="R";
                    6:text_character=" ";7:text_character="O";8:text_character="K";
                endcase

                6: case(index)
                    0:text_character="I";1:text_character="2";2:text_character="C";
                    3:text_character=" ";4:text_character="E";5:text_character="R";
                    6:text_character="R";7:text_character="O";8:text_character="R";
                endcase

                7: case(index)
                    0:text_character="W";1:text_character="A";2:text_character="I";
                    3:text_character="T";4:text_character="I";5:text_character="N";
                    6:text_character="G";7:text_character=" ";8:text_character="F";
                    9:text_character="O";10:text_character="R";11:text_character=" ";
                    12:text_character="D";13:text_character="A";14:text_character="T";
                    15:text_character="A";
                endcase

                8: case(index)
                    0:text_character="C";1:text_character="O";2:text_character="O";
                    3:text_character="L";
                endcase

                9: case(index)
                    0:text_character="C";1:text_character="O";2:text_character="M";
                    3:text_character="F";4:text_character="O";5:text_character="R";
                    6:text_character="T";7:text_character="A";8:text_character="B";
                    9:text_character="L";10:text_character="E";
                endcase

                10: case(index)
                    0:text_character="W";1:text_character="A";2:text_character="R";
                    3:text_character="M";
                endcase

                11: case(index)
                    0:text_character="H";1:text_character="O";2:text_character="T";
                endcase

                12: case(index)
                    0:text_character="D";1:text_character="R";2:text_character="Y";
                endcase

                13: case(index)
                    0:text_character="H";1:text_character="U";2:text_character="M";
                    3:text_character="I";4:text_character="D";
                endcase

                14: case(index)
                    0:text_character="H";1:text_character="O";2:text_character="T";
                    3:text_character=" ";4:text_character="&";5:text_character=" ";
                    6:text_character="H";7:text_character="U";8:text_character="M";
                    9:text_character="I";10:text_character="D";
                endcase
            endcase
        end
    endfunction

    // Render a complete text-ROM phrase.
    function text_pixel;
        input [9:0] px;
        input [9:0] py;
        input integer x0;
        input integer y0;
        input integer scale;
        input integer length;
        input integer text_id;
        integer character_index;
        integer character_x;
        begin
            text_pixel = 1'b0;

            if ((px >= x0) && (px < x0 + length*6*scale) &&
                (py >= y0) && (py < y0 + 8*scale)) begin
                character_index = (px - x0) / (6*scale);
                character_x = x0 + character_index*6*scale;
                text_pixel = char_pixel(px, py, character_x, y0, scale,
                                        text_character(text_id, character_index));
            end
        end
    endfunction

    // Convert decimal digit 0..9 into ASCII.
    function [7:0] digit_ascii;
        input integer digit;
        begin
            digit_ascii = "0" + digit[3:0];
        end
    endfunction

    // Draw a positive fixed-point value as XX.X or XXX.X.
    function number_tenths_pixel;
        input [9:0] px;
        input [9:0] py;
        input integer x0;
        input integer y0;
        input integer scale;
        input integer value;
        input integer digits_before_decimal;
        integer thousands;
        integer hundreds;
        integer tens;
        integer ones;
        integer tenths;
        begin
            thousands = (value / 10000) % 10;
            hundreds  = (value / 1000)  % 10;
            tens      = (value / 100)   % 10;
            ones      = (value / 10)    % 10;
            tenths    = value % 10;

            number_tenths_pixel = 1'b0;

            if (digits_before_decimal == 2) begin
                number_tenths_pixel =
                    char_pixel(px,py,x0,          y0,scale,digit_ascii(tens))   |
                    char_pixel(px,py,x0+6*scale,  y0,scale,digit_ascii(ones))   |
                    char_pixel(px,py,x0+12*scale, y0,scale,".")                 |
                    char_pixel(px,py,x0+18*scale, y0,scale,digit_ascii(tenths));
            end else begin
                number_tenths_pixel =
                    char_pixel(px,py,x0,          y0,scale,digit_ascii(hundreds)) |
                    char_pixel(px,py,x0+6*scale,  y0,scale,digit_ascii(tens))     |
                    char_pixel(px,py,x0+12*scale, y0,scale,digit_ascii(ones))     |
                    char_pixel(px,py,x0+18*scale, y0,scale,".")                   |
                    char_pixel(px,py,x0+24*scale, y0,scale,digit_ascii(tenths));
            end
        end
    endfunction

    // True when the current pixel is inside a rectangle.
    function in_box;
        input [9:0] px;
        input [9:0] py;
        input integer x0;
        input integer y0;
        input integer width;
        input integer height;
        begin
            in_box = (px >= x0) && (px < x0 + width) &&
                     (py >= y0) && (py < y0 + height);
        end
    endfunction

    // True only on the border of a rectangle.
    function box_border;
        input [9:0] px;
        input [9:0] py;
        input integer x0;
        input integer y0;
        input integer width;
        input integer height;
        input integer thickness;
        begin
            box_border =
                in_box(px,py,x0,y0,width,height) &&
                !in_box(px,py,x0+thickness,y0+thickness,
                        width-2*thickness,height-2*thickness);
        end
    endfunction

    // Integer working values simplify thresholds and gauge lengths.
    integer temp_f_value;
    integer temp_c_value;
    integer humidity_value;
    integer temp_bar_count;
    integer humidity_bar_count;
    integer segment_index;

    // Selected color and text-hit flags for the current pixel.
    reg [11:0] pixel_color;
    reg [11:0] temperature_color;
    reg [11:0] humidity_color;
    reg [11:0] environment_color;

    reg temp_text;
    reg humidity_text;
    reg environment_text;

    // Main combinational renderer.
    always @* begin
        temp_f_value = temperature_f_tenths;
        temp_c_value = temperature_c_tenths;
        humidity_value = humidity_tenths;

        if (temp_f_value < 0)
            temp_f_value = 0;
        if (temp_c_value < 0)
            temp_c_value = 0;
        if (humidity_value < 0)
            humidity_value = 0;

        // Convert temperature into 0..20 illuminated segments.
        // Temperature range shown by the bar: 40.0 F to 100.0 F.
        if (temp_f_value <= 400)
            temp_bar_count = 0;
        else if (temp_f_value >= 1000)
            temp_bar_count = 20;
        else
            temp_bar_count = ((temp_f_value - 400) * 20) / 600;

        // Convert humidity into 0..20 illuminated segments.
        // Humidity range shown by the bar: 0.0 to 100.0 percent.
        if (humidity_value >= 1000)
            humidity_bar_count = 20;
        else
            humidity_bar_count = (humidity_value * 20) / 1000;

        // Choose classification colors from current measurements.
        if (temp_f_value < 600)
            temperature_color = COLOR_BLUE;
        else if (temp_f_value <= 750)
            temperature_color = COLOR_GREEN;
        else if (temp_f_value <= 850)
            temperature_color = COLOR_YELLOW;
        else
            temperature_color = COLOR_RED;

        if (humidity_value < 300)
            humidity_color = COLOR_YELLOW;
        else if (humidity_value <= 600)
            humidity_color = COLOR_GREEN;
        else
            humidity_color = COLOR_CYAN;

        if ((temp_f_value >= 600) && (temp_f_value <= 750) &&
            (humidity_value >= 300) && (humidity_value <= 600))
            environment_color = COLOR_GREEN;
        else if ((temp_f_value > 850) || (humidity_value > 700))
            environment_color = COLOR_RED;
        else
            environment_color = COLOR_ORANGE;

        // Hit flags for selected classification text.
        temp_text = 1'b0;
        humidity_text = 1'b0;
        environment_text = 1'b0;

        if (temp_f_value < 600)
            temp_text = text_pixel(pixel_x,pixel_y,80,194,2,4,8);
        else if (temp_f_value <= 750)
            temp_text = text_pixel(pixel_x,pixel_y,62,194,2,11,9);
        else if (temp_f_value <= 850)
            temp_text = text_pixel(pixel_x,pixel_y,80,194,2,4,10);
        else
            temp_text = text_pixel(pixel_x,pixel_y,86,194,2,3,11);

        if (humidity_value < 300)
            humidity_text = text_pixel(pixel_x,pixel_y,438,194,2,3,12);
        else if (humidity_value <= 600)
            humidity_text = text_pixel(pixel_x,pixel_y,382,194,2,11,9);
        else
            humidity_text = text_pixel(pixel_x,pixel_y,420,194,2,5,13);

        // Build the combined environmental classification.
        // The bottom status deliberately uses scale 2.
        // Scale 2 divides are implemented as shifts, while scale 3 creates a
        // much deeper combinational divider that can cause visible VGA glitches.
        if ((temp_f_value >= 600) && (temp_f_value <= 750) &&
            (humidity_value >= 300) && (humidity_value <= 600))
            environment_text = text_pixel(pixel_x,pixel_y,254,398,2,11,9);
        else if ((temp_f_value > 850) && (humidity_value > 600))
            environment_text = text_pixel(pixel_x,pixel_y,254,398,2,11,14);
        else if (temp_f_value > 850)
            environment_text = text_pixel(pixel_x,pixel_y,302,398,2,3,11);
        else if (humidity_value > 600)
            environment_text = text_pixel(pixel_x,pixel_y,290,398,2,5,13);
        else if (humidity_value < 300)
            environment_text = text_pixel(pixel_x,pixel_y,302,398,2,3,12);
        else if (temp_f_value < 600)
            environment_text = text_pixel(pixel_x,pixel_y,296,398,2,4,8);
        else
            environment_text = text_pixel(pixel_x,pixel_y,296,398,2,4,10);

        // Default background and blanking color.
        pixel_color = COLOR_BLACK;

        if (video_active) begin
            // Background and panel geometry.
            // Background
            pixel_color = COLOR_BLACK;

            // Header line
            if (in_box(pixel_x,pixel_y,28,58,584,2))
                pixel_color = COLOR_PANEL_EDGE;

            // Main panels
            if (in_box(pixel_x,pixel_y,30,82,278,230))
                pixel_color = COLOR_PANEL;

            if (in_box(pixel_x,pixel_y,332,82,278,230))
                pixel_color = COLOR_PANEL;

            if (box_border(pixel_x,pixel_y,30,82,278,230,2) ||
                box_border(pixel_x,pixel_y,332,82,278,230,2))
                pixel_color = COLOR_PANEL_EDGE;

            // Bottom status panel
            if (in_box(pixel_x,pixel_y,30,332,580,118))
                pixel_color = COLOR_PANEL;

            if (box_border(pixel_x,pixel_y,30,332,580,118,2))
                pixel_color = COLOR_PANEL_EDGE;

            // Static title and panel headings.
            // Title
            if (text_pixel(pixel_x,pixel_y,50,24,2,30,0))
                pixel_color = COLOR_WHITE;

            // Panel headings
            if (text_pixel(pixel_x,pixel_y,72,98,2,11,1))
                pixel_color = COLOR_CYAN;

            if (text_pixel(pixel_x,pixel_y,354,98,2,17,2))
                pixel_color = COLOR_CYAN;

            // Dynamic readings, labels, and gauges.
            // Numeric readings
            if (data_valid && !sensor_error) begin
                if (number_tenths_pixel(pixel_x,pixel_y,70,126,4,
                                        temp_f_value,2))
                    pixel_color = temperature_color;

                if (char_pixel(pixel_x,pixel_y,170,126,4,"F"))
                    pixel_color = temperature_color;

                if (number_tenths_pixel(pixel_x,pixel_y,107,166,2,
                                        temp_c_value,2))
                    pixel_color = COLOR_DIM;

                if (char_pixel(pixel_x,pixel_y,157,166,2,"C"))
                    pixel_color = COLOR_DIM;

                if (number_tenths_pixel(pixel_x,pixel_y,382,126,4,
                                        humidity_value,2))
                    pixel_color = humidity_color;

                if (char_pixel(pixel_x,pixel_y,482,126,4,"%"))
                    pixel_color = humidity_color;

                // Classification words
                if (temp_text)
                    pixel_color = temperature_color;

                if (humidity_text)
                    pixel_color = humidity_color;

                // Segmented temperature bar
                for (segment_index = 0; segment_index < 20; segment_index = segment_index + 1) begin
                    if (in_box(pixel_x,pixel_y,
                               50 + segment_index*12,220,9,28)) begin
                        if (segment_index < temp_bar_count)
                            pixel_color = temperature_color;
                        else
                            pixel_color = COLOR_BAR_OFF;
                    end
                end

                // Segmented humidity bar
                for (segment_index = 0; segment_index < 20; segment_index = segment_index + 1) begin
                    if (in_box(pixel_x,pixel_y,
                               352 + segment_index*12,220,9,28)) begin
                        if (segment_index < humidity_bar_count)
                            pixel_color = humidity_color;
                        else
                            pixel_color = COLOR_BAR_OFF;
                    end
                end
            end

            // Bottom status area.
            // Bottom status labels
            if (text_pixel(pixel_x,pixel_y,48,348,1,13,3))
                pixel_color = COLOR_DIM;

            if (text_pixel(pixel_x,pixel_y,370,348,1,11,4))
                pixel_color = COLOR_DIM;

            if (sensor_error) begin
                if (text_pixel(pixel_x,pixel_y,48,370,2,9,6))
                    pixel_color = COLOR_RED;
            end else if (!data_valid) begin
                if (text_pixel(pixel_x,pixel_y,48,370,2,16,7))
                    pixel_color = COLOR_YELLOW;
            end else begin
                if (text_pixel(pixel_x,pixel_y,48,370,2,9,5))
                    pixel_color = COLOR_GREEN;

                if (environment_text)
                    pixel_color = environment_color;
            end

            // Small live-status indicator
            if (in_box(pixel_x,pixel_y,578,350,12,12)) begin
                if (sensor_error)
                    pixel_color = COLOR_RED;
                else if (data_valid)
                    pixel_color = COLOR_GREEN;
                else
                    pixel_color = COLOR_YELLOW;
            end
        end

        // Split selected color into Basys 3 VGA channels.
        vga_red   = pixel_color[11:8];
        vga_green = pixel_color[7:4];
        vga_blue  = pixel_color[3:0];
    end

endmodule


