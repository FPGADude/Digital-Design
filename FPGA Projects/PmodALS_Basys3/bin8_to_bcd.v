`timescale 1ns / 1ps
module bin8_to_bcd(
    input  wire [7:0] bin,
    output reg  [3:0] hundreds,
    output reg  [3:0] tens,
    output reg  [3:0] ones
);

    always @(*) begin
        hundreds = bin / 100;
        tens     = (bin % 100) / 10;
        ones     = bin % 10;
    end

endmodule
