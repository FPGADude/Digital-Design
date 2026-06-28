`timescale 1ns / 1ps

// ------------------------------------------------------------
// Single-Player Wall Pong for 128x64 SSD1306 OLED
// Standard arcade game interface:
//   - Owns game state
//   - Receives current OLED page/column
//   - Outputs one 8-bit vertical SSD1306 framebuffer byte
//
// Gameplay:
//   - One paddle on the left
//   - Ball bounces off top, bottom, and right wall
//   - Player returns ball with paddle
//   - Miss on left side resets ball
// ------------------------------------------------------------
module pong_game #(
    parameter int CLK_HZ = 12_000_000,
    parameter int BALL_HZ = 36,
    parameter int PADDLE_HZ = 60
)(
    input  logic clk,
    input  logic reset,
    input  logic game_active,

    input  logic btn_up,
    input  logic btn_down,
    input  logic btn_left,
    input  logic btn_right,
    input  logic btn_a,
    input  logic btn_start,

    input  logic [2:0] page,
    input  logic [6:0] col,
    output logic [7:0] pixel_byte,
    output logic [3:0] audio_event
);

    localparam int BALL_TICK_CLKS   = CLK_HZ / BALL_HZ;
    localparam int PADDLE_TICK_CLKS = CLK_HZ / PADDLE_HZ;

    localparam logic [6:0] BALL_SIZE = 7'd4;
    localparam logic [5:0] PADDLE_H  = 6'd16;
    localparam logic [6:0] PADDLE_X0 = 7'd5;
    localparam logic [6:0] PADDLE_X1 = 7'd8;

    logic [31:0] ball_tick_count;
    logic [31:0] paddle_tick_count;

    logic [6:0] ball_x;
    logic [5:0] ball_y;
    logic       ball_dx_right;
    logic       ball_dy_down;

    logic [5:0] paddle_y;
    logic       active_d;
    logic [3:0] misses;

    task automatic reset_pong;
        begin
            ball_tick_count   <= '0;
            paddle_tick_count <= '0;
            ball_x            <= 7'd48;
            ball_y            <= 6'd30;
            ball_dx_right     <= 1'b1;
            ball_dy_down      <= 1'b1;
            paddle_y          <= 6'd24;
            misses            <= 4'd0;
        end
    endtask

    task automatic reset_ball;
        begin
            ball_tick_count <= '0;
            ball_x          <= 7'd48;
            ball_y          <= 6'd30;
            ball_dx_right   <= 1'b1;
            ball_dy_down    <= ~ball_dy_down;
            misses          <= misses + 1'b1;
        end
    endtask

    function automatic logic paddle_hit_now;
        logic ball_vertical_overlap;
        begin
            ball_vertical_overlap = ((ball_y + 6'd3) >= paddle_y) &&
                                    (ball_y <= (paddle_y + PADDLE_H - 1'b1));

            paddle_hit_now = (!ball_dx_right) &&
                             (ball_x <= (PADDLE_X1 + 1'b1)) &&
                             (ball_x >= PADDLE_X0) &&
                             ball_vertical_overlap;
        end
    endfunction

    always_ff @(posedge clk) begin
        if (reset) begin
            active_d <= 1'b0;
            audio_event <= 4'd0;
            reset_pong();
        end else begin
            audio_event <= 4'd0;
            active_d <= game_active;

            if (game_active && !active_d) begin
                audio_event <= 4'd2;
                reset_pong();
            end else if (game_active) begin
                // A or Start restarts the current Pong round.
                if (btn_a || btn_start) begin
                    audio_event <= 4'd2;
                    reset_pong();
                end else begin
                    // Paddle update tick. Left/right are accepted too, so the
                    // player can use either D-pad orientation by mistake without
                    // breaking gameplay. Up/down are the intended controls.
                    if (paddle_tick_count == PADDLE_TICK_CLKS-1) begin
                        paddle_tick_count <= '0;

                        if ((btn_up || btn_left) && paddle_y > 6'd1) begin
                            paddle_y <= paddle_y - 1'b1;
                        end else if ((btn_down || btn_right) && paddle_y < (6'd63 - PADDLE_H)) begin
                            paddle_y <= paddle_y + 1'b1;
                        end
                    end else begin
                        paddle_tick_count <= paddle_tick_count + 1'b1;
                    end

                    // Ball update tick.
                    if (ball_tick_count == BALL_TICK_CLKS-1) begin
                        ball_tick_count <= '0;

                        // Horizontal movement / collisions.
                        if (ball_dx_right) begin
                            if (ball_x >= (7'd127 - BALL_SIZE)) begin
                                audio_event <= 4'd3;
                                ball_dx_right <= 1'b0;
                                ball_x <= ball_x - 1'b1;
                            end else begin
                                ball_x <= ball_x + 1'b1;
                            end
                        end else begin
                            if (paddle_hit_now()) begin
                                audio_event <= 4'd4;
                                ball_dx_right <= 1'b1;
                                ball_x <= PADDLE_X1 + 2'd2;

                                // Simple angle control: upper half sends ball up,
                                // lower half sends ball down.
                                if ((ball_y + 6'd2) < (paddle_y + (PADDLE_H >> 1))) begin
                                    ball_dy_down <= 1'b0;
                                end else begin
                                    ball_dy_down <= 1'b1;
                                end
                            end else if (ball_x <= 7'd1) begin
                                audio_event <= 4'd5;
                                reset_ball();
                            end else begin
                                ball_x <= ball_x - 1'b1;
                            end
                        end

                        // Vertical movement / collisions.
                        if (ball_dy_down) begin
                            if (ball_y >= (6'd63 - BALL_SIZE)) begin
                                audio_event <= 4'd3;
                                ball_dy_down <= 1'b0;
                                ball_y <= ball_y - 1'b1;
                            end else begin
                                ball_y <= ball_y + 1'b1;
                            end
                        end else begin
                            if (ball_y <= 6'd1) begin
                                audio_event <= 4'd3;
                                ball_dy_down <= 1'b1;
                                ball_y <= ball_y + 1'b1;
                            end else begin
                                ball_y <= ball_y - 1'b1;
                            end
                        end
                    end else begin
                        ball_tick_count <= ball_tick_count + 1'b1;
                    end
                end
            end else begin
                ball_tick_count   <= '0;
                paddle_tick_count <= '0;
            end
        end
    end

    function automatic logic pixel_at(input logic [6:0] x, input logic [5:0] y);
        logic top_bottom_border;
        logic right_wall;
        logic paddle_pixel;
        logic ball_pixel;
        logic miss_meter;
        begin
            top_bottom_border = (y == 6'd0) || (y == 6'd63);
            right_wall        = (x == 7'd127);

            paddle_pixel = (x >= PADDLE_X0) && (x <= PADDLE_X1) &&
                           (y >= paddle_y) && (y <= (paddle_y + PADDLE_H - 1'b1));

            ball_pixel = (x >= ball_x) && (x < (ball_x + BALL_SIZE)) &&
                         (y >= ball_y) && (y < (ball_y + BALL_SIZE));

            // Tiny miss counter in the upper-left corner. It wraps naturally.
            miss_meter = (y >= 6'd2) && (y <= 6'd4) &&
                         (x >= 7'd2) && (x < (7'd2 + {3'b000, misses, 1'b0}));

            pixel_at = top_bottom_border | right_wall | paddle_pixel | ball_pixel | miss_meter;
        end
    endfunction

    always_comb begin
        int bit_i;
        logic [5:0] y;
        pixel_byte = 8'h00;

        for (bit_i = 0; bit_i < 8; bit_i = bit_i + 1) begin
            y = {page, 3'b000} + bit_i[5:0];
            pixel_byte[bit_i] = pixel_at(col, y);
        end
    end

endmodule



