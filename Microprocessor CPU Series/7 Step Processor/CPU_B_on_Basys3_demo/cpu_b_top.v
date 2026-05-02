`timescale 1ns / 1ps

module cpu_b_top(
    input clk_100MHz,
    input btnC,         // reset
    output [3:0] an,
    output [0:6] seg,
    output [15:0] led
);

    wire clk_10Hz;
    wire step_clk, clk_e, clk_s;
    wire loading_ram = 1'b0;
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

    always @(posedge set_output or posedge btnC) begin
        if (btnC)
            fib_value <= 8'd0;
        else if (!data_address)
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

        .loading_ram(loading_ram),
        .set_mar_init(set_addr),
        .addr_init(address),
        .set_ram_init(set_ram),
        .instr_from_rom(instruction),

        .cpu_interface(cpu_interface),
        .enable_input(enable_input),
        .set_output(set_output),
        .data_address(data_address),

        .step_clk(step_clk),
        .clk_e(clk_e),
        .clk_s(clk_s)
    );
    
    assign led[0] = loading_ram;
    assign led[1] = clk_10Hz;
    assign led[2] = step_clk;
    assign led[3] = clk_e;
    assign led[4] = clk_s;
    assign led[5] = set_output;
    assign led[6] = data_address;
    assign led[7] = |fib_value;
    assign led[15:8] = cpu_interface;

endmodule
