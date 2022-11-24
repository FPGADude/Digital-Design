`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference Book: FPGA Prototyping By Verilog Examples Xilinx Spartan-3 Version
// Authored by: Dr. Pong P. Chu
// Published by: Wiley
//
// Adapted for the Basys 3 Artix-7 FPGA by David J. Marion
//
// UART Receiver for the UART System
//
// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////

module uart_receiver
    #(
        parameter   DBITS = 8,          // number of data bits in a data word
                    SB_TICK = 16        // number of stop bit / oversampling ticks (1 stop bit)
    )
    (
        input clk_100MHz,               // basys 3 FPGA
        input reset,                    // reset
        input rx,                       // receiver data line
        input sample_tick,              // sample tick from baud rate generator
        output reg data_ready,          // signal when new data word is complete (received)
        output [DBITS-1:0] data_out     // data to FIFO
    );
    
    // State Machine States
    localparam [1:0] idle  = 2'b00,
                     start = 2'b01,
                     data  = 2'b10,
                     stop  = 2'b11;
    
    // Registers                 
    reg [1:0] state, next_state;        // state registers
    reg [3:0] tick_reg, tick_next;      // number of ticks received from baud rate generator
    reg [2:0] nbits_reg, nbits_next;    // number of bits received in data state
    reg [7:0] data_reg, data_next;      // reassembled data word
    
    // Register Logic
    always @(posedge clk_100MHz, posedge reset)
        if(reset) begin
            state <= idle;
            tick_reg <= 0;
            nbits_reg <= 0;
            data_reg <= 0;
        end
        else begin
            state <= next_state;
            tick_reg <= tick_next;
            nbits_reg <= nbits_next;
            data_reg <= data_next;
        end        

    // State Machine Logic
    always @* begin
        next_state = state;
        data_ready = 1'b0;
        tick_next = tick_reg;
        nbits_next = nbits_reg;
        data_next = data_reg;
        
        case(state)
            idle:
                if(~rx) begin               // when data line goes LOW (start condition)
                    next_state = start;
                    tick_next = 0;
                end
            start:
                if(sample_tick)
                    if(tick_reg == 7) begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            data:
                if(sample_tick)
                    if(tick_reg == 15) begin
                        tick_next = 0;
                        data_next = {rx, data_reg[7:1]};
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            stop:
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) begin
                        next_state = idle;
                        data_ready = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
        endcase                    
    end
    
    // Output Logic
    assign data_out = data_reg;

endmodule
