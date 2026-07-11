`timescale 1ns / 1ps

// ============================================================
// Module: top_keypad_uart
// Project: Basys 3 4x4 Keypad + LEDs + UART
//
// Purpose:
//   Top-level module that connects the complete design together:
//     1. 4x4 keypad scanner
//     2. 16-LED blinker
//     3. ASCII conversion
//     4. UART transmitter
//
// Hardware connections:
//   A raw 4x4 keypad is connected to PMOD JB on the Basys 3.
//
//   Keypad Pin 1 / Row 1 -> JB1
//   Keypad Pin 2 / Row 2 -> JB2
//   Keypad Pin 3 / Row 3 -> JB3
//   Keypad Pin 4 / Row 4 -> JB4
//   Keypad Pin 5 / Col 1 -> JB7
//   Keypad Pin 6 / Col 2 -> JB8
//   Keypad Pin 7 / Col 3 -> JB9
//   Keypad Pin 8 / Col 4 -> JB10
//
// System behavior:
//   When a key is pressed:
//     1. keypad_scanner detects the row/column position.
//     2. keypad_scanner outputs key_code and a one-clock key_valid pulse.
//     3. led_blinker uses key_code to blink the matching Basys 3 LED.
//     4. This top module converts key_code into an ASCII character.
//     5. uart_tx sends that ASCII character to the PC terminal.
//
// Serial terminal settings:
//   9600 baud, 8 data bits, no parity, 1 stop bit, no flow control
//
// Notes:
//   The UART transmitter only sends bytes. It does not know what a
//   keypad is. That is why the key_code-to-ASCII conversion is kept in
//   this top module, where the system-level meaning of the key exists.
// ============================================================

module top_keypad_uart(
    input  wire       clk,       // 100 MHz Basys 3 system clock
    input  wire       reset,     // active-high reset, mapped to BTNC in the XDC

    input  wire [3:0] kp_cols,   // keypad column inputs from JB7-JB10
    output wire [3:0] kp_rows,   // keypad row outputs to JB1-JB4

    output wire [15:0] led,      // Basys 3 LED outputs
    output wire        uart_tx   // Basys 3 USB-UART TX output to PC
);

    // Decoded keypad index from the scanner.
    // Range: 0 to 15.
    wire [3:0] key_code;

    // One-clock pulse from the scanner when a new key is pressed.
    wire key_valid;

    // Busy flag from the UART transmitter. This is high while the UART
    // module is still sending a byte.
    wire uart_busy;

    // ASCII byte that will be sent to the PC terminal.
    // Examples:
    //   "1" = ASCII 0x31
    //   "A" = ASCII 0x41
    //   "*" = ASCII 0x2A
    reg [7:0] uart_data;

    // ------------------------------------------------------------
    // 4x4 keypad scanner
    // ------------------------------------------------------------
    // This module handles the low-level matrix scan. It drives one row
    // low at a time and reads the four column inputs to determine which
    // key is pressed.
    // ------------------------------------------------------------
    keypad_scanner u_keypad (
        .clk       (clk),
        .reset     (reset),
        .rows      (kp_rows),
        .cols      (kp_cols),
        .key_code  (key_code),
        .key_valid (key_valid)
    );

    // ------------------------------------------------------------
    // LED blink output
    // ------------------------------------------------------------
    // The keypad scanner produces a key_code from 0 to 15. This module
    // uses that same number as the LED index, so every keypad button
    // has a matching LED on the Basys 3.
    // ------------------------------------------------------------
    led_blinker u_leds (
        .clk       (clk),
        .reset     (reset),
        .key_code  (key_code),
        .key_valid (key_valid),
        .led       (led)
    );

    // ------------------------------------------------------------
    // key_code to ASCII conversion
    // ------------------------------------------------------------
    // The keypad scanner gives us a compact numeric code from 0 to 15.
    // That is useful inside the FPGA, but a PC terminal expects ASCII
    // characters. For example:
    //
    //   key_code = 5 is the internal index for the keypad button "5".
    //   The terminal must receive ASCII "5", not binary value 5.
    //
    // This combinational case statement performs that translation.
    // ------------------------------------------------------------
    always @(*) begin
        case (key_code)
            4'd0:  uart_data = "1";
            4'd1:  uart_data = "2";
            4'd2:  uart_data = "3";
            4'd3:  uart_data = "A";

            4'd4:  uart_data = "4";
            4'd5:  uart_data = "5";
            4'd6:  uart_data = "6";
            4'd7:  uart_data = "B";

            4'd8:  uart_data = "7";
            4'd9:  uart_data = "8";
            4'd10: uart_data = "9";
            4'd11: uart_data = "C";

            4'd12: uart_data = "*";
            4'd13: uart_data = "0";
            4'd14: uart_data = "#";
            4'd15: uart_data = "D";

            default: uart_data = "?";
        endcase
    end

    // ------------------------------------------------------------
    // UART transmitter
    // ------------------------------------------------------------
    // key_valid is already a one-clock pulse, so it is used as the
    // transmit request. The !uart_busy condition prevents a new byte
    // from starting while the UART module is still transmitting the
    // previous byte.
    //
    // For this version, each keypress sends one character only. The
    // terminal output will look like:
    //
    //   123A456B789C*0#D
    //
    // A later version could add a string sender to transmit full lines
    // such as "Key Pressed: 5".
    // ------------------------------------------------------------
    uart_tx u_uart_tx (
        .clk     (clk),
        .reset   (reset),
        .data_in (uart_data),
        .send    (key_valid && !uart_busy),
        .tx      (uart_tx),
        .busy    (uart_busy)
    );

endmodule
