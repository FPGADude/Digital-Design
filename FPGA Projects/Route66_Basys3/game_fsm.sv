module game_fsm (
    input  logic clk,
    input  logic rst,

    input  logic start_submit_pulse,
    input  logic one_hz_tick,
    input  logic [7:0] sw,
    input  logic [1:0] timer_select,

    output logic [7:0] leds,

    output logic [4:0] digit3_code,
    output logic [4:0] digit2_code,
    output logic [4:0] digit1_code,
    output logic [4:0] digit0_code,

    // Legacy tone-event outputs retained for compatibility/debugging.
    output logic sfx_start_pulse,
    output logic sfx_correct_pulse,
    output logic sfx_wrong_pulse,
    output logic sfx_gameover_pulse,

    // Route 66 voice events.
    output logic voice_begin_pulse,
    output logic voice_operation_pulse,
    output logic voice_operation_is_sub,
    output logic voice_correct_pulse,
    output logic voice_incorrect_pulse,
    output logic voice_ten_seconds_pulse,
    output logic voice_time_expired_pulse,
    output logic voice_gameover_pulse
);
    import route66_pkg::*;

    // Timer mode is sampled only when reset is pressed.
    // SW15:SW14 = 00 -> 60 s, 01 -> 45 s, 10 -> 30 s.
    // 11 intentionally makes no change to the previously latched setting.
    localparam logic [5:0] DEFAULT_TIME = 6'd30;
    localparam logic [2:0] SHOW_SECONDS  = 3'd1;
    localparam logic [2:0] CHECK_SECONDS = 3'd5;

    game_state_t state, next_state, prev_state;

    logic [2:0] question_index;
    logic [5:0] countdown;
    logic [5:0] question_time = DEFAULT_TIME;
    logic [3:0] score;
    logic       checked_correct;

    logic [2:0] show_counter;
    logic [2:0] check_counter;

    question_t current_question;
    logic      load_new_question;

    logic [7:0] correct_answer;
    logic       is_correct;

    logic [3:0] current_question_num;
    logic [3:0] timer_tens;
    logic [3:0] timer_ones;

    logic entering_check;
    logic entering_gameover;
    logic entering_playing;
    logic timed_out_check;

    assign current_question_num = question_index + 4'd1;
    assign timer_tens = countdown / 10;
    assign timer_ones = countdown % 10;

    assign entering_check     = (state == ST_CHECK)      && (prev_state != ST_CHECK);
    assign entering_gameover  = (state == ST_GAME_OVER)  && (prev_state != ST_GAME_OVER);
    assign entering_playing   = (state == ST_PLAYING)    && (prev_state != ST_PLAYING);
    assign load_new_question  = (state == ST_SHOW_QUESTION) && (prev_state != ST_SHOW_QUESTION);

    // A timeout transition decrements countdown from 1 to 0 on the same clock
    // that moves the FSM into ST_CHECK. A manual submit leaves countdown > 0.
    assign timed_out_check = entering_check && (countdown == 6'd0);

    random_question_gen u_rand_q (
        .clk(clk),
        .rst(rst),
        .load_new_question(load_new_question),
        .question(current_question)
    );

    answer_checker u_checker (
        .op(current_question.op),
        .operand(current_question.operand),
        .switches_value(sw),
        .correct_answer(correct_answer),
        .is_correct(is_correct)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            state      <= ST_IDLE;
            prev_state <= ST_IDLE;
        end else begin
            prev_state <= state;
            state      <= next_state;
        end
    end

    always_comb begin
        next_state = state;

        unique case (state)
            ST_IDLE: begin
                if (start_submit_pulse)
                    next_state = ST_SHOW_QUESTION;
            end

            ST_SHOW_QUESTION: begin
                if (one_hz_tick && (show_counter >= SHOW_SECONDS - 1'b1))
                    next_state = ST_PLAYING;
            end

            ST_PLAYING: begin
                // Manual submit wins if it occurs on the same clock as timeout.
                if (start_submit_pulse)
                    next_state = ST_CHECK;
                else if (one_hz_tick && (countdown <= 6'd1))
                    next_state = ST_CHECK;
            end

            ST_CHECK: begin
                if (one_hz_tick && (check_counter >= CHECK_SECONDS - 1'b1))
                    next_state = ST_NEXT;
            end

            ST_NEXT: begin
                if (question_index == NUM_QUESTIONS-1)
                    next_state = ST_GAME_OVER;
                else
                    next_state = ST_SHOW_QUESTION;
            end

            ST_GAME_OVER: begin
                if (start_submit_pulse)
                    next_state = ST_IDLE;
            end

            default: next_state = ST_IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            question_index  <= 3'd0;
            countdown       <= question_time;
            score           <= 4'd0;
            checked_correct <= 1'b0;
            show_counter    <= 3'd0;
            check_counter   <= 3'd0;

            // Latch difficulty/timer selection only on reset.  Changing
            // SW15:SW14 during a game therefore cannot change its timer.
            unique case (timer_select)
                2'b00: question_time <= 6'd60;
                2'b01: question_time <= 6'd45;
                2'b10: question_time <= 6'd30;
                2'b11: question_time <= question_time; // reserved / no change
                default: question_time <= question_time;
            endcase
        end else begin
            unique case (state)
                ST_IDLE: begin
                    show_counter  <= 3'd0;
                    check_counter <= 3'd0;

                    if (start_submit_pulse) begin
                        question_index  <= 3'd0;
                        countdown       <= question_time;
                        score           <= 4'd0;
                        checked_correct <= 1'b0;
                    end
                end

                ST_SHOW_QUESTION: begin
                    countdown       <= question_time;
                    check_counter   <= 3'd0;
                    checked_correct <= 1'b0;

                    if (prev_state != ST_SHOW_QUESTION)
                        show_counter <= 3'd0;
                    else if (one_hz_tick && (show_counter < SHOW_SECONDS))
                        show_counter <= show_counter + 1'b1;
                end

                ST_PLAYING: begin
                    show_counter <= 3'd0;

                    // Capture the result on the exact clock that ends the
                    // question. This prevents switch changes after Submit from
                    // changing the recorded answer during ST_CHECK.
                    if (start_submit_pulse) begin
                        checked_correct <= is_correct;
                        if (is_correct)
                            score <= score + 1'b1;
                    end else if (one_hz_tick && (countdown <= 6'd1)) begin
                        // Timeout: never award a point even if SW happens to
                        // equal the correct answer.
                        countdown       <= 6'd0;
                        checked_correct <= 1'b0;
                    end else if (one_hz_tick && (countdown != 6'd0)) begin
                        countdown <= countdown - 1'b1;
                    end
                end

                ST_CHECK: begin
                    if (entering_check)
                        check_counter <= 3'd0;
                    else if (one_hz_tick && (check_counter < CHECK_SECONDS))
                        check_counter <= check_counter + 1'b1;
                end

                ST_NEXT: begin
                    check_counter   <= 3'd0;
                    checked_correct <= 1'b0;

                    if (question_index != NUM_QUESTIONS-1)
                        question_index <= question_index + 1'b1;
                end

                ST_GAME_OVER: begin
                    show_counter  <= 3'd0;
                    check_counter <= 3'd0;
                end

                default: begin
                end
            endcase
        end
    end

    always_comb begin
        unique case (state)
            ST_IDLE,
            ST_GAME_OVER: leds = 8'h00;
            default:      leds = current_question.operand;
        endcase
    end

    always_comb begin
        digit3_code = 5'd19;
        digit2_code = 5'd19;
        digit1_code = 5'd19;
        digit0_code = 5'd19;

        unique case (state)
            ST_IDLE: begin
                digit3_code = 5'd10; // r
                digit2_code = 5'd11; // t
                digit1_code = 5'd6;
                digit0_code = 5'd6;
            end

            ST_SHOW_QUESTION: begin
                digit3_code = current_question_num;
                digit2_code = 5'd19;

                if (current_question.op == OP_ADD) begin
                    digit1_code = 5'd12; // A
                    digit0_code = 5'd13; // d
                end else begin
                    digit1_code = 5'd14; // S
                    digit0_code = 5'd15; // b
                end
            end

            ST_PLAYING: begin
                digit3_code = timer_tens;
                digit2_code = timer_ones;
                digit1_code = current_question_num;
                digit0_code = (current_question.op == OP_ADD) ? 5'd12 : 5'd14;
            end

            ST_CHECK: begin
                digit3_code = checked_correct ? 5'd16 : 5'd17; // C or E
                digit2_code = 5'd19;
                digit1_code = 5'd0;
                digit0_code = score;
            end

            ST_GAME_OVER: begin
                digit3_code = 5'd19;
                digit2_code = 5'd19;
                digit1_code = 5'd0;
                digit0_code = score;
            end

            default: begin
            end
        endcase
    end

    // Legacy tone-event pulses.
    always_comb begin
        sfx_start_pulse    = (state == ST_SHOW_QUESTION) && (prev_state == ST_IDLE);
        sfx_correct_pulse  = entering_check && !timed_out_check && checked_correct;
        sfx_wrong_pulse    = entering_check && (timed_out_check || !checked_correct);
        sfx_gameover_pulse = entering_gameover;
    end

    // Speech events. The voice manager queues these if speech is already busy.
    always_comb begin
        voice_begin_pulse        = (state == ST_SHOW_QUESTION) && (prev_state == ST_IDLE);
        voice_operation_pulse    = entering_playing;
        voice_operation_is_sub   = (current_question.op == OP_SUB);
        voice_correct_pulse      = entering_check && !timed_out_check && checked_correct;
        voice_incorrect_pulse    = entering_check && !timed_out_check && !checked_correct;
        voice_ten_seconds_pulse  = (state == ST_PLAYING) && one_hz_tick &&
                                   !start_submit_pulse && (countdown == 6'd11);
        voice_time_expired_pulse = timed_out_check;
        voice_gameover_pulse     = entering_gameover;
    end

endmodule
