`timescale 1ns / 1ps

module top_traff_contr(
    input wire clk,
    input wire reset,
    output wire [2:0] led1,
    output wire [2:0] led2
    );
    
    wire tick;
    
    oneHz_tick_gen TICK(
        .clk(clk),
        .reset(reset),
        .tick(tick)
    );
    
    traffic_controller_fsm FSM(
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .main_lights(led1),
        .side_lights(led2)
    );
    
    
endmodule
