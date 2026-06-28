`timescale 1ns / 1ps

// ------------------------------------------------------------
// Invaders for 128x64 SSD1306 OLED
// Standard arcade game interface:
//   - Owns game state
//   - Receives current OLED page/column
//   - Outputs one 8-bit vertical SSD1306 framebuffer byte
//
// Gameplay v1:
//   - Player cannon at bottom
//   - Left/right moves player
//   - A or Start fires one shot
//   - Shot removes invader on hit
//   - Invader block marches left/right and steps down at edges
//   - A or Start restarts board after clear or landing
// ------------------------------------------------------------
module invaders_game #(
    parameter int CLK_HZ = 12_000_000,
    parameter int PLAYER_HZ = 55,
    parameter int BULLET_HZ = 42,
    parameter int ALIEN_HZ  = 4
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

    localparam int PLAYER_TICK_CLKS = CLK_HZ / PLAYER_HZ;
    localparam int BULLET_TICK_CLKS = CLK_HZ / BULLET_HZ;
    localparam int ALIEN_TICK_CLKS  = CLK_HZ / ALIEN_HZ;

    localparam int ALIEN_COLS = 6;
    localparam int ALIEN_ROWS = 3;

    localparam logic [6:0] PLAYER_W = 7'd11;
    localparam logic [5:0] PLAYER_Y = 6'd58;

    localparam logic [6:0] ALIEN_W = 7'd8;
    localparam logic [5:0] ALIEN_H = 6'd5;
    localparam logic [6:0] ALIEN_GAP_X = 7'd7;
    localparam logic [5:0] ALIEN_GAP_Y = 6'd4;

    logic [31:0] player_tick_count;
    logic [31:0] bullet_tick_count;
    logic [31:0] alien_tick_count;

    logic [6:0] player_x;

    logic bullet_active;
    logic [6:0] bullet_x;
    logic [5:0] bullet_y;

    logic [6:0] alien_x0;
    logic [5:0] alien_y0;
    logic       alien_dir_right;

    logic active_d;
    logic game_over;
    logic cleared;

    logic aliens [0:ALIEN_ROWS-1][0:ALIEN_COLS-1];

    task automatic load_aliens;
        int r;
        int c;
        begin
            for (r = 0; r < ALIEN_ROWS; r = r + 1) begin
                for (c = 0; c < ALIEN_COLS; c = c + 1) begin
                    aliens[r][c] <= 1'b1;
                end
            end
        end
    endtask

    task automatic reset_invaders;
        begin
            player_tick_count <= '0;
            bullet_tick_count <= '0;
            alien_tick_count  <= '0;

            player_x <= 7'd58;
            bullet_active <= 1'b0;
            bullet_x <= 7'd0;
            bullet_y <= 6'd0;

            alien_x0 <= 7'd10;
            alien_y0 <= 6'd8;
            alien_dir_right <= 1'b1;

            game_over <= 1'b0;
            cleared <= 1'b0;
            load_aliens();
        end
    endtask

    function automatic logic any_alien_alive;
        int r;
        int c;
        begin
            any_alien_alive = 1'b0;
            for (r = 0; r < ALIEN_ROWS; r = r + 1) begin
                for (c = 0; c < ALIEN_COLS; c = c + 1) begin
                    if (aliens[r][c]) begin
                        any_alien_alive = 1'b1;
                    end
                end
            end
        end
    endfunction

    function automatic logic lowest_alien_at_bottom;
        int r;
        int c;
        logic [5:0] ay1;
        begin
            lowest_alien_at_bottom = 1'b0;
            for (r = 0; r < ALIEN_ROWS; r = r + 1) begin
                for (c = 0; c < ALIEN_COLS; c = c + 1) begin
                    ay1 = alien_y0 + r[5:0] * (ALIEN_H + ALIEN_GAP_Y) + ALIEN_H - 1'b1;
                    if (aliens[r][c] && ay1 >= 6'd54) begin
                        lowest_alien_at_bottom = 1'b1;
                    end
                end
            end
        end
    endfunction

    function automatic logic alien_block_hit_left;
        int r;
        int c;
        logic [6:0] ax0;
        begin
            alien_block_hit_left = 1'b0;
            for (r = 0; r < ALIEN_ROWS; r = r + 1) begin
                for (c = 0; c < ALIEN_COLS; c = c + 1) begin
                    ax0 = alien_x0 + c[6:0] * (ALIEN_W + ALIEN_GAP_X);
                    if (aliens[r][c] && ax0 <= 7'd2) begin
                        alien_block_hit_left = 1'b1;
                    end
                end
            end
        end
    endfunction

    function automatic logic alien_block_hit_right;
        int r;
        int c;
        logic [6:0] ax1;
        begin
            alien_block_hit_right = 1'b0;
            for (r = 0; r < ALIEN_ROWS; r = r + 1) begin
                for (c = 0; c < ALIEN_COLS; c = c + 1) begin
                    ax1 = alien_x0 + c[6:0] * (ALIEN_W + ALIEN_GAP_X) + ALIEN_W - 1'b1;
                    if (aliens[r][c] && ax1 >= 7'd125) begin
                        alien_block_hit_right = 1'b1;
                    end
                end
            end
        end
    endfunction

    function automatic logic bullet_hits_alien(
        input  logic [6:0] x,
        input  logic [5:0] y,
        output int hit_r,
        output int hit_c
    );
        int r;
        int c;
        logic [6:0] ax0;
        logic [6:0] ax1;
        logic [5:0] ay0;
        logic [5:0] ay1;
        begin
            bullet_hits_alien = 1'b0;
            hit_r = 0;
            hit_c = 0;

            for (r = 0; r < ALIEN_ROWS; r = r + 1) begin
                for (c = 0; c < ALIEN_COLS; c = c + 1) begin
                    ax0 = alien_x0 + c[6:0] * (ALIEN_W + ALIEN_GAP_X);
                    ax1 = ax0 + ALIEN_W - 1'b1;
                    ay0 = alien_y0 + r[5:0] * (ALIEN_H + ALIEN_GAP_Y);
                    ay1 = ay0 + ALIEN_H - 1'b1;

                    if (aliens[r][c] && x >= ax0 && x <= ax1 && y >= ay0 && y <= ay1) begin
                        bullet_hits_alien = 1'b1;
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

        if (reset) begin
            active_d <= 1'b0;
            audio_event <= 4'd0;
            reset_invaders();
        end else begin
            audio_event <= 4'd0;
            active_d <= game_active;

            if (game_active && !active_d) begin
                audio_event <= 4'd2;
                reset_invaders();
            end else if (game_active) begin
                if ((game_over || cleared) && (btn_a || btn_start)) begin
                    audio_event <= 4'd2;
                    reset_invaders();
                end else if (!game_over && !cleared) begin
                    if (!any_alien_alive()) begin
                        cleared <= 1'b1;
                        audio_event <= 4'd2;
                        bullet_active <= 1'b0;
                    end else if (lowest_alien_at_bottom()) begin
                        game_over <= 1'b1;
                        audio_event <= 4'd5;
                        bullet_active <= 1'b0;
                    end else begin
                        // Player movement.
                        if (player_tick_count == PLAYER_TICK_CLKS-1) begin
                            player_tick_count <= '0;
                            if ((btn_left || btn_down) && player_x > 7'd2) begin
                                player_x <= player_x - 1'b1;
                            end else if ((btn_right || btn_up) && player_x < (7'd126 - PLAYER_W)) begin
                                player_x <= player_x + 1'b1;
                            end
                        end else begin
                            player_tick_count <= player_tick_count + 1'b1;
                        end

                        // Fire. One bullet on screen at a time.
                        if ((btn_a || btn_start) && !bullet_active) begin
                            audio_event <= 4'd6;
                            bullet_active <= 1'b1;
                            bullet_x <= player_x + (PLAYER_W >> 1);
                            bullet_y <= PLAYER_Y - 6'd2;
                        end

                        // Bullet movement and hit test.
                        if (bullet_tick_count == BULLET_TICK_CLKS-1) begin
                            bullet_tick_count <= '0;
                            if (bullet_active) begin
                                if (bullet_hits_alien(bullet_x, bullet_y, hit_r, hit_c)) begin
                                    audio_event <= 4'd4;
                                    aliens[hit_r][hit_c] <= 1'b0;
                                    bullet_active <= 1'b0;
                                end else if (bullet_y <= 6'd1) begin
                                    bullet_active <= 1'b0;
                                end else begin
                                    bullet_y <= bullet_y - 1'b1;
                                end
                            end
                        end else begin
                            bullet_tick_count <= bullet_tick_count + 1'b1;
                        end

                        // Alien movement.
                        if (alien_tick_count == ALIEN_TICK_CLKS-1) begin
                            alien_tick_count <= '0;

                            if (alien_dir_right) begin
                                if (alien_block_hit_right()) begin
                                    audio_event <= 4'd3;
                                    alien_dir_right <= 1'b0;
                                    alien_y0 <= alien_y0 + 1'b1;
                                end else begin
                                    alien_x0 <= alien_x0 + 1'b1;
                                end
                            end else begin
                                if (alien_block_hit_left()) begin
                                    audio_event <= 4'd3;
                                    alien_dir_right <= 1'b1;
                                    alien_y0 <= alien_y0 + 1'b1;
                                end else begin
                                    alien_x0 <= alien_x0 - 1'b1;
                                end
                            end
                        end else begin
                            alien_tick_count <= alien_tick_count + 1'b1;
                        end
                    end
                end
            end else begin
                player_tick_count <= '0;
                bullet_tick_count <= '0;
                alien_tick_count  <= '0;
            end
        end
    end

    function automatic logic alien_pixel(input logic [6:0] x, input logic [5:0] y);
        int r;
        int c;
        logic [6:0] ax0;
        logic [6:0] ax1;
        logic [5:0] ay0;
        logic [5:0] ay1;
        logic [3:0] lx;
        logic [2:0] ly;
        begin
            alien_pixel = 1'b0;
            for (r = 0; r < ALIEN_ROWS; r = r + 1) begin
                for (c = 0; c < ALIEN_COLS; c = c + 1) begin
                    ax0 = alien_x0 + c[6:0] * (ALIEN_W + ALIEN_GAP_X);
                    ax1 = ax0 + ALIEN_W - 1'b1;
                    ay0 = alien_y0 + r[5:0] * (ALIEN_H + ALIEN_GAP_Y);
                    ay1 = ay0 + ALIEN_H - 1'b1;

                    if (aliens[r][c] && x >= ax0 && x <= ax1 && y >= ay0 && y <= ay1) begin
                        lx = x - ax0;
                        ly = y - ay0;
                        // Simple 8x5 invader shape.
                        case (ly)
                            3'd0: alien_pixel = (lx == 4'd1 || lx == 4'd6);
                            3'd1: alien_pixel = (lx == 4'd2 || lx == 4'd5);
                            3'd2: alien_pixel = (lx >= 4'd1 && lx <= 4'd6);
                            3'd3: alien_pixel = (lx == 4'd0 || lx == 4'd2 || lx == 4'd3 || lx == 4'd4 || lx == 4'd5 || lx == 4'd7);
                            3'd4: alien_pixel = (lx == 4'd0 || lx == 4'd2 || lx == 4'd5 || lx == 4'd7);
                            default: alien_pixel = 1'b0;
                        endcase
                    end
                end
            end
        end
    endfunction

    function automatic logic player_pixel(input logic [6:0] x, input logic [5:0] y);
        logic [3:0] lx;
        begin
            player_pixel = 1'b0;
            if (x >= player_x && x < (player_x + PLAYER_W) && y >= PLAYER_Y && y <= 6'd62) begin
                lx = x - player_x;
                case (y - PLAYER_Y)
                    6'd0: player_pixel = (lx == 4'd5);
                    6'd1: player_pixel = (lx >= 4'd4 && lx <= 4'd6);
                    6'd2: player_pixel = (lx >= 4'd2 && lx <= 4'd8);
                    6'd3: player_pixel = (lx >= 4'd1 && lx <= 4'd9);
                    default: player_pixel = 1'b1;
                endcase
            end
        end
    endfunction

    function automatic logic pixel_at(input logic [6:0] x, input logic [5:0] y);
        logic border;
        logic bullet_pixel;
        logic cleared_banner;
        logic gameover_banner;
        begin
            border = (x == 7'd0) || (x == 7'd127) || (y == 6'd0) || (y == 6'd63);
            bullet_pixel = bullet_active && (x == bullet_x) && (y >= bullet_y) && (y <= bullet_y + 6'd3);

            // Very simple status banners that do not need the font renderer.
            cleared_banner  = cleared  && (y >= 6'd28 && y <= 6'd35) && (x >= 7'd34 && x <= 7'd93) && (((x[2:0] == 3'd0) || (y[2:0] == 3'd0)));
            gameover_banner = game_over && (y >= 6'd28 && y <= 6'd35) && (x >= 7'd28 && x <= 7'd99) && (((x[2:0] == 3'd0) || (y[2:0] == 3'd0)));

            pixel_at = border | alien_pixel(x, y) | player_pixel(x, y) | bullet_pixel | cleared_banner | gameover_banner;
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



