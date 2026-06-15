`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: game_state
//
// Purpose:
//   This is the main gameplay engine for FPGA Frogger. It owns the current
//   game state: frog position, moving objects, turtle/snake behavior, scoring,
//   lives, home slots, title/game-over status, and audio event pulses.
//
// Big idea:
//   The renderer only draws what already exists. This module decides what exists.
//   Movement, collision detection, scoring, deaths, and level-clear behavior are
//   updated on frame_tick so gameplay runs at the video frame rate instead of the
//   raw FPGA clock rate.
//
// Timing model:
//   - clk is the game logic clock, normally 25 MHz from the pixel clock.
//   - frame_tick is a one-clock pulse once per VGA frame, about 60 Hz.
//   - Most visible gameplay changes happen only on frame_tick.
//   - Audio event outputs are one-clock pulses consumed by frogger_audio.v.
//////////////////////////////////////////////////////////////////////////////////
module game_state(
    input  wire clk,
    input  wire reset,
    input  wire frame_tick,
    input  wire up_pressed,
    input  wire down_pressed,
    input  wire left_pressed,
    input  wire right_pressed,
    input  wire start_pressed,

    output reg [9:0] frog_x,
    output reg [9:0] frog_y,

    // 13 cars
    output reg signed [10:0] car0_x,   output reg [9:0] car0_y,
    output reg signed [10:0] car1_x,   output reg [9:0] car1_y,
    output reg signed [10:0] car2_x,   output reg [9:0] car2_y,
    output reg signed [10:0] car3_x,   output reg [9:0] car3_y,
    output reg signed [10:0] car4_x,   output reg [9:0] car4_y,
    output reg signed [10:0] car5_x,   output reg [9:0] car5_y,
    output reg signed [10:0] car6_x,   output reg [9:0] car6_y,
    output reg signed [10:0] car7_x,   output reg [9:0] car7_y,
    output reg signed [10:0] car8_x,   output reg [9:0] car8_y,
    output reg signed [10:0] car9_x,   output reg [9:0] car9_y,
    output reg signed [10:0] car10_x,  output reg [9:0] car10_y,
    output reg signed [10:0] car11_x,  output reg [9:0] car11_y,
    output reg signed [10:0] car12_x,  output reg [9:0] car12_y,

    // 12 logs
    output reg signed [10:0] log0_x,   output reg [9:0] log0_y,
    output reg signed [10:0] log1_x,   output reg [9:0] log1_y,
    output reg signed [10:0] log2_x,   output reg [9:0] log2_y,
    output reg signed [10:0] log3_x,   output reg [9:0] log3_y,
    output reg signed [10:0] log4_x,   output reg [9:0] log4_y,
    output reg signed [10:0] log5_x,   output reg [9:0] log5_y,
    output reg signed [10:0] log6_x,   output reg [9:0] log6_y,
    output reg signed [10:0] log7_x,   output reg [9:0] log7_y,
    output reg signed [10:0] log8_x,   output reg [9:0] log8_y,
    output reg signed [10:0] log9_x,   output reg [9:0] log9_y,
    output reg signed [10:0] log10_x,  output reg [9:0] log10_y,
    output reg signed [10:0] log11_x,  output reg [9:0] log11_y,

    // Turtle groups and periodic snake
    output reg signed [10:0] turtle0_x, output reg [9:0] turtle0_y,
    output reg signed [10:0] turtle1_x, output reg [9:0] turtle1_y,
    output reg signed [10:0] turtle2_x, output reg [9:0] turtle2_y,
    output reg [1:0] turtle_state,
    output reg turtle_ripple_anim,
    output reg signed [10:0] snake_x,  output reg [9:0] snake_y,
    output reg snake_active,
    output reg snake_anim,
    output reg snake_dir,

    output reg title_active,
    output reg goal_flash_active,
    output reg [4:0] goal_filled,
    output wire [2:0] homes_filled_count,
    output reg level_clear_active,
    output reg death_flash_active,
    output reg game_over_active,
    output reg [2:0] lives,
    output reg [16:0] score,

    // One-frame audio event pulses
    output reg audio_start_event,
    output reg audio_hop_event,
    output reg audio_death_event,
    output reg audio_home_event
);

    // Screen and sprite dimensions used by both collision and movement logic.
    // These values must match the renderer assumptions.
    localparam SCREEN_W = 640;

    localparam FROG_W = 24;
    localparam FROG_H = 24;

    localparam CAR_W  = 48;
    localparam CAR_H  = 24;

    localparam LOG_S_W = 96;
    localparam LOG_L_W = 144;
    localparam LOG_H   = 24;

    // Turtle/snake sizes and timing. Turtle groups contain 3 turtles.
    // Turtle timing is measured in video frames, not raw clock cycles.
    localparam TURTLE_GROUP_W = 84;
    localparam TURTLE_H       = 24;
    localparam TURTLE_VISIBLE = 2'd0;
    localparam TURTLE_WARN    = 2'd1;
    localparam TURTLE_DOWN    = 2'd2;
    localparam TURTLE_VISIBLE_FRAMES = 180;
    localparam TURTLE_WARN_FRAMES    = 60;
    localparam TURTLE_DOWN_FRAMES    = 90;

    // Odd water rows 1, 3, and 5 are treated as a repeating 640-pixel
    // screen pattern: long log -> large visible gap -> long log -> smaller gap.
    // The second long log and turtle group are derived from the row base so
    // their spacing never drifts after wrapping.
    localparam LONG_LOG_PAIR_OFFSET  = 340; // distance from first long log to second
    localparam TURTLE_GAP_OFFSET     = 200; // center of larger visible gap: 144 + ((340-144-84)/2)

    localparam SNAKE_W = 64;
    localparam SNAKE_H = 16;
    localparam SNAKE_Y = 200;
    localparam SNAKE_ACTIVE_FRAMES   = 300;
    localparam SNAKE_INACTIVE_FRAMES = 240;
    localparam SNAKE_ANIM_FRAMES     = 8;

    // Frog movement step. The frog moves one tile at a time.
    // A 32-pixel vertical step aligns the frog with the road/water rows.
    localparam STEP_X = 32;
    localparam STEP_Y = 32;

    localparam START_X = 308;
    localparam START_Y = 388;

    localparam ROAD1_Y = 228;
    localparam ROAD2_Y = 260;
    localparam ROAD3_Y = 292;
    localparam ROAD4_Y = 324;
    localparam ROAD5_Y = 356;

    localparam WATER1_Y = 36;
    localparam WATER2_Y = 68;
    localparam WATER3_Y = 100;
    localparam WATER4_Y = 132;
    localparam WATER5_Y = 164;

    // State/display timers, measured in frame ticks.
    // These control short visual effects such as goal flash and death flash.
    localparam GOAL_FLASH_FRAMES  = 30;
    localparam LEVEL_CLEAR_FRAMES = 90;
    localparam DEATH_FLASH_FRAMES = 30;
    localparam GAME_OVER_FRAMES   = 90;
    localparam START_LIVES        = 3;
    localparam MAX_LIVES          = 6;   // active frog + up to 5 reserve frogs shown by renderer


    localparam GOAL0_X0 = 32;
    localparam GOAL0_X1 = 96;

    localparam GOAL1_X0 = 152;
    localparam GOAL1_X1 = 216;

    localparam GOAL2_X0 = 272;
    localparam GOAL2_X1 = 336;

    localparam GOAL3_X0 = 392;
    localparam GOAL3_X1 = 456;

    localparam GOAL4_X0 = 512;
    localparam GOAL4_X1 = 576;

    // Latched movement requests.
    // Button inputs are short pulses, so the game_state module captures them and
    // consumes them on the next frame_tick. This keeps input responsive while the
    // game itself updates only once per frame.
    reg req_up;
    reg req_down;
    reg req_left;
    reg req_right;
    reg req_start;

    // Collision and ride-status flags calculated combinationally below.
    // These are separated from the sequential game update so the frame update can
    // make decisions using clean, already-computed booleans.
    reg hit_car0, hit_car1, hit_car2, hit_car3, hit_car4, hit_car5, hit_car6;
    reg hit_car7, hit_car8, hit_car9, hit_car10, hit_car11, hit_car12;

    reg on_log0, on_log1, on_log2, on_log3, on_log4, on_log5;
    reg on_log6, on_log7, on_log8, on_log9, on_log10, on_log11;

    reg on_turtle0, on_turtle1, on_turtle2;
    reg frog_in_water;
    reg frog_on_any_log;
    reg frog_on_any_turtle;
    reg frog_on_safe_ride;
    reg hit_snake;

    // Animation and behavior timers for turtles and snake.
    // The turtle timer steps through visible/warning/submerged states.
    // The snake timer controls when the snake appears and disappears.
    reg [8:0] turtle_timer;
    reg [3:0] turtle_ripple_anim_timer;
    reg [8:0] snake_timer;
    reg [3:0] snake_anim_timer;
    // snake_dir is an output: 1 = moving right, 0 = moving left
    reg snake_spawn_side;   // 0 = spawn left, 1 = spawn right

    reg signed [10:0] frog_next_x;
    reg [9:0] frog_next_y;
    reg signed [10:0] carry_dx;

    // Timers for screen/game state effects.
    // death_flash_active intentionally holds the red flash before the next life or
    // game-over screen so every death path gives visible feedback.
    reg [6:0] goal_flash_timer;
    reg [6:0] level_clear_timer;
    reg [6:0] death_flash_timer;
    reg [6:0] game_over_timer;
    reg       game_over_start_armed;
    reg [5:0] title_start_guard;

    // Scoring / bonus-life support
    // best_y_this_frog prevents farming points by moving up/down/up repeatedly.
    // next_bonus_life_score tracks the next 100-point boundary for extra lives.
    reg [9:0]  best_y_this_frog;
    reg [16:0] next_bonus_life_score;
    reg [16:0] score_add_amount;
    reg [16:0] score_candidate;
    reg        bonus_life_earned;


    // Show title screen immediately after FPGA configuration, even before a manual reset.
    initial begin
        title_active = 1'b1;
    end

    // Temporary variables used when testing whether the frog reached a valid home.
    // These are assigned inside the frame update when frog_next_y enters the goal row.
    reg reached_goal_slot;
    reg [2:0] reached_goal_index;
    reg reached_filled_goal;
    reg all_goals_filled_after_score;
    reg death_event;



    // Function: add_score_wrap
    //   Adds points to the current score, then wraps the result at 100000.
    //   The visible display is five decimal digits, so the legal display range is
    //   00000 through 99999. This function keeps that behavior localized in one
    //   reusable helper instead of scattering wrap checks through the scoring code.
    //
    // Inputs:
    //   current_score - existing score value
    //   points_to_add - points earned this frame
    // Return:
    //   17-bit score after wraparound
    //
    // Add points and wrap from 99999 back to 00000.
    // This keeps the visible score in the 5-decimal-digit range.
    function [16:0] add_score_wrap;
        input [16:0] current_score;
        input [16:0] points_to_add;
        reg   [17:0] total;
        begin
            total = current_score + points_to_add;
            if (total >= 18'd100000)
                add_score_wrap = total - 18'd100000;
            else
                add_score_wrap = total[16:0];
        end
    endfunction



    // Function: wrap_screen_x
    //   Wraps an X coordinate back into the 0..639 visible screen interval.
    //   Used for long logs and turtle groups that form repeating screen patterns.
    //   Keeping this as a function avoids duplicating wrap logic in several places.
    //
    // Input:
    //   raw_x - signed X position that may be slightly below 0 or above SCREEN_W
    // Return:
    //   wrapped signed X coordinate
    function signed [10:0] wrap_screen_x;
        input signed [12:0] raw_x;
        reg signed [12:0] tmp;
        begin
            tmp = raw_x;
            if (tmp >= SCREEN_W)
                tmp = tmp - SCREEN_W;
            else if (tmp < 0)
                tmp = tmp + SCREEN_W;

            wrap_screen_x = tmp[10:0];
        end
    endfunction

    // Function: paired_long_log_x
    //   Given the base long-log position for a row, calculate the paired long log
    //   position using a fixed offset. This keeps the two-log row spacing stable
    //   forever instead of allowing independent wrapping drift.
    function signed [10:0] paired_long_log_x;
        input signed [10:0] base_log_x;
        begin
            paired_long_log_x = wrap_screen_x(base_log_x + LONG_LOG_PAIR_OFFSET);
        end
    endfunction

    // Function: centered_turtle_x
    //   Given the base long-log position for an odd water row, place the three
    //   turtles in the larger gap between the two long logs. The turtles are
    //   derived from the log base position so they remain locked to the row pattern.
    function signed [10:0] centered_turtle_x;
        input signed [10:0] base_log_x;
        begin
            centered_turtle_x = wrap_screen_x(base_log_x + TURTLE_GAP_OFFSET);
        end
    endfunction

    // Function: rect_overlap_wrap_x
    //   Axis-aligned rectangle collision test with screen-wrap support.
    //   Normal collision works when the object is fully on screen. The extra wrap
    //   test handles cases where an object extends past the right edge and visually
    //   continues at the left edge. This is important for long logs and turtle groups.
    //
    // Inputs:
    //   obj_x/obj_y/obj_w/obj_h - object rectangle
    //   frog_l/frog_t           - frog top-left coordinate
    // Return:
    //   1 if frog overlaps the object, including wrapped edge cases
    //
    // Collision helper for turtle groups that can wrap across the screen edge.
    function rect_overlap_wrap_x;
        input signed [10:0] obj_x;
        input [9:0] obj_w;
        input [9:0] obj_y;
        input [9:0] obj_h;
        input [9:0] frog_l;
        input [9:0] frog_t;
        reg normal_x_hit;
        reg wrap_x_hit;
        reg y_hit;
        reg signed [11:0] obj_r;
        reg [9:0] overflow_w;
        begin
            obj_r = obj_x + obj_w;
            y_hit = ((frog_t < obj_y + obj_h) && (frog_t + FROG_H > obj_y));

            normal_x_hit = ((frog_l < obj_x + obj_w) && (frog_l + FROG_W > obj_x));

            wrap_x_hit = 1'b0;
            if (obj_r > SCREEN_W) begin
                overflow_w = obj_r - SCREEN_W;
                wrap_x_hit = ((frog_l < overflow_w) || (frog_l + FROG_W > obj_x));
            end

            rect_overlap_wrap_x = y_hit && (normal_x_hit || wrap_x_hit);
        end
    endfunction

    // Count filled homes for the game-over screen.
    // Each bit of goal_filled represents one home slot, so summing the bits gives
    // a compact 0..5 count.
    assign homes_filled_count = goal_filled[0] + goal_filled[1] + goal_filled[2] + goal_filled[3] + goal_filled[4];

    // Combinational collision/ride-status logic.
    // This block does not store state. It continuously determines what the frog is
    // touching based on current positions. The sequential frame update later uses
    // these flags to decide whether the frog rides, scores, or dies.
    always @(*) begin
        hit_car0  = ((frog_x < car0_x  + CAR_W) && (frog_x + FROG_W > car0_x ) && (frog_y < car0_y  + CAR_H) && (frog_y + FROG_H > car0_y ));
        hit_car1  = ((frog_x < car1_x  + CAR_W) && (frog_x + FROG_W > car1_x ) && (frog_y < car1_y  + CAR_H) && (frog_y + FROG_H > car1_y ));
        hit_car2  = ((frog_x < car2_x  + CAR_W) && (frog_x + FROG_W > car2_x ) && (frog_y < car2_y  + CAR_H) && (frog_y + FROG_H > car2_y ));
        hit_car3  = ((frog_x < car3_x  + CAR_W) && (frog_x + FROG_W > car3_x ) && (frog_y < car3_y  + CAR_H) && (frog_y + FROG_H > car3_y ));
        hit_car4  = ((frog_x < car4_x  + CAR_W) && (frog_x + FROG_W > car4_x ) && (frog_y < car4_y  + CAR_H) && (frog_y + FROG_H > car4_y ));
        hit_car5  = ((frog_x < car5_x  + CAR_W) && (frog_x + FROG_W > car5_x ) && (frog_y < car5_y  + CAR_H) && (frog_y + FROG_H > car5_y ));
        hit_car6  = ((frog_x < car6_x  + CAR_W) && (frog_x + FROG_W > car6_x ) && (frog_y < car6_y  + CAR_H) && (frog_y + FROG_H > car6_y ));
        hit_car7  = ((frog_x < car7_x  + CAR_W) && (frog_x + FROG_W > car7_x ) && (frog_y < car7_y  + CAR_H) && (frog_y + FROG_H > car7_y ));
        hit_car8  = ((frog_x < car8_x  + CAR_W) && (frog_x + FROG_W > car8_x ) && (frog_y < car8_y  + CAR_H) && (frog_y + FROG_H > car8_y ));
        hit_car9  = ((frog_x < car9_x  + CAR_W) && (frog_x + FROG_W > car9_x ) && (frog_y < car9_y  + CAR_H) && (frog_y + FROG_H > car9_y ));
        hit_car10 = ((frog_x < car10_x + CAR_W) && (frog_x + FROG_W > car10_x) && (frog_y < car10_y + CAR_H) && (frog_y + FROG_H > car10_y));
        hit_car11 = ((frog_x < car11_x + CAR_W) && (frog_x + FROG_W > car11_x) && (frog_y < car11_y + CAR_H) && (frog_y + FROG_H > car11_y));
        hit_car12 = ((frog_x < car12_x + CAR_W) && (frog_x + FROG_W > car12_x) && (frog_y < car12_y + CAR_H) && (frog_y + FROG_H > car12_y));

        on_log0  = rect_overlap_wrap_x(log0_x,  LOG_L_W, log0_y,  LOG_H, frog_x, frog_y);
        on_log1  = rect_overlap_wrap_x(log1_x,  LOG_L_W, log1_y,  LOG_H, frog_x, frog_y);

        on_log2  = ((frog_x < log2_x  + LOG_S_W) && (frog_x + FROG_W > log2_x ) && (frog_y < log2_y  + LOG_H) && (frog_y + FROG_H > log2_y ));
        on_log3  = ((frog_x < log3_x  + LOG_S_W) && (frog_x + FROG_W > log3_x ) && (frog_y < log3_y  + LOG_H) && (frog_y + FROG_H > log3_y ));
        on_log4  = ((frog_x < log4_x  + LOG_S_W) && (frog_x + FROG_W > log4_x ) && (frog_y < log4_y  + LOG_H) && (frog_y + FROG_H > log4_y ));

        on_log5  = rect_overlap_wrap_x(log5_x,  LOG_L_W, log5_y,  LOG_H, frog_x, frog_y);
        on_log6  = rect_overlap_wrap_x(log6_x,  LOG_L_W, log6_y,  LOG_H, frog_x, frog_y);

        on_log7  = ((frog_x < log7_x  + LOG_S_W) && (frog_x + FROG_W > log7_x ) && (frog_y < log7_y  + LOG_H) && (frog_y + FROG_H > log7_y ));
        on_log8  = ((frog_x < log8_x  + LOG_S_W) && (frog_x + FROG_W > log8_x ) && (frog_y < log8_y  + LOG_H) && (frog_y + FROG_H > log8_y ));
        on_log9  = ((frog_x < log9_x  + LOG_S_W) && (frog_x + FROG_W > log9_x ) && (frog_y < log9_y  + LOG_H) && (frog_y + FROG_H > log9_y ));

        on_log10 = rect_overlap_wrap_x(log10_x, LOG_L_W, log10_y, LOG_H, frog_x, frog_y);
        on_log11 = rect_overlap_wrap_x(log11_x, LOG_L_W, log11_y, LOG_H, frog_x, frog_y);

        on_turtle0 = rect_overlap_wrap_x(turtle0_x, TURTLE_GROUP_W, turtle0_y, TURTLE_H, frog_x, frog_y);
        on_turtle1 = rect_overlap_wrap_x(turtle1_x, TURTLE_GROUP_W, turtle1_y, TURTLE_H, frog_x, frog_y);
        on_turtle2 = rect_overlap_wrap_x(turtle2_x, TURTLE_GROUP_W, turtle2_y, TURTLE_H, frog_x, frog_y);

        hit_snake = snake_active &&
            ((frog_x < snake_x + SNAKE_W) && (frog_x + FROG_W > snake_x) &&
             (frog_y < snake_y + SNAKE_H) && (frog_y + FROG_H > snake_y));

        frog_in_water = ((frog_y >= 32) && (frog_y < 192));

        frog_on_any_log =
            on_log0  || on_log1  || on_log2  || on_log3  ||
            on_log4  || on_log5  || on_log6  || on_log7  ||
            on_log8  || on_log9  || on_log10 || on_log11;

        frog_on_any_turtle = on_turtle0 || on_turtle1 || on_turtle2;
        frog_on_safe_ride  = frog_on_any_log || (frog_on_any_turtle && (turtle_state != TURTLE_DOWN));

        carry_dx = 0;
        if (on_log0 || on_log1 || on_turtle0)
            carry_dx = -1;
        else if (on_log2 || on_log3 || on_log4)
            carry_dx = 2;
        else if (on_log5 || on_log6 || on_turtle1)
            carry_dx = -1;
        else if (on_log7 || on_log8 || on_log9)
            carry_dx = 2;
        else if (on_log10 || on_log11 || on_turtle2)
            carry_dx = -1;
    end

    // Sequential game-state update.
    // This is the main state machine / gameplay engine. It initializes the game on
    // reset, latches player input, advances objects once per frame, applies scoring,
    // handles deaths, controls title/game-over screens, and emits audio events.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            frog_x <= START_X;
            frog_y <= START_Y;

            car0_x  <=   0;  car0_y  <= ROAD1_Y;
            car1_x  <= 220;  car1_y  <= ROAD1_Y;
            car2_x  <= 440;  car2_y  <= ROAD1_Y;

            car3_x  <= 140;  car3_y  <= ROAD2_Y;
            car4_x  <= 460;  car4_y  <= ROAD2_Y;

            car5_x  <=  60;  car5_y  <= ROAD3_Y;
            car6_x  <= 280;  car6_y  <= ROAD3_Y;
            car7_x  <= 500;  car7_y  <= ROAD3_Y;

            car8_x  <=  80;  car8_y  <= ROAD4_Y;
            car9_x  <= 400;  car9_y  <= ROAD4_Y;

            car10_x <=  20;  car10_y <= ROAD5_Y;
            car11_x <= 240;  car11_y <= ROAD5_Y;
            car12_x <= 460;  car12_y <= ROAD5_Y;

            log0_x  <= 120;  log0_y  <= WATER1_Y;
            log1_x  <= 460;  log1_y  <= WATER1_Y;

            log2_x  <=  20;  log2_y  <= WATER2_Y;
            log3_x  <= 230;  log3_y  <= WATER2_Y;
            log4_x  <= 440;  log4_y  <= WATER2_Y;

            log5_x  <=  60;  log5_y  <= WATER3_Y;
            log6_x  <= 400;  log6_y  <= WATER3_Y;

            log7_x  <=  70;  log7_y  <= WATER4_Y;
            log8_x  <= 280;  log8_y  <= WATER4_Y;
            log9_x  <= 490;  log9_y  <= WATER4_Y;

            log10_x <= 160;  log10_y <= WATER5_Y;
            log11_x <= 500;  log11_y <= WATER5_Y;

            turtle0_x <= centered_turtle_x(120); turtle0_y <= WATER1_Y;
            turtle1_x <= centered_turtle_x(60); turtle1_y <= WATER3_Y;
            turtle2_x <= centered_turtle_x(160); turtle2_y <= WATER5_Y;
            turtle_state <= TURTLE_VISIBLE;
            turtle_timer <= TURTLE_VISIBLE_FRAMES;
            turtle_ripple_anim <= 1'b0;
            turtle_ripple_anim_timer <= 4'd0;

            snake_x <= 0;
            snake_y <= SNAKE_Y;
            snake_active <= 1'b0;
            snake_timer <= SNAKE_INACTIVE_FRAMES;
            snake_anim_timer <= SNAKE_ANIM_FRAMES;
            snake_anim <= 1'b0;
            snake_dir <= 1'b1;
            snake_spawn_side <= 1'b0;

            req_up    <= 1'b0;
            req_down  <= 1'b0;
            req_left  <= 1'b0;
            req_right <= 1'b0;
            req_start <= 1'b0;

            title_active       <= 1'b1;
            title_start_guard  <= 6'd30;
            goal_flash_active  <= 1'b0;
            goal_flash_timer   <= 7'd0;
            goal_filled        <= 5'b00000;

            level_clear_active <= 1'b0;
            level_clear_timer  <= 7'd0;

            death_flash_active <= 1'b0;
            death_flash_timer  <= 7'd0;

            game_over_active   <= 1'b0;
            game_over_timer    <= 7'd0;
            game_over_start_armed <= 1'b0;
            lives              <= START_LIVES;
            score              <= 17'd0;
            audio_start_event   <= 1'b0;
            audio_hop_event     <= 1'b0;
            audio_death_event   <= 1'b0;
            audio_home_event    <= 1'b0;
            best_y_this_frog   <= START_Y;
            next_bonus_life_score <= 17'd100;
        end
        else begin
            // Clear one-clock audio event pulses by default.
            // Any event that happens later in this clock cycle will set its pulse
            // high for exactly one clk cycle so the audio module can detect it.
            audio_start_event <= 1'b0;
            audio_hop_event   <= 1'b0;
            audio_death_event <= 1'b0;
            audio_home_event  <= 1'b0;

            // After reset or returning to title, ignore start/move inputs for
            // a short time. 
            if (title_active && (title_start_guard != 0)) begin
                req_start <= 1'b0;
            end
            else if (start_pressed) begin
                req_start <= 1'b1;
            end

            if (!title_active && !level_clear_active && !death_flash_active && !game_over_active) begin
                if (up_pressed)
                    req_up <= 1'b1;
                if (down_pressed)
                    req_down <= 1'b1;
                if (left_pressed)
                    req_left <= 1'b1;
                if (right_pressed)
                    req_right <= 1'b1;
            end

            // frame_tick is the heartbeat of the gameplay logic.
            // All visible object movement and game progression happen here.
            if (frame_tick) begin
                if (title_start_guard != 0)
                    title_start_guard <= title_start_guard - 1'b1;

                if (goal_flash_timer != 0) begin
                    goal_flash_timer  <= goal_flash_timer - 1'b1;
                    goal_flash_active <= 1'b1;
                end
                else begin
                    goal_flash_active <= 1'b0;
                end

                // TITLE state: hold the frog at the start position and wait for
                // the selected controller's start command.
                if (title_active) begin
                    frog_x <= START_X;
                    frog_y <= START_Y;
                    req_up <= 1'b0; req_down <= 1'b0; req_left <= 1'b0; req_right <= 1'b0;
                    if (req_start) begin
                        title_active <= 1'b0;
                        audio_start_event <= 1'b1;
                        req_start <= 1'b0;
                    end
                end
                // LEVEL CLEAR state: short flash after all homes are filled.
                // After the timer expires, homes are cleared for the next round.
                else if (level_clear_active) begin
                    frog_x <= START_X;
                    frog_y <= START_Y;
                    req_up <= 1'b0; req_down <= 1'b0; req_left <= 1'b0; req_right <= 1'b0;

                    if (level_clear_timer != 0) begin
                        level_clear_timer <= level_clear_timer - 1'b1;
                    end
                    else begin
                        level_clear_active <= 1'b0;
                        goal_filled <= 5'b00000;
                    end
                end
                // DEATH FLASH state: hold a red flash briefly before returning to
                // gameplay or showing game over.
                else if (death_flash_active) begin
                    req_up <= 1'b0; req_down <= 1'b0; req_left <= 1'b0; req_right <= 1'b0;

                    if (death_flash_timer != 0) begin
                        death_flash_timer <= death_flash_timer - 1'b1;
                    end
                    else begin
                        death_flash_active <= 1'b0;
                    end
                end
                // GAME OVER state: hold the ending screen until the player presses
                // the appropriate start command again.
                else if (game_over_active) begin
                    // Hold the ending screen until the player intentionally
                    // presses Start/Center again.
                    frog_x <= START_X;
                    frog_y <= START_Y;
                    req_up <= 1'b0; req_down <= 1'b0; req_left <= 1'b0; req_right <= 1'b0;

                    if (!start_pressed)
                        game_over_start_armed <= 1'b1;

                    if (game_over_start_armed && req_start) begin
                        req_start <= 1'b0;
                        game_over_start_armed <= 1'b0;
                        frog_x <= START_X;
                        frog_y <= START_Y;

                        car0_x  <=   0;  car0_y  <= ROAD1_Y;
                        car1_x  <= 220;  car1_y  <= ROAD1_Y;
                        car2_x  <= 440;  car2_y  <= ROAD1_Y;

                        car3_x  <= 140;  car3_y  <= ROAD2_Y;
                        car4_x  <= 460;  car4_y  <= ROAD2_Y;

                        car5_x  <=  60;  car5_y  <= ROAD3_Y;
                        car6_x  <= 280;  car6_y  <= ROAD3_Y;
                        car7_x  <= 500;  car7_y  <= ROAD3_Y;

                        car8_x  <=  80;  car8_y  <= ROAD4_Y;
                        car9_x  <= 400;  car9_y  <= ROAD4_Y;

                        car10_x <=  20;  car10_y <= ROAD5_Y;
                        car11_x <= 240;  car11_y <= ROAD5_Y;
                        car12_x <= 460;  car12_y <= ROAD5_Y;

                        log0_x  <= 120;  log0_y  <= WATER1_Y;
                        log1_x  <= 460;  log1_y  <= WATER1_Y;

                        log2_x  <=  20;  log2_y  <= WATER2_Y;
                        log3_x  <= 230;  log3_y  <= WATER2_Y;
                        log4_x  <= 440;  log4_y  <= WATER2_Y;

                        log5_x  <=  60;  log5_y  <= WATER3_Y;
                        log6_x  <= 400;  log6_y  <= WATER3_Y;

                        log7_x  <=  70;  log7_y  <= WATER4_Y;
                        log8_x  <= 280;  log8_y  <= WATER4_Y;
                        log9_x  <= 490;  log9_y  <= WATER4_Y;

                        log10_x <= 160;  log10_y <= WATER5_Y;
                        log11_x <= 500;  log11_y <= WATER5_Y;

                        turtle0_x <= centered_turtle_x(120); turtle0_y <= WATER1_Y;
                        turtle1_x <= centered_turtle_x(60); turtle1_y <= WATER3_Y;
                        turtle2_x <= centered_turtle_x(160); turtle2_y <= WATER5_Y;
                        turtle_state <= TURTLE_VISIBLE;
                        turtle_timer <= TURTLE_VISIBLE_FRAMES;
                        turtle_ripple_anim <= 1'b0;
                        turtle_ripple_anim_timer <= 4'd0;

                        snake_x <= 0;
                        snake_y <= SNAKE_Y;
                        snake_active <= 1'b0;
                        snake_timer <= SNAKE_INACTIVE_FRAMES;
                        snake_dir <= 1'b1;
                        snake_spawn_side <= 1'b0;

                        title_active       <= 1'b1;
                        title_start_guard  <= 6'd30;
                        req_start          <= 1'b0;
                        goal_filled        <= 5'b00000;
                        goal_flash_active  <= 1'b0;
                        goal_flash_timer   <= 7'd0;
                        level_clear_active <= 1'b0;
                        level_clear_timer  <= 7'd0;
                        death_flash_active <= 1'b0;
                        death_flash_timer  <= 7'd0;
                        game_over_active   <= 1'b0;
                        game_over_timer    <= 7'd0;
                        game_over_start_armed <= 1'b0;
                        lives              <= START_LIVES;
                        score              <= 17'd0;
                        audio_start_event   <= 1'b0;
                        audio_hop_event     <= 1'b0;
                        audio_death_event   <= 1'b0;
                        audio_home_event    <= 1'b0;
                        best_y_this_frog   <= START_Y;
                        next_bonus_life_score <= 17'd100;
                    end
                end
                else begin
                    // PLAY state: move all objects, process one frog movement,
                    // test collisions, update score/lives, and generate audio events.
                    score_add_amount = 17'd0;
                    score_candidate  = score;
                    bonus_life_earned = 1'b0;

                    if (car0_x  >= SCREEN_W) car0_x  <= -CAR_W; else car0_x  <= car0_x  + 2;
                    if (car1_x  >= SCREEN_W) car1_x  <= -CAR_W; else car1_x  <= car1_x  + 2;
                    if (car2_x  >= SCREEN_W) car2_x  <= -CAR_W; else car2_x  <= car2_x  + 2;

                    if (car3_x  <= -CAR_W)   car3_x  <= SCREEN_W; else car3_x  <= car3_x  - 3;
                    if (car4_x  <= -CAR_W)   car4_x  <= SCREEN_W; else car4_x  <= car4_x  - 3;

                    if (car5_x  >= SCREEN_W) car5_x  <= -CAR_W; else car5_x  <= car5_x  + 2;
                    if (car6_x  >= SCREEN_W) car6_x  <= -CAR_W; else car6_x  <= car6_x  + 2;
                    if (car7_x  >= SCREEN_W) car7_x  <= -CAR_W; else car7_x  <= car7_x  + 2;

                    if (car8_x  <= -CAR_W)   car8_x  <= SCREEN_W; else car8_x  <= car8_x  - 3;
                    if (car9_x  <= -CAR_W)   car9_x  <= SCREEN_W; else car9_x  <= car9_x  - 3;

                    if (car10_x >= SCREEN_W) car10_x <= -CAR_W; else car10_x <= car10_x + 2;
                    if (car11_x >= SCREEN_W) car11_x <= -CAR_W; else car11_x <= car11_x + 2;
                    if (car12_x >= SCREEN_W) car12_x <= -CAR_W; else car12_x <= car12_x + 2;

                    log0_x <= wrap_screen_x(log0_x - 1);
                    log1_x <= paired_long_log_x(wrap_screen_x(log0_x - 1));

                    if (log2_x  >= SCREEN_W) log2_x  <= -LOG_S_W; else log2_x  <= log2_x  + 2;
                    if (log3_x  >= SCREEN_W) log3_x  <= -LOG_S_W; else log3_x  <= log3_x  + 2;
                    if (log4_x  >= SCREEN_W) log4_x  <= -LOG_S_W; else log4_x  <= log4_x  + 2;

                    log5_x <= wrap_screen_x(log5_x - 1);
                    log6_x <= paired_long_log_x(wrap_screen_x(log5_x - 1));

                    if (log7_x  >= SCREEN_W) log7_x  <= -LOG_S_W; else log7_x  <= log7_x  + 2;
                    if (log8_x  >= SCREEN_W) log8_x  <= -LOG_S_W; else log8_x  <= log8_x  + 2;
                    if (log9_x  >= SCREEN_W) log9_x  <= -LOG_S_W; else log9_x  <= log9_x  + 2;

                    log10_x <= wrap_screen_x(log10_x - 1);
                    log11_x <= paired_long_log_x(wrap_screen_x(log10_x - 1));

                    // Keep turtles centered in the larger gap between the
                    // two long logs on odd water rows 1, 3, and 5.
                    turtle0_x <= centered_turtle_x(wrap_screen_x(log0_x - 1));
                    turtle1_x <= centered_turtle_x(wrap_screen_x(log5_x - 1));
                    turtle2_x <= centered_turtle_x(wrap_screen_x(log10_x - 1));

                    // Dedicated submerged-turtle ripple animation.
                    // Toggle every 6 frames while the game is actively running.
                    if (turtle_ripple_anim_timer == 4'd5) begin
                        turtle_ripple_anim_timer <= 4'd0;
                        turtle_ripple_anim <= ~turtle_ripple_anim;
                    end
                    else begin
                        turtle_ripple_anim_timer <= turtle_ripple_anim_timer + 1'b1;
                    end

                    if (turtle_timer != 0) begin
                        turtle_timer <= turtle_timer - 1'b1;
                    end
                    else begin
                        if (turtle_state == TURTLE_VISIBLE) begin
                            turtle_state <= TURTLE_WARN;
                            turtle_timer <= TURTLE_WARN_FRAMES;
                        end
                        else if (turtle_state == TURTLE_WARN) begin
                            turtle_state <= TURTLE_DOWN;
                            turtle_timer <= TURTLE_DOWN_FRAMES;
                        end
                        else begin
                            turtle_state <= TURTLE_VISIBLE;
                            turtle_timer <= TURTLE_VISIBLE_FRAMES;
                        end
                    end

                    // Snake behavior: when inactive, count down to the next spawn.
                    // When active, move fully across the screen, then disappear.
                    // The snake_spawn_side bit alternates left/right spawns.
                    // Snake appears periodically on the center grass strip.
                    // Spawn side alternates between left and right.

                    if (!snake_active) begin
                        if (snake_timer != 0) begin
                            snake_timer <= snake_timer - 1'b1;
                        end
                        else begin
                            snake_active <= 1'b1;
                            snake_timer  <= SNAKE_ACTIVE_FRAMES;
                            snake_spawn_side <= ~snake_spawn_side;
                            snake_anim   <= 1'b0;
                            snake_anim_timer <= SNAKE_ANIM_FRAMES;

                            if (~snake_spawn_side) begin
                                snake_x   <= SCREEN_W - SNAKE_W;
                                snake_dir <= 1'b0; // move left toward center
                            end
                            else begin
                                snake_x   <= 0;
                                snake_dir <= 1'b1; // move right toward center
                            end
                        end
                    end
                    else begin
                        if (snake_anim_timer != 0) begin
                            snake_anim_timer <= snake_anim_timer - 1'b1;
                        end
                        else begin
                            snake_anim <= ~snake_anim;
                            snake_anim_timer <= SNAKE_ANIM_FRAMES;
                        end

                        if (snake_dir) begin
                            // Moving right: continue until completely off the right side.
                            if (snake_x >= SCREEN_W) begin
                                snake_active <= 1'b0;
                                snake_timer  <= SNAKE_INACTIVE_FRAMES;
                            end
                            else begin
                                snake_x <= snake_x + 1;
                            end
                        end
                        else begin
                            // Moving left: continue until completely off the left side.
                            if (snake_x <= -SNAKE_W) begin
                                snake_active <= 1'b0;
                                snake_timer  <= SNAKE_INACTIVE_FRAMES;
                            end
                            else begin
                                snake_x <= snake_x - 1;
                            end
                        end
                    end

                    frog_next_x = frog_x;
                    frog_next_y = frog_y;

                    if (req_up) begin
                        audio_hop_event <= 1'b1; // frog movement sound
                        if (frog_y >= STEP_Y)
                            frog_next_y = frog_y - STEP_Y;
                    end
                    else if (req_down) begin
                        audio_hop_event <= 1'b1; // frog movement sound
                        if (frog_y <= 384 - FROG_H)
                            frog_next_y = frog_y + STEP_Y;
                    end
                    else if (req_left) begin
                        audio_hop_event <= 1'b1; // frog movement sound
                        if (frog_x >= STEP_X)
                            frog_next_x = frog_x - STEP_X;
                    end
                    else if (req_right) begin
                        audio_hop_event <= 1'b1; // frog movement sound
                        if (frog_x <= SCREEN_W - FROG_W - STEP_X)
                            frog_next_x = frog_x + STEP_X;
                    end

                    // Scoring: award 1 point only when this frog reaches
                    // a new highest row during the current attempt. Moving down
                    // and then back up does not farm points because best_y_this_frog
                    // keeps track of the best progress already earned.
                    if (req_up && (frog_next_y < best_y_this_frog)) begin
                        score_add_amount = score_add_amount + 17'd1;
                        best_y_this_frog <= frog_next_y;
                    end

                    // If the frog is standing on a safe log or visible/warning turtle,
                    // carry the frog horizontally with that object.
                    if (frog_on_safe_ride)
                        frog_next_x = frog_next_x + carry_dx;

                    if (frog_next_x < 0)
                        frog_next_x = 0;
                    else if (frog_next_x > SCREEN_W - FROG_W)
                        frog_next_x = SCREEN_W - FROG_W;

                    frog_x <= frog_next_x;
                    frog_y <= frog_next_y;

                    // Determine whether this frame caused a death or goal event.
                    death_event = 1'b0;

                    if (hit_car0  || hit_car1  || hit_car2  || hit_car3  || hit_car4 ||
                        hit_car5  || hit_car6  || hit_car7  || hit_car8  || hit_car9 ||
                        hit_car10 || hit_car11 || hit_car12 || hit_snake) begin
                        death_event = 1'b1;
                    end
                    else if (frog_in_water && !frog_on_safe_ride) begin
                        death_event = 1'b1;
                    end
                    else if (frog_on_any_turtle && (turtle_state == TURTLE_DOWN)) begin
                        death_event = 1'b1;
                    end
                    else if (frog_next_y < 32) begin
                        reached_goal_slot  = 1'b0;
                        reached_goal_index = 3'd0;

                        if ((frog_next_x >= GOAL0_X0) && (frog_next_x + FROG_W <= GOAL0_X1)) begin
                            reached_goal_slot  = 1'b1;
                            reached_goal_index = 3'd0;
                        end
                        else if ((frog_next_x >= GOAL1_X0) && (frog_next_x + FROG_W <= GOAL1_X1)) begin
                            reached_goal_slot  = 1'b1;
                            reached_goal_index = 3'd1;
                        end
                        else if ((frog_next_x >= GOAL2_X0) && (frog_next_x + FROG_W <= GOAL2_X1)) begin
                            reached_goal_slot  = 1'b1;
                            reached_goal_index = 3'd2;
                        end
                        else if ((frog_next_x >= GOAL3_X0) && (frog_next_x + FROG_W <= GOAL3_X1)) begin
                            reached_goal_slot  = 1'b1;
                            reached_goal_index = 3'd3;
                        end
                        else if ((frog_next_x >= GOAL4_X0) && (frog_next_x + FROG_W <= GOAL4_X1)) begin
                            reached_goal_slot  = 1'b1;
                            reached_goal_index = 3'd4;
                        end

                        reached_filled_goal = 1'b0;
                        if (reached_goal_slot && goal_filled[reached_goal_index])
                            reached_filled_goal = 1'b1;

                        if (!reached_goal_slot || reached_filled_goal) begin
                            death_event = 1'b1;
                        end
                        else begin
                            all_goals_filled_after_score = 1'b0;

                            case (reached_goal_index)
                                3'd0: if ((goal_filled | 5'b00001) == 5'b11111) all_goals_filled_after_score = 1'b1;
                                3'd1: if ((goal_filled | 5'b00010) == 5'b11111) all_goals_filled_after_score = 1'b1;
                                3'd2: if ((goal_filled | 5'b00100) == 5'b11111) all_goals_filled_after_score = 1'b1;
                                3'd3: if ((goal_filled | 5'b01000) == 5'b11111) all_goals_filled_after_score = 1'b1;
                                3'd4: if ((goal_filled | 5'b10000) == 5'b11111) all_goals_filled_after_score = 1'b1;
                                default: all_goals_filled_after_score = 1'b0;
                            endcase

                            goal_filled[reached_goal_index] <= 1'b1;
                            audio_home_event <= 1'b1;
                            frog_x <= START_X;
                            frog_y <= START_Y;
                            best_y_this_frog <= START_Y;
                            goal_flash_timer  <= GOAL_FLASH_FRAMES;
                            goal_flash_active <= 1'b1;

                            if (all_goals_filled_after_score) begin
                                level_clear_active <= 1'b1;
                                level_clear_timer  <= LEVEL_CLEAR_FRAMES;
                                score_add_amount = score_add_amount + 17'd35;  // 10 for home + 25 for filling all homes
                            end
                            else begin
                                score_add_amount = score_add_amount + 17'd10;
                            end
                        end
                    end

                    // Apply score additions after all movement/goal logic is known.
                    // No advancement/home points are awarded on a death event.
                    if (!death_event && (score_add_amount != 17'd0)) begin
                        score_candidate = add_score_wrap(score, score_add_amount);

                        // Award one extra frog every 100 points. The display can show
                        // up to 5 reserve frogs, so internally that means max lives = 6
                        // including the active frog.
                        if ((score_candidate >= score) &&
                            (score < next_bonus_life_score) &&
                            (score_candidate >= next_bonus_life_score)) begin
                            bonus_life_earned = 1'b1;
                        end

                        score <= score_candidate;

                        if (bonus_life_earned && (lives < MAX_LIVES))
                            lives <= lives + 1'b1;

                        if (bonus_life_earned) begin
                            if (next_bonus_life_score >= 17'd99900)
                                next_bonus_life_score <= 17'd100;
                            else
                                next_bonus_life_score <= next_bonus_life_score + 17'd100;
                        end

                        // If score rolled over from 99999 to 00000 range, restart
                        // bonus-life tracking at 100 for the new score cycle.
                        if (score_candidate < score)
                            next_bonus_life_score <= 17'd100;
                    end

                    // Centralized death handling.
                    // Every death source uses this one path so the red flash, life
                    // decrement, audio event, and game-over transition stay consistent.
                    if (death_event) begin
                        audio_death_event <= 1'b1;
                        // Every death path now goes through the same visible red flash.
                        death_flash_active <= 1'b1;
                        death_flash_timer  <= DEATH_FLASH_FRAMES;

                        frog_x <= START_X;
                        frog_y <= START_Y;
                        best_y_this_frog <= START_Y;

                        if (lives > 1) begin
                            lives <= lives - 1'b1;
                        end
                        else begin
                            lives <= 3'd0;
                            req_start <= 1'b0;
                            game_over_active <= 1'b1;
                            game_over_timer  <= GAME_OVER_FRAMES;
                            game_over_start_armed <= 1'b0;
                        end
                    end

                    req_up    <= 1'b0;
                    req_down  <= 1'b0;
                    req_left  <= 1'b0;
                    req_right <= 1'b0;
                end
            end
        end
    end

endmodule

