`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// File: acl_vga_renderer.v
// Project: Pmod ACL VGA Display for Basys 3
//
// Draws the final 640x480 VGA scene using precomputed axis signs, decimal
// digits, and bar lengths supplied by the top-level display pipeline.
//
// Display features:
// - Project title
// - Accurate -2g, -1g, 0, +1g, +2g scale
// - Signed X, Y, and Z values shown directly in g
// - Center-referenced horizontal bar graphs
// - Bottom status line: UPDATE RATE: 100 Hz | DATA VALID
// -----------------------------------------------------------------------------
module acl_vga_renderer(
    input  wire        video_on,
    input  wire [9:0]  x,
    input  wire [9:0]  y,

    input  wire        x_neg,
    input  wire        y_neg,
    input  wire        z_neg,
    input  wire [9:0]  x_len,
    input  wire [9:0]  y_len,
    input  wire [9:0]  z_len,

    input  wire [3:0]  x_d3,
    input  wire [3:0]  x_d2,
    input  wire [3:0]  x_d1,
    input  wire [3:0]  x_d0,
    input  wire [3:0]  y_d3,
    input  wire [3:0]  y_d2,
    input  wire [3:0]  y_d1,
    input  wire [3:0]  y_d0,
    input  wire [3:0]  z_d3,
    input  wire [3:0]  z_d2,
    input  wire [3:0]  z_d1,
    input  wire [3:0]  z_d0,

    input  wire        data_valid,
    input  wire        init_done,
    output reg  [11:0] rgb
);

    localparam C_BLACK = 12'h000;
    localparam C_WHITE = 12'hFFF;
    localparam C_CYAN  = 12'h0FF;
    localparam C_RED   = 12'hF22;
    localparam C_GREEN = 12'h2F2;
    localparam C_YELL  = 12'hFF0;
    localparam C_DGRAY = 12'h111;

    // The scale spans 480 pixels total, or 240 pixels from zero to either end.
    // The top-level supplies an accurate 120 pixels per g bar length, so the
    // five labels correspond to -2g, -1g, 0g, +1g, and +2g.
    localparam BAR_LEFT   = 10'd80;
    localparam BAR_RIGHT  = 10'd560;
    localparam BAR_CENTER = 10'd320;

    function [7:0] digit_ascii;
        input [3:0] d;
        begin
            digit_ascii = "0" + d;
        end
    endfunction

    function [7:0] title_char;
        input [4:0] idx;
        begin
            case (idx)
                0:  title_char = "P";
                1:  title_char = "M";
                2:  title_char = "O";
                3:  title_char = "D";
                4:  title_char = " ";
                5:  title_char = "A";
                6:  title_char = "C";
                7:  title_char = "L";
                8:  title_char = " ";
                9:  title_char = "A";
                10: title_char = "D";
                11: title_char = "X";
                12: title_char = "L";
                13: title_char = "3";
                14: title_char = "4";
                15: title_char = "5";
                16: title_char = " ";
                17: title_char = "V";
                18: title_char = "G";
                19: title_char = "A";
                20: title_char = " ";
                21: title_char = "D";
                22: title_char = "E";
                23: title_char = "M";
                24: title_char = "O";
                default: title_char = " ";
            endcase
        end
    endfunction

    function [7:0] axis_label_char;
        input [1:0] axis;
        begin
            case (axis)
                2'd0: axis_label_char = "X";
                2'd1: axis_label_char = "Y";
                default: axis_label_char = "Z";
            endcase
        end
    endfunction

    function [7:0] axis_digit_ascii;
        input [1:0] axis;
        input [1:0] pos;
        begin
            case (axis)
                2'd0: begin
                    case (pos)
                        2'd0: axis_digit_ascii = digit_ascii(x_d3);
                        2'd1: axis_digit_ascii = digit_ascii(x_d2);
                        2'd2: axis_digit_ascii = digit_ascii(x_d1);
                        default: axis_digit_ascii = digit_ascii(x_d0);
                    endcase
                end
                2'd1: begin
                    case (pos)
                        2'd0: axis_digit_ascii = digit_ascii(y_d3);
                        2'd1: axis_digit_ascii = digit_ascii(y_d2);
                        2'd2: axis_digit_ascii = digit_ascii(y_d1);
                        default: axis_digit_ascii = digit_ascii(y_d0);
                    endcase
                end
                default: begin
                    case (pos)
                        2'd0: axis_digit_ascii = digit_ascii(z_d3);
                        2'd1: axis_digit_ascii = digit_ascii(z_d2);
                        2'd2: axis_digit_ascii = digit_ascii(z_d1);
                        default: axis_digit_ascii = digit_ascii(z_d0);
                    endcase
                end
            endcase
        end
    endfunction

    function [7:0] axis_sign_char;
        input [1:0] axis;
        begin
            case (axis)
                2'd0: axis_sign_char = x_neg ? "-" : "+";
                2'd1: axis_sign_char = y_neg ? "-" : "+";
                default: axis_sign_char = z_neg ? "-" : "+";
            endcase
        end
    endfunction

    // Scale labels: -2g, -1g, 0, +1g, +2g.
    function [7:0] scale_char;
        input [2:0] label_sel;
        input [1:0] idx;
        begin
            case (label_sel)
                3'd0: begin
                    case (idx)
                        0: scale_char = "-";
                        1: scale_char = "2";
                        2: scale_char = "g";
                        default: scale_char = " ";
                    endcase
                end
                3'd1: begin
                    case (idx)
                        0: scale_char = "-";
                        1: scale_char = "1";
                        2: scale_char = "g";
                        default: scale_char = " ";
                    endcase
                end
                3'd2: begin
                    case (idx)
                        0: scale_char = "0";
                        default: scale_char = " ";
                    endcase
                end
                3'd3: begin
                    case (idx)
                        0: scale_char = "+";
                        1: scale_char = "1";
                        2: scale_char = "g";
                        default: scale_char = " ";
                    endcase
                end
                default: begin
                    case (idx)
                        0: scale_char = "+";
                        1: scale_char = "2";
                        2: scale_char = "g";
                        default: scale_char = " ";
                    endcase
                end
            endcase
        end
    endfunction

    // Complete bottom status line. The data_valid input is latched by the top
    // module after the first successful sample, so DATA VALID stays visible.
    function [7:0] footer_char;
        input [5:0] idx;
        begin
            if (data_valid) begin
                case (idx)
                    0: footer_char="U";  1: footer_char="P";  2: footer_char="D";
                    3: footer_char="A";  4: footer_char="T";  5: footer_char="E";
                    6: footer_char=" ";  7: footer_char="R";  8: footer_char="A";
                    9: footer_char="T"; 10: footer_char="E"; 11: footer_char=":";
                    12: footer_char=" "; 13: footer_char="1"; 14: footer_char="0";
                    15: footer_char="0"; 16: footer_char=" "; 17: footer_char="H";
                    18: footer_char="z"; 19: footer_char=" "; 20: footer_char="|";
                    21: footer_char=" "; 22: footer_char="D"; 23: footer_char="A";
                    24: footer_char="T"; 25: footer_char="A"; 26: footer_char=" ";
                    27: footer_char="V"; 28: footer_char="A"; 29: footer_char="L";
                    30: footer_char="I"; 31: footer_char="D";
                    default: footer_char=" ";
                endcase
            end else if (init_done) begin
                case (idx)
                    0: footer_char="U";  1: footer_char="P";  2: footer_char="D";
                    3: footer_char="A";  4: footer_char="T";  5: footer_char="E";
                    6: footer_char=" ";  7: footer_char="R";  8: footer_char="A";
                    9: footer_char="T"; 10: footer_char="E"; 11: footer_char=":";
                    12: footer_char=" "; 13: footer_char="1"; 14: footer_char="0";
                    15: footer_char="0"; 16: footer_char=" "; 17: footer_char="H";
                    18: footer_char="z"; 19: footer_char=" "; 20: footer_char="|";
                    21: footer_char=" "; 22: footer_char="I"; 23: footer_char="N";
                    24: footer_char="I"; 25: footer_char="T"; 26: footer_char=" ";
                    27: footer_char="D"; 28: footer_char="O"; 29: footer_char="N";
                    30: footer_char="E";
                    default: footer_char=" ";
                endcase
            end else begin
                case (idx)
                    0: footer_char="I";  1: footer_char="N";  2: footer_char="I";
                    3: footer_char="T";  4: footer_char="I";  5: footer_char="A";
                    6: footer_char="L";  7: footer_char="I";  8: footer_char="Z";
                    9: footer_char="I"; 10: footer_char="N"; 11: footer_char="G";
                    default: footer_char=" ";
                endcase
            end
        end
    endfunction

    wire title_area = (y >= 28 && y < 36 && x >= 220 && x < 220 + 25*8);
    wire [4:0] title_idx = (x - 220) >> 3;
    wire [7:0] title_code = title_char(title_idx);
    wire title_pix;
    text_renderer title_text(
        .x(x), .y(y),
        .text_x(220 + title_idx*8), .text_y(28),
        .char_code(title_code), .pixel_on(title_pix)
    );

    reg [7:0] dyn_code;
    reg [9:0] dyn_tx;
    reg [9:0] dyn_ty;
    reg [1:0] axis_sel;
    reg [5:0] char_pos;
    reg [2:0] scale_sel;
    wire dyn_pix;

    text_renderer dyn_text(
        .x(x), .y(y),
        .text_x(dyn_tx), .text_y(dyn_ty),
        .char_code(dyn_code), .pixel_on(dyn_pix)
    );

    always @(*) begin
        dyn_code = " ";
        dyn_tx = 10'd0;
        dyn_ty = 10'd0;
        axis_sel = 2'd0;
        char_pos = 6'd0;
        scale_sel = 3'd0;

        // Scale labels above the axis rows.
        if (y >= 62 && y < 70 && x >= 68 && x < 92) begin
            dyn_ty = 62;
            dyn_tx = 68 + (((x - 68) >> 3) * 8);
            char_pos = (x - 68) >> 3;
            scale_sel = 3'd0;
            dyn_code = scale_char(scale_sel, char_pos[1:0]);
        end else if (y >= 62 && y < 70 && x >= 188 && x < 212) begin
            dyn_ty = 62;
            dyn_tx = 188 + (((x - 188) >> 3) * 8);
            char_pos = (x - 188) >> 3;
            scale_sel = 3'd1;
            dyn_code = scale_char(scale_sel, char_pos[1:0]);
        end else if (y >= 62 && y < 70 && x >= 316 && x < 324) begin
            dyn_ty = 62;
            dyn_tx = 316;
            char_pos = 0;
            scale_sel = 3'd2;
            dyn_code = scale_char(scale_sel, 0);
        end else if (y >= 62 && y < 70 && x >= 428 && x < 452) begin
            dyn_ty = 62;
            dyn_tx = 428 + (((x - 428) >> 3) * 8);
            char_pos = (x - 428) >> 3;
            scale_sel = 3'd3;
            dyn_code = scale_char(scale_sel, char_pos[1:0]);
        end else if (y >= 62 && y < 70 && x >= 548 && x < 572) begin
            dyn_ty = 62;
            dyn_tx = 548 + (((x - 548) >> 3) * 8);
            char_pos = (x - 548) >> 3;
            scale_sel = 3'd4;
            dyn_code = scale_char(scale_sel, char_pos[1:0]);

        // Axis value text. Format: X AXIS: +0.00g
        end else if (y >= 94 && y < 102 && x >= 112 && x < 112 + 14*8) begin
            dyn_ty = 94;
            dyn_tx = 112 + (((x - 112) >> 3) * 8);
            char_pos = (x - 112) >> 3;
            axis_sel = 2'd0;
        end else if (y >= 194 && y < 202 && x >= 112 && x < 112 + 14*8) begin
            dyn_ty = 194;
            dyn_tx = 112 + (((x - 112) >> 3) * 8);
            char_pos = (x - 112) >> 3;
            axis_sel = 2'd1;
        end else if (y >= 294 && y < 302 && x >= 112 && x < 112 + 14*8) begin
            dyn_ty = 294;
            dyn_tx = 112 + (((x - 112) >> 3) * 8);
            char_pos = (x - 112) >> 3;
            axis_sel = 2'd2;
        end

        if ((y >= 94 && y < 102 && x >= 112 && x < 112 + 14*8) ||
            (y >= 194 && y < 202 && x >= 112 && x < 112 + 14*8) ||
            (y >= 294 && y < 302 && x >= 112 && x < 112 + 14*8)) begin
            case (char_pos)
                0: dyn_code = axis_label_char(axis_sel);
                1: dyn_code = " ";
                2: dyn_code = "A";
                3: dyn_code = "X";
                4: dyn_code = "I";
                5: dyn_code = "S";
                6: dyn_code = ":";
                7: dyn_code = " ";
                8: dyn_code = axis_sign_char(axis_sel);
                9: dyn_code = axis_digit_ascii(axis_sel, 0);
                10: dyn_code = ".";
                11: dyn_code = axis_digit_ascii(axis_sel, 1);
                12: dyn_code = axis_digit_ascii(axis_sel, 2);
                13: dyn_code = "g";
                default: dyn_code = " ";
            endcase
        end else if (y >= 416 && y < 424 && x >= 192 && x < 192 + 32*8) begin
            dyn_ty = 416;
            dyn_tx = 192 + (((x - 192) >> 3) * 8);
            char_pos = (x - 192) >> 3;
            dyn_code = footer_char(char_pos);
        end
    end

    wire border = (x == 40 || x == 600 || y == 48 || y == 450) &&
                  (x >= 40 && x <= 600 && y >= 48 && y <= 450);

    // Small scale tick marks aligned with -2g, -1g, 0, +1g, and +2g.
    wire scale_ticks = ((x == BAR_LEFT) || (x == 10'd200) ||
                        (x == BAR_CENTER) || (x == 10'd440) ||
                        (x == BAR_RIGHT)) && (y >= 74 && y < 84);

    wire x_track = (y >= 122 && y < 156 && x >= BAR_LEFT && x <= BAR_RIGHT);
    wire y_track = (y >= 222 && y < 256 && x >= BAR_LEFT && x <= BAR_RIGHT);
    wire z_track = (y >= 322 && y < 356 && x >= BAR_LEFT && x <= BAR_RIGHT);

    wire x_bar_pos = (!x_neg) && (y >= 126 && y < 152) &&
                     (x >= BAR_CENTER) && (x < BAR_CENTER + x_len);
    wire x_bar_neg = (x_neg) && (y >= 126 && y < 152) &&
                     (x < BAR_CENTER) && (x >= BAR_CENTER - x_len);

    wire y_bar_pos = (!y_neg) && (y >= 226 && y < 252) &&
                     (x >= BAR_CENTER) && (x < BAR_CENTER + y_len);
    wire y_bar_neg = (y_neg) && (y >= 226 && y < 252) &&
                     (x < BAR_CENTER) && (x >= BAR_CENTER - y_len);

    wire z_bar_pos = (!z_neg) && (y >= 326 && y < 352) &&
                     (x >= BAR_CENTER) && (x < BAR_CENTER + z_len);
    wire z_bar_neg = (z_neg) && (y >= 326 && y < 352) &&
                     (x < BAR_CENTER) && (x >= BAR_CENTER - z_len);

    wire center_line = ((x >= BAR_CENTER-1) && (x <= BAR_CENTER+1)) &&
                       ((y >= 114 && y < 164) ||
                        (y >= 214 && y < 264) ||
                        (y >= 314 && y < 364));

    always @(*) begin
        rgb = C_BLACK;

        if (!video_on)
            rgb = C_BLACK;
        else if (border)
            rgb = C_CYAN;
        else if (title_pix)
            rgb = C_CYAN;
        else if (dyn_pix) begin
            if (y >= 94 && y < 102)
                rgb = C_RED;
            else if (y >= 194 && y < 202)
                rgb = C_YELL;
            else if (y >= 294 && y < 302)
                rgb = C_GREEN;
            else if (y >= 416 && y < 424)
                rgb = data_valid ? C_GREEN : C_WHITE;
            else
                rgb = C_WHITE;
        end else if (scale_ticks)
            rgb = C_WHITE;
        else if (center_line)
            rgb = C_WHITE;
        else if (x_bar_pos || x_bar_neg)
            rgb = C_RED;
        else if (y_bar_pos || y_bar_neg)
            rgb = C_YELL;
        else if (z_bar_pos || z_bar_neg)
            rgb = C_GREEN;
        else if (x_track || y_track || z_track)
            rgb = C_DGRAY;
        else
            rgb = C_BLACK;
    end

endmodule

