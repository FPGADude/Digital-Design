`timescale 1ns / 1ps

//=============================================================================
// Module: top_keypad_ascii_uart_ila
//
// Purpose:
//   Top-level integration module for the Basys 3 keypad-to-UART ILA project.
//
// Data path:
//   4x4 keypad
//       -> matrix keypad scanner
//       -> 4-bit hexadecimal key code
//       -> ASCII converter
//       -> UART transmitter
//       -> Basys 3 USB-UART output
//
// ILA role:
//   The Integrated Logic Analyzer observes the keypad row/column activity,
//   decoded key value, ASCII byte, UART control signals, UART shift register,
//   bit index, and final serial transmit line.
//
// Board controls:
//   btnU - Active-high synchronous reset
//   led0 - One-clock key_valid indication
//   led1 - UART busy indication
//=============================================================================
module top_keypad_ascii_uart_ila(
    input wire clk,               // Basys 3 100 MHz system clock
    input wire btnC,              // Active-high synchronous reset
    input wire [3:0] keypad_cols, // Active-low keypad column inputs
    output wire [3:0] keypad_rows,// Active-low keypad row-drive outputs
    output wire uart_tx_out,      // UART serial output to USB-UART bridge
    output wire led0,             // Indicates the one-cycle key_valid pulse
    output wire led1              // Illuminated while UART transmitter is busy
);

    // Control and status signals shared among the project modules.
    wire scan_tick, key_valid, uart_start, uart_busy, uart_baud_tick;

    // Decoded keypad value and UART bit-position counter.
    wire [3:0] key_code, uart_bit_index;

    // Current keypad row number, retained as an internal observation signal.
    wire [1:0] active_row;

    // ASCII byte generated from the hexadecimal keypad code.
    wire [7:0] ascii_data;

    // Complete UART frame currently being shifted toward the TX output.
    wire [9:0] uart_shift_register;

    //-------------------------------------------------------------------------
    // Keypad scan-rate enable generator
    //
    // Generates 4,000 scan advances per second. Since the keypad has four
    // rows, one complete keypad frame is scanned 1,000 times per second.
    //-------------------------------------------------------------------------
    clock_enable_generator #(
        .CLOCK_FREQ_HZ(100_000_000),
        .TICK_FREQ_HZ(4_000)
    )
    u_scan_tick(
        .clk(clk),
        .reset(btnC),
        .tick(scan_tick)
    );

    //-------------------------------------------------------------------------
    // 4x4 matrix keypad scanner and frame-based debounce logic
    //-------------------------------------------------------------------------
    keypad_scanner #(
        .STABLE_FRAMES_REQUIRED(5),
        .RELEASE_FRAMES_REQUIRED(5)
    )
    u_keypad_scanner(
        .clk(clk),
        .reset(btnC),
        .scan_tick(scan_tick),
        .columns(keypad_cols),
        .rows(keypad_rows),
        .key_valid(key_valid),
        .key_code(key_code),
        .active_row(active_row)
    );

    // Convert the accepted 4-bit hexadecimal key into an ASCII byte.
    ascii_converter u_ascii_converter(
        .key_code(key_code),
        .ascii_data(ascii_data)
    );

    // Begin a UART transmission only when a new key is accepted and the
    // transmitter is available.
    assign uart_start = key_valid && !uart_busy;

    //-------------------------------------------------------------------------
    // UART transmitter
    //
    // Sends one ASCII character at 115,200 baud using an 8-N-1 frame.
    //-------------------------------------------------------------------------
    uart_tx #(
        .CLOCK_FREQ_HZ(100_000_000),
        .BAUD_RATE(115_200)
    )
    u_uart_tx(
        .clk(clk),
        .reset(btnC),
        .start(uart_start),
        .data_in(ascii_data),
        .tx(uart_tx_out),
        .busy(uart_busy),
        .bit_index(uart_bit_index),
        .shift_register(uart_shift_register),
        .baud_tick(uart_baud_tick)
    );

    // LED0 receives the short key_valid pulse; LED1 remains high throughout
    // the UART frame while the transmitter is busy.
    assign led0 = key_valid;
    assign led1 = uart_busy;

    //-------------------------------------------------------------------------
    // Vivado Integrated Logic Analyzer
    //
    // Probe map:
    //   probe0 - keypad_rows          [3:0]
    //   probe1 - keypad_cols          [3:0]
    //   probe2 - key_valid
    //   probe3 - key_code             [3:0]
    //   probe4 - ascii_data           [7:0]
    //   probe5 - uart_start
    //   probe6 - uart_busy
    //   probe7 - uart_bit_index       [3:0]
    //   probe8 - uart_shift_register  [9:0]
    //   probe9 - uart_tx_out
    //
    // The ILA is clocked directly by the same 100 MHz system clock used by
    // the observed logic, avoiding any debug clock-domain crossing.
    //-------------------------------------------------------------------------
    ila_0 u_ila(
        .clk(clk),
        .probe0(keypad_rows),
        .probe1(keypad_cols),
        .probe2(key_valid),
        .probe3(key_code),
        .probe4(ascii_data),
        .probe5(uart_start),
        .probe6(uart_busy),
        .probe7(uart_bit_index),
        .probe8(uart_shift_register),
        .probe9(uart_tx_out)
    );

endmodule
