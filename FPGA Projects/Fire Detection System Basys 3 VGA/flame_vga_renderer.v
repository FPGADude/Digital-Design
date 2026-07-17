`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA Renderer for the Flame Detection System
//
// Screen states:
//   CLEAR      - green status panel
//   VERIFYING  - yellow status panel while the 50 ms filter is active
//   ALARM      - red flashing alarm panel
//////////////////////////////////////////////////////////////////////////////////

module flame_vga_renderer (
    input  wire        clk,
    input  wire        video_on,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire        flame_raw_sync,
    input  wire        flame_detected,
    input  wire        alarm_active,
    input  wire [15:0] detection_count,
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,

    // High only during the bright half of the flashing alarm cycle.
    // The top module uses this same signal to control the active buzzer,
    // keeping the sound exactly synchronized with the red VGA flashing.
    output wire        alarm_flash
);

    reg [25:0] flash_counter;
    wire flash_phase = flash_counter[25];

    // The buzzer is enabled only while the alarm is latched and the VGA
    // renderer is in the bright half of its red flashing cycle.
    assign alarm_flash = alarm_active && flash_phase;

    always @(posedge clk)
        flash_counter <= flash_counter + 1'b1;

    // Text engine signals
    reg        text_enable;
    reg [7:0]  text_ascii;
    reg [3:0]  text_r, text_g, text_b;
    wire [7:0] font_pixels;

    font_rom_8x16 font (
        .ascii(text_ascii),
        .row(pixel_y[3:0]),
        .pixels(font_pixels)
    );

    wire text_pixel = text_enable && font_pixels[7 - pixel_x[2:0]];

    // Character coordinates
    wire [6:0] char_x = pixel_x[9:3];
    wire [4:0] char_y = pixel_y[8:4];

    // Convert one hexadecimal digit to ASCII
    function [7:0] hex_ascii;
        input [3:0] nibble;
        begin
            if (nibble < 10)
                hex_ascii = 8'h30 + nibble;
            else
                hex_ascii = 8'h41 + (nibble - 10);
        end
    endfunction

    // Helper for strings placed directly by character position
    always @(*) begin
        text_enable = 1'b0;
        text_ascii  = 8'h20;
        text_r = 4'hF;
        text_g = 4'hF;
        text_b = 4'hF;

        // Title: FLAME DETECTION SYSTEM
        if (char_y == 3 && char_x >= 29 && char_x <= 50) begin
            text_enable = 1'b1;
            case (char_x - 29)
                0:text_ascii="F";1:text_ascii="L";2:text_ascii="A";3:text_ascii="M";
                4:text_ascii="E";5:text_ascii=" ";6:text_ascii="D";7:text_ascii="E";
                8:text_ascii="T";9:text_ascii="E";10:text_ascii="C";11:text_ascii="T";
                12:text_ascii="I";13:text_ascii="O";14:text_ascii="N";15:text_ascii=" ";
                16:text_ascii="S";17:text_ascii="Y";18:text_ascii="S";19:text_ascii="T";
                20:text_ascii="E";21:text_ascii="M";
            endcase
        end

        // STATUS:
        else if (char_y == 9 && char_x >= 16 && char_x <= 22) begin
            text_enable = 1'b1;
            case (char_x - 16)
                0:text_ascii="S";1:text_ascii="T";2:text_ascii="A";3:text_ascii="T";
                4:text_ascii="U";5:text_ascii="S";6:text_ascii=":";
            endcase
        end

        // Status word
        else if (char_y == 9 && char_x >= 26 && char_x <= 39) begin
            text_enable = 1'b1;

            if (alarm_active) begin
                text_r = 4'hF; text_g = 4'hF; text_b = 4'hF;
                case (char_x - 26)
                    0:text_ascii="F";1:text_ascii="L";2:text_ascii="A";
                    3:text_ascii="M";4:text_ascii="E";5:text_ascii=" ";
                    6:text_ascii="D";7:text_ascii="E";8:text_ascii="T";
                    9:text_ascii="E";10:text_ascii="C";11:text_ascii="T";
                    12:text_ascii="E";13:text_ascii="D";
                    default:text_ascii=" ";
                endcase
            end
            else if (flame_raw_sync && !flame_detected) begin
                text_r = 4'hF; text_g = 4'hF; text_b = 4'h0;
                case (char_x - 26)
                    0:text_ascii="V";1:text_ascii="E";2:text_ascii="R";
                    3:text_ascii="I";4:text_ascii="F";5:text_ascii="Y";
                    6:text_ascii="I";7:text_ascii="N";8:text_ascii="G";
                    default:text_ascii=" ";
                endcase
            end
            else begin
                text_r = 4'h0; text_g = 4'hF; text_b = 4'h0;
                case (char_x - 26)
                    0:text_ascii="S";1:text_ascii="Y";2:text_ascii="S";
                    3:text_ascii="T";4:text_ascii="E";5:text_ascii="M";
                    6:text_ascii=" ";7:text_ascii="C";8:text_ascii="L";
                    9:text_ascii="E";10:text_ascii="A";11:text_ascii="R";
                    default:text_ascii=" ";
                endcase
            end
        end

        // SENSOR:
        else if (char_y == 14 && char_x >= 16 && char_x <= 22) begin
            text_enable = 1'b1;
            case (char_x - 16)
                0:text_ascii="S";1:text_ascii="E";2:text_ascii="N";3:text_ascii="S";
                4:text_ascii="O";5:text_ascii="R";6:text_ascii=":";
            endcase
        end

        // ACTIVE / IDLE
        else if (char_y == 14 && char_x >= 26 && char_x <= 31) begin
            text_enable = 1'b1;
            if (flame_raw_sync) begin
                text_r=4'hF; text_g=4'h8; text_b=4'h0;
                case (char_x - 26)
                    0:text_ascii="A";1:text_ascii="C";2:text_ascii="T";
                    3:text_ascii="I";4:text_ascii="V";5:text_ascii="E";
                endcase
            end
            else begin
                text_r=4'h0; text_g=4'hF; text_b=4'hF;
                case (char_x - 26)
                    0:text_ascii="I";1:text_ascii="D";2:text_ascii="L";
                    3:text_ascii="E";default:text_ascii=" ";
                endcase
            end
        end

        // DETECTIONS:
        else if (char_y == 19 && char_x >= 16 && char_x <= 26) begin
            text_enable = 1'b1;
            case (char_x - 16)
                0:text_ascii="D";1:text_ascii="E";2:text_ascii="T";3:text_ascii="E";
                4:text_ascii="C";5:text_ascii="T";6:text_ascii="I";7:text_ascii="O";
                8:text_ascii="N";9:text_ascii="S";10:text_ascii=":";
            endcase
        end

        // Four hex count digits
        else if (char_y == 19 && char_x >= 30 && char_x <= 33) begin
            text_enable = 1'b1;
            case (char_x)
                30:text_ascii = hex_ascii(detection_count[15:12]);
                31:text_ascii = hex_ascii(detection_count[11:8]);
                32:text_ascii = hex_ascii(detection_count[7:4]);
                33:text_ascii = hex_ascii(detection_count[3:0]);
            endcase
        end

        // Instruction line: PRESS BTNC TO ACKNOWLEDGE
        else if (char_y == 27 && char_x >= 27 && char_x <= 51) begin
            text_enable = 1'b1;
            text_r=4'hA; text_g=4'hA; text_b=4'hA;
            case (char_x - 27)
                0:text_ascii="P";1:text_ascii="R";2:text_ascii="E";3:text_ascii="S";
                4:text_ascii="S";5:text_ascii=" ";6:text_ascii="B";7:text_ascii="T";
                8:text_ascii="N";9:text_ascii="C";10:text_ascii=" ";11:text_ascii="T";
                12:text_ascii="O";13:text_ascii=" ";14:text_ascii="A";15:text_ascii="C";
                16:text_ascii="K";17:text_ascii="N";18:text_ascii="O";19:text_ascii="W";
                20:text_ascii="L";21:text_ascii="E";22:text_ascii="D";23:text_ascii="G";
                24:text_ascii="E";
            endcase
        end
    end

    // Main graphics and text compositing
    always @(*) begin
        vga_r = 4'h0;
        vga_g = 4'h0;
        vga_b = 4'h0;

        if (video_on) begin
            // Dark background
            vga_r = 4'h1;
            vga_g = 4'h1;
            vga_b = 4'h2;

            // Header bar
            if (pixel_y >= 24 && pixel_y < 80) begin
                vga_r = 4'h1;
                vga_g = 4'h3;
                vga_b = 4'h6;
            end

            // Main status panel
            if (pixel_x >= 96 && pixel_x < 544 &&
                pixel_y >= 112 && pixel_y < 368) begin

                if (alarm_active) begin
                    if (flash_phase) begin
                        vga_r = 4'hA; vga_g = 4'h0; vga_b = 4'h0;
                    end
                    else begin
                        vga_r = 4'h4; vga_g = 4'h0; vga_b = 4'h0;
                    end
                end
                else if (flame_raw_sync && !flame_detected) begin
                    vga_r = 4'h5; vga_g = 4'h4; vga_b = 4'h0;
                end
                else begin
                    vga_r = 4'h0; vga_g = 4'h4; vga_b = 4'h2;
                end
            end

            // Panel border
            if (((pixel_x >= 94 && pixel_x < 546) &&
                 ((pixel_y >= 110 && pixel_y < 114) ||
                  (pixel_y >= 366 && pixel_y < 370))) ||
                ((pixel_y >= 110 && pixel_y < 370) &&
                 ((pixel_x >= 94 && pixel_x < 98) ||
                  (pixel_x >= 542 && pixel_x < 546)))) begin
                vga_r = 4'hC; vga_g = 4'hC; vga_b = 4'hC;
            end

            // Text has highest priority
            if (text_pixel) begin
                vga_r = text_r;
                vga_g = text_g;
                vga_b = text_b;
            end
        end
    end

endmodule



