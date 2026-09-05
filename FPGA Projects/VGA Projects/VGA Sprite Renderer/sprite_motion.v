`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Frame-synchronized sprite position controller.
//
// Controls:
//   SW[3:0]   : speed (0 = 1 pixel/frame ... 15 = 16 pixels/frame)
//   SW[4]     : pause
//   SW[15:14] : motion mode
//               00 = diagonal bounce
//               01 = horizontal only
//               10 = vertical only
//               11 = diagonal bounce
//   BTNC      : reset sprite to center
//
// Position changes happen only on frame_tick, so every active video frame uses
// one consistent sprite position.
// -----------------------------------------------------------------------------
module sprite_motion (
    input  wire       pix_clk,      // from vga timing
    input  wire       reset,        // btnC         -> global reset
    input  wire       frame_tick,   // from vga timing
    input  wire [3:0] speed_sel,    // sw[3:0]      -> speed mode
    input  wire       pause,        // sw4          -> disable movement
    input  wire [1:0] mode,         // sw[15:14]    -> direction mode
    output reg  [9:0] sprite_x,     // to sprite renderer
    output reg  [8:0] sprite_y      // to sprite renderer
);

    localparam integer SCREEN_W = 640;
    localparam integer SCREEN_H = 480;
    localparam integer SPRITE_W = 32;
    localparam integer SPRITE_H = 32;

    localparam [9:0] X_MAX = SCREEN_W - SPRITE_W; // 608
    localparam [8:0] Y_MAX = SCREEN_H - SPRITE_H; // 448

    reg dir_x = 1'b1; // 1 = right, 0 = left
    reg dir_y = 1'b1; // 1 = down,  0 = up

    wire [5:0] speed = {2'b00, speed_sel} + 6'd1;

    wire move_x = (mode == 2'b00) || (mode == 2'b01) || (mode == 2'b11);
    wire move_y = (mode == 2'b00) || (mode == 2'b10) || (mode == 2'b11);

    always @(posedge pix_clk) begin
        if (reset) begin
            sprite_x <= 10'd304; // (640 - 32) / 2
            sprite_y <=  9'd224; // (480 - 32) / 2
            dir_x    <= 1'b1;
            dir_y    <= 1'b1;
        end else if (frame_tick && !pause) begin

            // Horizontal movement / bounce.
            if (move_x) begin
                if (dir_x) begin
                    if (sprite_x + speed >= X_MAX) begin
                        sprite_x <= X_MAX;
                        dir_x    <= 1'b0;
                    end else begin
                        sprite_x <= sprite_x + speed;
                    end
                end else begin
                    if (sprite_x <= speed) begin
                        sprite_x <= 10'd0;
                        dir_x    <= 1'b1;
                    end else begin
                        sprite_x <= sprite_x - speed;
                    end
                end
            end

            // Vertical movement / bounce.
            if (move_y) begin
                if (dir_y) begin
                    if (sprite_y + speed >= Y_MAX) begin
                        sprite_y <= Y_MAX;
                        dir_y    <= 1'b0;
                    end else begin
                        sprite_y <= sprite_y + speed;
                    end
                end else begin
                    if (sprite_y <= speed) begin
                        sprite_y <= 9'd0;
                        dir_y    <= 1'b1;
                    end else begin
                        sprite_y <= sprite_y - speed;
                    end
                end
            end
        end
    end

endmodule
