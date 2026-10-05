`timescale 1ns / 1ps

module xadc_average (
    input  wire        clk,

    input  wire [11:0] sample_in,
    input  wire        sample_valid_in,

    output reg  [11:0] sample_out = 12'd0,
    output reg         sample_valid_out = 1'b0
);

    // ============================================================
    // 16-SAMPLE MOVING AVERAGE
    //
    // Maintain a running sum:
    //
    // new_sum = old_sum
    //         - oldest_sample
    //         + newest_sample
    //
    // Average = sum / 16
    //
    // Since 16 is a power of two, division is simply >> 4.
    // ============================================================

    reg [11:0] sample_history [0:15];

    reg [3:0]  write_index = 4'd0;

    // Maximum:
    //
    // 4095 * 16 = 65520
    //
    // so 16 bits are sufficient.
    reg [15:0] running_sum = 16'd0;

    reg [4:0] fill_count = 5'd0;

    wire [15:0] next_sum;

    assign next_sum =
        running_sum
        - sample_history[write_index]
        + sample_in;

    integer i;

    initial begin
        for (i = 0; i < 16; i = i + 1)
            sample_history[i] = 12'd0;
    end


    always @(posedge clk) begin

        sample_valid_out <= 1'b0;

        if (sample_valid_in) begin

            sample_history[write_index] <= sample_in;
            running_sum                 <= next_sum;
            write_index                 <= write_index + 1'b1;

            // Wait until all 16 history locations contain
            // real ADC measurements.
            if (fill_count < 5'd16) begin

                fill_count <= fill_count + 1'b1;

                if (fill_count == 5'd15) begin
                    sample_out       <= next_sum >> 4;
                    sample_valid_out <= 1'b1;
                end

            end
            else begin

                sample_out       <= next_sum >> 4;
                sample_valid_out <= 1'b1;

            end

        end

    end

endmodule