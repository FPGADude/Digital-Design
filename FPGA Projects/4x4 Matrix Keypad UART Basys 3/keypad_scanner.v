`timescale 1ns / 1ps

// ============================================================
// Module: keypad_scanner
// Project: Basys 3 4x4 Keypad + LEDs + UART
//
// Purpose:
//   This module scans a plain/raw 4x4 matrix keypad. It does not
//   depend on the Digilent Pmod KYPD. The keypad is treated as a
//   simple switch matrix with four row wires and four column wires.
//
// Hardware concept:
//   - The FPGA drives the row wires.
//   - The FPGA reads the column wires.
//   - The row outputs are active-low.
//   - The column inputs are normally pulled high.
//   - Pressing a key connects one row wire to one column wire.
//
// Scan method:
//   The scanner activates one row at a time by driving that row low
//   while keeping the other rows high. If a key in that row is pressed,
//   the matching column input will be pulled low. The row number and
//   column number together identify the key.
//
// Outputs:
//   key_code:
//     A 4-bit key index from 0 to 15.
//
//   key_valid:
//     A one-clock pulse when a new key press is detected. This pulse
//     is useful for triggering other one-time events such as blinking
//     an LED or starting a UART transmission.
//
// Important behavior:
//   This version intentionally prevents repeated key_valid pulses while
//   the same key is held. The user must release the keypad before a new
//   key_valid pulse can be generated.
//
// Keypad layout assumed:
//
//          Col1  Col2  Col3  Col4
//   Row1     1     2     3     A
//   Row2     4     5     6     B
//   Row3     7     8     9     C
//   Row4     *     0     #     D
//
// key_code mapping:
//   0  = 1      1  = 2      2  = 3      3  = A
//   4  = 4      5  = 5      6  = 6      7  = B
//   8  = 7      9  = 8      10 = 9      11 = C
//   12 = *      13 = 0      14 = #      15 = D
// ============================================================

module keypad_scanner(
    input  wire       clk,        // 100 MHz Basys 3 system clock
    input  wire       reset,      // active-high synchronous reset

    output reg  [3:0] rows,       // keypad row drive signals, active-low
    input  wire [3:0] cols,       // keypad column sense signals, active-low when pressed

    output reg  [3:0] key_code,   // decoded key index, 0 to 15
    output reg        key_valid   // one-clock pulse for each new key press
);

    // ------------------------------------------------------------
    // Row scan timing
    // ------------------------------------------------------------
    // The Basys 3 clock is 100 MHz, which means one clock cycle is
    // 10 ns. Counting 100,000 clock cycles gives:
    //
    //   100,000 cycles * 10 ns = 1,000,000 ns = 1 ms
    //
    // So each row remains active for about 1 ms. Since there are four
    // rows, a full keypad frame takes about 4 ms. This is plenty fast
    // for human button presses.
    // ------------------------------------------------------------
    localparam SCAN_MAX = 100_000 - 1;

    // Counts clock cycles for the current row's active time.
    reg [16:0] scan_count;

    // Selects which row is currently being driven low.
    // 0 = Row 1, 1 = Row 2, 2 = Row 3, 3 = Row 4.
    reg [1:0] row_index;

    // key_held is set after a key event is accepted. It stays set
    // until the scanner has seen an entire frame with no key pressed.
    // This keeps one long key hold from producing repeated events.
    reg key_held;

    // frame_pressed remembers whether any key was detected during the
    // current four-row scan frame. At the end of Row 4, this is used
    // to decide whether the keypad has been fully released.
    reg frame_pressed;

    // Combinational signals for the currently active row only.
    // current_pressed says whether the current row sees a pressed key.
    // current_key holds the decoded 0-15 key value for that row/column.
    reg       current_pressed;
    reg [3:0] current_key;

    // ------------------------------------------------------------
    // Main scanner state logic
    // ------------------------------------------------------------
    // This block advances the row scan, samples the columns, creates
    // key_valid pulses, and manages the press/release behavior.
    //
    // The columns are sampled only at the end of the 1 ms row window.
    // That gives the row output time to settle before the column value
    // is interpreted.
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            // Return the scanner to a known idle state.
            scan_count    <= 17'd0;
            row_index     <= 2'd0;
            key_code      <= 4'd0;
            key_valid     <= 1'b0;
            key_held      <= 1'b0;
            frame_pressed <= 1'b0;
        end else begin
            // key_valid is normally low. It is raised for one clock
            // only when a new keypress is accepted below.
            key_valid <= 1'b0;

            if (scan_count == SCAN_MAX) begin
                // End of the current row's scan window.
                scan_count <= 17'd0;

                // If the current row sees a key and no key is already
                // considered held, accept this as a new keypress.
                if (current_pressed && !key_held) begin
                    key_code  <= current_key;
                    key_valid <= 1'b1;
                    key_held  <= 1'b1;
                end

                // Row 4 is the last row in the scan frame. At this
                // point the scanner has checked all four rows once.
                if (row_index == 2'd3) begin
                    // If no key was detected earlier in the frame and
                    // no key is detected on the current row, then the
                    // keypad is fully released. Allow the next press to
                    // generate a new key_valid pulse.
                    if (!frame_pressed && !current_pressed) begin
                        key_held <= 1'b0;
                    end

                    // Start the next frame at Row 1.
                    frame_pressed <= 1'b0;
                    row_index     <= 2'd0;
                end else begin
                    // For Rows 1-3, remember if this row saw a key so
                    // the end-of-frame release check has full-frame info.
                    if (current_pressed) begin
                        frame_pressed <= 1'b1;
                    end

                    // Move to the next row.
                    row_index <= row_index + 1'b1;
                end
            end else begin
                // Continue timing the current row.
                scan_count <= scan_count + 1'b1;
            end
        end
    end

    // ------------------------------------------------------------
    // Row drive logic
    // ------------------------------------------------------------
    // Only one row is driven low at a time. The other rows stay high.
    // Because the columns use pullups, a pressed key pulls one column
    // low only when its row is the active row.
    // ------------------------------------------------------------
    always @(*) begin
        case (row_index)
            2'd0: rows = 4'b1110; // Row 1 active-low, others inactive-high
            2'd1: rows = 4'b1101; // Row 2 active-low, others inactive-high
            2'd2: rows = 4'b1011; // Row 3 active-low, others inactive-high
            2'd3: rows = 4'b0111; // Row 4 active-low, others inactive-high
            default: rows = 4'b1111; // safety default: no row selected
        endcase
    end

    // ------------------------------------------------------------
    // Column decode logic
    // ------------------------------------------------------------
    // With pullups enabled, no key pressed gives cols = 1111.
    // A pressed key makes one column read 0 while the matching row is
    // being driven low.
    //
    // The key code is formed as:
    //
    //   key_code = {row_index, column_index}
    //
    // This naturally gives four keys per row:
    //   Row 0 -> codes 0,1,2,3
    //   Row 1 -> codes 4,5,6,7
    //   Row 2 -> codes 8,9,10,11
    //   Row 3 -> codes 12,13,14,15
    //
    // Multiple simultaneous key presses are not handled in this simple
    // demo. The project assumes one key is pressed at a time.
    // ------------------------------------------------------------
    always @(*) begin
        current_pressed = 1'b0;
        current_key     = 4'd0;

        case (cols)
            4'b1110: begin                 // Column 1 is low
                current_pressed = 1'b1;
                current_key     = {row_index, 2'd0};
            end

            4'b1101: begin                 // Column 2 is low
                current_pressed = 1'b1;
                current_key     = {row_index, 2'd1};
            end

            4'b1011: begin                 // Column 3 is low
                current_pressed = 1'b1;
                current_key     = {row_index, 2'd2};
            end

            4'b0111: begin                 // Column 4 is low
                current_pressed = 1'b1;
                current_key     = {row_index, 2'd3};
            end

            default: begin                 // No valid single-column press
                current_pressed = 1'b0;
                current_key     = 4'd0;
            end
        endcase
    end

endmodule
