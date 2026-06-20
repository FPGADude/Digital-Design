`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Module: text_renderer
// -----------------------------------------------------------------------------
// Purpose:
//   Draws the countdown digits that appear beside the orange DON'T WALK hand.
//
//   The base graphics and pedestrian icons are handled by pixel_renderer.sv.
//   This module only asserts text_on when the current pixel belongs to one of
//   the countdown digits. vga_display_controller.sv then overlays text_rgb on
//   top of the scene whenever text_on is high.
//
// Notes:
//   - The countdown is displayed only during the blinking DON'T WALK states.
//   - Digits blink in sync with the hand icon by using the shared blink_on signal.
//   - The digit drawing is a small seven-segment style renderer built from
//     rectangles, so no ROM/font memory is required.
// -----------------------------------------------------------------------------

module text_renderer (
    input  logic [9:0] pix_x,
    input  logic [9:0] pix_y,
    input  logic       main_count_active,
    input  logic       cross_count_active,
    input  logic [3:0] main_count_digit,
    input  logic [3:0] cross_count_digit,
    input  logic       blink_on,
    output logic       text_on,
    output logic [11:0] rgb
);

    // Countdown digits use the same orange color as the DON'T WALK hand.
    localparam logic [11:0] C_ORANGE = 12'hF80;

    // Basic rectangle test used by the seven-segment digit renderer.
    // Returns 1 when the current pixel is inside the inclusive rectangle.
    function automatic logic in_rect(input int x0, input int y0, input int x1, input int y1);
        return (pix_x >= x0) && (pix_x <= x1) && (pix_y >= y0) && (pix_y <= y1);
    endfunction

    // Small 7-segment digit for the pedestrian signal boxes.
    // The digit is drawn using seven rectangular segments:
    //
    //       a
    //      ---
    //   f | g | b
    //      ---
    //   e |   | c
    //      ---
    //       d
    //
    // The case statement turns each numeric digit into its segment pattern.
    // Width about 14 px, height about 20 px.
    function automatic logic seg_digit_small(input int x0, input int y0, input logic [3:0] digit);
        logic [6:0] seg;
        logic a,b,c,d,e,f,g;
        begin
            unique case (digit)
                4'd0: seg = 7'b1111110;
                4'd1: seg = 7'b0110000;
                4'd2: seg = 7'b1101101;
                4'd3: seg = 7'b1111001;
                4'd4: seg = 7'b0110011;
                4'd5: seg = 7'b1011011;
                4'd6: seg = 7'b1011111;
                4'd7: seg = 7'b1110000;
                4'd8: seg = 7'b1111111;
                4'd9: seg = 7'b1111011;
                default: seg = 7'b0000000;
            endcase

            a = seg[6] && in_rect(x0+3,  y0+0,  x0+13, y0+2);
            b = seg[5] && in_rect(x0+13, y0+3,  x0+15, y0+9);
            c = seg[4] && in_rect(x0+13, y0+12, x0+15, y0+18);
            d = seg[3] && in_rect(x0+3,  y0+18, x0+13, y0+20);
            e = seg[2] && in_rect(x0+0,  y0+12, x0+2,  y0+18);
            f = seg[1] && in_rect(x0+0,  y0+3,  x0+2,  y0+9);
            g = seg[0] && in_rect(x0+3,  y0+9,  x0+13, y0+11);

            return a || b || c || d || e || f || g;
        end
    endfunction

    // Combinational text overlay logic.
    // Default is text_on = 0, meaning the VGA controller will show the base scene.
    // When a countdown digit pixel is active, text_on becomes 1 and the VGA
    // controller replaces the scene color with text_rgb.
    always_comb begin
        text_on = 1'b0;
        rgb     = C_ORANGE;

        // Countdown digits appear only during the blinking DON'T WALK phase.
        // They blink in sync with the hand icon.
        if (blink_on) begin
            // Main pedestrian timer digits: left and right crosswalk pairs.
            if (main_count_active &&
                (seg_digit_small(127, 104, main_count_digit) ||
                 seg_digit_small(127, 388, main_count_digit) ||
                 seg_digit_small(497, 104, main_count_digit) ||
                 seg_digit_small(497, 388, main_count_digit))) begin
                text_on = 1'b1;
            end

            // Cross pedestrian timer digits: top and bottom crosswalk pairs.
            if (cross_count_active &&
                (seg_digit_small(185,  90, cross_count_digit) ||
                 seg_digit_small(441,  90, cross_count_digit) ||
                 seg_digit_small(185, 404, cross_count_digit) ||
                 seg_digit_small(441, 404, cross_count_digit))) begin
                text_on = 1'b1;
            end
        end
    end

endmodule


