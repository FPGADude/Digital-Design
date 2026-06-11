`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_function_demo
// Description:
//   Simulates function_demo.v and applies several test cases so the
//   waveform clearly shows the behavior of add_two(), max_two(), and is_even().
//////////////////////////////////////////////////////////////////////////////////

module tb_function_demo;

    reg  [7:0] a;
    reg  [7:0] b;
    reg  [7:0] value;

    wire [7:0] sum;
    wire [7:0] maximum;
    wire       even_flag;

    function_demo dut (
        .a(a),
        .b(b),
        .value(value),
        .sum(sum),
        .maximum(maximum),
        .even_flag(even_flag)
    );

    initial begin
        // Test 1: 10 + 20 = 30, max = 20, 4 is even
        a     = 8'd10;
        b     = 8'd20;
        value = 8'd4;
        #20;

        // Test 2: 35 + 12 = 47, max = 35, 7 is odd
        a     = 8'd35;
        b     = 8'd12;
        value = 8'd7;
        #20;

        // Test 3: 50 + 50 = 100, max = 50, 100 is even
        a     = 8'd50;
        b     = 8'd50;
        value = 8'd100;
        #20;

        // Test 4: 200 + 100 = 300, but 8-bit sum wraps to 44
        // max = 200, 101 is odd
        a     = 8'd200;
        b     = 8'd100;
        value = 8'd101;
        #20;

        // Test 5: 0 + 255 = 255, max = 255, 0 is even
        a     = 8'd0;
        b     = 8'd255;
        value = 8'd0;
        #20;

        $finish;
    end

endmodule

