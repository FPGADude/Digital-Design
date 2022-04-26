`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Authored by David J. Marion aka FPGA Dude
// Created on 4/20/2022
//////////////////////////////////////////////////////////////////////////////////

module sim_reg_file;
    reg clk;
    reg we;
    reg [2:0] w_address;
    reg [2:0] r_address;
    reg [7:0] w_data;
    wire [7:0] r_data;
    integer i;
    
    register_file DUT(
        .clk(clk),
        .we(we),
        .w_address(w_address),
        .r_address(r_address),
        .w_data(w_data),
        .r_data(r_data)
        );

    always #1 clk = ~clk;
    
    initial begin
        clk = 1'b0;
        we = 1'b0;
        w_address = 3'b0;
        r_address = 3'b0;
        w_data = 8'b0;
        i = 0;
        
        #3 we = 1'b1;
        
        for(i = 0; i < 8; i = i + 1) begin
            w_address = i;
            w_data = i * 10;
            #2;
        end
        
        #2 we = 1'b0;
        
        for(i = 0; i < 8; i = i + 1) begin
            r_address = i;
            #2;
        end
        
        $finish;
    
    end

endmodule
