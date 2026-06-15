`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: renderer
//
// Purpose:
//   Converts the current game state into a 12-bit RGB value for the VGA display.
//   This module is the real-time graphics engine for FPGA Frogger.
//
// Big idea:
//   The VGA timing module scans through every pixel coordinate. For each pixel,
//   renderer.v decides what should appear there: background, road, water, frog,
//   cars, logs, turtles, snake, homes, score digits, title screen, or game-over
//   screen. There is no framebuffer; every pixel color is generated directly from
//   coordinates and object state.
//
// Important design style:
//   Most drawing operations are small Verilog functions that answer yes/no
//   questions such as "is the current pixel inside this sprite?". These functions
//   synthesize into ordinary comparison and combinational logic.
//////////////////////////////////////////////////////////////////////////////////
module renderer(
    // From VGA Timing module
    input  wire video_on,
    // Current pixel coordinates
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,

    // From Game State module
    // Frog position
    input  wire [9:0] frog_x,
    input  wire [9:0] frog_y,

    // 13 cars
    input  wire signed [10:0] car0_x,   input wire [9:0] car0_y,
    input  wire signed [10:0] car1_x,   input wire [9:0] car1_y,
    input  wire signed [10:0] car2_x,   input wire [9:0] car2_y,
    input  wire signed [10:0] car3_x,   input wire [9:0] car3_y,
    input  wire signed [10:0] car4_x,   input wire [9:0] car4_y,
    input  wire signed [10:0] car5_x,   input wire [9:0] car5_y,
    input  wire signed [10:0] car6_x,   input wire [9:0] car6_y,
    input  wire signed [10:0] car7_x,   input wire [9:0] car7_y,
    input  wire signed [10:0] car8_x,   input wire [9:0] car8_y,
    input  wire signed [10:0] car9_x,   input wire [9:0] car9_y,
    input  wire signed [10:0] car10_x,  input wire [9:0] car10_y,
    input  wire signed [10:0] car11_x,  input wire [9:0] car11_y,
    input  wire signed [10:0] car12_x,  input wire [9:0] car12_y,

    // 12 logs
    input  wire signed [10:0] log0_x,   input wire [9:0] log0_y,
    input  wire signed [10:0] log1_x,   input wire [9:0] log1_y,
    input  wire signed [10:0] log2_x,   input wire [9:0] log2_y,
    input  wire signed [10:0] log3_x,   input wire [9:0] log3_y,
    input  wire signed [10:0] log4_x,   input wire [9:0] log4_y,
    input  wire signed [10:0] log5_x,   input wire [9:0] log5_y,
    input  wire signed [10:0] log6_x,   input wire [9:0] log6_y,
    input  wire signed [10:0] log7_x,   input wire [9:0] log7_y,
    input  wire signed [10:0] log8_x,   input wire [9:0] log8_y,
    input  wire signed [10:0] log9_x,   input wire [9:0] log9_y,
    input  wire signed [10:0] log10_x,  input wire [9:0] log10_y,
    input  wire signed [10:0] log11_x,  input wire [9:0] log11_y,

    // Turtle groups and periodic snake
    input  wire signed [10:0] turtle0_x, input wire [9:0] turtle0_y,
    input  wire signed [10:0] turtle1_x, input wire [9:0] turtle1_y,
    input  wire signed [10:0] turtle2_x, input wire [9:0] turtle2_y,
    input  wire [1:0] turtle_state,
    input  wire turtle_ripple_anim,
    input  wire signed [10:0] snake_x,  input wire [9:0] snake_y,
    input  wire snake_active,
    input  wire snake_anim,
    input  wire snake_dir,

    // Game State and UI signals
    input  wire title_active,
    input  wire input_mode,
    input  wire goal_flash_active,
    input  wire [4:0] goal_filled,
    input  wire [2:0] homes_filled_count,
    input  wire level_clear_active,
    input  wire death_flash_active,
    input  wire game_over_active,
    input  wire [2:0] lives,
    input  wire [16:0] score,

    output reg  [11:0] rgb
);

    // Colors
    localparam BLACK      = 12'h000;
    localparam GOAL_GREEN = 12'h0F0;
    localparam GOAL_FLASH = 12'hF0F;
    localparam WATER_BLUE = 12'h00F;
    localparam MEDIAN_GRN = 12'h0A0;
    localparam ROAD_GRAY  = 12'h666;
    localparam START_GRN  = 12'h0C0;
    localparam WHITE      = 12'hFFF;
    localparam CYAN       = 12'h0FF;
    localparam YELLOW     = 12'hFF0;
    localparam RED        = 12'hF00;
    localparam GAME_OVER  = 12'hF00;

    localparam FROG_CLR   = 12'h0F0;
    localparam FROG_DARK  = 12'h030;
    localparam LOG_CLR    = 12'h840;
    localparam LOG_DARK   = 12'h420;
    localparam TURTLE_CLR = 12'hC84;
    localparam TURTLE_WARN_CLR = 12'hED8;
    localparam TURTLE_DARK = 12'h742;
    localparam TURTLE_EDGE = 12'h963;
    localparam SNAKE_CLR  = 12'hFF0;
    localparam SNAKE_DARK = 12'h680;
    localparam WINDOW_CLR = 12'hBFF;
    localparam TIRE_CLR   = 12'h111;

    localparam CAR0_CLR   = 12'hF00;
    localparam CAR1_CLR   = 12'hF88;
    localparam CAR2_CLR   = 12'h0FF;
    localparam CAR3_CLR   = 12'h8FF;
    localparam CAR4_CLR   = 12'hF80;
    localparam CAR5_CLR   = 12'hFA0;
    localparam CAR6_CLR   = 12'hF0F;
    localparam CAR7_CLR   = 12'hA0F;
    localparam CAR8_CLR   = 12'h0F8;
    localparam CAR9_CLR   = 12'h08F;
    localparam CAR10_CLR  = 12'hFD0;
    localparam CAR11_CLR  = 12'hD44;
    localparam CAR12_CLR  = 12'h4DF;

    localparam FROG_W  = 24;
    localparam FROG_H  = 24;
    localparam CAR_W   = 48;
    localparam CAR_H   = 24;
    localparam LOG_S_W = 96;
    localparam LOG_L_W = 144;
    localparam LOG_H   = 24;
    localparam SCREEN_W = 640;
    localparam TURTLE_GROUP_W = 84;
    localparam TURTLE_H = 24;
    localparam SNAKE_W = 64;
    localparam SNAKE_H = 16;

    localparam TURTLE_VISIBLE = 2'd0;
    localparam TURTLE_WARN    = 2'd1;
    localparam TURTLE_DOWN    = 2'd2;

    reg [11:0] bg_rgb;
    reg road_dash_on;
    reg frog_on;
    reg frog_eye;
    reg car_window;
    reg car_tire;
    reg log_bark;

    reg car0_on, car1_on, car2_on, car3_on, car4_on, car5_on, car6_on;
    reg car7_on, car8_on, car9_on, car10_on, car11_on, car12_on;

    reg log0_on, log1_on, log2_on, log3_on, log4_on, log5_on;
    reg log6_on, log7_on, log8_on, log9_on, log10_on, log11_on;

    reg turtle0_on, turtle1_on, turtle2_on;
    reg turtle_eye;
    reg turtle_ripple;
    reg snake_on;
    reg snake_eye;

    reg title_logo_on;
    reg title_prompt_on;
    reg title_mode_on;
    reg title_panel_on;
    reg title_border_on;
    reg gameover_logo_on;
    reg final_label_on;
    reg homes_label_on;
    reg final_score_digit0_on;
    reg final_score_digit1_on;
    reg final_score_digit2_on;
    reg final_score_digit3_on;
    reg final_score_digit4_on;
    reg homes_count_digit_on;

    reg goal0_on, goal1_on, goal2_on, goal3_on, goal4_on;
    reg goal0_fill_on, goal1_fill_on, goal2_fill_on, goal3_fill_on, goal4_fill_on;

    reg life0_on, life1_on, life2_on, life3_on, life4_on;

    reg signed [10:0] pix_x_s;
    reg signed [10:0] pix_y_s;

    reg [3:0] score_ten_thousands;
    reg [3:0] score_thousands;
    reg [3:0] score_hundreds;
    reg [3:0] score_tens;
    reg [3:0] score_ones;

    reg score_digit0_on, score_digit1_on, score_digit2_on, score_digit3_on, score_digit4_on;

    // Function: seg_pattern
    //   Converts a decimal digit into a seven-segment-style bit pattern.
    //   The digit renderer uses this pattern to draw the score and final score
    //   using rectangular segments.
    function [6:0] seg_pattern;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: seg_pattern = 7'b1111110;
                4'd1: seg_pattern = 7'b0110000;
                4'd2: seg_pattern = 7'b1101101;
                4'd3: seg_pattern = 7'b1111001;
                4'd4: seg_pattern = 7'b0110011;
                4'd5: seg_pattern = 7'b1011011;
                4'd6: seg_pattern = 7'b1011111;
                4'd7: seg_pattern = 7'b1110000;
                4'd8: seg_pattern = 7'b1111111;
                4'd9: seg_pattern = 7'b1111011;
                default: seg_pattern = 7'b0000001;
            endcase
        end
    endfunction

    // Function: digit_pixel_on
    //   Draws one large decimal digit using a seven-segment layout.
    //   Returns 1 when the current VGA pixel falls on one of the active segments
    //   for the requested digit.
    function digit_pixel_on;
        input [3:0] digit;
        input [9:0] px;
        input [9:0] py;
        input [9:0] x0;
        input [9:0] y0;
        reg [6:0] seg;
        begin
            seg = seg_pattern(digit);
            digit_pixel_on = 1'b0;

            if ((px >= x0) && (px < x0 + 20) && (py >= y0) && (py < y0 + 32)) begin
                // a
                if (seg[6] && (py >= y0)      && (py < y0 + 4)  && (px >= x0 + 4)  && (px < x0 + 16))
                    digit_pixel_on = 1'b1;
                // b
                else if (seg[5] && (py >= y0 + 4)  && (py < y0 + 14) && (px >= x0 + 16) && (px < x0 + 20))
                    digit_pixel_on = 1'b1;
                // c
                else if (seg[4] && (py >= y0 + 18) && (py < y0 + 28) && (px >= x0 + 16) && (px < x0 + 20))
                    digit_pixel_on = 1'b1;
                // d
                else if (seg[3] && (py >= y0 + 28) && (py < y0 + 32) && (px >= x0 + 4)  && (px < x0 + 16))
                    digit_pixel_on = 1'b1;
                // e
                else if (seg[2] && (py >= y0 + 18) && (py < y0 + 28) && (px >= x0)      && (px < x0 + 4))
                    digit_pixel_on = 1'b1;
                // f
                else if (seg[1] && (py >= y0 + 4)  && (py < y0 + 14) && (px >= x0)      && (px < x0 + 4))
                    digit_pixel_on = 1'b1;
                // g
                else if (seg[0] && (py >= y0 + 14) && (py < y0 + 18) && (px >= x0 + 4)  && (px < x0 + 16))
                    digit_pixel_on = 1'b1;
            end
        end
    endfunction

    // Function: font5x7_row
    //   Tiny built-in 5x7 font ROM implemented as a case statement.
    //   Given a character and row number, returns the five pixels for that row.
    //   This is used for title, mode, score-label, and game-over text.
    function [4:0] font5x7_row;
        input [7:0] ch;
        input [2:0] row;
        begin
            case (ch)
                "A": case(row) 0:font5x7_row=5'b01110;1:font5x7_row=5'b10001;2:font5x7_row=5'b10001;3:font5x7_row=5'b11111;4:font5x7_row=5'b10001;5:font5x7_row=5'b10001;6:font5x7_row=5'b10001;default:font5x7_row=0; endcase
                "B": case(row) 0:font5x7_row=5'b11110;1:font5x7_row=5'b10001;2:font5x7_row=5'b10001;3:font5x7_row=5'b11110;4:font5x7_row=5'b10001;5:font5x7_row=5'b10001;6:font5x7_row=5'b11110;default:font5x7_row=0; endcase
                "C": case(row) 0:font5x7_row=5'b01111;1:font5x7_row=5'b10000;2:font5x7_row=5'b10000;3:font5x7_row=5'b10000;4:font5x7_row=5'b10000;5:font5x7_row=5'b10000;6:font5x7_row=5'b01111;default:font5x7_row=0; endcase
                "D": case(row) 0:font5x7_row=5'b11110;1:font5x7_row=5'b10001;2:font5x7_row=5'b10001;3:font5x7_row=5'b10001;4:font5x7_row=5'b10001;5:font5x7_row=5'b10001;6:font5x7_row=5'b11110;default:font5x7_row=0; endcase
                "E": case(row) 0:font5x7_row=5'b11111;1:font5x7_row=5'b10000;2:font5x7_row=5'b10000;3:font5x7_row=5'b11110;4:font5x7_row=5'b10000;5:font5x7_row=5'b10000;6:font5x7_row=5'b11111;default:font5x7_row=0; endcase
                "F": case(row) 0:font5x7_row=5'b11111;1:font5x7_row=5'b10000;2:font5x7_row=5'b10000;3:font5x7_row=5'b11110;4:font5x7_row=5'b10000;5:font5x7_row=5'b10000;6:font5x7_row=5'b10000;default:font5x7_row=0; endcase
                "G": case(row) 0:font5x7_row=5'b01111;1:font5x7_row=5'b10000;2:font5x7_row=5'b10000;3:font5x7_row=5'b10111;4:font5x7_row=5'b10001;5:font5x7_row=5'b10001;6:font5x7_row=5'b01110;default:font5x7_row=0; endcase
                "H": case(row) 0:font5x7_row=5'b10001;1:font5x7_row=5'b10001;2:font5x7_row=5'b10001;3:font5x7_row=5'b11111;4:font5x7_row=5'b10001;5:font5x7_row=5'b10001;6:font5x7_row=5'b10001;default:font5x7_row=0; endcase
                "I": case(row) 0:font5x7_row=5'b11111;1:font5x7_row=5'b00100;2:font5x7_row=5'b00100;3:font5x7_row=5'b00100;4:font5x7_row=5'b00100;5:font5x7_row=5'b00100;6:font5x7_row=5'b11111;default:font5x7_row=0; endcase
                "L": case(row) 0:font5x7_row=5'b10000;1:font5x7_row=5'b10000;2:font5x7_row=5'b10000;3:font5x7_row=5'b10000;4:font5x7_row=5'b10000;5:font5x7_row=5'b10000;6:font5x7_row=5'b11111;default:font5x7_row=0; endcase
                "M": case(row) 0:font5x7_row=5'b10001;1:font5x7_row=5'b11011;2:font5x7_row=5'b10101;3:font5x7_row=5'b10101;4:font5x7_row=5'b10001;5:font5x7_row=5'b10001;6:font5x7_row=5'b10001;default:font5x7_row=0; endcase
                "N": case(row) 0:font5x7_row=5'b10001;1:font5x7_row=5'b11001;2:font5x7_row=5'b10101;3:font5x7_row=5'b10011;4:font5x7_row=5'b10001;5:font5x7_row=5'b10001;6:font5x7_row=5'b10001;default:font5x7_row=0; endcase
                "O": case(row) 0:font5x7_row=5'b01110;1:font5x7_row=5'b10001;2:font5x7_row=5'b10001;3:font5x7_row=5'b10001;4:font5x7_row=5'b10001;5:font5x7_row=5'b10001;6:font5x7_row=5'b01110;default:font5x7_row=0; endcase
                "P": case(row) 0:font5x7_row=5'b11110;1:font5x7_row=5'b10001;2:font5x7_row=5'b10001;3:font5x7_row=5'b11110;4:font5x7_row=5'b10000;5:font5x7_row=5'b10000;6:font5x7_row=5'b10000;default:font5x7_row=0; endcase
                "R": case(row) 0:font5x7_row=5'b11110;1:font5x7_row=5'b10001;2:font5x7_row=5'b10001;3:font5x7_row=5'b11110;4:font5x7_row=5'b10100;5:font5x7_row=5'b10010;6:font5x7_row=5'b10001;default:font5x7_row=0; endcase
                "S": case(row) 0:font5x7_row=5'b01111;1:font5x7_row=5'b10000;2:font5x7_row=5'b10000;3:font5x7_row=5'b01110;4:font5x7_row=5'b00001;5:font5x7_row=5'b00001;6:font5x7_row=5'b11110;default:font5x7_row=0; endcase
                "T": case(row) 0:font5x7_row=5'b11111;1:font5x7_row=5'b00100;2:font5x7_row=5'b00100;3:font5x7_row=5'b00100;4:font5x7_row=5'b00100;5:font5x7_row=5'b00100;6:font5x7_row=5'b00100;default:font5x7_row=0; endcase
                "U": case(row) 0:font5x7_row=5'b10001;1:font5x7_row=5'b10001;2:font5x7_row=5'b10001;3:font5x7_row=5'b10001;4:font5x7_row=5'b10001;5:font5x7_row=5'b10001;6:font5x7_row=5'b01110;default:font5x7_row=0; endcase
                "V": case(row) 0:font5x7_row=5'b10001;1:font5x7_row=5'b10001;2:font5x7_row=5'b10001;3:font5x7_row=5'b10001;4:font5x7_row=5'b01010;5:font5x7_row=5'b01010;6:font5x7_row=5'b00100;default:font5x7_row=0; endcase
                "Y": case(row) 0:font5x7_row=5'b10001;1:font5x7_row=5'b10001;2:font5x7_row=5'b01010;3:font5x7_row=5'b00100;4:font5x7_row=5'b00100;5:font5x7_row=5'b00100;6:font5x7_row=5'b00100;default:font5x7_row=0; endcase
                default: font5x7_row = 5'b00000;
            endcase
        end
    endfunction

    // Function: char_pixel_on
    //   Scales and draws a single 5x7 font character.
    //   Returns 1 when pix_x/pix_y hits an active font pixel. The scale input
    //   allows the same font to be used for small labels and large title text.
    function char_pixel_on;
        input [9:0] px;
        input [9:0] py;
        input [9:0] x0;
        input [9:0] y0;
        input [7:0] ch;
        input [2:0] scale;
        reg [9:0] lx;
        reg [9:0] ly;
        reg [2:0] col;
        reg [2:0] row;
        reg [4:0] bits;
        begin
            char_pixel_on = 1'b0;
            if ((px >= x0) && (px < x0 + (5 * scale)) &&
                (py >= y0) && (py < y0 + (7 * scale))) begin
                lx = px - x0;
                ly = py - y0;
                col = lx / scale;
                row = ly / scale;
                bits = font5x7_row(ch, row);
                if (bits[4 - col])
                    char_pixel_on = 1'b1;
            end
        end
    endfunction


    // -------------------------------------------------------------------------
    // Simple shaped sprite masks.
    // No ROMs or extra files
    // Collision logic remains rectangular in the game engine.
    // -------------------------------------------------------------------------
    // Function: frog_sprite_on
    //   Draws the main frog sprite shape. Instead of a square, the frog is built
    //   from simple oval/body/leg regions using coordinate comparisons.
    function frog_sprite_on;
        input [9:0] px;
        input [9:0] py;
        input [9:0] x0;
        input [9:0] y0;
        reg [5:0] x;
        reg [5:0] y;
        begin
            frog_sprite_on = 1'b0;
            x = px - x0;
            y = py - y0;

            if ((px >= x0) && (px < x0 + FROG_W) && (py >= y0) && (py < y0 + FROG_H)) begin
                // Head and body
                if ((x >= 6  && x < 18 && y >= 1  && y < 10) ||
                    (x >= 4  && x < 20 && y >= 7  && y < 19) ||
                    (x >= 7  && x < 17 && y >= 17 && y < 22))
                    frog_sprite_on = 1'b1;

                // Front and rear legs
                if ((x >= 1  && x < 8  && y >= 8  && y < 14) ||
                    (x >= 16 && x < 23 && y >= 8  && y < 14) ||
                    (x >= 1  && x < 9  && y >= 18 && y < 23) ||
                    (x >= 15 && x < 23 && y >= 18 && y < 23))
                    frog_sprite_on = 1'b1;

                // Trim the corners so it does not look like a box.
                if ((x < 3  && y < 6)  || (x > 20 && y < 6) ||
                    (x < 2  && y > 14 && y < 18) || (x > 21 && y > 14 && y < 18))
                    frog_sprite_on = 1'b0;
            end
        end
    endfunction

    // Function: frog_eye_on
    //   Draws dark frog eye pixels on top of the frog sprite. This is separate
    //   from frog_sprite_on so the final RGB priority can color eyes differently.
    function frog_eye_on;
        input [9:0] px;
        input [9:0] py;
        input [9:0] x0;
        input [9:0] y0;
        reg [5:0] x;
        reg [5:0] y;
        begin
            frog_eye_on = 1'b0;
            x = px - x0;
            y = py - y0;
            if ((px >= x0) && (px < x0 + FROG_W) && (py >= y0) && (py < y0 + FROG_H)) begin
                if (((x >= 7 && x < 10) || (x >= 14 && x < 17)) && (y >= 3 && y < 6))
                    frog_eye_on = 1'b1;
            end
        end
    endfunction

    // Function: car_sprite_on
    //   Draws a car body with a slightly shaped outline. All cars share this
    //   geometry, while the RGB priority block assigns different colors per car.
    function car_sprite_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        reg signed [11:0] x;
        reg signed [11:0] y;
        begin
            car_sprite_on = 1'b0;
            x = px - x0;
            y = py - $signed({1'b0, y0});

            if ((x >= 0) && (x < CAR_W) && (y >= 0) && (y < CAR_H)) begin
                // Main body and roof/cabin. This gives a simple car silhouette.
                if ((x >= 3  && x < 45 && y >= 9  && y < 20) ||
                    (x >= 12 && x < 36 && y >= 4  && y < 12) ||
                    (x >= 7  && x < 41 && y >= 7  && y < 17))
                    car_sprite_on = 1'b1;

                // Bumpers/nose pixels.
                if ((x >= 0 && x < 6 && y >= 12 && y < 18) ||
                    (x >= 42 && x < 48 && y >= 12 && y < 18))
                    car_sprite_on = 1'b1;

                // Trim upper corners.
                if ((x < 5 && y < 10) || (x > 42 && y < 10) ||
                    (x < 2 && y > 19) || (x > 45 && y > 19))
                    car_sprite_on = 1'b0;
            end
        end
    endfunction

    // Function: car_window_on
    //   Identifies the car window pixels. Kept separate from the car body so
    //   windows can be drawn with their own color and priority.
    function car_window_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        reg signed [11:0] x;
        reg signed [11:0] y;
        begin
            car_window_on = 1'b0;
            x = px - x0;
            y = py - $signed({1'b0, y0});
            if ((x >= 0) && (x < CAR_W) && (y >= 0) && (y < CAR_H)) begin
                if (((x >= 15 && x < 23) || (x >= 25 && x < 33)) && (y >= 6 && y < 10))
                    car_window_on = 1'b1;
            end
        end
    endfunction

    // Function: car_tire_on
    //   Identifies tire pixels for the cars. Tires are drawn over the car body
    //   with a dark color.
    function car_tire_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        reg signed [11:0] x;
        reg signed [11:0] y;
        begin
            car_tire_on = 1'b0;
            x = px - x0;
            y = py - $signed({1'b0, y0});
            if ((x >= 0) && (x < CAR_W) && (y >= 0) && (y < CAR_H)) begin
                if (((x >= 8 && x < 16) || (x >= 32 && x < 40)) && (y >= 17 && y < 23))
                    car_tire_on = 1'b1;
            end
        end
    endfunction

    // Function: log_sprite_on
    //   Draws a jagged/rounded log shape. Short and long logs both use this
    //   function; the width input determines the size.
    function log_sprite_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        input [10:0] w;
        reg signed [11:0] x;
        reg signed [11:0] y;
        begin
            log_sprite_on = 1'b0;
            x = px - x0;
            y = py - $signed({1'b0, y0});

            if ((x >= 0) && (x < w) && (y >= 0) && (y < LOG_H)) begin
                // Long center section.
                if ((x >= 6) && (x < w - 6) && (y >= 5) && (y < 20))
                    log_sprite_on = 1'b1;

                // Jagged/chipped ends.
                if ((x < 8) && (y >= 8) && (y < 17))
                    log_sprite_on = 1'b1;
                if ((x >= w - 8) && (y >= 7) && (y < 18))
                    log_sprite_on = 1'b1;
                if ((x >= 2) && (x < 12) && (y >= 3) && (y < 9))
                    log_sprite_on = 1'b1;
                if ((x >= w - 12) && (x < w - 2) && (y >= 15) && (y < 22))
                    log_sprite_on = 1'b1;

                // Notches to make the outline less rectangular.
                if (((x[4:0] == 5'd3) || (x[4:0] == 5'd19)) && (y < 6))
                    log_sprite_on = 1'b0;
                if (((x[4:0] == 5'd11) || (x[4:0] == 5'd27)) && (y > 18))
                    log_sprite_on = 1'b0;
            end
        end
    endfunction

    // Function: log_bark_on
    //   Draws darker bark/detail lines on logs. Separated from log_sprite_on so
    //   the renderer can give the bark pixels higher drawing priority.
    function log_bark_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        input [10:0] w;
        reg signed [11:0] x;
        reg signed [11:0] y;
        begin
            log_bark_on = 1'b0;
            x = px - x0;
            y = py - $signed({1'b0, y0});

            if ((x >= 0) && (x < w) && (y >= 0) && (y < LOG_H)) begin
                // Bark stripes and ring marks.
                if (((y == 9) || (y == 15)) && (x > 10) && (x < w - 10) && (x[4:0] < 5'd20))
                    log_bark_on = 1'b1;
                if (((x[5:0] == 6'd16) || (x[5:0] == 6'd17)) && (y >= 7) && (y < 18))
                    log_bark_on = 1'b1;
            end
        end
    endfunction

    // Function: log_sprite_wrap_on
    //   Draws a log with horizontal wrap support. If the log crosses the right
    //   edge, the repeated copy at x - SCREEN_W makes it appear at the left edge.
    function log_sprite_wrap_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        input [10:0] w;
        begin
            log_sprite_wrap_on = log_sprite_on(px, py, x0, y0, w) ||
                                 log_sprite_on(px, py, x0 - SCREEN_W, y0, w);
        end
    endfunction

    // Function: log_bark_wrap_on
    //   Same idea as log_sprite_wrap_on, but for the darker bark pixels.
    function log_bark_wrap_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        input [10:0] w;
        begin
            log_bark_wrap_on = log_bark_on(px, py, x0, y0, w) ||
                               log_bark_on(px, py, x0 - SCREEN_W, y0, w);
        end
    endfunction

    // Function: turtle_group_sprite_on
    //   Draws a group of three turtles. This function returns 0 while turtles are
    //   submerged so only water ripples are drawn during TURTLE_DOWN.
    function turtle_group_sprite_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        reg signed [11:0] x;
        reg signed [11:0] y;
        reg [1:0] idx;
        reg signed [11:0] lx;
        begin
            turtle_group_sprite_on = 1'b0;
            x = px - x0;
            if (x < 0)
                x = x + SCREEN_W;
            y = py - $signed({1'b0, y0});

            if ((x >= 0) && (x < TURTLE_GROUP_W) && (y >= 0) && (y < TURTLE_H) && (turtle_state != TURTLE_DOWN)) begin
                // Three rounded turtle bodies, each 24 pixels wide, with 4-pixel gaps.
                // This shape gives each turtle a body, shell, head, and small tail.
                for (idx = 0; idx < 3; idx = idx + 1) begin
                    lx = x - (idx * 28);
                    if ((lx >= 0) && (lx < 24)) begin
                        // shell/body oval
                        if ((lx >= 4  && lx < 20 && y >= 6  && y < 20) ||
                            (lx >= 7  && lx < 17 && y >= 3  && y < 23) ||
                            (lx >= 2  && lx < 22 && y >= 10 && y < 17) ||
                            // small head to the right
                            (lx >= 19 && lx < 24 && y >= 9  && y < 15) ||
                            // small tail to the left
                            (lx >= 0  && lx < 4  && y >= 11 && y < 14))
                            turtle_group_sprite_on = 1'b1;
                    end
                end
            end
        end
    endfunction

    // Function: turtle_group_eye_on
    //   Draws the small dark eye pixels for each turtle in the three-turtle group.
    function turtle_group_eye_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        reg signed [11:0] x;
        reg signed [11:0] y;
        reg [1:0] idx;
        reg signed [11:0] lx;
        begin
            turtle_group_eye_on = 1'b0;
            x = px - x0;
            if (x < 0)
                x = x + SCREEN_W;
            y = py - $signed({1'b0, y0});

            if ((x >= 0) && (x < TURTLE_GROUP_W) && (y >= 0) && (y < TURTLE_H) && (turtle_state != TURTLE_DOWN)) begin
                for (idx = 0; idx < 3; idx = idx + 1) begin
                    lx = x - (idx * 28);
                    // eye on the turtle head
                    if ((lx >= 21 && lx < 23) && (y >= 10 && y < 12))
                        turtle_group_eye_on = 1'b1;
                end
            end
        end
    endfunction

    // Function: turtle_ripple_on_fn
    //   Draws animated white water-rustle pixels when turtles are submerged.
    //   The turtle_ripple_anim input flips between two ripple patterns so the
    //   water looks alive instead of static.
    function turtle_ripple_on_fn;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        reg signed [11:0] x;
        reg signed [11:0] y;
        begin
            turtle_ripple_on_fn = 1'b0;
            x = px - x0;
            if (x < 0)
                x = x + SCREEN_W;
            y = py - $signed({1'b0, y0});

            // Animated white water rustle where submerged turtles are located.
            // Uses a dedicated turtle_ripple_anim phase.
            if ((turtle_state == TURTLE_DOWN) &&
                (x >= -4) && (x < TURTLE_GROUP_W + 4) &&
                (y >= 4) && (y < TURTLE_H + 4)) begin
                if (!turtle_ripple_anim) begin
                    if (((y == 8)  && ((x[4:0] >= 2  && x[4:0] < 14) || (x[4:0] >= 20 && x[4:0] < 28))) ||
                        ((y == 15) && ((x[4:0] >= 8  && x[4:0] < 20))) ||
                        ((y == 21) && ((x[4:0] >= 0  && x[4:0] < 10) || (x[4:0] >= 18 && x[4:0] < 30))))
                        turtle_ripple_on_fn = 1'b1;
                end
                else begin
                    if (((y == 9)  && ((x[4:0] >= 8  && x[4:0] < 20))) ||
                        ((y == 14) && ((x[4:0] >= 0  && x[4:0] < 12) || (x[4:0] >= 18 && x[4:0] < 30))) ||
                        ((y == 20) && ((x[4:0] >= 6  && x[4:0] < 24))))
                        turtle_ripple_on_fn = 1'b1;
                end
            end
        end
    endfunction

    // Function: snake_sprite_on
    //   Draws the snake body. The snake_anim bit alternates the hump pattern to
    //   create a simple animation while the snake moves across the median.
    function snake_sprite_on;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        reg signed [11:0] x;
        reg signed [11:0] y;
        begin
            snake_sprite_on = 1'b0;
            x = px - x0;
            y = py - $signed({1'b0, y0});
            if (snake_active && (x >= 0) && (x < SNAKE_W) && (y >= 0) && (y < SNAKE_H)) begin
                // Wavy snake body.  snake_anim flips the hump pattern every few frames.
                if ((y >= 6 && y < 11) ||
                    (!snake_anim && (x[4:0] < 5'd12) && (y >= 3 && y < 8)) ||
                    (!snake_anim && (x[4:0] >= 5'd16) && (x[4:0] < 5'd28) && (y >= 9 && y < 14)) ||
                    ( snake_anim && (x[4:0] < 5'd12) && (y >= 9 && y < 14)) ||
                    ( snake_anim && (x[4:0] >= 5'd16) && (x[4:0] < 5'd28) && (y >= 3 && y < 8)))
                    snake_sprite_on = 1'b1;
                // Head points in the direction of travel.
                if (snake_dir) begin
                    if ((x >= SNAKE_W - 12) && (x < SNAKE_W) && (y >= 4) && (y < 13))
                        snake_sprite_on = 1'b1;
                end
                else begin
                    if ((x >= 0) && (x < 12) && (y >= 4) && (y < 13))
                        snake_sprite_on = 1'b1;
                end
            end
        end
    endfunction

    // Function: snake_eye_on_fn
    //   Draws the snake eye/head detail. snake_dir controls which end of the
    //   sprite gets the eye so the snake faces the direction of travel.
    function snake_eye_on_fn;
        input signed [10:0] px;
        input signed [10:0] py;
        input signed [10:0] x0;
        input [9:0] y0;
        reg signed [11:0] x;
        reg signed [11:0] y;
        begin
            snake_eye_on_fn = 1'b0;
            x = px - x0;
            y = py - $signed({1'b0, y0});
            if (snake_active) begin
                if (snake_dir) begin
                    if ((x >= SNAKE_W - 8) && (x < SNAKE_W - 5) && (y >= 6) && (y < 9))
                        snake_eye_on_fn = 1'b1;
                end
                else begin
                    if ((x >= 5) && (x < 8) && (y >= 6) && (y < 9))
                        snake_eye_on_fn = 1'b1;
                end
            end
        end
    endfunction

    // Convert unsigned VGA pixel coordinates to signed values for sprite math.
    // Many objects can have negative X positions while wrapping onto the screen.
    always @(*) begin
        pix_x_s = $signed({1'b0, pix_x});
        pix_y_s = $signed({1'b0, pix_y});
    end

    // Break the binary score into decimal digits for the on-screen score display.
    // This uses division/modulo by constants; for this small educational game it is
    // simple and readable.
    always @(*) begin
        score_ten_thousands = (score / 10000) % 10;
        score_thousands     = (score / 1000)  % 10;
        score_hundreds      = (score / 100)   % 10;
        score_tens      = (score / 10)   % 10;
        score_ones      = score % 10;
    end

    // Main object/text detection block.
    // Each *_on signal means "the current pixel belongs to this object."
    // The final RGB priority block later decides which object wins if multiple
    // objects overlap the same pixel.
    always @(*) begin
        road_dash_on = 1'b0;

        if ((pix_y == 10'd256 || pix_y == 10'd288 || pix_y == 10'd320 || pix_y == 10'd352) &&
            (pix_x[5:3] != 3'b111))
            road_dash_on = 1'b1;
    end

    always @(*) begin
        frog_on = 1'b0;
        frog_eye = 1'b0;
        car_window = 1'b0;
        car_tire = 1'b0;
        log_bark = 1'b0;
        turtle_eye = 1'b0;
        turtle_ripple = 1'b0;
        snake_on = 1'b0;
        snake_eye = 1'b0;
        title_logo_on = 1'b0;
        title_prompt_on = 1'b0;
        title_mode_on = 1'b0;
        title_panel_on = 1'b0;
        title_border_on = 1'b0;
        gameover_logo_on = 1'b0;
        final_label_on = 1'b0;
        homes_label_on = 1'b0;
        final_score_digit0_on = 1'b0;
        final_score_digit1_on = 1'b0;
        final_score_digit2_on = 1'b0;
        final_score_digit3_on = 1'b0;
        final_score_digit4_on = 1'b0;
        homes_count_digit_on = 1'b0;

        car0_on = 1'b0;   car1_on = 1'b0;   car2_on = 1'b0;   car3_on = 1'b0;
        car4_on = 1'b0;   car5_on = 1'b0;   car6_on = 1'b0;   car7_on = 1'b0;
        car8_on = 1'b0;   car9_on = 1'b0;   car10_on = 1'b0;  car11_on = 1'b0;
        car12_on = 1'b0;

        log0_on = 1'b0;   log1_on = 1'b0;   log2_on = 1'b0;   log3_on = 1'b0;
        log4_on = 1'b0;   log5_on = 1'b0;   log6_on = 1'b0;   log7_on = 1'b0;
        log8_on = 1'b0;   log9_on = 1'b0;   log10_on = 1'b0;  log11_on = 1'b0;

        turtle0_on = 1'b0; turtle1_on = 1'b0; turtle2_on = 1'b0;

        goal0_on = 1'b0;  goal1_on = 1'b0;  goal2_on = 1'b0;  goal3_on = 1'b0;  goal4_on = 1'b0;
        goal0_fill_on = 1'b0; goal1_fill_on = 1'b0; goal2_fill_on = 1'b0; goal3_fill_on = 1'b0; goal4_fill_on = 1'b0;

        life0_on = 1'b0; life1_on = 1'b0; life2_on = 1'b0; life3_on = 1'b0; life4_on = 1'b0;

        score_digit0_on = 1'b0;
        score_digit1_on = 1'b0;
        score_digit2_on = 1'b0;
        score_digit3_on = 1'b0;
        score_digit4_on = 1'b0;

        frog_on  = frog_sprite_on(pix_x, pix_y, frog_x, frog_y);
        frog_eye = frog_eye_on(pix_x, pix_y, frog_x, frog_y);

        if (car_sprite_on(pix_x_s, pix_y_s, car0_x, car0_y)) car0_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car1_x, car1_y)) car1_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car2_x, car2_y)) car2_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car3_x, car3_y)) car3_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car4_x, car4_y)) car4_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car5_x, car5_y)) car5_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car6_x, car6_y)) car6_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car7_x, car7_y)) car7_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car8_x, car8_y)) car8_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car9_x, car9_y)) car9_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car10_x, car10_y)) car10_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car11_x, car11_y)) car11_on = 1'b1;
        if (car_sprite_on(pix_x_s, pix_y_s, car12_x, car12_y)) car12_on = 1'b1;

        if (log_sprite_wrap_on(pix_x_s, pix_y_s, log0_x, log0_y, LOG_L_W)) log0_on = 1'b1;
        if (log_sprite_wrap_on(pix_x_s, pix_y_s, log1_x, log1_y, LOG_L_W)) log1_on = 1'b1;

        if (log_sprite_on(pix_x_s, pix_y_s, log2_x, log2_y, LOG_S_W)) log2_on = 1'b1;
        if (log_sprite_on(pix_x_s, pix_y_s, log3_x, log3_y, LOG_S_W)) log3_on = 1'b1;
        if (log_sprite_on(pix_x_s, pix_y_s, log4_x, log4_y, LOG_S_W)) log4_on = 1'b1;

        if (log_sprite_wrap_on(pix_x_s, pix_y_s, log5_x, log5_y, LOG_L_W)) log5_on = 1'b1;
        if (log_sprite_wrap_on(pix_x_s, pix_y_s, log6_x, log6_y, LOG_L_W)) log6_on = 1'b1;

        if (log_sprite_on(pix_x_s, pix_y_s, log7_x, log7_y, LOG_S_W)) log7_on = 1'b1;
        if (log_sprite_on(pix_x_s, pix_y_s, log8_x, log8_y, LOG_S_W)) log8_on = 1'b1;
        if (log_sprite_on(pix_x_s, pix_y_s, log9_x, log9_y, LOG_S_W)) log9_on = 1'b1;

        if (log_sprite_wrap_on(pix_x_s, pix_y_s, log10_x, log10_y, LOG_L_W)) log10_on = 1'b1;
        if (log_sprite_wrap_on(pix_x_s, pix_y_s, log11_x, log11_y, LOG_L_W)) log11_on = 1'b1;

        if (turtle_group_sprite_on(pix_x_s, pix_y_s, turtle0_x, turtle0_y)) turtle0_on = 1'b1;
        if (turtle_group_sprite_on(pix_x_s, pix_y_s, turtle1_x, turtle1_y)) turtle1_on = 1'b1;
        if (turtle_group_sprite_on(pix_x_s, pix_y_s, turtle2_x, turtle2_y)) turtle2_on = 1'b1;
        turtle_eye = turtle_group_eye_on(pix_x_s, pix_y_s, turtle0_x, turtle0_y) ||
                     turtle_group_eye_on(pix_x_s, pix_y_s, turtle1_x, turtle1_y) ||
                     turtle_group_eye_on(pix_x_s, pix_y_s, turtle2_x, turtle2_y);
        turtle_ripple = turtle_ripple_on_fn(pix_x_s, pix_y_s, turtle0_x, turtle0_y) ||
                        turtle_ripple_on_fn(pix_x_s, pix_y_s, turtle1_x, turtle1_y) ||
                        turtle_ripple_on_fn(pix_x_s, pix_y_s, turtle2_x, turtle2_y);

        snake_on  = snake_sprite_on(pix_x_s, pix_y_s, snake_x, snake_y);
        snake_eye = snake_eye_on_fn(pix_x_s, pix_y_s, snake_x, snake_y);

        car_window = car_window_on(pix_x_s, pix_y_s, car0_x,  car0_y)  || car_window_on(pix_x_s, pix_y_s, car1_x,  car1_y)  ||
                     car_window_on(pix_x_s, pix_y_s, car2_x,  car2_y)  || car_window_on(pix_x_s, pix_y_s, car3_x,  car3_y)  ||
                     car_window_on(pix_x_s, pix_y_s, car4_x,  car4_y)  || car_window_on(pix_x_s, pix_y_s, car5_x,  car5_y)  ||
                     car_window_on(pix_x_s, pix_y_s, car6_x,  car6_y)  || car_window_on(pix_x_s, pix_y_s, car7_x,  car7_y)  ||
                     car_window_on(pix_x_s, pix_y_s, car8_x,  car8_y)  || car_window_on(pix_x_s, pix_y_s, car9_x,  car9_y)  ||
                     car_window_on(pix_x_s, pix_y_s, car10_x, car10_y) || car_window_on(pix_x_s, pix_y_s, car11_x, car11_y) ||
                     car_window_on(pix_x_s, pix_y_s, car12_x, car12_y);

        car_tire = car_tire_on(pix_x_s, pix_y_s, car0_x,  car0_y)  || car_tire_on(pix_x_s, pix_y_s, car1_x,  car1_y)  ||
                   car_tire_on(pix_x_s, pix_y_s, car2_x,  car2_y)  || car_tire_on(pix_x_s, pix_y_s, car3_x,  car3_y)  ||
                   car_tire_on(pix_x_s, pix_y_s, car4_x,  car4_y)  || car_tire_on(pix_x_s, pix_y_s, car5_x,  car5_y)  ||
                   car_tire_on(pix_x_s, pix_y_s, car6_x,  car6_y)  || car_tire_on(pix_x_s, pix_y_s, car7_x,  car7_y)  ||
                   car_tire_on(pix_x_s, pix_y_s, car8_x,  car8_y)  || car_tire_on(pix_x_s, pix_y_s, car9_x,  car9_y)  ||
                   car_tire_on(pix_x_s, pix_y_s, car10_x, car10_y) || car_tire_on(pix_x_s, pix_y_s, car11_x, car11_y) ||
                   car_tire_on(pix_x_s, pix_y_s, car12_x, car12_y);

        log_bark = log_bark_wrap_on(pix_x_s, pix_y_s, log0_x,  log0_y,  LOG_L_W) || log_bark_wrap_on(pix_x_s, pix_y_s, log1_x,  log1_y,  LOG_L_W) ||
                   log_bark_on(pix_x_s, pix_y_s, log2_x,  log2_y,  LOG_S_W) || log_bark_on(pix_x_s, pix_y_s, log3_x,  log3_y,  LOG_S_W) ||
                   log_bark_on(pix_x_s, pix_y_s, log4_x,  log4_y,  LOG_S_W) || log_bark_wrap_on(pix_x_s, pix_y_s, log5_x,  log5_y,  LOG_L_W) ||
                   log_bark_wrap_on(pix_x_s, pix_y_s, log6_x,  log6_y,  LOG_L_W) || log_bark_on(pix_x_s, pix_y_s, log7_x,  log7_y,  LOG_S_W) ||
                   log_bark_on(pix_x_s, pix_y_s, log8_x,  log8_y,  LOG_S_W) || log_bark_on(pix_x_s, pix_y_s, log9_x,  log9_y,  LOG_S_W) ||
                   log_bark_wrap_on(pix_x_s, pix_y_s, log10_x, log10_y, LOG_L_W) || log_bark_wrap_on(pix_x_s, pix_y_s, log11_x, log11_y, LOG_L_W);

        if ((pix_y >= 4) && (pix_y < 28) && (pix_x >= 32)  && (pix_x < 96))  goal0_on = 1'b1;
        if ((pix_y >= 4) && (pix_y < 28) && (pix_x >= 152) && (pix_x < 216)) goal1_on = 1'b1;
        if ((pix_y >= 4) && (pix_y < 28) && (pix_x >= 272) && (pix_x < 336)) goal2_on = 1'b1;
        if ((pix_y >= 4) && (pix_y < 28) && (pix_x >= 392) && (pix_x < 456)) goal3_on = 1'b1;
        if ((pix_y >= 4) && (pix_y < 28) && (pix_x >= 512) && (pix_x < 576)) goal4_on = 1'b1;

        if (goal_filled[0] && (pix_y >= 8) && (pix_y < 24) && (pix_x >= 36)  && (pix_x < 92))  goal0_fill_on = 1'b1;
        if (goal_filled[1] && (pix_y >= 8) && (pix_y < 24) && (pix_x >= 156) && (pix_x < 212)) goal1_fill_on = 1'b1;
        if (goal_filled[2] && (pix_y >= 8) && (pix_y < 24) && (pix_x >= 276) && (pix_x < 332)) goal2_fill_on = 1'b1;
        if (goal_filled[3] && (pix_y >= 8) && (pix_y < 24) && (pix_x >= 396) && (pix_x < 452)) goal3_fill_on = 1'b1;
        if (goal_filled[4] && (pix_y >= 8) && (pix_y < 24) && (pix_x >= 516) && (pix_x < 572)) goal4_fill_on = 1'b1;

        // Lives are total frogs remaining, including the active frog on screen.
        // Display only the reserve frogs at the bottom left.
        // Start with lives = 3 -> show 2 small frogs. Last life -> show 0.
        if ((lives >= 2) && frog_sprite_on(pix_x, pix_y, 10'd16,  10'd432)) life0_on = 1'b1;
        if ((lives >= 3) && frog_sprite_on(pix_x, pix_y, 10'd48,  10'd432)) life1_on = 1'b1;
        if ((lives >= 4) && frog_sprite_on(pix_x, pix_y, 10'd80,  10'd432)) life2_on = 1'b1;
        if ((lives >= 5) && frog_sprite_on(pix_x, pix_y, 10'd112, 10'd432)) life3_on = 1'b1;
        if ((lives >= 6) && frog_sprite_on(pix_x, pix_y, 10'd144, 10'd432)) life4_on = 1'b1;

        score_digit0_on = digit_pixel_on(score_ten_thousands, pix_x, pix_y, 10'd488, 10'd428);
        score_digit1_on = digit_pixel_on(score_thousands,     pix_x, pix_y, 10'd512, 10'd428);
        score_digit2_on = digit_pixel_on(score_hundreds,      pix_x, pix_y, 10'd536, 10'd428);
        score_digit3_on = digit_pixel_on(score_tens,          pix_x, pix_y, 10'd560, 10'd428);
        score_digit4_on = digit_pixel_on(score_ones,          pix_x, pix_y, 10'd584, 10'd428);

        // Title screen and ending screen text.
        title_panel_on  = ((pix_x >= 10'd72) && (pix_x < 10'd568) &&
                           (pix_y >= 10'd48) && (pix_y < 10'd310));
        title_border_on = (((pix_x >= 10'd68) && (pix_x < 10'd572) &&
                            (pix_y >= 10'd44) && (pix_y < 10'd48)) ||
                           ((pix_x >= 10'd68) && (pix_x < 10'd572) &&
                            (pix_y >= 10'd310) && (pix_y < 10'd314)) ||
                           ((pix_y >= 10'd44) && (pix_y < 10'd314) &&
                            (pix_x >= 10'd68) && (pix_x < 10'd72)) ||
                           ((pix_y >= 10'd44) && (pix_y < 10'd314) &&
                            (pix_x >= 10'd568) && (pix_x < 10'd572)));

        // Centered FROGGER logo.
        if (char_pixel_on(pix_x, pix_y, 10'd215, 10'd82, "F", 3'd5)) title_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd245, 10'd82, "R", 3'd5)) title_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd275, 10'd82, "O", 3'd5)) title_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd305, 10'd82, "G", 3'd5)) title_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd335, 10'd82, "G", 3'd5)) title_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd365, 10'd82, "E", 3'd5)) title_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd395, 10'd82, "R", 3'd5)) title_logo_on = 1'b1;

        // Centered title prompt.
        if (!input_mode) begin
            // BASYS mode: PRESS UP
            if (char_pixel_on(pix_x, pix_y, 10'd248, 10'd170, "P", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd266, 10'd170, "R", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd284, 10'd170, "E", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd302, 10'd170, "S", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd320, 10'd170, "S", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd356, 10'd170, "U", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd374, 10'd170, "P", 3'd3)) title_prompt_on = 1'b1;
        end
        else begin
            // NES mode: PRESS START
            if (char_pixel_on(pix_x, pix_y, 10'd221, 10'd170, "P", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd239, 10'd170, "R", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd257, 10'd170, "E", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd275, 10'd170, "S", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd293, 10'd170, "S", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd329, 10'd170, "S", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd347, 10'd170, "T", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd365, 10'd170, "A", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd383, 10'd170, "R", 3'd3)) title_prompt_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd401, 10'd170, "T", 3'd3)) title_prompt_on = 1'b1;
        end

        // Centered controller mode label.
        if (!input_mode) begin
            // BASYS BUTTONS
            if (char_pixel_on(pix_x, pix_y, 10'd203, 10'd235, "B", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd221, 10'd235, "A", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd239, 10'd235, "S", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd257, 10'd235, "Y", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd275, 10'd235, "S", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd311, 10'd235, "B", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd329, 10'd235, "U", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd347, 10'd235, "T", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd365, 10'd235, "T", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd383, 10'd235, "O", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd401, 10'd235, "N", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd419, 10'd235, "S", 3'd3)) title_mode_on = 1'b1;
        end
        else begin
            // NES CONTROLLER
            if (char_pixel_on(pix_x, pix_y, 10'd194, 10'd235, "N", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd212, 10'd235, "E", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd230, 10'd235, "S", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd266, 10'd235, "C", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd284, 10'd235, "O", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd302, 10'd235, "N", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd320, 10'd235, "T", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd338, 10'd235, "R", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd356, 10'd235, "O", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd374, 10'd235, "L", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd392, 10'd235, "L", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd410, 10'd235, "E", 3'd3)) title_mode_on = 1'b1;
            if (char_pixel_on(pix_x, pix_y, 10'd428, 10'd235, "R", 3'd3)) title_mode_on = 1'b1;
        end

        if (char_pixel_on(pix_x, pix_y, 10'd185, 10'd82, "G", 3'd5)) gameover_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd215, 10'd82, "A", 3'd5)) gameover_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd245, 10'd82, "M", 3'd5)) gameover_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd275, 10'd82, "E", 3'd5)) gameover_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd335, 10'd82, "O", 3'd5)) gameover_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd365, 10'd82, "V", 3'd5)) gameover_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd395, 10'd82, "E", 3'd5)) gameover_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd425, 10'd82, "R", 3'd5)) gameover_logo_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd190, 10'd180, "F", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd208, 10'd180, "I", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd226, 10'd180, "N", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd244, 10'd180, "A", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd262, 10'd180, "L", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd298, 10'd180, "S", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd316, 10'd180, "C", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd334, 10'd180, "O", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd352, 10'd180, "R", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd370, 10'd180, "E", 3'd3)) final_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd230, 10'd300, "H", 3'd3)) homes_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd248, 10'd300, "O", 3'd3)) homes_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd266, 10'd300, "M", 3'd3)) homes_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd284, 10'd300, "E", 3'd3)) homes_label_on = 1'b1;
        if (char_pixel_on(pix_x, pix_y, 10'd302, 10'd300, "S", 3'd3)) homes_label_on = 1'b1;

        final_score_digit0_on = digit_pixel_on(score_ten_thousands, pix_x, pix_y, 10'd248, 10'd230);
        final_score_digit1_on = digit_pixel_on(score_thousands,     pix_x, pix_y, 10'd272, 10'd230);
        final_score_digit2_on = digit_pixel_on(score_hundreds,      pix_x, pix_y, 10'd296, 10'd230);
        final_score_digit3_on = digit_pixel_on(score_tens,          pix_x, pix_y, 10'd320, 10'd230);
        final_score_digit4_on = digit_pixel_on(score_ones,          pix_x, pix_y, 10'd344, 10'd230);
        homes_count_digit_on  = digit_pixel_on({1'b0, homes_filled_count}, pix_x, pix_y, 10'd360, 10'd292);
    end

    // Background generation.
    // This creates the fixed playfield bands: scoreboard, water, median, road,
    // start area, plus goal/home coloring.
    always @(*) begin
        bg_rgb = BLACK;

        if (pix_y < 10'd32)
            bg_rgb = BLACK;
        else if (pix_y < 10'd192)
            bg_rgb = WATER_BLUE;
        else if (pix_y < 10'd224)
            bg_rgb = MEDIAN_GRN;
        else if (pix_y < 10'd384)
            bg_rgb = ROAD_GRAY;
        else if (pix_y < 10'd416)
            bg_rgb = START_GRN;
        else
            bg_rgb = BLACK;

        if (road_dash_on)
            bg_rgb = WHITE;

        if ((goal0_on && !goal_filled[0]) ||
            (goal1_on && !goal_filled[1]) ||
            (goal2_on && !goal_filled[2]) ||
            (goal3_on && !goal_filled[3]) ||
            (goal4_on && !goal_filled[4]))
            bg_rgb = goal_flash_active ? GOAL_FLASH : WHITE;

        if (goal0_fill_on || goal1_fill_on || goal2_fill_on || goal3_fill_on || goal4_fill_on)
            bg_rgb = GOAL_GREEN;
    end

    // Final RGB priority encoder.
    // The order matters. Objects listed earlier are drawn "on top" of objects
    // listed later. For example, car windows/tires appear over car bodies, and
    // frog eyes appear over the frog body.
    always @(*) begin
        if (!video_on)
            rgb = BLACK;
        else if (title_active) begin
            if (title_logo_on)
                rgb = FROG_CLR;
            else if (title_prompt_on)
                rgb = WHITE;
            else if (title_mode_on)
                rgb = input_mode ? RED : CYAN;
            else if (title_border_on)
                rgb = YELLOW;
            else if (title_panel_on)
                rgb = 12'h013;
            else
                rgb = BLACK;
        end
        else if (death_flash_active)
            rgb = GAME_OVER;
        else if (game_over_active) begin
            if (gameover_logo_on)
                rgb = RED;
            else if (final_label_on || homes_label_on)
                rgb = WHITE;
            else if (final_score_digit0_on || final_score_digit1_on || final_score_digit2_on || final_score_digit3_on || final_score_digit4_on || homes_count_digit_on)
                rgb = YELLOW;
            else
                rgb = BLACK;
        end
        else if (level_clear_active)
            rgb = GOAL_FLASH;
        else if (frog_eye)
            rgb = FROG_DARK;
        else if (frog_on)
            rgb = FROG_CLR;
        else if (car_tire)
            rgb = TIRE_CLR;
        else if (car_window)
            rgb = WINDOW_CLR;
        else if (car0_on)
            rgb = CAR0_CLR;
        else if (car1_on)
            rgb = CAR1_CLR;
        else if (car2_on)
            rgb = CAR2_CLR;
        else if (car3_on)
            rgb = CAR3_CLR;
        else if (car4_on)
            rgb = CAR4_CLR;
        else if (car5_on)
            rgb = CAR5_CLR;
        else if (car6_on)
            rgb = CAR6_CLR;
        else if (car7_on)
            rgb = CAR7_CLR;
        else if (car8_on)
            rgb = CAR8_CLR;
        else if (car9_on)
            rgb = CAR9_CLR;
        else if (car10_on)
            rgb = CAR10_CLR;
        else if (car11_on)
            rgb = CAR11_CLR;
        else if (car12_on)
            rgb = CAR12_CLR;
        else if (snake_eye)
            rgb = SNAKE_DARK;
        else if (snake_on)
            rgb = SNAKE_CLR;
        else if (turtle_eye)
            rgb = TURTLE_DARK;
        else if (turtle_ripple)
            rgb = WHITE;
        else if (turtle0_on || turtle1_on || turtle2_on)
            rgb = (turtle_state == TURTLE_WARN) ? TURTLE_WARN_CLR : TURTLE_CLR;
        else if (log_bark)
            rgb = LOG_DARK;
        else if (log0_on || log1_on || log2_on || log3_on || log4_on || log5_on ||
                 log6_on || log7_on || log8_on || log9_on || log10_on || log11_on)
            rgb = LOG_CLR;
        else if (life0_on || life1_on || life2_on || life3_on || life4_on)
            rgb = FROG_CLR;
        else if (score_digit0_on || score_digit1_on || score_digit2_on || score_digit3_on || score_digit4_on)
            rgb = WHITE;
        else
            rgb = bg_rgb;
    end

endmodule