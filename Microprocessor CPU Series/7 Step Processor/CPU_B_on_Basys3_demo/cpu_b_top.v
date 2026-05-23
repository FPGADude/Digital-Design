`timescale 1ns / 1ps

module cpu_b_top(
    input clk_100MHz,
    input btnC,         // reset
    output [3:0] an,
    output [0:6] seg,
    output [3:0] clocks,
    output [15:8] led
);

    wire clk_10Hz;
    wire step_clk, clk_e, clk_s;
    wire set_addr = 1'b0;
    wire set_ram = 1'b0;
    wire [7:0] address = 8'h00;
    wire [7:0] instruction = 8'h00;

    wire [7:0] cpu_interface;
    wire enable_input;
    wire set_output;
    wire data_address;

    reg [7:0] fib_value;

    wire [3:0] ones;
    wire [3:0] tens;
    wire [3:0] hundreds;
    wire [3:0] thousands;

    oneHz_gen GEN(
        .clk_100MHz(clk_100MHz),
        .reset(btnC),
        .clk_10Hz(clk_10Hz)
    );

    always @(posedge clk_10Hz or posedge btnC) begin
        if (btnC)
            fib_value <= 8'd0;
        else if (set_output && !data_address)
            fib_value <= cpu_interface;
    end

    bin8_to_bcd B2BCD(
        .bin_in(fib_value),
        .ones(ones),
        .tens(tens),
        .hundreds(hundreds),
        .thousands(thousands)
    );

    seg7_control SEG7(
        .clk_100MHz(clk_100MHz),
        .reset(btnC),
        .ones(ones),
        .tens(tens),
        .hundreds(hundreds),
        .thousands(thousands),
        .seg(seg),
        .digit(an)
    );

    cpu_b CPU(
        .in_clk(clk_10Hz),
        .reset(btnC),
        .cpu_interface(cpu_interface),
        .enable_input(enable_input),
        .set_output(set_output),
        .data_address(data_address),
        .step_clk(step_clk),
        .clk_e(clk_e),
        .clk_s(clk_s)
    );
    
    assign clocks[0] = clk_10Hz;
    assign clocks[1] = step_clk;
    assign clocks[2] = clk_e;
    assign clocks[3] = clk_s;
    assign led[15:8] = cpu_interface;

endmodule
