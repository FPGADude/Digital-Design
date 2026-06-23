// ================================================================
// top_elevator.v
// ================================================================
// Creator : David J. Marion
// Date    : 6.20.2026
// Project : Basys 3 FPGA Elevator Controller
// Purpose : Top-level integration for the Basys 3 elevator 
//           controller project.
//
// Notes   : Connects buttons, emergency-stop switch, request logic,
//           elevator FSM, seven-segment display, and VGA output.
//
// Board   : Digilent Basys 3, 100 MHz system clock
// Language: Verilog HDL
// ================================================================

module top_elevator(
    input  wire clk,
    input  wire btnU,   // request floor 4
    input  wire btnL,   // request floor 3
    input  wire btnR,   // request floor 2
    input  wire btnD,   // request floor 1
    input  wire btnC,   // manual door open request
    input  wire emer_stop_sw,   // sw[15]

    output wire [6:0] seg,
    output wire [3:0] an,
    output wire [3:0] led,

    output wire Hsync,
    output wire Vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue
);

    // This project does not use a dedicated reset button.
    // Can implement reset using a switch if desired.
    wire reset = 1'b0;

    // SW15 is used as the emergency stop input.
    wire emergency_stop = emer_stop_sw;

    // Debounced one-clock pulses from each Basys 3 pushbutton.
    wire btnU_pulse, btnL_pulse, btnR_pulse, btnD_pulse, btnC_pulse;
    wire [3:0] request_pulse;
    wire [3:0] requests;

    wire [2:0] state;
    wire [1:0] curr_floor;
    wire dir_up;
    wire moving;
    wire door_open;
    wire door_opening;
    wire door_closing;
    wire arrive_pulse;
    wire clear_current_request;
    wire [9:0] car_y;
    wire [5:0] door_pos;
    wire estop_active;

    wire [9:0] pix_x;
    wire [9:0] pix_y;
    wire video_on;
    wire [11:0] rgb_next;

    // Convert each mechanical button press into one clean request pulse.
    debounce_onepulse db_u(.clk(clk), .reset(reset), .btn_in(btnU), .pulse(btnU_pulse));
    debounce_onepulse db_l(.clk(clk), .reset(reset), .btn_in(btnL), .pulse(btnL_pulse));
    debounce_onepulse db_r(.clk(clk), .reset(reset), .btn_in(btnR), .pulse(btnR_pulse));
    debounce_onepulse db_d(.clk(clk), .reset(reset), .btn_in(btnD), .pulse(btnD_pulse));
    debounce_onepulse db_c(.clk(clk), .reset(reset), .btn_in(btnC), .pulse(btnC_pulse));

    // Button-to-floor mapping:
    // btnD -> floor 1, btnR -> floor 2, btnL -> floor 3, btnU -> floor 4.
    assign request_pulse = {btnU_pulse, btnL_pulse, btnR_pulse, btnD_pulse};

    // Request manager stores pending floor calls until the controller
    // arrives and opens the door at that floor.
    request_manager u_request_manager(
        .clk(clk),
        .reset(reset),
        .request_pulse(request_pulse),
        .curr_floor(curr_floor),
        .clear_current_request(clear_current_request),
        .requests(requests)
    );

    // Main elevator controller. Handles scheduling, smooth movement,
    // door timing, and emergency-stop behavior.
    elevator_controller u_elevator_controller(
        .clk(clk),
        .reset(reset),
        .requests(requests),
        .door_button(btnC_pulse),
        .emergency_stop(emergency_stop),
        .state(state),
        .curr_floor(curr_floor),
        .dir_up(dir_up),
        .moving(moving),
        .door_open(door_open),
        .door_opening(door_opening),
        .door_closing(door_closing),
        .arrive_pulse(arrive_pulse),
        .clear_current_request(clear_current_request),
        .car_y(car_y),
        .door_pos(door_pos),
        .estop_active(estop_active)
    );

    // Show the current floor on the Basys 3 seven-segment display.
    sevenseg_floor u_sevenseg(
        .clk(clk),
        .floor(curr_floor),
        .emergency_stop(emergency_stop),
        .seg(seg),
        .an(an)
    );

    // LED status indicators for quick board-level debugging.
    assign led[0] = moving;
    assign led[1] = door_open;
    assign led[2] = moving & dir_up;
    assign led[3] = moving & ~dir_up;

    // VGA timing produces pixel coordinates and sync pulses.
    vga_timing u_vga_timing(
        .clk(clk),
        .hsync(Hsync),
        .vsync(Vsync),
        .video_on(video_on),
        .pixel_x(pix_x),
        .pixel_y(pix_y)
    );

    // Renderer converts the elevator state into a 12-bit RGB pixel color.
    elevator_renderer u_renderer(
        .pixel_x(pix_x),
        .pixel_y(pix_y),
        .video_on(video_on),
        .state(state),
        .curr_floor(curr_floor),
        .dir_up(dir_up),
        .requests(requests),
        .moving(moving),
        .door_open(door_open),
        .door_opening(door_opening),
        .door_closing(door_closing),
        .car_y(car_y),
        .door_pos(door_pos),
        .estop_active(estop_active),
        .rgb(rgb_next)
    );

    // VGA Outputs
    assign vgaRed   = rgb_next[11:8];
    assign vgaGreen = rgb_next[7:4];
    assign vgaBlue  = rgb_next[3:0];

endmodule