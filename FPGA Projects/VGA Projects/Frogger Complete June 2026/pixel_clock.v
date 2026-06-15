`timescale 1ns / 1ps
// Generate the 25MHz clock for VGA 640x480 @ 60 Hz
module pixel_clock(
    input  wire clk_100MHz,
    input  wire reset,
    output wire clk_25MHz
);

    reg [1:0] div_count;

    always @(posedge clk_100MHz or posedge reset) begin
        if (reset)
            div_count <= 2'b00;
        else
            div_count <= div_count + 2'b01;
    end

    assign clk_25MHz = div_count[1];

endmodule
