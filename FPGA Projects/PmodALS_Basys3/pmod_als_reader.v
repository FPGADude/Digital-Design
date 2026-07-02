`timescale 1ns / 1ps

module pmod_als_reader(
    input  wire       clk,
    input  wire       reset,

    input  wire       als_sdo,
    output reg        als_cs,
    output reg        als_sck,

    output reg [7:0]  light_value
);

    // Set up a 1MHz SCK cycle
    // 100 MHz / 50 = 2 MHz toggle rate
    // Full SCK period = 100 cycles = 1 MHz
    localparam integer HALF_PERIOD_COUNT = 50;

    // Minimum wait time between samples 1000 ns, or 1 us
    // Sample every 10 ms ( well above minimum wait time )
    // 1 / 100_000_000 = 10 ns
    // 10 ns * 1_000_000 = 10 ms
    localparam integer SAMPLE_DELAY_COUNT = 1_000_000;

    // State encodings
    localparam IDLE     = 2'd0;
    localparam TRANSFER = 2'd1;
    localparam DONE     = 2'd2;
    localparam WAITING  = 2'd3;

    // State, counters, and shift reg
    reg [1:0]  state;
    reg [5:0]  clk_count;
    reg [3:0]  bit_count;
    reg [14:0] shift_reg;
    reg [19:0] delay_count;

    // State Machine 
    always @(posedge clk) begin
        if (reset) begin                        // synchronous reset
            state        <= IDLE;
            clk_count    <= 0;
            bit_count    <= 0;
            shift_reg    <= 0;
            delay_count  <= 0;
            light_value  <= 0;
            als_cs       <= 1'b1;
            als_sck      <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    als_cs      <= 1'b1;        // chip select inactive
                    als_sck     <= 1'b0;
                    clk_count   <= 0;
                    bit_count   <= 0;
                    shift_reg   <= 0;
                    delay_count <= 0;
                    state       <= TRANSFER;
                end

                TRANSFER: begin
                    als_cs <= 1'b0;             // activate chip select

                    // Generate SCK signal to synchronize serial sensor data
                    // Implement 1MHz SCK
                    if (clk_count == HALF_PERIOD_COUNT - 1) begin
                        clk_count <= 0;
                        als_sck   <= ~als_sck;

                        // Sample SDO on the rising edge of SCK
                        if (als_sck == 1'b0) begin
                            shift_reg <= {shift_reg[13:0], als_sdo};
                            bit_count <= bit_count + 1'b1;

                            if (bit_count == 5'd15) begin
                                state <= DONE;
                            end
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DONE: begin
                    als_cs       <= 1'b1;                   // deactivate chip select
                    als_sck      <= 1'b0;

                    // Received data frame:
                    // [14:12] = 3 leading zeroes
                    // [11:4]  = 8-bit light value
                    // [3:0]   = 4 trailing zeroes
                    light_value <= shift_reg[11:4];

//                    delay_count  <= 0;                      // Initialize delay count to zero
                    state        <= WAITING;
                end

                WAITING: begin
                    als_cs  <= 1'b1;                        // chip select inactive
                    als_sck <= 1'b0;

                    // Implement 10 ms waiting period
                    if (delay_count == SAMPLE_DELAY_COUNT - 1) begin
                        state <= IDLE;
                    end else begin
                        delay_count <= delay_count + 1'b1;  // Increment delay count
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
