`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////
//  Frogger on Basys 3 FPGA
//  David J. Marion  
//  June 12, 2026
//
//  Module hierarchy:
//      frogger_top.v
//          - pixel_clock.v
//          - vga_timing.v
//          - frame_tick.v
//          - button_input.v
//          - nes_controller.v
//          - game_state.v
//          - renderer.v
//          - frogger_audio.v
//////////////////////////////////////////////////////////////////
module frogger_top(
    input  wire clk_100MHz,
    input  wire btnU,               // move up
    input  wire btnD,               // move down
    input  wire btnL,               // move left
    input  wire btnR,               // move down
    input  wire btnC,               // reset     
    input  wire mode_sw,            // sw[15], 1 = NES Controller mode, 0 = Basys 3 Buttons mode
    
    // NES Controller signals (Pmod JA)
    input  wire data,              // input data from nes controller to FPGA
	output wire latch,             // signal to latch nes controller button states
	output wire nes_clk,           // nes controller serial data sync clock
    
    // VGA outputs
    output wire Hsync,
    output wire Vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,

    // AMP2 audio outputs (Pmod JB)
    output wire amp2_ain,
    output wire amp2_gain,
    output wire amp2_shutdown_n
);

    wire clk_25MHz;
    wire reset;
    wire video_on;
    wire [9:0] pix_x;
    wire [9:0] pix_y;
    wire [11:0] rgb;
    wire frame_tick;

    wire btn_up_pressed;
    wire btn_down_pressed;
    wire btn_left_pressed;
    wire btn_right_pressed;

    wire nes_A;
    wire nes_B;
    wire nes_select;
    wire nes_start;
    wire nes_up;
    wire nes_down;
    wire nes_left;
    wire nes_right;

    reg nes_A_d;
    reg nes_start_d;
    reg nes_up_d;
    reg nes_down_d;
    reg nes_left_d;
    reg nes_right_d;

    wire nes_A_pressed;
    wire nes_start_pressed;
    wire nes_up_pressed;
    wire nes_down_pressed;
    wire nes_left_pressed;
    wire nes_right_pressed;

    reg input_mode;              // 0 = Basys3 buttons, 1 = NES controller, latched on reset/startup
    reg nes_input_armed = 1'b0;  // goes high after a short startup delay in NES mode
    reg [5:0] nes_arm_frames = 6'd0;
    reg startup_latch_done = 1'b0;
    reg [3:0] startup_latch_count = 4'd0;


    wire up_pressed;
    wire down_pressed;
    wire left_pressed;
    wire right_pressed;
    wire start_pressed;

    wire [9:0] frog_x;
    wire [9:0] frog_y;

    // 13 cars
    wire signed [10:0] car0_x;   wire [9:0] car0_y;
    wire signed [10:0] car1_x;   wire [9:0] car1_y;
    wire signed [10:0] car2_x;   wire [9:0] car2_y;
    wire signed [10:0] car3_x;   wire [9:0] car3_y;
    wire signed [10:0] car4_x;   wire [9:0] car4_y;
    wire signed [10:0] car5_x;   wire [9:0] car5_y;
    wire signed [10:0] car6_x;   wire [9:0] car6_y;
    wire signed [10:0] car7_x;   wire [9:0] car7_y;
    wire signed [10:0] car8_x;   wire [9:0] car8_y;
    wire signed [10:0] car9_x;   wire [9:0] car9_y;
    wire signed [10:0] car10_x;  wire [9:0] car10_y;
    wire signed [10:0] car11_x;  wire [9:0] car11_y;
    wire signed [10:0] car12_x;  wire [9:0] car12_y;

    // 12 logs
    wire signed [10:0] log0_x;   wire [9:0] log0_y;
    wire signed [10:0] log1_x;   wire [9:0] log1_y;
    wire signed [10:0] log2_x;   wire [9:0] log2_y;
    wire signed [10:0] log3_x;   wire [9:0] log3_y;
    wire signed [10:0] log4_x;   wire [9:0] log4_y;
    wire signed [10:0] log5_x;   wire [9:0] log5_y;
    wire signed [10:0] log6_x;   wire [9:0] log6_y;
    wire signed [10:0] log7_x;   wire [9:0] log7_y;
    wire signed [10:0] log8_x;   wire [9:0] log8_y;
    wire signed [10:0] log9_x;   wire [9:0] log9_y;
    wire signed [10:0] log10_x;  wire [9:0] log10_y;
    wire signed [10:0] log11_x;  wire [9:0] log11_y;

    // turtle groups and snake
    wire signed [10:0] turtle0_x; wire [9:0] turtle0_y;
    wire signed [10:0] turtle1_x; wire [9:0] turtle1_y;
    wire signed [10:0] turtle2_x; wire [9:0] turtle2_y;
    wire [1:0] turtle_state;
    wire turtle_ripple_anim;
    wire signed [10:0] snake_x; wire [9:0] snake_y;
    wire snake_active;
    wire snake_anim;
    wire snake_dir;

    // User Interface
    wire title_active;
    wire goal_flash_active;
    wire [4:0] goal_filled;
    wire [2:0] homes_filled_count;
    wire level_clear_active;
    wire death_flash_active;
    wire game_over_active;
    wire [2:0] lives;
    wire [16:0] score;

    // Audio
    wire audio_start_event;
    wire audio_hop_event;
    wire audio_death_event;
    wire audio_home_event;
    wire game_music_enable;

    assign reset = btnC;

    pixel_clock u_pixel_clock (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .clk_25MHz(clk_25MHz)
    );

    vga_timing u_vga_timing (
        .clk(clk_25MHz),
        .reset(reset),
        .hsync(Hsync),
        .vsync(Vsync),
        .video_on(video_on),
        .pix_x(pix_x),
        .pix_y(pix_y)
    );
    
    frame_tick u_frame_tick(
        .clk(clk_25MHz),
        .reset(reset),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .tick(frame_tick)
    );

    button_input u_button_input (
        .clk(clk_25MHz),
        .reset(reset),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .up_pressed(btn_up_pressed),
        .down_pressed(btn_down_pressed),
        .left_pressed(btn_left_pressed),
        .right_pressed(btn_right_pressed)
    );

    nes_controller u_nes_controller (
        .clk(clk_100MHz),
        .reset(reset),
        .data(data),
        .latch(latch),
        .nes_clk(nes_clk),
        .A(nes_A),
        .B(nes_B),
        .select(nes_select),
        .start(nes_start),
        .up(nes_up),
        .down(nes_down),
        .left(nes_left),
        .right(nes_right)
    );

    always @(posedge clk_25MHz) begin
        if (reset) begin
            // Manual reset returns to title and samples the physical mode switch.
            input_mode <= mode_sw;

            startup_latch_done <= 1'b1;
            startup_latch_count <= 4'd0;

            nes_input_armed <= 1'b0;
            nes_arm_frames <= 6'd0;

            nes_A_d <= 1'b0;
            nes_start_d <= 1'b0;
            nes_up_d <= 1'b0;
            nes_down_d <= 1'b0;
            nes_left_d <= 1'b0;
            nes_right_d <= 1'b0;
        end
        else begin
            // At FPGA configuration/startup, wait briefly, then sample mode_sw
            // so the first title screen shows the correct controller mode.
            if (!startup_latch_done) begin
                if (startup_latch_count == 4'd15) begin
                    input_mode <= mode_sw;
                    startup_latch_done <= 1'b1;
                end
                else begin
                    startup_latch_count <= startup_latch_count + 1'b1;
                end

                nes_input_armed <= 1'b0;
                nes_arm_frames <= 6'd0;
            end
            else begin
                // While title is active, allow the physical switch to choose
                // the controller mode. Once title_active goes low, the selected
                // mode is locked for gameplay.
                if (title_active)
                    input_mode <= mode_sw;

                // Arm NES input after a short delay whenever NES mode is selected.
                // IMPORTANT: this must also happen on the title screen, otherwise
                // the NES Start/A button can never begin the game.
                if (!input_mode) begin
                    nes_input_armed <= 1'b0;
                    nes_arm_frames <= 6'd0;
                end
                else if (frame_tick && !nes_input_armed) begin
                    if (nes_arm_frames == 6'd30)
                        nes_input_armed <= 1'b1;
                    else
                        nes_arm_frames <= nes_arm_frames + 1'b1;
                end
            end

            nes_A_d <= nes_A;
            nes_start_d <= nes_start;
            nes_up_d <= nes_up;
            nes_down_d <= nes_down;
            nes_left_d <= nes_left;
            nes_right_d <= nes_right;
        end
    end

    assign nes_A_pressed     = nes_A     & ~nes_A_d;
    assign nes_start_pressed = nes_start & ~nes_start_d;
    assign nes_up_pressed    = nes_up    & ~nes_up_d;
    assign nes_down_pressed  = nes_down  & ~nes_down_d;
    assign nes_left_pressed  = nes_left  & ~nes_left_d;
    assign nes_right_pressed = nes_right & ~nes_right_d;

    assign up_pressed    = input_mode ? (nes_input_armed & nes_up_pressed)    : btn_up_pressed;
    assign down_pressed  = input_mode ? (nes_input_armed & nes_down_pressed)  : btn_down_pressed;
    assign left_pressed  = input_mode ? (nes_input_armed & nes_left_pressed)  : btn_left_pressed;
    assign right_pressed = input_mode ? (nes_input_armed & nes_right_pressed) : btn_right_pressed;
    assign start_pressed = input_mode ? (nes_input_armed & (nes_start_pressed | nes_A_pressed)) :
                                        btn_up_pressed ;


    assign game_music_enable = (!title_active && !game_over_active && !death_flash_active && !level_clear_active);
    game_state u_game_state (
        .clk(clk_25MHz),
        .reset(reset),
        .frame_tick(frame_tick),
        .up_pressed(up_pressed),
        .down_pressed(down_pressed),
        .left_pressed(left_pressed),
        .right_pressed(right_pressed),
        .start_pressed(start_pressed),

        .frog_x(frog_x),
        .frog_y(frog_y),

        .car0_x(car0_x),   .car0_y(car0_y),
        .car1_x(car1_x),   .car1_y(car1_y),
        .car2_x(car2_x),   .car2_y(car2_y),
        .car3_x(car3_x),   .car3_y(car3_y),
        .car4_x(car4_x),   .car4_y(car4_y),
        .car5_x(car5_x),   .car5_y(car5_y),
        .car6_x(car6_x),   .car6_y(car6_y),
        .car7_x(car7_x),   .car7_y(car7_y),
        .car8_x(car8_x),   .car8_y(car8_y),
        .car9_x(car9_x),   .car9_y(car9_y),
        .car10_x(car10_x), .car10_y(car10_y),
        .car11_x(car11_x), .car11_y(car11_y),
        .car12_x(car12_x), .car12_y(car12_y),

        .log0_x(log0_x),   .log0_y(log0_y),
        .log1_x(log1_x),   .log1_y(log1_y),
        .log2_x(log2_x),   .log2_y(log2_y),
        .log3_x(log3_x),   .log3_y(log3_y),
        .log4_x(log4_x),   .log4_y(log4_y),
        .log5_x(log5_x),   .log5_y(log5_y),
        .log6_x(log6_x),   .log6_y(log6_y),
        .log7_x(log7_x),   .log7_y(log7_y),
        .log8_x(log8_x),   .log8_y(log8_y),
        .log9_x(log9_x),   .log9_y(log9_y),
        .log10_x(log10_x), .log10_y(log10_y),
        .log11_x(log11_x), .log11_y(log11_y),

        .turtle0_x(turtle0_x), .turtle0_y(turtle0_y),
        .turtle1_x(turtle1_x), .turtle1_y(turtle1_y),
        .turtle2_x(turtle2_x), .turtle2_y(turtle2_y),
        .turtle_state(turtle_state),
        .turtle_ripple_anim(turtle_ripple_anim),
        .snake_x(snake_x), .snake_y(snake_y),
        .snake_active(snake_active),
        .snake_anim(snake_anim),
        .snake_dir(snake_dir),

        .title_active(title_active),
        .goal_flash_active(goal_flash_active),
        .goal_filled(goal_filled),
        .homes_filled_count(homes_filled_count),
        .level_clear_active(level_clear_active),
        .death_flash_active(death_flash_active),
        .game_over_active(game_over_active),
        .lives(lives),
        .score(score),
        .audio_start_event(audio_start_event),
        .audio_hop_event(audio_hop_event),
        .audio_death_event(audio_death_event),
        .audio_home_event(audio_home_event)
    );

    renderer u_renderer (
        .video_on(video_on),
        .pix_x(pix_x),
        .pix_y(pix_y),

        .frog_x(frog_x),
        .frog_y(frog_y),

        .car0_x(car0_x),   .car0_y(car0_y),
        .car1_x(car1_x),   .car1_y(car1_y),
        .car2_x(car2_x),   .car2_y(car2_y),
        .car3_x(car3_x),   .car3_y(car3_y),
        .car4_x(car4_x),   .car4_y(car4_y),
        .car5_x(car5_x),   .car5_y(car5_y),
        .car6_x(car6_x),   .car6_y(car6_y),
        .car7_x(car7_x),   .car7_y(car7_y),
        .car8_x(car8_x),   .car8_y(car8_y),
        .car9_x(car9_x),   .car9_y(car9_y),
        .car10_x(car10_x), .car10_y(car10_y),
        .car11_x(car11_x), .car11_y(car11_y),
        .car12_x(car12_x), .car12_y(car12_y),

        .log0_x(log0_x),   .log0_y(log0_y),
        .log1_x(log1_x),   .log1_y(log1_y),
        .log2_x(log2_x),   .log2_y(log2_y),
        .log3_x(log3_x),   .log3_y(log3_y),
        .log4_x(log4_x),   .log4_y(log4_y),
        .log5_x(log5_x),   .log5_y(log5_y),
        .log6_x(log6_x),   .log6_y(log6_y),
        .log7_x(log7_x),   .log7_y(log7_y),
        .log8_x(log8_x),   .log8_y(log8_y),
        .log9_x(log9_x),   .log9_y(log9_y),
        .log10_x(log10_x), .log10_y(log10_y),
        .log11_x(log11_x), .log11_y(log11_y),

        .turtle0_x(turtle0_x), .turtle0_y(turtle0_y),
        .turtle1_x(turtle1_x), .turtle1_y(turtle1_y),
        .turtle2_x(turtle2_x), .turtle2_y(turtle2_y),
        .turtle_state(turtle_state),
        .turtle_ripple_anim(turtle_ripple_anim),
        .snake_x(snake_x), .snake_y(snake_y),
        .snake_active(snake_active),
        .snake_anim(snake_anim),
        .snake_dir(snake_dir),

        .title_active(title_active),
        .input_mode(input_mode),
        .goal_flash_active(goal_flash_active),
        .goal_filled(goal_filled),
        .homes_filled_count(homes_filled_count),
        .level_clear_active(level_clear_active),
        .death_flash_active(death_flash_active),
        .game_over_active(game_over_active),
        .lives(lives),
        .score(score),

        .rgb(rgb)
    );


    frogger_audio u_frogger_audio (
        .clk(clk_100MHz),
        .reset(reset),
        .game_music_enable(game_music_enable),
        .start_event(audio_start_event),
        .hop_event(audio_hop_event),
        .death_event(audio_death_event),
        .home_event(audio_home_event),
        .amp2_ain(amp2_ain),
        .amp2_gain(amp2_gain),
        .amp2_shutdown_n(amp2_shutdown_n)
    );

    assign vgaRed   = rgb[11:8];
    assign vgaGreen = rgb[7:4];
    assign vgaBlue  = rgb[3:0];

endmodule

