`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Module: tick_gen_1s
// -----------------------------------------------------------------------------
// Purpose:
//   Generates a one-clock-cycle pulse once per second.
//
//   The FPGA clock continues running at the full board clock rate, but the
//   traffic FSM only advances when tick_1s is asserted. This is preferred over
//   creating a new slow clock because it keeps the whole design synchronous to
//   one clock domain.
//
// Parameters:
//   CLK_FREQ_HZ sets the input clock frequency. On the Basys 3 this is
//   100,000,000 Hz.
// -----------------------------------------------------------------------------

module tick_gen_1s #(
    parameter int CLK_FREQ_HZ = 100_000_000
)(
    input  logic clk,
    input  logic reset,
    output logic tick_1s
);

    // Terminal count for one full second of input clock cycles.
    localparam int COUNT_MAX = CLK_FREQ_HZ - 1;
    // Counter width computed from the clock frequency parameter.
    localparam int COUNT_W   = $clog2(CLK_FREQ_HZ);

    // Free-running counter that resets each time a one-second tick is produced.
    logic [COUNT_W-1:0] count_reg;

    // Synchronous counter.
    // tick_1s is high for one clk cycle when the counter reaches COUNT_MAX.
    always_ff @(posedge clk) begin
        if (reset) begin
            count_reg <= '0;
            tick_1s   <= 1'b0;
        end else begin
            if (count_reg == COUNT_MAX[COUNT_W-1:0]) begin
                count_reg <= '0;
                tick_1s   <= 1'b1;
            end else begin
                count_reg <= count_reg + 1'b1;
                tick_1s   <= 1'b0;
            end
        end
    end

endmodule


