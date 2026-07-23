`timescale 1ns / 1ps
//==============================================================================
// Module:      uart_tx
// Project:     FPGA Wi-Fi Temperature Monitor
//
// Description:
//   Parameterized 8-N-1 UART transmitter.
//
// Frame format:
//   1 start bit (LOW)
//   8 data bits (least-significant bit first)
//   no parity
//   1 stop bit (HIGH)
//
// Handshake:
//   data_valid - Pulse HIGH for one clock while the transmitter is idle.
//   busy       - Remains HIGH from the start bit through the stop bit.
//
// Default Cmod A7 settings:
//   System clock: 12 MHz
//   Baud rate:    115200
//   Rounded clocks per UART bit: 104
//==============================================================================

module uart_tx #(
    parameter integer CLK_FREQ_HZ = 12_000_000,
    parameter integer BAUD_RATE   = 115_200
)(
    input  wire       clk,
    input  wire       reset,

    input  wire [7:0] data_in,
    input  wire       data_valid,

    output reg        tx,
    output reg        busy
);

    // Rounded integer divider minimizes baud-rate error.
    localparam integer CLKS_PER_BIT =
        (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;

    // Complete UART frame:
    //   bit 0      = start bit
    //   bits 1..8  = data bits
    //   bit 9      = stop bit
    reg [9:0] frame_shift;

    reg [3:0]  bit_count;
    reg [15:0] clock_count;

    always @(posedge clk) begin
        if (reset) begin
            tx          <= 1'b1;
            busy        <= 1'b0;
            frame_shift <= 10'h3FF;
            bit_count   <= 4'd0;
            clock_count <= 16'd0;
        end

        //----------------------------------------------------------------------
        // Idle state: UART line rests HIGH while waiting for data_valid.
        //----------------------------------------------------------------------
        else if (!busy) begin
            tx <= 1'b1;

            if (data_valid) begin
                frame_shift <= {1'b1, data_in, 1'b0};
                bit_count   <= 4'd0;
                clock_count <= 16'd0;
                busy        <= 1'b1;

                // Start transmitting the start bit immediately.
                tx <= 1'b0;
            end
        end

        //----------------------------------------------------------------------
        // Active transmission: hold each frame bit for CLKS_PER_BIT clocks.
        //----------------------------------------------------------------------
        else begin
            if (clock_count == CLKS_PER_BIT - 1) begin
                clock_count <= 16'd0;

                if (bit_count == 4'd9) begin
                    // Stop bit completed; return to idle.
                    busy <= 1'b0;
                    tx   <= 1'b1;
                end
                else begin
                    bit_count   <= bit_count + 1'b1;
                    frame_shift <= {1'b1, frame_shift[9:1]};
                    tx          <= frame_shift[1];
                end
            end
            else begin
                clock_count <= clock_count + 1'b1;
            end
        end
    end

endmodule
