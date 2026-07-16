`timescale 1ns / 1ps

//=============================================================================
// Module: keypad_scanner
//
// Purpose:
//   Scans a 4x4 matrix keypad, determines which key is pressed, verifies that
//   the key remains stable for several complete scan frames, and produces a
//   one-clock-cycle key_valid pulse for each accepted key press.
//
// Electrical convention:
//   - One keypad row is driven low at a time.
//   - The column inputs use pull-up resistors and normally read logic high.
//   - Pressing a key connects the active low row to one column, causing that
//     column input to read logic low.
//
// Keypad layout used by this design:
//
//       Col0 Col1 Col2 Col3
// Row0    1    2    3    A
// Row1    4    5    6    B
// Row2    7    8    9    C
// Row3    0    F    E    D
//
// Debounce behavior:
//   A candidate key must be observed for STABLE_FRAMES_REQUIRED complete
//   keypad scans before it is accepted. After acceptance, no additional
//   key_valid pulse is generated until the keypad has been released for
//   RELEASE_FRAMES_REQUIRED complete scan frames.
//
// Parameters:
//   STABLE_FRAMES_REQUIRED  - Number of matching scans required to accept.
//   RELEASE_FRAMES_REQUIRED - Number of empty scans required to re-arm.
//=============================================================================
module keypad_scanner #(
    parameter integer STABLE_FRAMES_REQUIRED = 5,
    parameter integer RELEASE_FRAMES_REQUIRED = 5
)(
    input wire clk,             // System clock
    input wire reset,           // Active-high synchronous reset
    input wire scan_tick,       // Advances the scanner by one row
    input wire [3:0] columns,   // Active-low keypad column inputs
    output reg [3:0] rows,      // Active-low keypad row-drive outputs
    output reg key_valid,       // One-clock pulse when a new key is accepted
    output reg [3:0] key_code,  // Hexadecimal code for the accepted key
    output wire [1:0] active_row// Current row index, exposed for observation
);

    // Row currently being driven and sampled.
    reg [1:0] scan_row = 0;

    // Accumulates whether any key was found during the current four-row frame.
    reg frame_found = 0;

    // Stores the decoded key found earlier in the current frame.
    reg [3:0] frame_code = 0;

    // Key value currently being evaluated by the stability counter.
    reg [3:0] candidate_code = 0;

    // Counts consecutive complete frames containing the same candidate key.
    reg [2:0] stable_frames = 0;

    // Counts consecutive complete frames with no key pressed.
    reg [2:0] release_frames = 0;

    // Prevents a held key from generating repeated key_valid pulses.
    reg key_held = 0;

    // Combinational result for the row currently being sampled.
    reg sample_pressed;
    reg [1:0] sample_column;
    reg [3:0] sample_code;

    // Final result for the complete four-row scan frame.
    reg completed_found;
    reg [3:0] completed_code;

    // Expose the current row number as an internal observation signal.
    assign active_row = scan_row;

    //-------------------------------------------------------------------------
    // Row drive decoder
    //
    // Exactly one row is driven low at a time. The remaining rows remain high.
    //-------------------------------------------------------------------------
    always @(*) begin
        case (scan_row)
            2'd0: rows = 4'b1110;
            2'd1: rows = 4'b1101;
            2'd2: rows = 4'b1011;
            default: rows = 4'b0111;
        endcase
    end

    //-------------------------------------------------------------------------
    // Current-row column detection and key decoding
    //
    // The first low column is treated as the pressed key for the active row.
    //-------------------------------------------------------------------------
    always @(*) begin
        // Assume a key is present unless all four columns remain high.
        sample_pressed = 1'b1;

        // Convert the active-low column pattern into a two-bit column index.
        if (!columns[0]) sample_column = 0;
        else if (!columns[1]) sample_column = 1;
        else if (!columns[2]) sample_column = 2;
        else if (!columns[3]) sample_column = 3;
        else begin
            sample_pressed = 0;
            sample_column = 0;
        end

        // Convert the row/column location into the project keypad code.
        case ({scan_row, sample_column})
            4'b0000: sample_code = 4'h1;
            4'b0001: sample_code = 4'h2;
            4'b0010: sample_code = 4'h3;
            4'b0011: sample_code = 4'hA;
            4'b0100: sample_code = 4'h4;
            4'b0101: sample_code = 4'h5;
            4'b0110: sample_code = 4'h6;
            4'b0111: sample_code = 4'hB;
            4'b1000: sample_code = 4'h7;
            4'b1001: sample_code = 4'h8;
            4'b1010: sample_code = 4'h9;
            4'b1011: sample_code = 4'hC;
            4'b1100: sample_code = 4'h0;
            4'b1101: sample_code = 4'hF;
            4'b1110: sample_code = 4'hE;
            default: sample_code = 4'hD;
        endcase
    end

    //-------------------------------------------------------------------------
    // Complete-frame result
    //
    // On the final row, include both any previously detected key and the
    // current row's combinational sample in the completed frame result.
    //-------------------------------------------------------------------------
    always @(*) begin
        completed_found = frame_found | sample_pressed;
        completed_code = sample_pressed ? sample_code : frame_code;
    end

    //-------------------------------------------------------------------------
    // Sequential scanner, debounce, and one-shot key event generation
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            // Restore all scanner and debounce state.
            scan_row <= 0;
            frame_found <= 0;
            frame_code <= 0;
            candidate_code <= 0;
            stable_frames <= 0;
            release_frames <= 0;
            key_held <= 0;
            key_valid <= 0;
            key_code <= 0;
        end else begin
            // key_valid is normally low and is asserted for only one clock.
            key_valid <= 0;

            // Advance the keypad scan only when the scan enable pulse arrives.
            if (scan_tick) begin
                if (scan_row != 3) begin
                    // Rows 0 through 2: remember any detected key and advance.
                    if (sample_pressed) begin
                        frame_found <= 1;
                        frame_code <= sample_code;
                    end
                    scan_row <= scan_row + 1'b1;
                end else begin
                    // Row 3 completes one full keypad scan frame.
                    scan_row <= 0;
                    frame_found <= 0;
                    frame_code <= 0;

                    if (key_held) begin
                        // While a key is held, wait for several fully released
                        // frames before allowing another key event.
                        if (completed_found)
                            release_frames <= 0;
                        else if (release_frames == RELEASE_FRAMES_REQUIRED - 1) begin
                            release_frames <= 0;
                            key_held <= 0;
                        end else
                            release_frames <= release_frames + 1'b1;
                    end else begin
                        // The keypad is armed and may accept a new key.
                        release_frames <= 0;

                        if (!completed_found)
                            // No key in this frame: discard partial stability.
                            stable_frames <= 0;
                        else if (completed_code != candidate_code) begin
                            // A new candidate appeared: begin stability timing.
                            candidate_code <= completed_code;
                            stable_frames <= 1;
                        end else if (stable_frames == STABLE_FRAMES_REQUIRED - 1) begin
                            // The same key remained present long enough.
                            key_code <= completed_code;
                            key_valid <= 1;
                            key_held <= 1;
                            stable_frames <= 0;
                        end else
                            // Continue counting matching full scan frames.
                            stable_frames <= stable_frames + 1'b1;
                    end
                end
            end
        end
    end

endmodule
