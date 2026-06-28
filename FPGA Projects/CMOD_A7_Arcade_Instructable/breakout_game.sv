`timescale 1ns / 1ps

// ------------------------------------------------------------
// Breakout for 128x64 SSD1306 OLED
// Standard arcade game interface:
//   - Owns game state
//   - Receives current OLED page/column
//   - Outputs one 8-bit vertical SSD1306 framebuffer byte
//
// Gameplay:
//   - Paddle at bottom
//   - Ball breaks bricks at top
//   - Miss at bottom resets the ball
//   - A or Start restarts the whole board
// ------------------------------------------------------------
module breakout_game #(
    parameter int CLK_HZ = 12_000_000,
    parameter int BALL_HZ = 22,
    parameter int PADDLE_HZ = 45
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

    localparam logic [6:0] BALL_SIZE = 7'd3;
    localparam logic [6:0] PADDLE_W  = 7'd24;
    localparam logic [5:0] PADDLE_Y  = 6'd58;

    localparam int BRICK_COLS = 8;
    localparam int BRICK_ROWS = 3;
    localparam logic [6:0] BRICK_X0 = 7'd4;
    localparam logic [5:0] BRICK_Y0 = 6'd8;
    localparam logic [6:0] BRICK_W  = 7'd14;
    localparam logic [5:0] BRICK_H  = 6'd6;
    localparam logic [6:0] BRICK_GAP_X = 7'd2;
    localparam logic [5:0] BRICK_GAP_Y = 6'd2;

    logic [31:0] ball_tick_count;
    logic [31:0] paddle_tick_count;

    logic [6:0] ball_x;
    logic [5:0] ball_y;
    logic       ball_dx_right;
    logic       ball_dy_down;

    logic [6:0] paddle_x;
    logic       active_d;
    logic [3:0] misses;

    logic bricks [0:BRICK_ROWS-1][0:BRICK_COLS-1];

    task automatic load_bricks;
        int r;
        int c;
        begin
            for (r = 0; r < BRICK_ROWS; r = r + 1) begin
                for (c = 0; c < BRICK_COLS; c = c + 1) begin
                    bricks[r][c] <= 1'b1;
                end
            end
        end
    endtask

    task automatic reset_ball;
        begin
            ball_tick_count <= '0;
            ball_x          <= 7'd62;
            ball_y          <= 6'd42;
            ball_dx_right   <= ~ball_dx_right;
            ball_dy_down    <= 1'b0;
        end
    endtask

    task automatic reset_breakout;
        begin
            ball_tick_count   <= '0;
            paddle_tick_count <= '0;
            ball_x            <= 7'd62;
            ball_y            <= 6'd42;
            ball_dx_right     <= 1'b1;
            ball_dy_down      <= 1'b0;
            paddle_x          <= 7'd52;
            misses            <= 4'd0;
            load_bricks();
        end
    endtask

    function automatic logic paddle_hit_now;
        logic horizontal_overlap;
        begin
            horizontal_overlap = ((ball_x + BALL_SIZE - 1'b1) >= paddle_x) &&
                                 (ball_x <= (paddle_x + PADDLE_W - 1'b1));

            paddle_hit_now = ball_dy_down &&
                             ((ball_y + BALL_SIZE) >= PADDLE_Y) &&
                             (ball_y <= (PADDLE_Y + 6'd2)) &&
                             horizontal_overlap;
        end
    endfunction

    function automatic logic point_hits_brick(
        input logic [6:0] x,
        input logic [5:0] y,
        output int hit_r,
        output int hit_c
    );
        int r;
        int c;
        logic [6:0] bx0;
        logic [6:0] bx1;
        logic [5:0] by0;
        logic [5:0] by1;
        begin
            point_hits_brick = 1'b0;
            hit_r = 0;
            hit_c = 0;

            for (r = 0; r < BRICK_ROWS; r = r + 1) begin
                for (c = 0; c < BRICK_COLS; c = c + 1) begin
                    bx0 = BRICK_X0 + c[6:0] * (BRICK_W + BRICK_GAP_X);
                    bx1 = bx0 + BRICK_W - 1'b1;
                    by0 = BRICK_Y0 + r[5:0] * (BRICK_H + BRICK_GAP_Y);
                    by1 = by0 + BRICK_H - 1'b1;

                    if (bricks[r][c] && x >= bx0 && x <= bx1 && y >= by0 && y <= by1) begin
                        point_hits_brick = 1'b1;
                        hit_r = r;
                        hit_c = c;
                    end
                end
            end
        end
    endfunction

    always_ff @(posedge clk) begin
        int hit_r;
        int hit_c;
        logic [6:0] test_x;
        logic [5:0] test_y;

        if (reset) begin
            active_d <= 1'b0;
            audio_event <= 4'd0;
            reset_breakout();
        end else begin
            audio_event <= 4'd0;
            active_d <= game_active;

            if (game_active && !active_d) begin
                audio_event <= 4'd2;
                reset_breakout();
            end else if (game_active) begin
                if (btn_a || btn_start) begin
                    audio_event <= 4'd2;
                    reset_breakout();
                end else begin
                    // Paddle update tick.
                    if (paddle_tick_count == PADDLE_TICK_CLKS-1) begin
                        paddle_tick_count <= '0;

                        if ((btn_left || btn_up) && paddle_x > 7'd2) begin
                            paddle_x <= paddle_x - 1'b1;
                        end else if ((btn_right || btn_down) && paddle_x < (7'd125 - PADDLE_W)) begin
                            paddle_x <= paddle_x + 1'b1;
                        end
                    end else begin
                        paddle_tick_count <= paddle_tick_count + 1'b1;
                    end

                    // Ball update tick.
                    if (ball_tick_count == BALL_TICK_CLKS-1) begin
                        ball_tick_count <= '0;

                        // Test the next ball corner in the direction of travel.
                        test_x = ball_dx_right ? (ball_x + BALL_SIZE) : (ball_x - 1'b1);
                        test_y = ball_dy_down  ? (ball_y + BALL_SIZE) : (ball_y - 1'b1);

                        if (point_hits_brick(test_x, test_y, hit_r, hit_c)) begin
                            audio_event <= 4'd4;
                            bricks[hit_r][hit_c] <= 1'b0;
                            ball_dy_down <= ~ball_dy_down;
                        end else begin
                            // Horizontal wall movement.
                            if (ball_dx_right) begin
                                if (ball_x >= (7'd127 - BALL_SIZE)) begin
                                    audio_event <= 4'd3;
                                    ball_dx_right <= 1'b0;
                                    ball_x <= ball_x - 1'b1;
                                end else begin
                                    ball_x <= ball_x + 1'b1;
                                end
                            end else begin
                                if (ball_x <= 7'd1) begin
                                    audio_event <= 4'd3;
                                    ball_dx_right <= 1'b1;
                                    ball_x <= ball_x + 1'b1;
                                end else begin
                                    ball_x <= ball_x - 1'b1;
                                end
                            end

                            // Vertical wall, paddle, and miss movement.
                            if (ball_dy_down) begin
                                if (paddle_hit_now()) begin
                                    audio_event <= 4'd4;
                                    ball_dy_down <= 1'b0;
                                    ball_y <= PADDLE_Y - BALL_SIZE - 1'b1;

                                    // Simple angle control from paddle position.
                                    if ((ball_x + 7'd1) < (paddle_x + (PADDLE_W >> 1))) begin
                                        ball_dx_right <= 1'b0;
                                    end else begin
                                        ball_dx_right <= 1'b1;
                                    end
                                end else if (ball_y >= (6'd63 - BALL_SIZE)) begin
                                    audio_event <= 4'd5;
                                    misses <= misses + 1'b1;
                                    reset_ball();
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

    function automatic logic brick_pixel(input logic [6:0] x, input logic [5:0] y);
        int r;
        int c;
        logic [6:0] bx0;
        logic [6:0] bx1;
        logic [5:0] by0;
        logic [5:0] by1;
        begin
            brick_pixel = 1'b0;
            for (r = 0; r < BRICK_ROWS; r = r + 1) begin
                for (c = 0; c < BRICK_COLS; c = c + 1) begin
                    bx0 = BRICK_X0 + c[6:0] * (BRICK_W + BRICK_GAP_X);
                    bx1 = bx0 + BRICK_W - 1'b1;
                    by0 = BRICK_Y0 + r[5:0] * (BRICK_H + BRICK_GAP_Y);
                    by1 = by0 + BRICK_H - 1'b1;

                    if (bricks[r][c] && x >= bx0 && x <= bx1 && y >= by0 && y <= by1) begin
                        brick_pixel = 1'b1;
                    end
                end
            end
        end
    endfunction

    function automatic logic pixel_at(input logic [6:0] x, input logic [5:0] y);
        logic top_wall;
        logic side_walls;
        logic paddle_pixel;
        logic ball_pixel;
        logic miss_meter;
        begin
            top_wall = (y == 6'd0);
            side_walls = (x == 7'd0) || (x == 7'd127);

            paddle_pixel = (x >= paddle_x) && (x < (paddle_x + PADDLE_W)) &&
                           (y >= PADDLE_Y) && (y <= (PADDLE_Y + 6'd2));

            ball_pixel = (x >= ball_x) && (x < (ball_x + BALL_SIZE)) &&
                         (y >= ball_y) && (y < (ball_y + BALL_SIZE));

            miss_meter = (y >= 6'd2) && (y <= 6'd4) &&
                         (x >= 7'd2) && (x < (7'd2 + {3'b000, misses, 1'b0}));

            pixel_at = top_wall | side_walls | brick_pixel(x, y) | paddle_pixel | ball_pixel | miss_meter;
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


