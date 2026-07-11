`timescale 1ns / 1ps

// ============================================================
// Module: led_blinker
// Project: Basys 3 4x4 Keypad + LEDs + UART
//
// Purpose:
//   This module turns a one-clock key_valid pulse into a visible LED
//   blink on the Basys 3 board.
//
// Inputs from keypad_scanner:
//   key_code:
//     Selects which LED should blink. The keypad scanner produces a
//     value from 0 to 15, so the value maps directly to LED0-LED15.
//
//   key_valid:
//     A one-clock pulse telling this module that a new keypress was
//     detected. This module starts or restarts the LED blink whenever
//     key_valid is asserted.
//
// Behavior:
//   - When a key is pressed, exactly one LED turns on.
//   - The LED remains on for about 0.25 seconds.
//   - After the blink time expires, all LEDs turn off.
//   - If a new keypress arrives during a blink, the active LED changes
//     immediately and the blink timer restarts.
//
// LED/key mapping:
//   LED0  = 1      LED1  = 2      LED2  = 3      LED3  = A
//   LED4  = 4      LED5  = 5      LED6  = 6      LED7  = B
//   LED8  = 7      LED9  = 8      LED10 = 9      LED11 = C
//   LED12 = *      LED13 = 0      LED14 = #      LED15 = D
// ============================================================

module led_blinker(
    input  wire       clk,        // 100 MHz Basys 3 system clock
    input  wire       reset,      // active-high synchronous reset

    input  wire [3:0] key_code,   // LED/key index, 0 to 15
    input  wire       key_valid,  // one-clock pulse from keypad scanner

    output reg [15:0] led         // Basys 3 LED outputs
);

    // ------------------------------------------------------------
    // Blink timing
    // ------------------------------------------------------------
    // 100 MHz means each clock cycle is 10 ns.
    //
    //   25,000,000 cycles * 10 ns = 250,000,000 ns = 0.25 s
    //
    // This makes the LED blink long enough to be easily visible.
    // ------------------------------------------------------------
    localparam BLINK_TIME = 25_000_000;

    // Counts down while the LED is actively blinking.
    reg [24:0] blink_count;

    // Stores which LED should remain on during the blink interval.
    reg [3:0] active_led;

    // Indicates that a blink is currently in progress.
    reg blinking;

    always @(posedge clk) begin
        if (reset) begin
            // Reset all outputs and internal state.
            led         <= 16'b0;
            blink_count <= 25'd0;
            active_led  <= 4'd0;
            blinking    <= 1'b0;
        end else begin
            if (key_valid) begin
                // A new keypress has arrived.
                // Store the selected LED, reload the blink timer, and
                // immediately turn on the chosen LED.
                active_led  <= key_code;
                blink_count <= BLINK_TIME - 1;
                blinking    <= 1'b1;
                led         <= (16'b1 << key_code);
            end else if (blinking) begin
                // A blink is already in progress. Keep the active LED
                // on until the countdown reaches zero.
                if (blink_count == 0) begin
                    // Blink time is finished, so turn off all LEDs.
                    led      <= 16'b0;
                    blinking <= 1'b0;
                end else begin
                    // Continue the blink countdown and keep exactly one
                    // LED turned on.
                    blink_count <= blink_count - 1'b1;
                    led         <= (16'b1 << active_led);
                end
            end else begin
                // No active blink and no new keypress: LEDs are off.
                led <= 16'b0;
            end
        end
    end

endmodule
