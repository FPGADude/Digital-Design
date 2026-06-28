`timescale 1ns / 1ps

module button_debounce_active_low #(
    parameter int CLK_HZ = 12_000_000,
    parameter int DEBOUNCE_MS = 5
)(
    input  logic clk,
    input  logic reset,
    input  logic btn_n,
    output logic pressed
);

    localparam int DEBOUNCE_CLKS = (CLK_HZ / 1000) * DEBOUNCE_MS;
    localparam int COUNT_W = (DEBOUNCE_CLKS <= 1) ? 1 : $clog2(DEBOUNCE_CLKS);

    logic sync_0, sync_1;
    logic stable_n;
    logic [COUNT_W-1:0] count;

    always_ff @(posedge clk) begin
        if (reset) begin
            sync_0   <= 1'b1;
            sync_1   <= 1'b1;
            stable_n <= 1'b1;
            count    <= '0;
            pressed  <= 1'b0;
        end else begin
            sync_0 <= btn_n;
            sync_1 <= sync_0;

            if (sync_1 == stable_n) begin
                count <= '0;
            end else begin
                if (count == DEBOUNCE_CLKS-1) begin
                    stable_n <= sync_1;
                    count <= '0;
                end else begin
                    count <= count + 1'b1;
                end
            end

            pressed <= ~stable_n;
        end
    end

endmodule



