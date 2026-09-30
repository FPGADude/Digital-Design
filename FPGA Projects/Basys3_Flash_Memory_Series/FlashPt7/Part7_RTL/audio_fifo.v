`timescale 1ns / 1ps

// ============================================================================
// Audio FIFO
//
// A small single-clock FIFO decouples the SPI flash data rate from the fixed
// 22.05 kHz audio playback rate. With ADDR_WIDTH=10, the FIFO stores 1024
// eight-bit PCM samples.
//
// The memory is written by the flash streamer and read by the audio player.
// front_data is a look-ahead value: it always reflects the sample currently
// addressed by rd_ptr.
// ============================================================================
module audio_fifo #(
    parameter integer ADDR_WIDTH = 10
)(
    input  wire                  clk,
    input  wire                  reset,

    input  wire                  push,
    input  wire [7:0]            push_data,

    input  wire                  pop,

    output wire [7:0]            front_data,
    output wire                  empty,
    output wire                  full,
    output reg  [ADDR_WIDTH:0]   count
);

    localparam integer DEPTH = (1 << ADDR_WIDTH);

    // Let Vivado choose the appropriate implementation for this
    // asynchronous look-ahead FIFO memory.
    reg [7:0] mem [0:DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    assign empty      = (count == 0);
    assign full       = (count == DEPTH);
    assign front_data = mem[rd_ptr];

    always @(posedge clk) begin
        if (reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            // Four possibilities exist each clock:
            //   00: no transfer
            //   10: push only
            //   01: pop only
            //   11: simultaneous push and pop
            case ({push && !full, pop && !empty})
                2'b10: begin
                    mem[wr_ptr] <= push_data;
                    wr_ptr      <= wr_ptr + 1'b1;
                    count       <= count + 1'b1;
                end

                2'b01: begin
                    rd_ptr <= rd_ptr + 1'b1;
                    count  <= count - 1'b1;
                end

                2'b11: begin
                    mem[wr_ptr] <= push_data;
                    wr_ptr      <= wr_ptr + 1'b1;
                    rd_ptr      <= rd_ptr + 1'b1;
                    // Count is unchanged because one byte entered and one left.
                end

                default: begin
                    // Hold state.
                end
            endcase
        end
    end

endmodule
