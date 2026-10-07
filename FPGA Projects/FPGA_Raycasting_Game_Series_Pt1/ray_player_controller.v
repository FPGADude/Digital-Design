`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// PLAYER CONTROLLER
//
// Maintains the player's world position and viewing angle.
//
// Position format: unsigned Q8.8
//   bits [15:8] = map-cell integer portion
//   bits [7:0]  = fraction within the cell
//
// Angle format: 6 bits = 64 discrete headings around 360 degrees.
// The angle LUT converts this compact angle into signed direction vectors.
//
// Movement is updated once per VGA frame rather than at 100 MHz. This gives
// predictable human-scale motion and keeps movement independent of raw clock
// speed. Collision is checked before committing a candidate position.
///////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// Frame-synchronized player movement and collision controller.
//
// Position is unsigned Q8.8 map coordinates. The controller updates once every
// three VGA frames while a button is held, producing controlled movement and
// rotation without needing a mechanical-button pulse for every step.
// -----------------------------------------------------------------------------
module ray_player_controller(
    input  wire        clk,
    input  wire        reset,
    input  wire        frame_tick,
    input  wire        btn_up,
    input  wire        btn_down,
    input  wire        btn_left,
    input  wire        btn_right,
    input  wire        security_door_open,
    output reg  [15:0] player_x,
    output reg  [15:0] player_y,
    output reg  [5:0]  player_angle
);
    localparam [15:0] START_X = 16'h0380; // 3.5 map cells
    localparam [15:0] START_Y = 16'h0480; // 4.5 map cells
    localparam [5:0]  START_ANGLE = 6'd0; // east

    reg up_meta, up_sync, down_meta, down_sync;
    reg left_meta, left_sync, right_meta, right_sync;
    reg [1:0] frame_divider;

    wire signed [9:0] dir_x;
    wire signed [9:0] dir_y;
    wire signed [9:0] unused_plane_x;
    wire signed [9:0] unused_plane_y;

    ray_angle_lut angle_lut(
        .angle(player_angle),
        .dir_x(dir_x), .dir_y(dir_y),
        .plane_x(unused_plane_x), .plane_y(unused_plane_y)
    );

    // One movement step is 1/16 map cell. Reversing simply negates the vector.
    wire signed [10:0] forward_dx = dir_x >>> 4;
    wire signed [10:0] forward_dy = dir_y >>> 4;
    wire signed [10:0] selected_dx = down_sync ? -forward_dx : forward_dx;
    wire signed [10:0] selected_dy = down_sync ? -forward_dy : forward_dy;
    wire move_requested = up_sync ^ down_sync;

    wire signed [16:0] candidate_x_signed = $signed({1'b0, player_x}) + selected_dx;
    wire signed [16:0] candidate_y_signed = $signed({1'b0, player_y}) + selected_dy;
    wire [15:0] candidate_x = candidate_x_signed[15:0];
    wire [15:0] candidate_y = candidate_y_signed[15:0];

    // Separate X and Y collision checks allow the player to slide along walls.
    // This keeps the ROM itself static and applies one narrow dynamic
    // override for the Sector 1 security door at cell (8,7). This avoids
    // redesigning the map storage while allowing collision to become passable
    // after the player unlocks the door.
    wire wall_at_candidate_x_raw;
    wire wall_at_candidate_y_raw;
    ray_map_rom collision_x_rom(
        .map_x(candidate_x[11:8]), .map_y(player_y[11:8]),
        .wall(wall_at_candidate_x_raw), .wall_type()
    );
    ray_map_rom collision_y_rom(
        .map_x(player_x[11:8]), .map_y(candidate_y[11:8]),
        .wall(wall_at_candidate_y_raw), .wall_type()
    );

    wire candidate_x_is_open_door = security_door_open &&
        (candidate_x[11:8] == 4'd8) && (player_y[11:8] == 4'd7);
    wire candidate_y_is_open_door = security_door_open &&
        (player_x[11:8] == 4'd8) && (candidate_y[11:8] == 4'd7);

    wire wall_at_candidate_x = wall_at_candidate_x_raw && !candidate_x_is_open_door;
    wire wall_at_candidate_y = wall_at_candidate_y_raw && !candidate_y_is_open_door;

    always @(posedge clk) begin
        if (reset) begin
            up_meta       <= 1'b0;
            up_sync       <= 1'b0;
            down_meta     <= 1'b0;
            down_sync     <= 1'b0;
            left_meta     <= 1'b0;
            left_sync     <= 1'b0;
            right_meta    <= 1'b0;
            right_sync    <= 1'b0;
            frame_divider <= 2'd0;
            player_x      <= START_X;
            player_y      <= START_Y;
            player_angle  <= START_ANGLE;
        end else begin
            // Two-flop synchronizers for the four asynchronous pushbuttons.
            up_meta    <= btn_up;
            up_sync    <= up_meta;
            down_meta  <= btn_down;
            down_sync  <= down_meta;
            left_meta  <= btn_left;
            left_sync  <= left_meta;
            right_meta <= btn_right;
            right_sync <= right_meta;

            if (frame_tick) begin
                if (frame_divider == 2'd2) begin
                    frame_divider <= 2'd0;

                    // Rotation has priority over translation.
                    if (left_sync && !right_sync)
                        player_angle <= player_angle - 6'd1;
                    else if (right_sync && !left_sync)
                        player_angle <= player_angle + 6'd1;
                    else if (move_requested) begin
                        if (!wall_at_candidate_x)
                            player_x <= candidate_x;
                        if (!wall_at_candidate_y)
                            player_y <= candidate_y;
                    end
                end else begin
                    frame_divider <= frame_divider + 2'd1;
                end
            end
        end
    end
endmodule
