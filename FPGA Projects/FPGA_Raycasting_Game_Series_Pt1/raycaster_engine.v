`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// RAYCASTER ENGINE - THE CORE OF THE 3D SYSTEM
//
// This module is a CLOCKED STATE MACHINE, not 320 parallel raycasters.
// It reuses one arithmetic datapath to cast ray 0, then ray 1, and so on.
//
// For each screen column the engine:
//   A. Gets camera position from ray_camera_lut.
//   B. Combines camera position with player direction/camera plane.
//   C. Determines X/Y DDA step direction.
//   D. Gets reciprocal magnitudes from ray_reciprocal_lut.
//   E. Repeatedly advances to the nearest next map boundary.
//   F. Stops when the map ROM reports a wall.
//   G. Computes perpendicular distance (avoids fisheye distortion).
//   H. Converts distance to projected wall height.
//   I. Emits the completed column and advances to the next ray.
//
// LUTs are intentional FPGA design choices. Values such as angle vectors,
// camera coordinates, reciprocals and projection scale are predictable, so
// storing precomputed answers is cheaper and easier to time than implementing
// general-purpose runtime math such as division.
//
// The engine emits texture metadata even though Part 1's top-level renderer
// does not use textures yet. This lets Part 2 add textures without replacing
// the fundamental DDA engine.
///////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// Timing-clean, movable 320-column DDA raycaster with per-column depth output.
//
// The player position is Q8.8. Direction, camera plane, and ray components use
// signed Q1.8. Reciprocal and projection divisions are implemented as ROMs.
// One ray is completed at a time and written into the inactive column buffer.
// -----------------------------------------------------------------------------
module raycaster_engine (
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [15:0] player_x,
    input  wire [15:0] player_y,
    input  wire [5:0]  player_angle,
    input  wire        security_door_open,
    output reg         busy,
    output reg         done,
    output reg  [8:0]  column_addr,
    output reg  [8:0]  column_height,
    output reg  [1:0]  column_shade,
    output reg  [5:0]  column_texture_x,
    output reg  [9:0]  column_texture_step,
    output reg  [1:0]  column_wall_type,
    output reg  [15:0] column_depth,
    // Wall-fixture metadata for the wall cell hit by each ray.
    output reg  [3:0]  column_map_x,
    output reg  [3:0]  column_map_y,
    output reg         column_hit_side,
    output reg         column_write_enable
);
    localparam S_IDLE       = 5'd0;
    localparam S_VIEW       = 5'd1;
    localparam S_CAMERA     = 5'd2;
    localparam S_MULTIPLY   = 5'd3;
    localparam S_RAY_DIR    = 5'd4;
    localparam S_RECIP      = 5'd5;
    localparam S_SETUP_A    = 5'd6;
    localparam S_SETUP_B    = 5'd7;
    localparam S_STEP       = 5'd8;
    localparam S_CHECK      = 5'd9;
    localparam S_DISTANCE   = 5'd10;
    localparam S_HEIGHT     = 5'd11;
    localparam S_TEX_MUL    = 5'd12;
    localparam S_TEX_COORD  = 5'd13;
    localparam S_TEX_SAVE   = 5'd14;
    localparam S_WRITE      = 5'd15;
    localparam S_CAMERA_PIPE = 5'd16;

    reg [4:0] state;
    reg [8:0] ray_column;
    reg [15:0] player_x_latched, player_y_latched;
    reg [5:0] player_angle_latched;

    reg signed [9:0] view_dir_x, view_dir_y;
    reg signed [9:0] view_plane_x, view_plane_y;
    (* keep = "true" *) reg signed [9:0] camera_x_lookup_reg;
    (* keep = "true" *) reg signed [9:0] camera_x_reg;
    reg signed [19:0] plane_product_x, plane_product_y;
    reg signed [9:0] ray_dir_x, ray_dir_y;
    reg [8:0] abs_ray_x, abs_ray_y;
    reg step_x_negative, step_y_negative;

    reg [4:0] map_x, map_y;
    reg [15:0] delta_dist_x, delta_dist_y;
    reg [15:0] side_dist_x, side_dist_y;
    reg [8:0] boundary_x, boundary_y;
    reg hit_side;
    reg [5:0] dda_steps;
    reg [15:0] perpendicular_distance;
    reg [7:0] distance_index_reg;
    reg [1:0] hit_wall_type;
    reg signed [25:0] wall_coordinate_product;
    reg signed [16:0] wall_coordinate_q8_8;

    wire signed [9:0] lut_dir_x, lut_dir_y, lut_plane_x, lut_plane_y;
    ray_angle_lut view_lut(
        .angle(player_angle_latched),
        .dir_x(lut_dir_x), .dir_y(lut_dir_y),
        .plane_x(lut_plane_x), .plane_y(lut_plane_y)
    );

    wire signed [9:0] camera_x_lut;
    ray_camera_lut camera_lut(
        .column(ray_column), .camera_x(camera_x_lut)
    );

    wire [15:0] reciprocal_x, reciprocal_y;
    ray_reciprocal_lut reciprocal_lut_x(
        .magnitude(abs_ray_x), .reciprocal(reciprocal_x)
    );
    ray_reciprocal_lut reciprocal_lut_y(
        .magnitude(abs_ray_y), .reciprocal(reciprocal_y)
    );

    // Dynamic door override. The map ROM remains static so the rest of
    // Sector 1 is untouched; once unlocked, DDA rays treat cell (8,7) as empty.
    wire wall_hit_raw;
    wire [1:0] map_wall_type;
    ray_map_rom map_rom(
        .map_x(map_x[3:0]), .map_y(map_y[3:0]),
        .wall(wall_hit_raw), .wall_type(map_wall_type)
    );
    wire security_door_cell = (map_x[3:0] == 4'd8) && (map_y[3:0] == 4'd7);
    wire wall_hit = wall_hit_raw && !(security_door_open && security_door_cell);

    wire [23:0] side_product_x = boundary_x * delta_dist_x;
    wire [23:0] side_product_y = boundary_y * delta_dist_y;

    wire [8:0] height_from_lut;
    wire [9:0] texture_step_from_lut;
    ray_height_lut height_lut(
        .distance_index(distance_index_reg), .wall_height(height_from_lut)
    );
    ray_texture_step_lut texture_step_lut(
        .distance_index(distance_index_reg), .texture_step(texture_step_from_lut)
    );

    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            column_write_enable <= 1'b0;
            ray_column <= 9'd0;
            column_addr <= 9'd0;
            column_height <= 9'd0;
            column_shade <= 2'd0;
            column_texture_x <= 6'd0;
            column_texture_step <= 10'd8;
            column_wall_type <= 2'd0;
            column_depth <= 16'hffff;
            player_x_latched <= 16'h0380;
            player_y_latched <= 16'h0480;
            player_angle_latched <= 6'd0;
            view_dir_x <= 10'sd256; view_dir_y <= 10'sd0;
            view_plane_x <= 10'sd0; view_plane_y <= 10'sd169;
            camera_x_lookup_reg <= 10'sd0;
            camera_x_reg <= 10'sd0;
            plane_product_x <= 20'sd0; plane_product_y <= 20'sd0;
            ray_dir_x <= 10'sd256; ray_dir_y <= 10'sd0;
            abs_ray_x <= 9'd256; abs_ray_y <= 9'd0;
            step_x_negative <= 1'b0; step_y_negative <= 1'b0;
            map_x <= 5'd3; map_y <= 5'd4;
            delta_dist_x <= 16'd256; delta_dist_y <= 16'hffff;
            side_dist_x <= 16'd0; side_dist_y <= 16'd0;
            boundary_x <= 9'd0; boundary_y <= 9'd0;
            hit_side <= 1'b0;
            dda_steps <= 6'd0;
            perpendicular_distance <= 16'd0;
            distance_index_reg <= 8'd0;
            hit_wall_type <= 2'd0;
            wall_coordinate_product <= 26'sd0;
            wall_coordinate_q8_8 <= 17'sd0;
        end else begin
            done <= 1'b0;
            column_write_enable <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        ray_column <= 9'd0;
                        player_x_latched <= player_x;
                        player_y_latched <= player_y;
                        player_angle_latched <= player_angle;
                        state <= S_VIEW;
                    end
                end

                // Capture direction and camera plane once for the whole frame.
                S_VIEW: begin
                    view_dir_x <= lut_dir_x;
                    view_dir_y <= lut_dir_y;
                    view_plane_x <= lut_plane_x;
                    view_plane_y <= lut_plane_y;
                    state <= S_CAMERA;
                end

                S_CAMERA: begin
                    // First register isolates the large 320-entry camera ROM.
                    camera_x_lookup_reg <= camera_x_lut;
                    state <= S_CAMERA_PIPE;
                end

                S_CAMERA_PIPE: begin
                    // Second explicit register prevents Vivado from merging the
                    // camera lookup directly into the plane multiplier input.
                    camera_x_reg <= camera_x_lookup_reg;
                    state <= S_MULTIPLY;
                end

                // DSP-friendly registered camera-plane products.
                S_MULTIPLY: begin
                    plane_product_x <= view_plane_x * camera_x_reg;
                    plane_product_y <= view_plane_y * camera_x_reg;
                    state <= S_RAY_DIR;
                end

                S_RAY_DIR: begin
                    ray_dir_x <= view_dir_x + (plane_product_x >>> 8);
                    ray_dir_y <= view_dir_y + (plane_product_y >>> 8);
                    step_x_negative <= (view_dir_x + (plane_product_x >>> 8)) < 0;
                    step_y_negative <= (view_dir_y + (plane_product_y >>> 8)) < 0;
                    if ((view_dir_x + (plane_product_x >>> 8)) < 0)
                        abs_ray_x <= -(view_dir_x + (plane_product_x >>> 8));
                    else
                        abs_ray_x <= view_dir_x + (plane_product_x >>> 8);
                    if ((view_dir_y + (plane_product_y >>> 8)) < 0)
                        abs_ray_y <= -(view_dir_y + (plane_product_y >>> 8));
                    else
                        abs_ray_y <= view_dir_y + (plane_product_y >>> 8);
                    state <= S_RECIP;
                end

                S_RECIP: begin
                    delta_dist_x <= reciprocal_x;
                    delta_dist_y <= reciprocal_y;
                    state <= S_SETUP_A;
                end

                S_SETUP_A: begin
                    map_x <= {1'b0, player_x_latched[11:8]};
                    map_y <= {1'b0, player_y_latched[11:8]};
                    if (step_x_negative)
                        boundary_x <= {1'b0, player_x_latched[7:0]};
                    else
                        boundary_x <= 9'd256 - {1'b0, player_x_latched[7:0]};
                    if (step_y_negative)
                        boundary_y <= {1'b0, player_y_latched[7:0]};
                    else
                        boundary_y <= 9'd256 - {1'b0, player_y_latched[7:0]};
                    dda_steps <= 6'd0;
                    state <= S_SETUP_B;
                end

                S_SETUP_B: begin
                    side_dist_x <= side_product_x[23:8];
                    side_dist_y <= side_product_y[23:8];
                    state <= S_STEP;
                end

                S_STEP: begin
                    dda_steps <= dda_steps + 6'd1;
                    if (side_dist_x < side_dist_y) begin
                        side_dist_x <= side_dist_x + delta_dist_x;
                        if (step_x_negative)
                            map_x <= map_x - 5'd1;
                        else
                            map_x <= map_x + 5'd1;
                        hit_side <= 1'b0;
                    end else begin
                        side_dist_y <= side_dist_y + delta_dist_y;
                        if (step_y_negative)
                            map_y <= map_y - 5'd1;
                        else
                            map_y <= map_y + 5'd1;
                        hit_side <= 1'b1;
                    end
                    state <= S_CHECK;
                end

                S_CHECK: begin
                    if (wall_hit || map_x[4] || map_y[4] || dda_steps == 6'd31) begin
                        hit_wall_type <= wall_hit ? map_wall_type : 2'd0;
                        if (hit_side)
                            perpendicular_distance <= side_dist_y - delta_dist_y;
                        else
                            perpendicular_distance <= side_dist_x - delta_dist_x;
                        state <= S_DISTANCE;
                    end else begin
                        state <= S_STEP;
                    end
                end

                S_DISTANCE: begin
                    if (perpendicular_distance[15:4] > 12'd255)
                        distance_index_reg <= 8'd255;
                    else
                        distance_index_reg <= perpendicular_distance[11:4];
                    state <= S_HEIGHT;
                end

                S_HEIGHT: begin
                    column_height <= height_from_lut;
                    column_texture_step <= texture_step_from_lut;
                    column_wall_type <= hit_wall_type;
                    column_depth <= perpendicular_distance;
                    column_map_x <= map_x[3:0];
                    column_map_y <= map_y[3:0];
                    column_hit_side <= hit_side;
                    if (hit_side)
                        column_shade <= (distance_index_reg > 8'd96) ? 2'd3 : 2'd2;
                    else
                        column_shade <= (distance_index_reg > 8'd96) ? 2'd1 : 2'd0;
                    state <= S_TEX_MUL;
                end

                // Find the exact fractional position where the ray struck the wall.
                S_TEX_MUL: begin
                    if (hit_side)
                        wall_coordinate_product <= $signed({1'b0, perpendicular_distance}) * ray_dir_x;
                    else
                        wall_coordinate_product <= $signed({1'b0, perpendicular_distance}) * ray_dir_y;
                    state <= S_TEX_COORD;
                end

                S_TEX_COORD: begin
                    if (hit_side)
                        wall_coordinate_q8_8 <= $signed({1'b0, player_x_latched}) + (wall_coordinate_product >>> 8);
                    else
                        wall_coordinate_q8_8 <= $signed({1'b0, player_y_latched}) + (wall_coordinate_product >>> 8);
                    state <= S_TEX_SAVE;
                end

                S_TEX_SAVE: begin
                    // Flip selected faces so adjacent corners keep a consistent orientation.
                    if ((!hit_side && !step_x_negative) || (hit_side && step_y_negative))
                        column_texture_x <= 6'd63 - wall_coordinate_q8_8[7:2];
                    else
                        column_texture_x <= wall_coordinate_q8_8[7:2];
                    state <= S_WRITE;
                end

                S_WRITE: begin
                    column_addr <= ray_column;
                    column_write_enable <= 1'b1;
                    if (ray_column == 9'd319) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        state <= S_IDLE;
                    end else begin
                        ray_column <= ray_column + 9'd1;
                        state <= S_CAMERA;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule


