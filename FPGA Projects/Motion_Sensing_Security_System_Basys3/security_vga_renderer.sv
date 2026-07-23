`timescale 1ns / 1ps

// ============================================================================
// Module: security_vga_renderer
// Project: FPGA Motion Security System
//
// Purpose:
//   Produces the complete 12-bit RGB security-console image for a 640x480 VGA
//   display.
//
// Display elements:
//   - outer cyan frame
//   - blue title panel
//   - state-dependent central status panel
//   - PIR motion-zone bar
//   - warm-up and arming countdowns
//   - live PIR status
//   - hexadecimal intrusion count
//   - state-dependent button instructions
//
// Text rendering:
//   Six 32-character text rows are selected from the current system state.
//   ASCII characters are converted to 8x8 glyph rows by font_rom.
//   Each font pixel is doubled horizontally and vertically, producing a
//   readable 16x16 character cell.
//
// Color behavior:
//   WARMUP, DISARMED, ARMING, ARMED, and ALARM use different panel colors.
//   The alarm panel blinks between two red intensities.
// ============================================================================
module security_vga_renderer (
    input  logic        clk,
    input  logic [9:0]  pixel_x,
    input  logic [9:0]  pixel_y,
    input  logic        video_on,

    input  logic [2:0]  system_state,
    input  logic        pir_level,
    input  logic [5:0]  warmup_seconds,
    input  logic [2:0]  arming_seconds,
    input  logic [15:0] intrusion_count,
    input  logic        alarm_muted,

    output logic [11:0] rgb
);

    // State encodings match security_fsm.
    localparam logic [2:0]
        ST_WARMUP   = 3'd0,
        ST_DISARMED = 3'd1,
        ST_ARMING   = 3'd2,
        ST_ARMED    = 3'd3,
        ST_ALARM    = 3'd4;

    // Text-rendering pipeline signals.
    logic [255:0] selected_line;
    logic [3:0]   text_row;
    logic [5:0]   text_col;
    logic [7:0]   char_code;
    logic [2:0]   font_row;
    logic [7:0]   font_pixels;
    logic         text_pixel;

    // Slow visual blink source for the alarm panel.
    logic [23:0] blink_counter = '0;
    logic blink;

    assign blink = blink_counter[23];

    always_ff @(posedge clk) begin
        blink_counter <= blink_counter + 1'b1;
    end

    // Convert a hexadecimal nibble to its ASCII character.
    function automatic logic [7:0] hex_ascii(input logic [3:0] value);
        if (value < 10)
            hex_ascii = "0" + value;
        else
            hex_ascii = "A" + value - 10;
    endfunction

    // Convert a 0-63 value into decimal tens and ones characters.
    function automatic logic [7:0] tens_ascii(input logic [5:0] value);
        tens_ascii = "0" + ((value / 10) % 10);
    endfunction

    function automatic logic [7:0] ones_ascii(input logic [5:0] value);
        ones_ascii = "0" + (value % 10);
    endfunction

    // Build one of six 32-character rows for the current system state.
    always_comb begin
        selected_line = "                                ";

        case (text_row)

            4'd0:
                selected_line = " FPGA MOTION SECURITY SYSTEM    ";

            4'd1: begin
                case (system_state)
                    ST_WARMUP:   selected_line = "       PIR SENSOR WARMUP        ";
                    ST_DISARMED: selected_line = "          SYSTEM READY          ";
                    ST_ARMING:   selected_line = "         SYSTEM ARMING          ";
                    ST_ARMED:    selected_line = "          SYSTEM ARMED          ";
                    ST_ALARM:    selected_line = "      INTRUSION DETECTED        ";
                    default:     selected_line = "                                ";
                endcase
            end

            4'd2: begin
                case (system_state)
                    ST_WARMUP:   selected_line = "      PLEASE WAIT 00 SECONDS    ";
                    ST_DISARMED: selected_line = "       STATUS: DISARMED         ";
                    ST_ARMING:   selected_line = "       CLEAR THE AREA: 0        ";
                    ST_ARMED:    selected_line = "        STATUS: SECURE          ";
                    ST_ALARM:    selected_line = "         STATUS: ALARM          ";
                    default:     selected_line = "                                ";
                endcase

                if (system_state == ST_WARMUP) begin
                    selected_line[8*(32-18)-1 -: 8] = tens_ascii(warmup_seconds);
                    selected_line[8*(32-19)-1 -: 8] = ones_ascii(warmup_seconds);
                end

                if (system_state == ST_ARMING) begin
                    selected_line[8*(32-23)-1 -: 8] = "0" + arming_seconds;
                end
            end

            4'd3: begin
                if (system_state == ST_WARMUP)
                    selected_line = " PIR OUTPUT IGNORED UNTIL READY ";
                else if (pir_level)
                    selected_line = "       SENSOR: MOTION           ";
                else
                    selected_line = "       SENSOR: CLEAR            ";
            end

            4'd4: begin
                selected_line = "       INTRUSIONS: 0000         ";
                selected_line[8*(32-19)-1 -: 8] = hex_ascii(intrusion_count[15:12]);
                selected_line[8*(32-20)-1 -: 8] = hex_ascii(intrusion_count[11:8]);
                selected_line[8*(32-21)-1 -: 8] = hex_ascii(intrusion_count[7:4]);
                selected_line[8*(32-22)-1 -: 8] = hex_ascii(intrusion_count[3:0]);
            end

            4'd5: begin
                case (system_state)
                    ST_WARMUP:   selected_line = "   STABILIZING... BTNR = RESET  ";
                    ST_DISARMED: selected_line = "  BTNC = ARM    BTNR = RESET   ";
                    ST_ARMING:   selected_line = "  BTND = CANCEL  BTNR = RESET  ";
                    ST_ARMED:    selected_line = "  BTND = DISARM  BTNR = RESET  ";
                    ST_ALARM:
                        selected_line = alarm_muted ?
                            "BTNU=UNMUTE BTND=DISARM BTNR=RST" :
                            " BTNU=MUTE BTND=DISARM BTNR=RST";
                    default:
                        selected_line = "                                ";
                endcase
            end

            default:
                selected_line = "                                ";

        endcase
    end

    // ------------------------------------------------------------------------
    // Text geometry and character addressing
    // ------------------------------------------------------------------------

    // Text rows use a 16x16 cell: 8x8 font scaled by two.
    logic in_text_row;
    logic [9:0] local_x;
    logic [9:0] local_y;

    always_comb begin
        in_text_row = 1'b0;
        text_row    = 4'd0;
        local_y     = 10'd0;

        if ((pixel_y >= 42) && (pixel_y < 58)) begin
            in_text_row = 1'b1;
            text_row    = 4'd0;
            local_y     = pixel_y - 42;
        end
        else if ((pixel_y >= 112) && (pixel_y < 128)) begin
            in_text_row = 1'b1;
            text_row    = 4'd1;
            local_y     = pixel_y - 112;
        end
        else if ((pixel_y >= 160) && (pixel_y < 176)) begin
            in_text_row = 1'b1;
            text_row    = 4'd2;
            local_y     = pixel_y - 160;
        end
        else if ((pixel_y >= 208) && (pixel_y < 224)) begin
            in_text_row = 1'b1;
            text_row    = 4'd3;
            local_y     = pixel_y - 208;
        end
        else if ((pixel_y >= 300) && (pixel_y < 316)) begin
            in_text_row = 1'b1;
            text_row    = 4'd4;
            local_y     = pixel_y - 300;
        end
        else if ((pixel_y >= 424) && (pixel_y < 440)) begin
            in_text_row = 1'b1;
            text_row    = 4'd5;
            local_y     = pixel_y - 424;
        end
    end

    always_comb begin
        local_x    = pixel_x - 64;
        text_col   = local_x[9:4];
        char_code  = 8'h20;
        font_row   = local_y[3:1];
        text_pixel = 1'b0;

        if (in_text_row &&
            (pixel_x >= 64) &&
            (pixel_x < 576) &&
            (text_col < 32)) begin

            char_code = selected_line[255 - text_col*8 -: 8];

            if (local_x[3:1] < 8)
                text_pixel = font_pixels[7 - local_x[3:1]];
        end
    end

    // Font ROM returns the selected 8-pixel glyph row.
    font_rom u_font (
        .char_code (char_code),
        .row       (font_row),
        .pixels    (font_pixels)
    );

    // ------------------------------------------------------------------------
    // Geometric regions used to draw the console background
    // ------------------------------------------------------------------------

    logic outer_frame;
    logic title_panel;
    logic state_panel;
    logic motion_bar;
    logic motion_box;

    always_comb begin
        outer_frame =
            ((pixel_x >= 24) && (pixel_x < 616) &&
             ((pixel_y >= 16) && (pixel_y < 20))) ||
            ((pixel_x >= 24) && (pixel_x < 616) &&
             ((pixel_y >= 460) && (pixel_y < 464))) ||
            ((pixel_y >= 16) && (pixel_y < 464) &&
             ((pixel_x >= 24) && (pixel_x < 28))) ||
            ((pixel_y >= 16) && (pixel_y < 464) &&
             ((pixel_x >= 612) && (pixel_x < 616)));

        title_panel =
            (pixel_x >= 32) && (pixel_x < 608) &&
            (pixel_y >= 26) && (pixel_y < 74);

        state_panel =
            (pixel_x >= 72) && (pixel_x < 568) &&
            (pixel_y >= 94) && (pixel_y < 242);

        motion_bar =
            (pixel_x >= 96) && (pixel_x < 544) &&
            (pixel_y >= 250) && (pixel_y < 286);

        motion_box =
            pir_level &&
            (pixel_x >= 292) && (pixel_x < 348) &&
            (pixel_y >= 246) && (pixel_y < 290);
    end

    // Apply drawing priority: background, frame, panels, motion bar, then text.
    always_comb begin
        if (!video_on) begin
            rgb = 12'h000;
        end
        else begin
            rgb = 12'h012;

            if (outer_frame)
                rgb = 12'h4CF;

            if (title_panel)
                rgb = 12'h036;

            if (state_panel) begin
                case (system_state)
                    ST_WARMUP:   rgb = 12'h321;
                    ST_DISARMED: rgb = 12'h123;
                    ST_ARMING:   rgb = 12'h431;
                    ST_ARMED:    rgb = 12'h032;
                    ST_ALARM:    rgb = blink ? 12'h700 : 12'h300;
                    default:     rgb = 12'h111;
                endcase
            end

            if (motion_bar) begin
                if (system_state == ST_ALARM)
                    rgb = 12'hF20;
                else if (pir_level)
                    rgb = 12'hFA0;
                else if (system_state == ST_ARMED)
                    rgb = 12'h0B4;
                else
                    rgb = 12'h246;
            end

            if (motion_box)
                rgb = 12'hFFF;

            if (text_pixel)
                rgb = 12'hFFF;
        end
    end

endmodule
