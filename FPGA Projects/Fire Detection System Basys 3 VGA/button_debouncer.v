`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module: button_debouncer
//
// Purpose:
//   Conditions the mechanical center pushbutton used to acknowledge an alarm.
//   The asynchronous button input is first synchronized to the 100 MHz FPGA
//   clock, then required to remain stable for COUNT_MAX clock cycles before the
//   debounced state is changed. A rising edge of that stable state produces a
//   single-clock button_pulse.
//
// Important behavior:
//   - button_pulse is asserted for exactly one clk period per valid press.
//   - Holding the button does not generate repeated acknowledge pulses.
//   - COUNT_MAX = 1,000,000 gives approximately 10 ms at 100 MHz.
//////////////////////////////////////////////////////////////////////////////////
module button_debouncer #(
    parameter integer COUNT_MAX = 1_000_000
)(
    input  wire clk,
    input  wire reset,
    input  wire button_in,
    output reg  button_pulse
);

    // Two-stage synchronizer for the asynchronous mechanical input.
    reg button_meta;
    reg button_sync;
    // Debounced level and its delayed copy for rising-edge detection.
    reg button_state;
    reg button_state_d;

    // Counter width is derived automatically from the debounce interval.
    localparam integer COUNTER_WIDTH = $clog2(COUNT_MAX + 1);
    reg [COUNTER_WIDTH-1:0] counter;

    // Synchronize, debounce, and create the one-clock press pulse.
    always @(posedge clk) begin
        if (reset) begin
            button_meta    <= 1'b0;
            button_sync    <= 1'b0;
            button_state   <= 1'b0;
            button_state_d <= 1'b0;
            counter        <= {COUNTER_WIDTH{1'b0}};
            button_pulse   <= 1'b0;
        end
        else begin
            button_meta <= button_in;
            button_sync <= button_meta;

            // Stable input: no pending state change, so restart the timer.
            if (button_sync == button_state)
                counter <= {COUNTER_WIDTH{1'b0}};
            // New level remained stable for the entire debounce interval.
            else if (counter == COUNT_MAX - 1) begin
                button_state <= button_sync;
                counter <= {COUNTER_WIDTH{1'b0}};
            end
            else
                counter <= counter + 1'b1;

            // Compare the present debounced level with its previous value.
            button_state_d <= button_state;
            button_pulse <= button_state & ~button_state_d;
        end
    end

endmodule
