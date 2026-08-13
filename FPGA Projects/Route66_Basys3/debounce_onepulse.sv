module debounce_onepulse #(
    parameter int CLK_HZ = 100_000_000,
    parameter int DEBOUNCE_MS = 20
) (
    input  logic clk,
    input  logic rst,
    input  logic noisy_in,
    output logic pulse_out
);

    localparam int COUNT_MAX = (CLK_HZ / 1000) * DEBOUNCE_MS;
    localparam int COUNT_W   = $clog2(COUNT_MAX + 1);

    logic sync_0, sync_1;
    logic stable_state;
    logic stable_state_d;
    logic [COUNT_W-1:0] count;

    // synchronize button to clk
    always_ff @(posedge clk) begin
        if (rst) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= noisy_in;
            sync_1 <= sync_0;
        end
    end

    // debounce
    always_ff @(posedge clk) begin
        if (rst) begin
            stable_state <= 1'b0;
            count        <= '0;
        end else begin
            if (sync_1 == stable_state) begin
                count <= '0;
            end else begin
                if (count == COUNT_MAX - 1) begin
                    stable_state <= sync_1;
                    count        <= '0;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end

    // one-pulse on rising edge of debounced press
    always_ff @(posedge clk) begin
        if (rst) begin
            stable_state_d <= 1'b0;
        end else begin
            stable_state_d <= stable_state;
        end
    end

    assign pulse_out = stable_state & ~stable_state_d;

endmodule
