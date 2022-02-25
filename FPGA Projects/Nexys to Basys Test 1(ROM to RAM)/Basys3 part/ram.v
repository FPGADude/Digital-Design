`timescale 1ns / 1ps

module ram(
    input sync_in,          // 1Hz for demonstration purposes, from Nexys
    input wr_en,            // write enable from Nexys control
    input [3:0] addr,       // memory address from Nexys control
    input [3:0] data_in,    // data from Nexys rom
    output [3:0] data_out   // data to LEDs on Basys
    );
    
    reg [3:0] ram [15:0];
    
    always @(posedge sync_in)
        if(wr_en)
            ram[addr] <= data_in;
            
    assign data_out = ram[addr];
    
endmodule
