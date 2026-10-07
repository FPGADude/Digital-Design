`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// FPGA Discovery - FPGA Raycasting, Part 1
// Flat-Colored 3D Raycaster + Live Minimap
//
// PURPOSE
// -------
// This is the integration/top-level module. It connects:
//
//     1. Basys 3 or NES controller input
//     2. Q8.8 player position and viewing angle
//     3. Sequential 320-ray DDA engine
//     4. Double-buffered ray-column data
//     5. 640x480 VGA renderer
//     6. Educational minimap overlay
//
// One ray represents two horizontal VGA pixels:
//
//     320 rays x 2 pixels = 640 VGA pixels
//
// The raycaster writes the next completed scene into one column-buffer bank
// while VGA displays the previous bank. The banks swap only after a complete
// raycast frame is ready.
///////////////////////////////////////////////////////////////////////////////

module raycasting_top (
	input  wire       clk,

	input  wire       btnC,
	input  wire       btnU,
	input  wire       btnD,
	input  wire       btnL,
	input  wire       btnR,

	input  wire       sw15,

	input  wire       nes_data,
	output wire       nes_latch,
	output wire       nes_clk,

	output wire       Hsync,
	output wire       Vsync,

	output reg  [3:0] vgaRed,
	output reg  [3:0] vgaGreen,
	output reg  [3:0] vgaBlue,

	output wire       led15
);


	///////////////////////////////////////////////////////////////////////////
	// INPUT MODE
	///////////////////////////////////////////////////////////////////////////

	// SW15 selects the active controller:
	//
	//     0 = Basys 3 pushbuttons
	//     1 = NES controller
	//
	// LD15 mirrors the selected mode.

	assign led15 = sw15;


	///////////////////////////////////////////////////////////////////////////
	// NES CONTROLLER
	///////////////////////////////////////////////////////////////////////////

	wire nes_a;
	wire nes_b;
	wire nes_select;
	wire nes_start;

	wire nes_up;
	wire nes_down;
	wire nes_left;
	wire nes_right;

	nes_controller nes (
		.clk      (clk),
		.reset    (btnC),
		.data     (nes_data),

		.latch    (nes_latch),
		.nes_clk  (nes_clk),

		.A        (nes_a),
		.B        (nes_b),
		.select   (nes_select),
		.start    (nes_start),

		.up       (nes_up),
		.down     (nes_down),
		.left     (nes_left),
		.right    (nes_right)
	);


	///////////////////////////////////////////////////////////////////////////
	// BASYS 3 BUTTON DEBOUNCING
	///////////////////////////////////////////////////////////////////////////

	wire basys_up;
	wire basys_down;
	wire basys_left;
	wire basys_right;


	button_debouncer #(
		.STABLE_MS (10)
	) debounce_up (
		.clk       (clk),
		.reset     (btnC),
		.noisy_in  (btnU),
		.clean_out (basys_up)
	);


	button_debouncer #(
		.STABLE_MS (10)
	) debounce_down (
		.clk       (clk),
		.reset     (btnC),
		.noisy_in  (btnD),
		.clean_out (basys_down)
	);


	button_debouncer #(
		.STABLE_MS (10)
	) debounce_left (
		.clk       (clk),
		.reset     (btnC),
		.noisy_in  (btnL),
		.clean_out (basys_left)
	);


	button_debouncer #(
		.STABLE_MS (10)
	) debounce_right (
		.clk       (clk),
		.reset     (btnC),
		.noisy_in  (btnR),
		.clean_out (basys_right)
	);


	///////////////////////////////////////////////////////////////////////////
	// ACTIVE CONTROL SIGNALS
	///////////////////////////////////////////////////////////////////////////

	wire move_up;
	wire move_down;
	wire turn_left;
	wire turn_right;
	wire reset_cmd;

	assign move_up =
		sw15 ? nes_up : basys_up;

	assign move_down =
		sw15 ? nes_down : basys_down;

	assign turn_left =
		sw15 ? nes_left : basys_left;

	assign turn_right =
		sw15 ? nes_right : basys_right;

	assign reset_cmd =
		btnC |
		(sw15 & nes_start);


	///////////////////////////////////////////////////////////////////////////
	// VGA TIMING
	///////////////////////////////////////////////////////////////////////////

	wire [9:0] pixel_x;
	wire [9:0] pixel_y;

	wire video_active;
	wire pixel_tick;
	wire frame_start;


	vga_640x480 vga (
		.clk_100mhz   (clk),
		.reset        (reset_cmd),

		.pixel_x      (pixel_x),
		.pixel_y      (pixel_y),

		.video_active (video_active),

		.hsync        (Hsync),
		.vsync        (Vsync),

		.pixel_tick   (pixel_tick),
		.frame_start  (frame_start)
	);


	///////////////////////////////////////////////////////////////////////////
	// PLAYER STATE
	///////////////////////////////////////////////////////////////////////////

	wire [15:0] player_x;
	wire [15:0] player_y;

	wire [5:0] player_angle;


	ray_player_controller player (
		.clk                (clk),
		.reset              (reset_cmd),
		.frame_tick         (frame_start),

		.btn_up             (move_up),
		.btn_down           (move_down),
		.btn_left           (turn_left),
		.btn_right          (turn_right),

		.security_door_open (1'b0),

		.player_x           (player_x),
		.player_y           (player_y),
		.player_angle       (player_angle)
	);


	///////////////////////////////////////////////////////////////////////////
	// SEQUENTIAL 320-RAY ENGINE
	///////////////////////////////////////////////////////////////////////////

	reg engine_start = 1'b0;

	wire engine_busy;
	wire engine_done;

	wire [8:0] col_addr;
	wire [8:0] col_height;

	wire [1:0] col_shade;
	wire [1:0] col_wall_type;

	wire [5:0] col_tex_x;
	wire [9:0] col_tex_step;

	wire [15:0] col_depth;

	wire [3:0] col_map_x;
	wire [3:0] col_map_y;

	wire col_hit_side;
	wire col_we;


	raycaster_engine engine (
		.clk                 (clk),
		.reset               (reset_cmd),
		.start               (engine_start),

		.player_x            (player_x),
		.player_y            (player_y),
		.player_angle        (player_angle),

		.security_door_open  (1'b0),

		.busy                (engine_busy),
		.done                (engine_done),

		.column_addr         (col_addr),
		.column_height       (col_height),
		.column_shade        (col_shade),

		.column_texture_x    (col_tex_x),
		.column_texture_step (col_tex_step),

		.column_wall_type    (col_wall_type),
		.column_depth        (col_depth),

		.column_map_x        (col_map_x),
		.column_map_y        (col_map_y),

		.column_hit_side     (col_hit_side),
		.column_write_enable (col_we)
	);


	///////////////////////////////////////////////////////////////////////////
	// DOUBLE-BUFFER CONTROL
	///////////////////////////////////////////////////////////////////////////

	reg display_bank = 1'b0;
	reg render_bank  = 1'b1;

	reg frame_ready  = 1'b0;


	always @(posedge clk) begin

		if (reset_cmd) begin

			engine_start <= 1'b0;

			display_bank <= 1'b0;
			render_bank  <= 1'b1;

			frame_ready  <= 1'b0;

		end
		else begin

			// engine_start is intentionally a one-clock pulse.
			engine_start <= 1'b0;


			// VGA frame boundary.
			if (frame_start) begin

				// If the raycaster has completed a scene, make the completed
				// render bank visible and move rendering to the other bank.
				if (frame_ready) begin

					display_bank <= render_bank;
					render_bank  <= ~render_bank;

					frame_ready  <= 1'b0;

				end


				// Start another 320-column render when the engine is idle.
				if (!engine_busy && !frame_ready) begin

					engine_start <= 1'b1;

				end

			end


			// The sequential raycaster finishes all 320 columns well before
			// the next VGA frame boundary.
			if (engine_done) begin

				frame_ready <= 1'b1;

			end

		end

	end


	///////////////////////////////////////////////////////////////////////////
	// COLUMN BUFFER
	///////////////////////////////////////////////////////////////////////////

	// Two VGA pixels share one ray result.
	wire [8:0] read_addr;

	assign read_addr =
		pixel_x[9:1];


	wire [8:0] read_height;

	wire [1:0] read_shade;
	wire [1:0] read_wall_type;

	wire [5:0] unused_tex_x;
	wire [9:0] unused_tex_step;

	wire [15:0] unused_depth;

	wire [3:0] unused_map_x;
	wire [3:0] unused_map_y;

	wire unused_side;


	ray_column_buffer buffer (
		.clk                (clk),

		.write_bank         (render_bank),
		.write_addr         (col_addr),
		.write_height       (col_height),
		.write_shade        (col_shade),

		.write_texture_x    (col_tex_x),
		.write_texture_step (col_tex_step),

		.write_wall_type    (col_wall_type),
		.write_depth        (col_depth),

		.write_map_x        (col_map_x),
		.write_map_y        (col_map_y),

		.write_hit_side     (col_hit_side),
		.write_enable       (col_we),

		.read_bank          (display_bank),
		.read_addr          (read_addr),

		.read_height        (read_height),
		.read_shade         (read_shade),

		.read_texture_x     (unused_tex_x),
		.read_texture_step  (unused_tex_step),

		.read_wall_type     (read_wall_type),
		.read_depth         (unused_depth),

		.read_map_x         (unused_map_x),
		.read_map_y         (unused_map_y),

		.read_hit_side      (unused_side)
	);


	///////////////////////////////////////////////////////////////////////////
	// 3D WALL PROJECTION
	///////////////////////////////////////////////////////////////////////////

	wire [8:0] half_h;

	assign half_h =
		read_height >> 1;


	wire [9:0] wall_top;

	assign wall_top =
		(half_h >= 240) ?
			10'd0 :
			(10'd240 - half_h);


	wire [9:0] wall_bottom;

	assign wall_bottom =
		(half_h >= 239) ?
			10'd479 :
			(10'd240 + half_h);


	wire wall_pixel;

	assign wall_pixel =
		(pixel_y >= wall_top) &&
		(pixel_y <= wall_bottom);


	///////////////////////////////////////////////////////////////////////////
	// MINIMAP CONSTANTS
	///////////////////////////////////////////////////////////////////////////

	localparam integer MM_X0   = 12;
	localparam integer MM_Y0   = 12;
	localparam integer MM_CELL = 12;


	///////////////////////////////////////////////////////////////////////////
	// MINIMAP WORKING VALUES
	///////////////////////////////////////////////////////////////////////////

	integer mm_x;
	integer mm_y;

	integer mm_lx;
	integer mm_ly;

	integer player_cell_x;
	integer player_cell_y;

	integer player_screen_x;
	integer player_screen_y;

	integer look_x;
	integer look_y;

	integer dxp;
	integer dyp;

	integer crossp;
	integer dotp;


	reg mm_area;
	reg mm_wall;
	reg mm_grid;

	reg mm_player;
	reg mm_heading;


	///////////////////////////////////////////////////////////////////////////
	// MINIMAP MAP LOOKUP
	///////////////////////////////////////////////////////////////////////////

	function tutorial_wall;

		input [2:0] x;
		input [2:0] y;

		begin

			case ({y, x})

				// Top boundary.
				6'o00,
				6'o01,
				6'o02,
				6'o03,
				6'o04,
				6'o05,
				6'o06,
				6'o07,

				// Row 1.
				6'o10,
				6'o17,

				// Row 2.
				6'o20,
				6'o22,
				6'o23,
				6'o27,

				// Row 3.
				6'o30,
				6'o35,
				6'o37,

				// Row 4.
				6'o40,
				6'o47,

				// Row 5.
				6'o50,
				6'o52,
				6'o57,

				// Row 6.
				6'o60,
				6'o64,
				6'o67,

				// Bottom boundary.
				6'o70,
				6'o71,
				6'o72,
				6'o73,
				6'o74,
				6'o75,
				6'o76,
				6'o77: begin

					tutorial_wall = 1'b1;

				end


				default: begin

					tutorial_wall = 1'b0;

				end

			endcase

		end

	endfunction


	///////////////////////////////////////////////////////////////////////////
	// MINIMAP DIRECTION VECTOR
	///////////////////////////////////////////////////////////////////////////

	wire signed [9:0] mini_dir_x;
	wire signed [9:0] mini_dir_y;

	wire signed [9:0] mini_plane_x;
	wire signed [9:0] mini_plane_y;


	ray_angle_lut mini_angle (
		.angle   (player_angle),

		.dir_x   (mini_dir_x),
		.dir_y   (mini_dir_y),

		.plane_x (mini_plane_x),
		.plane_y (mini_plane_y)
	);


	///////////////////////////////////////////////////////////////////////////
	// VGA PIXEL RENDERER
	///////////////////////////////////////////////////////////////////////////

	always @* begin

		///////////////////////////////////////////////////////////////////////
		// DEFAULT OUTPUTS
		///////////////////////////////////////////////////////////////////////

		vgaRed   = 4'd0;
		vgaGreen = 4'd0;
		vgaBlue  = 4'd0;


		///////////////////////////////////////////////////////////////////////
		// DEFAULT MINIMAP STATE
		///////////////////////////////////////////////////////////////////////

		mm_area    = 1'b0;
		mm_wall    = 1'b0;
		mm_grid    = 1'b0;

		mm_player  = 1'b0;
		mm_heading = 1'b0;

		mm_x  = 0;
		mm_y  = 0;

		mm_lx = 0;
		mm_ly = 0;


		///////////////////////////////////////////////////////////////////////
		// PLAYER POSITION ON THE MINIMAP
		///////////////////////////////////////////////////////////////////////

		player_cell_x =
			player_x[15:8];

		player_cell_y =
			player_y[15:8];


		// Preserve the fractional Q8.8 position inside the current map cell.
		player_screen_x =
			MM_X0 +
			(player_cell_x * MM_CELL) +
			((player_x[7:0] * MM_CELL) >> 8);

		player_screen_y =
			MM_Y0 +
			(player_cell_y * MM_CELL) +
			((player_y[7:0] * MM_CELL) >> 8);


		///////////////////////////////////////////////////////////////////////
		// MINIMAP HEADING-LINE MATH
		///////////////////////////////////////////////////////////////////////

		// The angle LUT is scaled so that 256 represents 1.0.
		// Shifting by five gives a short direction vector for the minimap.
		look_x =
			mini_dir_x >>> 5;

		look_y =
			mini_dir_y >>> 5;


		dxp =
			$signed({1'b0, pixel_x}) -
			player_screen_x;

		dyp =
			$signed({1'b0, pixel_y}) -
			player_screen_y;


		crossp =
			(dxp * look_y) -
			(dyp * look_x);


		if (crossp < 0) begin

			crossp =
				-crossp;

		end


		dotp =
			(dxp * look_x) +
			(dyp * look_y);


		///////////////////////////////////////////////////////////////////////
		// ACTIVE VIDEO
		///////////////////////////////////////////////////////////////////////

		if (video_active) begin

			///////////////////////////////////////////////////////////////////
			// BASE 3D SCENE
			///////////////////////////////////////////////////////////////////

			if (wall_pixel) begin

				case (read_shade)

					2'd0: begin

						vgaRed   = 4'd4;
						vgaGreen = 4'd13;
						vgaBlue  = 4'd15;

					end


					2'd1: begin

						vgaRed   = 4'd3;
						vgaGreen = 4'd10;
						vgaBlue  = 4'd12;

					end


					2'd2: begin

						vgaRed   = 4'd2;
						vgaGreen = 4'd8;
						vgaBlue  = 4'd10;

					end


					default: begin

						vgaRed   = 4'd2;
						vgaGreen = 4'd6;
						vgaBlue  = 4'd8;

					end

				endcase

			end
			else if (pixel_y < 240) begin

				// Ceiling.
				vgaRed   = 4'd1;
				vgaGreen = 4'd1;
				vgaBlue  = 4'd3;

			end
			else begin

				// Floor.
				vgaRed   = 4'd3;
				vgaGreen = 4'd3;
				vgaBlue  = 4'd3;

			end


			///////////////////////////////////////////////////////////////////
			// MINIMAP BOUNDS
			///////////////////////////////////////////////////////////////////

			mm_area =
				(pixel_x >= MM_X0) &&
				(pixel_x < (MM_X0 + 96)) &&
				(pixel_y >= MM_Y0) &&
				(pixel_y < (MM_Y0 + 96));


			if (mm_area) begin

				///////////////////////////////////////////////////////////////
				// MAP CELL FOR THE CURRENT VGA PIXEL
				///////////////////////////////////////////////////////////////

				mm_x =
					(pixel_x - MM_X0) /
					MM_CELL;

				mm_y =
					(pixel_y - MM_Y0) /
					MM_CELL;


				mm_lx =
					(pixel_x - MM_X0) %
					MM_CELL;

				mm_ly =
					(pixel_y - MM_Y0) %
					MM_CELL;


				mm_wall =
					tutorial_wall(
						mm_x[2:0],
						mm_y[2:0]
					);


				mm_grid =
					(mm_lx == 0) ||
					(mm_ly == 0);


				///////////////////////////////////////////////////////////////
				// PLAYER MARKER
				///////////////////////////////////////////////////////////////

				if (
					(pixel_x >= (player_screen_x - 2)) &&
					(pixel_x <= (player_screen_x + 2)) &&
					(pixel_y >= (player_screen_y - 2)) &&
					(pixel_y <= (player_screen_y + 2))
				) begin

					mm_player = 1'b1;

				end


				///////////////////////////////////////////////////////////////
				// VIEWING-DIRECTION LINE
				///////////////////////////////////////////////////////////////

				if (
					(crossp < 12) &&
					(dotp >= 0) &&
					(dotp <= (
						(look_x * look_x) +
						(look_y * look_y)
					))
				) begin

					mm_heading = 1'b1;

				end


				///////////////////////////////////////////////////////////////
				// MINIMAP PIXEL PRIORITY
				///////////////////////////////////////////////////////////////

				if (mm_player) begin

					// Yellow player marker.
					vgaRed   = 4'd15;
					vgaGreen = 4'd15;
					vgaBlue  = 4'd0;

				end
				else if (mm_heading) begin

					// White viewing-direction line.
					vgaRed   = 4'd15;
					vgaGreen = 4'd15;
					vgaBlue  = 4'd15;

				end
				else if (mm_grid) begin

					// Gray cell grid.
					vgaRed   = 4'd5;
					vgaGreen = 4'd5;
					vgaBlue  = 4'd5;

				end
				else if (mm_wall) begin

					// Cyan wall.
					vgaRed   = 4'd0;
					vgaGreen = 4'd12;
					vgaBlue  = 4'd15;

				end
				else begin

					// Black walkable cell.
					vgaRed   = 4'd0;
					vgaGreen = 4'd0;
					vgaBlue  = 4'd0;

				end

			end

		end

	end

endmodule
