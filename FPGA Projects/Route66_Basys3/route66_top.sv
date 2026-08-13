module route66_top (
    input  logic       clk_100MHz,
    input  logic       btnL,     // start / submit
    input  logic       btnR,     // reset
    input  logic [15:0] sw,
    output logic [7:0] led,
    output logic [6:0] seg,
    output logic [3:0] an,

    output logic       amp2_ain,
    output logic       amp2_gain,
    output logic       amp2_shutdown_n
);
    import route66_pkg::*;

    logic rst_pulse;
    logic start_submit_pulse;
    logic one_hz_tick;
    logic refresh_tick;
    logic [4:0] digit3_code, digit2_code, digit1_code, digit0_code;

    // Legacy SFX event wires retained at the FSM boundary.
    logic sfx_start_pulse, sfx_correct_pulse, sfx_wrong_pulse, sfx_gameover_pulse;

    // Voice event wires.
    logic voice_begin_pulse;
    logic voice_operation_pulse;
    logic voice_operation_is_sub;
    logic voice_correct_pulse;
    logic voice_incorrect_pulse;
    logic voice_ten_seconds_pulse;
    logic voice_time_expired_pulse;
    logic voice_gameover_pulse;

    debounce_onepulse #(.CLK_HZ(100_000_000), .DEBOUNCE_MS(20)) u_btnL (
        .clk(clk_100MHz), .rst(1'b0), .noisy_in(btnL), .pulse_out(start_submit_pulse)
    );
    debounce_onepulse #(.CLK_HZ(100_000_000), .DEBOUNCE_MS(20)) u_btnR (
        .clk(clk_100MHz), .rst(1'b0), .noisy_in(btnR), .pulse_out(rst_pulse)
    );

    tick_gen #(.CLK_HZ(100_000_000), .TICK_HZ(1)) u_tick_1hz (
        .clk(clk_100MHz), .rst(rst_pulse), .tick(one_hz_tick)
    );
    tick_gen #(.CLK_HZ(100_000_000), .TICK_HZ(1000)) u_tick_refresh (
        .clk(clk_100MHz), .rst(rst_pulse), .tick(refresh_tick)
    );

    game_fsm u_game (
        .clk(clk_100MHz),
        .rst(rst_pulse),
        .start_submit_pulse(start_submit_pulse),
        .one_hz_tick(one_hz_tick),
        .sw(sw[7:0]),
        .timer_select(sw[15:14]),
        .leds(led),
        .digit3_code(digit3_code),
        .digit2_code(digit2_code),
        .digit1_code(digit1_code),
        .digit0_code(digit0_code),
        .sfx_start_pulse(sfx_start_pulse),
        .sfx_correct_pulse(sfx_correct_pulse),
        .sfx_wrong_pulse(sfx_wrong_pulse),
        .sfx_gameover_pulse(sfx_gameover_pulse),
        .voice_begin_pulse(voice_begin_pulse),
        .voice_operation_pulse(voice_operation_pulse),
        .voice_operation_is_sub(voice_operation_is_sub),
        .voice_correct_pulse(voice_correct_pulse),
        .voice_incorrect_pulse(voice_incorrect_pulse),
        .voice_ten_seconds_pulse(voice_ten_seconds_pulse),
        .voice_time_expired_pulse(voice_time_expired_pulse),
        .voice_gameover_pulse(voice_gameover_pulse)
    );

    sevenseg_mux u_display (
        .clk(clk_100MHz),
        .rst(rst_pulse),
        .refresh_tick(refresh_tick),
        .digit3_code(digit3_code),
        .digit2_code(digit2_code),
        .digit1_code(digit1_code),
        .digit0_code(digit0_code),
        .seg(seg),
        .an(an)
    );

    logic       voice_start;
    logic [3:0] voice_phrase_id;
    logic       voice_busy;
    logic signed [15:0] voice_pcm;
    logic       voice_sample_valid;
    logic       voice_pwm;

    route66_voice_manager #(.CLOCK_HZ(100_000_000)) u_voice_manager (
        .clk(clk_100MHz),
        .reset(rst_pulse),
        .voice_busy(voice_busy),
        .ev_begin(voice_begin_pulse),
        .ev_operation(voice_operation_pulse),
        .operation_is_sub(voice_operation_is_sub),
        .ev_correct(voice_correct_pulse),
        .ev_incorrect(voice_incorrect_pulse),
        .ev_ten_seconds(voice_ten_seconds_pulse),
        .ev_time_expired(voice_time_expired_pulse),
        .ev_game_over(voice_gameover_pulse),
        .voice_start(voice_start),
        .voice_phrase_id(voice_phrase_id)
    );

    route66_voice_core #(.CLOCK_HZ(100_000_000), .SAMPLE_HZ(12_500)) u_voice (
        .clk(clk_100MHz),
        .reset(rst_pulse),
        .start(voice_start),
        .phrase_id(voice_phrase_id),
        .busy(voice_busy),
        .sample_out(voice_pcm),
        .sample_valid(voice_sample_valid)
    );

    route66_pwm_dac u_voice_dac (
        .clk(clk_100MHz),
        .reset(rst_pulse),
        .pcm_sample(voice_pcm),
        .sample_valid(voice_sample_valid),
        .pwm_out(voice_pwm)
    );

    assign amp2_ain        = voice_pwm;
    assign amp2_gain       = 1'b0;
    assign amp2_shutdown_n = 1'b1;

endmodule
