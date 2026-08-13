module tick_gen #(
    parameter int CLK_HZ = 100_000_000,
    parameter int TICK_HZ = 1
) (
    input  logic clk,
    input  logic rst,
    output logic tick
);

    localparam int COUNT_MAX = CLK_HZ / TICK_HZ;
    localparam int COUNT_W   = $clog2(COUNT_MAX);

    logic [COUNT_W-1:0] count;

    always_ff @(posedge clk) begin
        if (rst) begin
            count <= '0;
            tick  <= 1'b0;
        end else begin
            if (count == COUNT_MAX - 1) begin
                count <= '0;
                tick  <= 1'b1;
            end else begin
                count <= count + 1'b1;
                tick  <= 1'b0;
            end
        end
    end

endmodule
