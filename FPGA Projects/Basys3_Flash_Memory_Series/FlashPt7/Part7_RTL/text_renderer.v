`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - Flash-Backed Text Renderer
//
// Character codes are selected by RTL, but glyph PIXELS are fetched from the
// 4096-byte font BRAM loaded from QSPI flash.
//
// Font format:
//   address = (ASCII << 4) + glyph_row
//   16 bytes per character
//   bit 7 = left-most pixel
// ============================================================================
module text_renderer(
    input  wire       font_ready,
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire [7:0] font_data,

    output reg [11:0] font_addr,
    output reg        text_on,
    output reg [11:0] text_rgb
);

    reg [7:0] char_code;
    reg [3:0] glyph_row;
    reg [2:0] glyph_col;
    reg       selected;

    integer cx;

    always @(*) begin
        char_code = 8'h20;
        glyph_row = 4'd0;
        glyph_col = 3'd0;
        selected  = 1'b0;
        text_rgb  = 12'hFFF;
        cx = 0;

        // ------------------------------------------------------------
        // FPGA DISCOVERY
        // 14 chars, 2x scale -> 16x32 pixels per character.
        // Fits inside the existing white top panel.
        // ------------------------------------------------------------
        if (font_ready &&
            pixel_x >= 208 && pixel_x < 432 &&
            pixel_y >= 49  && pixel_y < 81) begin

            cx        = (pixel_x - 208) >> 4;
            glyph_col = ((pixel_x - 208) >> 1) & 3'b111;
            glyph_row = (pixel_y - 49) >> 1;
            selected  = 1'b1;
            text_rgb  = 12'h013; // dark blue on white

            case(cx)
                 0: char_code = "F";
                 1: char_code = "P";
                 2: char_code = "G";
                 3: char_code = "A";
                 4: char_code = " ";
                 5: char_code = "D";
                 6: char_code = "I";
                 7: char_code = "S";
                 8: char_code = "C";
                 9: char_code = "O";
                10: char_code = "V";
                11: char_code = "E";
                12: char_code = "R";
                13: char_code = "Y";
                default: char_code = " ";
            endcase
        end

        // ------------------------------------------------------------
        // THANKS FOR WATCHING
        //
        // The finished FPGA project doubles as the video's closing screen.
        // ------------------------------------------------------------
        else if (font_ready &&
                 pixel_x >= 244 && pixel_x < 396 &&
                 pixel_y >= 292 && pixel_y < 308) begin

            cx        = (pixel_x - 244) >> 3;
            glyph_col = (pixel_x - 244) & 3'b111;
            glyph_row = pixel_y - 292;
            selected  = 1'b1;
            text_rgb  = 12'hFFF;

            case (cx)
                 0: char_code = "T";
                 1: char_code = "H";
                 2: char_code = "A";
                 3: char_code = "N";
                 4: char_code = "K";
                 5: char_code = "S";
                 6: char_code = " ";
                 7: char_code = "F";
                 8: char_code = "O";
                 9: char_code = "R";
                10: char_code = " ";
                11: char_code = "W";
                12: char_code = "A";
                13: char_code = "T";
                14: char_code = "C";
                15: char_code = "H";
                16: char_code = "I";
                17: char_code = "N";
                18: char_code = "G";
                default: char_code = " ";
            endcase
        end

        // ------------------------------------------------------------
        // JEDEC ID: C2 20 16
        // ------------------------------------------------------------
        else if (font_ready &&
                 pixel_x >= 248 && pixel_x < 392 &&
                 pixel_y >= 334 && pixel_y < 350) begin

            cx        = (pixel_x - 248) >> 3;
            glyph_col = (pixel_x - 248) & 3'b111;
            glyph_row = pixel_y - 334;
            selected  = 1'b1;
            text_rgb  = 12'hFFF;

            case(cx)
                 0: char_code="J";  1: char_code="E";
                 2: char_code="D";  3: char_code="E";
                 4: char_code="C";  5: char_code=" ";
                 6: char_code="I";  7: char_code="D";
                 8: char_code=":";  9: char_code=" ";
                10: char_code="C"; 11: char_code="2";
                12: char_code=" "; 13: char_code="2";
                14: char_code="0"; 15: char_code=" ";
                16: char_code="1"; 17: char_code="6";
                default: char_code=" ";
            endcase
        end

        // ------------------------------------------------------------
        // LIKE AND SUBSCRIBE
        //
        // Green provides a clear call-to-action while matching the existing
        // status/accent color used by the VGA presentation.
        // ------------------------------------------------------------
        else if (font_ready &&
                 pixel_x >= 248 && pixel_x < 392 &&
                 pixel_y >= 402 && pixel_y < 418) begin

            cx        = (pixel_x - 248) >> 3;
            glyph_col = (pixel_x - 248) & 3'b111;
            glyph_row = pixel_y - 402;
            selected  = 1'b1;
            text_rgb  = 12'h0F0;

            case (cx)
                 0: char_code = "L";
                 1: char_code = "I";
                 2: char_code = "K";
                 3: char_code = "E";
                 4: char_code = " ";
                 5: char_code = "A";
                 6: char_code = "N";
                 7: char_code = "D";
                 8: char_code = " ";
                 9: char_code = "S";
                10: char_code = "U";
                11: char_code = "B";
                12: char_code = "S";
                13: char_code = "C";
                14: char_code = "R";
                15: char_code = "I";
                16: char_code = "B";
                17: char_code = "E";
                default: char_code = " ";
            endcase
        end

        // Synchronous BRAM receives this address continuously. VGA x/y remain
        // stable for four 100-MHz clocks per pixel, giving the BRAM read time
        // to settle well within each 25-MHz pixel interval.
        font_addr = {char_code, 4'b0000} + glyph_row;

        text_on = selected && font_data[3'd7 - glyph_col];
    end
endmodule
