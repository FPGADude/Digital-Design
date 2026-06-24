`timescale 1ns / 1ps


module tb_traffic_controller_fsm;
    reg clk, reset, tick;
    wire [2:0] main;
    wire [2:0] side;
    integer i;
    
    always #5 clk = ~clk;
    
    traffic_controller_fsm DUT(
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .main_lights(main),
        .side_lights(side)
    );

    initial begin
        clk = 0;
        reset = 0;
        tick = 0;
        for(i = 0; i < 46; i = i + 1) begin
            #10 tick = 1;
            #10 tick = 0;
        end
        
        $finish;
    
    end


endmodule
