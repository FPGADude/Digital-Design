`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference book: "FPGA Prototyping by Verilog Examples"
//                      "Xilinx Spartan-3 Version"
// Written by: Dr. Pong P. Chu
// Published by: Wiley, 2008
//
// Adapted for Basys 3 by David J. Marion aka FPGA Dude
//
//////////////////////////////////////////////////////////////////////////////////

module timer(
    input clk,
    input reset,
    input timer_start, timer_tick,
    output timer_up
    );
    
    // signal declaration
    reg [6:0] timer_reg, timer_next;
    
    // register control
    always @(posedge clk or posedge reset)
        if(reset)
            timer_reg <= 7'b1111111;
        else
            timer_reg <= timer_next;
    
    // next state logic
    always @*
        if(timer_start)
            timer_next = 7'b1111111;
        else if((timer_tick) && (timer_reg != 0))
            timer_next = timer_reg - 1;
        else
            timer_next = timer_reg;
            
    // output
    assign timer_up = (timer_reg == 0);
    
endmodule
