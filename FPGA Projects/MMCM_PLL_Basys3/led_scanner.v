`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: led_scanner
//
// Description:
//   Reusable 8-LED "Knight Rider" scanner. A one-hot LED pattern moves from
//   one end of the LED group to the other, then reverses direction.
//
//   The STEP_COUNT parameter is deliberately expressed in input-clock cycles.
//   In this demonstration, two identical instances use the same STEP_COUNT:
//     - one is clocked at 100 MHz
//     - one is clocked at 200 MHz
//
//   Therefore, the 200 MHz scanner advances exactly twice as fast.
//////////////////////////////////////////////////////////////////////////////////

module led_scanner #(
    parameter integer STEP_COUNT = 12_500_000
)(
    input  wire       clk,
    input  wire       reset,
    output reg  [7:0] leds
);

    // STEP_COUNT must be at least 2 for the counter comparison below.
    reg [31:0] step_counter;
    reg        direction_left;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            step_counter   <= 32'd0;
            leds           <= 8'b0000_0001;
            direction_left <= 1'b1;
        end
        else begin
            if (step_counter == STEP_COUNT - 1) begin
                step_counter <= 32'd0;

                if (direction_left) begin
                    // Move toward LED bit 7.
                    if (leds == 8'b1000_0000) begin
                        // Reverse at the upper end without pausing there.
                        leds           <= 8'b0100_0000;
                        direction_left <= 1'b0;
                    end
                    else begin
                        leds <= leds << 1;
                    end
                end
                else begin
                    // Move toward LED bit 0.
                    if (leds == 8'b0000_0001) begin
                        // Reverse at the lower end without pausing there.
                        leds           <= 8'b0000_0010;
                        direction_left <= 1'b1;
                    end
                    else begin
                        leds <= leds >> 1;
                    end
                end
            end
            else begin
                step_counter <= step_counter + 1'b1;
            end
        end
    end

endmodule

