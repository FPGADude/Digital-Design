`timescale 1ns / 1ps


module nexys_top(
    input clk,              // 100MHz from Nexys
    output o_1Hz,           // to Basys ram
    output [3:0] o_data,    // to Basys ram
    output wr_en,           // to Basys ram
    output [3:0] o_addr,    // to Basys ram
    output [3:0] led        // 4 LEDs on Nexys, rom data out
    );
    
    wire w_1Hz;
    wire [3:0] w_addr;
    wire [3:0] w_data;
    
    rom r(.addr(w_addr), .data(w_data));
    rom_control rc(.clk_1Hz(w_1Hz), .addr(w_addr), .wr_en(wr_en));
    oneHz_gen uno(.clk(clk), .clk_1Hz(w_1Hz));
    
    assign o_addr = w_addr;
    assign o_data = w_data;
    assign led = w_data;
    assign o_1Hz = w_1Hz;
    
endmodule
