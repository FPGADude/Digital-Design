`timescale 1ns / 1ps

module rom_control(
    input clk_1Hz, 
    output [3:0] addr,
    output reg wr_en
    );
    
    reg [3:0] addr_ctr = 0;             // 4-bit Counter

    // Counter Control Logic
    always @(posedge clk_1Hz)
        addr_ctr <= addr_ctr + 1;
    
    // State Machine Parameters
    parameter READ_ROM  = 2'b00;
    parameter WRITE_RAM = 2'b01;
    parameter READ_RAM  = 2'b10;
    
    reg [1:0] state_reg = READ_ROM;     // State Register
    
    // Next State Logic
    always @(posedge clk_1Hz) begin
        case(state_reg)
            READ_ROM  :     if(addr_ctr == 15) state_reg <= WRITE_RAM;
            
            WRITE_RAM : begin
                            wr_en = 1'b1;
                            if(addr_ctr == 15) state_reg <= READ_RAM;
                        end
            
            READ_RAM  : begin
                            wr_en = 1'b0;
                            if(addr_ctr == 15) state_reg <= READ_ROM;
                        end    
        endcase
    end
    
    assign addr = addr_ctr;
    
endmodule
