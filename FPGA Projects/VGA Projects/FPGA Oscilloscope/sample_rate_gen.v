`timescale 1ns / 1ps

module sample_rate_gen (
    input  wire clk,
    output reg  sample_tick = 1'b0
);

    // 100 MHz system clock
    // Desired sample rate = 64 kHz
    //
    // Fractional accumulator:
    //
    // accumulator += 64,000
    //
    // When >= 100,000,000:
    //   generate one-clock sample_tick
    //   subtract 100,000,000

    reg [26:0] accumulator = 27'd0;

    always @(posedge clk) begin

        sample_tick <= 1'b0;

        if (accumulator + 27'd64000 >= 27'd100000000) begin

            accumulator <=
                accumulator +
                27'd64000 -
                27'd100000000;

            sample_tick <= 1'b1;

        end
        else begin

            accumulator <=
                accumulator + 27'd64000;

        end

    end

endmodule
