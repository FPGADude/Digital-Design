// ================================================================
// elevator_controller.v
// ================================================================
// Creator : David J. Marion
// Date    : 6.20.2026
// Project : Basys 3 FPGA Elevator Controller
// Purpose : Main elevator finite-state machine and animation
//           controller.
//
// Notes   : Implements direction-based request servicing, smooth
//           car movement, door timing, and SW15 emergency stop.
//
// Board   : Digilent Basys 3, 100 MHz system clock
// Language: Verilog HDL
// ================================================================

module elevator_controller(
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] requests,
    input  wire       door_button,
    input  wire       emergency_stop,

    output reg  [2:0] state,
    output reg  [1:0] curr_floor,
    output reg        dir_up,
    output reg        moving,
    output reg        door_open,
    output reg        door_opening,
    output reg        door_closing,
    output reg        arrive_pulse,
    output reg        clear_current_request,
    output reg  [9:0] car_y,
    output reg  [5:0] door_pos,
    output wire       estop_active
);

    // FSM states. The controller separates motion from door operation so
    // the VGA car can move smoothly before the doors open at a requested floor.
    localparam IDLE       = 3'd0;
    localparam MOVE_UP    = 3'd1;
    localparam MOVE_DOWN  = 3'd2;
    localparam OPEN_DOOR  = 3'd3;
    localparam WAIT_DOOR  = 3'd4;
    localparam CLOSE_DOOR = 3'd5;

    // VGA Y positions for the top of the elevator car at each floor.
    // Smaller Y values are higher on the screen, so floor 4 is near the top.
    localparam FLOOR1_Y = 10'd345;
    localparam FLOOR2_Y = 10'd245;
    localparam FLOOR3_Y = 10'd145;
    localparam FLOOR4_Y = 10'd45;

    // 100 MHz clock settings.
    // MOVE_TICK = 2,000,000 gives 50 pixels/second. Floors are 100 pixels apart,
    // so travel between adjacent floors takes about 2 seconds.
    // Movement and door timing parameters. These are intentionally easy
    // to tune during demonstration:
    //   MOVE_TICK  controls car pixel speed.
    //   DOOR_TICK  controls door animation speed.
    //   WAIT_TICKS controls how long doors stay open.
    //   DOOR_MAX   is the maximum opening distance of each door half.
    parameter MOVE_TICK  = 2000000;
    parameter DOOR_TICK  = 5000000;
    parameter WAIT_TICKS = 200000000;
    parameter DOOR_MAX   = 34;

    // Independent counters for car movement, door animation, and dwell time.
    reg [31:0] move_count;
    reg [31:0] door_count;
    reg [31:0] wait_count;

    // Request helper signals used by the scheduling logic.
    // current_requested: request bit for the floor where the car currently is.
    // requests_above/below: any pending requests above or below curr_floor.
    wire current_requested;
    wire requests_above;
    wire requests_below;

    // Values for the adjacent floor in the current movement direction.
    // The car moves one floor interval at a time but only stops if that
    // arrived floor has a pending request.
    reg [1:0] next_floor_up;
    reg [1:0] next_floor_down;
    reg [9:0] target_y;
    reg       next_requested;
    reg       above_after_next;
    reg       below_after_next;


    // Initial values make the simulation and FPGA power-up start at floor 1
    // with doors closed and no pending movement.
    initial begin
        state = IDLE;
        curr_floor = 2'd0;
        dir_up = 1'b1;
        moving = 1'b0;
        door_open = 1'b0;
        door_opening = 1'b0;
        door_closing = 1'b0;
        arrive_pulse = 1'b0;
        clear_current_request = 1'b0;
        car_y = FLOOR1_Y;
        door_pos = 6'd0;
        move_count = 32'd0;
        door_count = 32'd0;
        wait_count = 32'd0;
    end

    // estop_active is passed through to the VGA renderer/status panel.
    assign estop_active = emergency_stop;
    assign current_requested = requests[curr_floor];
    assign requests_above = ((curr_floor < 2'd3) && |(requests & (4'b1111 << (curr_floor + 1))));
    assign requests_below = ((curr_floor > 2'd0) && |(requests & ((4'b0001 << curr_floor) - 1)));

    // Convert logical floor number into the car's VGA Y coordinate.
    function [9:0] floor_to_y;
        input [1:0] floor;
        begin
            case (floor)
                2'd0: floor_to_y = FLOOR1_Y;
                2'd1: floor_to_y = FLOOR2_Y;
                2'd2: floor_to_y = FLOOR3_Y;
                2'd3: floor_to_y = FLOOR4_Y;
                default: floor_to_y = FLOOR1_Y;
            endcase
        end
    endfunction

    // Combinational scheduling helper. Depending on the movement state,
    // calculate the next adjacent floor, target Y position, and whether
    // more requests remain beyond that next floor.
    always @(*) begin
        next_floor_up   = (curr_floor < 2'd3) ? (curr_floor + 1'b1) : curr_floor;
        next_floor_down = (curr_floor > 2'd0) ? (curr_floor - 1'b1) : curr_floor;

        if (state == MOVE_UP) begin
            target_y = floor_to_y(next_floor_up);
            next_requested = requests[next_floor_up];
            above_after_next = ((next_floor_up < 2'd3) && |(requests & (4'b1111 << (next_floor_up + 1))));
            below_after_next = ((next_floor_up > 2'd0) && |(requests & ((4'b0001 << next_floor_up) - 1)));
        end else begin
            target_y = floor_to_y(next_floor_down);
            next_requested = requests[next_floor_down];
            above_after_next = ((next_floor_down < 2'd3) && |(requests & (4'b1111 << (next_floor_down + 1))));
            below_after_next = ((next_floor_down > 2'd0) && |(requests & ((4'b0001 << next_floor_down) - 1)));
        end
    end

    // Sequential FSM. All movement, door timing, request clearing, and
    // direction decisions happen here on the 100 MHz clock.
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            curr_floor <= 2'd0;
            dir_up <= 1'b1;
            car_y <= FLOOR1_Y;
            door_pos <= 6'd0;
            move_count <= 32'd0;
            door_count <= 32'd0;
            wait_count <= 32'd0;
            arrive_pulse <= 1'b0;
            clear_current_request <= 1'b0;
        end else begin
            arrive_pulse <= 1'b0;
            clear_current_request <= 1'b0;

            // Emergency stop freezes motion and timers. When SW15 is turned back off,
            // the elevator resumes from the exact same position.
            if (!emergency_stop) begin
                case (state)
                    // IDLE: car is stopped with doors closed. If the current
                    // floor is requested, open immediately. Otherwise choose a
                    // direction based on pending requests above/below.
                    IDLE: begin
                        move_count <= 32'd0;
                        door_count <= 32'd0;
                        wait_count <= 32'd0;
                        door_pos <= 6'd0;

                        if (current_requested || door_button) begin
                            state <= OPEN_DOOR;
                            clear_current_request <= 1'b1;
                        end else if (requests_above) begin
                            state <= MOVE_UP;
                            dir_up <= 1'b1;
                        end else if (requests_below) begin
                            state <= MOVE_DOWN;
                            dir_up <= 1'b0;
                        end
                    end

                    // MOVE_UP: animate car_y upward one pixel at a time until
                    // the next floor position is reached. Stop only if that
                    // floor has a pending request; otherwise continue upward or
                    // reverse if needed.
                    MOVE_UP: begin
                        if (move_count >= MOVE_TICK-1) begin
                            move_count <= 32'd0;

                            if (car_y > target_y)
                                car_y <= car_y - 1'b1;

                            if (car_y <= target_y + 1) begin
                                car_y <= target_y;
                                curr_floor <= next_floor_up;
                                arrive_pulse <= 1'b1;

                                if (next_requested) begin
                                    state <= OPEN_DOOR;
                                    clear_current_request <= 1'b1;
                                end else if (above_after_next) begin
                                    state <= MOVE_UP;
                                    dir_up <= 1'b1;
                                end else if (below_after_next) begin
                                    state <= MOVE_DOWN;
                                    dir_up <= 1'b0;
                                end else begin
                                    state <= IDLE;
                                end
                            end
                        end else begin
                            move_count <= move_count + 1'b1;
                        end
                    end

                    // MOVE_DOWN: same idea as MOVE_UP, but car_y increases
                    // because larger Y values are lower on the VGA screen.
                    MOVE_DOWN: begin
                        if (move_count >= MOVE_TICK-1) begin
                            move_count <= 32'd0;

                            if (car_y < target_y)
                                car_y <= car_y + 1'b1;

                            if (car_y >= target_y - 1) begin
                                car_y <= target_y;
                                curr_floor <= next_floor_down;
                                arrive_pulse <= 1'b1;

                                if (next_requested) begin
                                    state <= OPEN_DOOR;
                                    clear_current_request <= 1'b1;
                                end else if (below_after_next) begin
                                    state <= MOVE_DOWN;
                                    dir_up <= 1'b0;
                                end else if (above_after_next) begin
                                    state <= MOVE_UP;
                                    dir_up <= 1'b1;
                                end else begin
                                    state <= IDLE;
                                end
                            end
                        end else begin
                            move_count <= move_count + 1'b1;
                        end
                    end

                    // OPEN_DOOR: increase door_pos. The renderer uses door_pos
                    // to shrink the two door rectangles away from the center.
                    OPEN_DOOR: begin
                        if (door_count >= DOOR_TICK-1) begin
                            door_count <= 32'd0;
                            if (door_pos < DOOR_MAX)
                                door_pos <= door_pos + 1'b1;
                            else begin
                                state <= WAIT_DOOR;
                                wait_count <= 32'd0;
                            end
                        end else begin
                            door_count <= door_count + 1'b1;
                        end
                    end

                    // WAIT_DOOR: hold doors open for a visible dwell time.
                    WAIT_DOOR: begin
                        if (wait_count >= WAIT_TICKS-1) begin
                            wait_count <= 32'd0;
                            state <= CLOSE_DOOR;
                        end else begin
                            wait_count <= wait_count + 1'b1;
                        end
                    end

                    // CLOSE_DOOR: decrease door_pos until both door halves meet.
                    // After closing, continue in the same direction when possible
                    // before reversing, which mimics real elevator scheduling.
                    CLOSE_DOOR: begin
                        if (door_count >= DOOR_TICK-1) begin
                            door_count <= 32'd0;
                            if (door_pos > 0)
                                door_pos <= door_pos - 1'b1;
                            else begin
                                if (dir_up) begin
                                    if (requests_above) begin
                                        state <= MOVE_UP;
                                        dir_up <= 1'b1;
                                    end else if (requests_below) begin
                                        state <= MOVE_DOWN;
                                        dir_up <= 1'b0;
                                    end else if (current_requested || door_button) begin
                                        state <= OPEN_DOOR;
                                        clear_current_request <= 1'b1;
                                    end else begin
                                        state <= IDLE;
                                    end
                                end else begin
                                    if (requests_below) begin
                                        state <= MOVE_DOWN;
                                        dir_up <= 1'b0;
                                    end else if (requests_above) begin
                                        state <= MOVE_UP;
                                        dir_up <= 1'b1;
                                    end else if (current_requested || door_button) begin
                                        state <= OPEN_DOOR;
                                        clear_current_request <= 1'b1;
                                    end else begin
                                        state <= IDLE;
                                    end
                                end
                            end
                        end else begin
                            door_count <= door_count + 1'b1;
                        end
                    end

                    default: begin
                        state <= IDLE;
                    end
                endcase
            end
        end
    end

    // Output decode for LEDs, VGA status text, and door state flags.
    always @(*) begin
        moving = ((state == MOVE_UP) || (state == MOVE_DOWN)) && !emergency_stop;
        door_opening = (state == OPEN_DOOR);
        door_closing = (state == CLOSE_DOOR);
        door_open = (state == OPEN_DOOR) || (state == WAIT_DOOR);
    end

endmodule