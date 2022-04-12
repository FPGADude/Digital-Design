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

module m100_counter(
    input clk,
    input reset,
    input d_inc, d_clr,
    output [3:0] dig0, dig1
    );
    
    // signal declaration
    reg [3:0] r_dig0, r_dig1, dig0_next, dig1_next;
    
    // register control
    always @(posedge clk or posedge reset)
        if(reset) begin
            r_dig1 <= 0;
            r_dig0 <= 0;
        end
        
        else begin
            r_dig1 <= dig1_next;
            r_dig0 <= dig0_next;
        end
    
    // next state logic
    always @* begin
        dig0_next = r_dig0;
        dig1_next = r_dig1;
        
        if(d_clr) begin
            dig0_next <= 0;
            dig1_next <= 0;
        end
        
        else if(d_inc)
            if(r_dig0 == 9) begin
                dig0_next = 0;
                
                if(r_dig1 == 9)
                    dig1_next = 0;
                else
                    dig1_next = r_dig1 + 1;
            end
        
            else    // dig0 != 9
                dig0_next = r_dig0 + 1;
    end
    
    // output
    assign dig0 = r_dig0;
    assign dig1 = r_dig1;
    
endmodule
