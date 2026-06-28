`timescale 1ns / 1ps

// ------------------------------------------------------------
// Snake Game Module for 128x64 SSD1306 OLED
// Standard arcade game interface:
//   - Owns game state
//   - Receives current OLED page/column
//   - Outputs one 8-bit vertical SSD1306 framebuffer byte
// ------------------------------------------------------------
module snake_game #(
    parameter int CLK_HZ = 12_000_000,
    parameter int SNAKE_HZ = 2,
    parameter int MAX_LEN = 32
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

    localparam int TICK_CLKS = CLK_HZ / SNAKE_HZ;

    typedef enum logic [1:0] {
        DIR_UP    = 2'd0,
        DIR_DOWN  = 2'd1,
        DIR_LEFT  = 2'd2,
        DIR_RIGHT = 2'd3
    } dir_t;

    logic [3:0] snake_x [0:MAX_LEN-1];
    logic [2:0] snake_y [0:MAX_LEN-1];
    logic [5:0] snake_len;
    logic [3:0] food_x;
    logic [2:0] food_y;
    logic [31:0] tick_count;
    dir_t dir;
    logic game_over;
    logic active_d;
    logic dir_changed_this_tick;

    task automatic reset_snake;
        int j;
        begin
            tick_count <= '0;
            dir <= DIR_RIGHT;
            snake_len <= 6'd3;
            food_x <= 4'd11;
            food_y <= 3'd4;
            game_over <= 1'b0;
            dir_changed_this_tick <= 1'b0;

            for (j = 0; j < MAX_LEN; j = j + 1) begin
                snake_x[j] <= 4'd0;
                snake_y[j] <= 3'd0;
            end

            snake_x[0] <= 4'd7; snake_y[0] <= 3'd3;
            snake_x[1] <= 4'd6; snake_y[1] <= 3'd3;
            snake_x[2] <= 4'd5; snake_y[2] <= 3'd3;
        end
    endtask

    // Game update logic
    always_ff @(posedge clk) begin
        int i;
        logic [3:0] next_x;
        logic [2:0] next_y;
        logic wall_hit;
        logic self_hit;
        logic ate_food;

        if (reset) begin
            active_d <= 1'b0;
            audio_event <= 4'd0;
            reset_snake();
        end else begin
            audio_event <= 4'd0;
            active_d <= game_active;

            if (game_active && !active_d) begin
                audio_event <= 4'd2;
                reset_snake();
            end else if (game_active) begin
                if (!dir_changed_this_tick && !game_over) begin
                    if (btn_up && dir != DIR_DOWN) begin
                        dir <= DIR_UP;
                        dir_changed_this_tick <= 1'b1;
                        audio_event <= 4'd3;
                    end else if (btn_down && dir != DIR_UP) begin
                        dir <= DIR_DOWN;
                        dir_changed_this_tick <= 1'b1;
                        audio_event <= 4'd3;
                    end else if (btn_left && dir != DIR_RIGHT) begin
                        dir <= DIR_LEFT;
                        dir_changed_this_tick <= 1'b1;
                        audio_event <= 4'd3;
                    end else if (btn_right && dir != DIR_LEFT) begin
                        dir <= DIR_RIGHT;
                        dir_changed_this_tick <= 1'b1;
                        audio_event <= 4'd3;
                    end
                end

                if (tick_count == TICK_CLKS-1) begin
                    tick_count <= '0;
                    dir_changed_this_tick <= 1'b0;

                    if (game_over) begin
                        if (btn_a || btn_start || btn_up || btn_down || btn_left || btn_right) begin
                            audio_event <= 4'd2;
                            reset_snake();
                        end
                    end else begin
                        next_x = snake_x[0];
                        next_y = snake_y[0];
                        wall_hit = 1'b0;
                        self_hit = 1'b0;
                        ate_food = 1'b0;

                        case (dir)
                            DIR_UP: begin
                                if (snake_y[0] == 3'd0) wall_hit = 1'b1;
                                else next_y = snake_y[0] - 1'b1;
                            end
                            DIR_DOWN: begin
                                if (snake_y[0] == 3'd7) wall_hit = 1'b1;
                                else next_y = snake_y[0] + 1'b1;
                            end
                            DIR_LEFT: begin
                                if (snake_x[0] == 4'd0) wall_hit = 1'b1;
                                else next_x = snake_x[0] - 1'b1;
                            end
                            default: begin
                                if (snake_x[0] == 4'd15) wall_hit = 1'b1;
                                else next_x = snake_x[0] + 1'b1;
                            end
                        endcase

                        for (i = 1; i < MAX_LEN; i = i + 1) begin
                            if (i < snake_len) begin
                                if ((snake_x[i] == next_x) && (snake_y[i] == next_y)) begin
                                    self_hit = 1'b1;
                                end
                            end
                        end

                        ate_food = (next_x == food_x) && (next_y == food_y);

                        if (wall_hit || self_hit) begin
                            game_over <= 1'b1;
                            audio_event <= 4'd5;
                        end else begin
                            for (i = MAX_LEN-1; i > 0; i = i - 1) begin
                                if (i < snake_len || (ate_food && i == snake_len)) begin
                                    snake_x[i] <= snake_x[i-1];
                                    snake_y[i] <= snake_y[i-1];
                                end
                            end

                            snake_x[0] <= next_x;
                            snake_y[0] <= next_y;

                            if (ate_food) begin
                                audio_event <= 4'd4;
                                if (snake_len < MAX_LEN) begin
                                    snake_len <= snake_len + 1'b1;
                                end
                                food_x <= food_x + 4'd5;
                                food_y <= food_y + 3'd3;
                            end
                        end
                    end
                end else begin
                    tick_count <= tick_count + 1'b1;
                end
            end else begin
                tick_count <= '0;
                dir_changed_this_tick <= 1'b0;
            end
        end
    end

    function automatic logic pixel_at(input logic [6:0] x, input logic [5:0] y);
        logic [3:0] cell_x;
        logic [2:0] cell_y;
        logic [2:0] inner_x;
        logic [2:0] inner_y;
        logic hit_snake;
        logic hit_food;
        int k;
        begin
            cell_x = x[6:3];
            cell_y = y[5:3];
            inner_x = x[2:0];
            inner_y = y[2:0];
            hit_snake = 1'b0;

            for (k = 0; k < MAX_LEN; k = k + 1) begin
                if (k < snake_len) begin
                    if ((snake_x[k] == cell_x) && (snake_y[k] == cell_y)) begin
                        hit_snake = 1'b1;
                    end
                end
            end

            hit_food = (food_x == cell_x) && (food_y == cell_y);

            pixel_at = (x == 7'd0) || (x == 7'd127) || (y == 6'd0) || (y == 6'd63) ||
                       (hit_snake && (inner_x >= 3'd1) && (inner_x <= 3'd6) &&
                                     (inner_y >= 3'd1) && (inner_y <= 3'd6)) ||
                       (hit_food  && (inner_x >= 3'd2) && (inner_x <= 3'd5) &&
                                     (inner_y >= 3'd2) && (inner_y <= 3'd5));

            if (game_over && tick_count[20] && (y == 6'd31 || y == 6'd32)) begin
                pixel_at = 1'b1;
            end
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





