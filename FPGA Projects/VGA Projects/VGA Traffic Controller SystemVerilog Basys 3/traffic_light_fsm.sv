`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Module: traffic_light_fsm
// -----------------------------------------------------------------------------
// Purpose:
//   Implements the traffic-light and pedestrian-signal state machine.
//
//   The FSM receives a one-second enable pulse from tick_gen_1s. On each tick,
//   it increments the seconds-in-state counter. When the programmed duration for
//   the current state expires, the FSM advances to the next state.
//
//   The outputs are symbolic encodings for:
//     - main_light  : main street traffic light color
//     - cross_light : cross street traffic light color
//     - main_ped    : pedestrian signal for crossings associated with main timing
//     - cross_ped   : pedestrian signal for crossings associated with cross timing
//
//   Countdown enable/digit outputs are sent to text_renderer.sv.
//
// Timing Parameters:
//   All state durations are set with module parameters so the top module can
//   easily adjust the demo timing without rewriting the FSM.
// -----------------------------------------------------------------------------

module traffic_light_fsm #(
    parameter int MAIN_WALK_SEC     = 20,
    parameter int MAIN_COUNT_SEC    = 5,
    parameter int MAIN_STEADY_SEC   = 5,
    parameter int MAIN_YELLOW_SEC   = 3,
    parameter int ALL_RED_1_SEC     = 2,
    parameter int CROSS_WALK_SEC    = 20,
    parameter int CROSS_COUNT_SEC   = 5,
    parameter int CROSS_STEADY_SEC  = 5,
    parameter int CROSS_YELLOW_SEC  = 3,
    parameter int ALL_RED_2_SEC     = 2
)(
    input  logic       clk,
    input  logic       reset,
    input  logic       tick_1s,
    output logic [1:0] main_light,
    output logic [1:0] cross_light,
    output logic [1:0] main_ped,
    output logic [1:0] cross_ped,
    output logic       main_count_active,
    output logic       cross_count_active,
    output logic [3:0] main_count_digit,
    output logic [3:0] cross_count_digit
);

    // Traffic light output encodings used by the VGA pixel renderer.
    localparam logic [1:0] LIGHT_RED    = 2'd0;
    localparam logic [1:0] LIGHT_YELLOW = 2'd1;
    localparam logic [1:0] LIGHT_GREEN  = 2'd2;

    // Pedestrian output encodings used by the VGA pixel/text renderers.
    localparam logic [1:0] PED_DONT_STEADY = 2'd0;
    localparam logic [1:0] PED_WALK        = 2'd1;
    localparam logic [1:0] PED_DONT_BLINK  = 2'd2;

    // Enumerated FSM states.
    // Using enum names makes the state diagram readable in the RTL and makes
    // simulation waveforms much easier to understand than raw binary values.
    typedef enum logic [3:0] {
        S_MAIN_GREEN_WALK,
        S_MAIN_DONT_COUNT,
        S_MAIN_DONT_STEADY,
        S_MAIN_YELLOW,
        S_ALL_RED_1,
        S_CROSS_GREEN_WALK,
        S_CROSS_DONT_COUNT,
        S_CROSS_DONT_STEADY,
        S_CROSS_YELLOW,
        S_ALL_RED_2
    } state_t;

    // State register and next-state signal.
    state_t state_reg, state_next;
    // Seconds elapsed within the current state.
    logic [7:0] sec_reg, sec_next;
    // Duration, in seconds, of the current state.
    logic [7:0] state_duration;

    // State and timer registers.
    // The FSM only updates on tick_1s, so state durations are measured in seconds
    // while the logic remains synchronous to the full FPGA clock.
    always_ff @(posedge clk) begin
        if (reset) begin
            state_reg <= S_MAIN_GREEN_WALK;
            sec_reg   <= 8'd0;
        end else if (tick_1s) begin
            state_reg <= state_next;
            sec_reg   <= sec_next;
        end
    end

    // Select the programmed duration for the active state.
    // Each enum state maps to one top-level timing parameter.
    always_comb begin
        unique case (state_reg)
            S_MAIN_GREEN_WALK:    state_duration = MAIN_WALK_SEC[7:0];
            S_MAIN_DONT_COUNT:    state_duration = MAIN_COUNT_SEC[7:0];
            S_MAIN_DONT_STEADY:   state_duration = MAIN_STEADY_SEC[7:0];
            S_MAIN_YELLOW:        state_duration = MAIN_YELLOW_SEC[7:0];
            S_ALL_RED_1:          state_duration = ALL_RED_1_SEC[7:0];
            S_CROSS_GREEN_WALK:   state_duration = CROSS_WALK_SEC[7:0];
            S_CROSS_DONT_COUNT:   state_duration = CROSS_COUNT_SEC[7:0];
            S_CROSS_DONT_STEADY:  state_duration = CROSS_STEADY_SEC[7:0];
            S_CROSS_YELLOW:       state_duration = CROSS_YELLOW_SEC[7:0];
            S_ALL_RED_2:          state_duration = ALL_RED_2_SEC[7:0];
            default:              state_duration = 8'd1;
        endcase
    end

    // Next-state and timer-count logic.
    // By default, stay in the same state and increment the seconds counter.
    // When the current state's duration expires, reset the counter and advance
    // to the next state in the intersection sequence.
    always_comb begin
        state_next = state_reg;
        sec_next   = sec_reg + 8'd1;

        if (sec_reg >= state_duration - 1'b1) begin
            sec_next = 8'd0;
            unique case (state_reg)
                S_MAIN_GREEN_WALK:   state_next = S_MAIN_DONT_COUNT;
                S_MAIN_DONT_COUNT:   state_next = S_MAIN_DONT_STEADY;
                S_MAIN_DONT_STEADY:  state_next = S_MAIN_YELLOW;
                S_MAIN_YELLOW:       state_next = S_ALL_RED_1;
                S_ALL_RED_1:         state_next = S_CROSS_GREEN_WALK;
                S_CROSS_GREEN_WALK:  state_next = S_CROSS_DONT_COUNT;
                S_CROSS_DONT_COUNT:  state_next = S_CROSS_DONT_STEADY;
                S_CROSS_DONT_STEADY: state_next = S_CROSS_YELLOW;
                S_CROSS_YELLOW:      state_next = S_ALL_RED_2;
                S_ALL_RED_2:         state_next = S_MAIN_GREEN_WALK;
                default:             state_next = S_MAIN_GREEN_WALK;
            endcase
        end
    end

    // Output decode logic.
    // Defaults are safe: all vehicle lights red and all pedestrian signals steady
    // DON'T WALK. Each state then overrides only the outputs it needs.
    always_comb begin
        main_light         = LIGHT_RED;
        cross_light        = LIGHT_RED;
        main_ped           = PED_DONT_STEADY;
        cross_ped          = PED_DONT_STEADY;
        main_count_active  = 1'b0;
        cross_count_active = 1'b0;
        main_count_digit   = 4'd0;
        cross_count_digit  = 4'd0;

        unique case (state_reg)
            S_MAIN_GREEN_WALK: begin
                main_light = LIGHT_GREEN;
                cross_light = LIGHT_RED;
                main_ped = PED_WALK;
            end

            S_MAIN_DONT_COUNT: begin
                main_light = LIGHT_GREEN;
                cross_light = LIGHT_RED;
                main_ped = PED_DONT_BLINK;
                main_count_active = 1'b1;
                main_count_digit = MAIN_COUNT_SEC[3:0] - sec_reg[3:0];
            end

            S_MAIN_DONT_STEADY: begin
                main_light = LIGHT_GREEN;
                cross_light = LIGHT_RED;
            end

            S_MAIN_YELLOW: begin
                main_light = LIGHT_YELLOW;
                cross_light = LIGHT_RED;
            end

            S_ALL_RED_1: begin
                main_light = LIGHT_RED;
                cross_light = LIGHT_RED;
            end

            S_CROSS_GREEN_WALK: begin
                main_light = LIGHT_RED;
                cross_light = LIGHT_GREEN;
                cross_ped = PED_WALK;
            end

            S_CROSS_DONT_COUNT: begin
                main_light = LIGHT_RED;
                cross_light = LIGHT_GREEN;
                cross_ped = PED_DONT_BLINK;
                cross_count_active = 1'b1;
                cross_count_digit = CROSS_COUNT_SEC[3:0] - sec_reg[3:0];
            end

            S_CROSS_DONT_STEADY: begin
                main_light = LIGHT_RED;
                cross_light = LIGHT_GREEN;
            end

            S_CROSS_YELLOW: begin
                main_light = LIGHT_RED;
                cross_light = LIGHT_YELLOW;
            end

            S_ALL_RED_2: begin
                main_light = LIGHT_RED;
                cross_light = LIGHT_RED;
            end

            default: begin
                main_light = LIGHT_RED;
                cross_light = LIGHT_RED;
            end
        endcase
    end

endmodule

