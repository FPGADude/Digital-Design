`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Reference Book: FPGA Prototyping By Verilog Examples Xilinx Spartan-3 Version
// Authored by: Dr. Pong P. Chu
// Published by: Wiley
//
// Adapted for the Basys 3 Artix-7 FPGA by David J. Marion
//
// UART Transmitter for the UART System
//
// Comments:
// - Many of the variable names have been changed for clarity
//////////////////////////////////////////////////////////////////////////////////

module uart_transmitter
    #(
        parameter   DBITS = 8,          // number of data bits
                    SB_TICK = 16        // number of stop bit / oversampling ticks (1 stop bit)
    )
    (
        input clk_100MHz,               // basys 3 FPGA
        input reset,                    // reset
        input tx_start,                 // begin data transmission (FIFO NOT empty)
        input sample_tick,              // from baud rate generator
        input [DBITS-1:0] data_in,      // data word from FIFO
        output reg tx_done,             // end of transmission
        output tx                       // transmitter data line
    );
    
    // State Machine States
    localparam [1:0]    idle  = 2'b00,
                        start = 2'b01,
                        data  = 2'b10,
                        stop  = 2'b11;
    
    // Registers                    
    reg [1:0] state, next_state;            // state registers
    reg [3:0] tick_reg, tick_next;          // number of ticks received from baud rate generator
    reg [2:0] nbits_reg, nbits_next;        // number of bits transmitted in data state
    reg [DBITS-1:0] data_reg, data_next;    // assembled data word to transmit serially
    reg tx_reg, tx_next;                    // data filter for potential glitches
    
    // Register Logic
    always @(posedge clk_100MHz, posedge reset)
        if(reset) begin
            state <= idle;
            tick_reg <= 0;
            nbits_reg <= 0;
            data_reg <= 0;
            tx_reg <= 1'b1;
        end
        else begin
            state <= next_state;
            tick_reg <= tick_next;
            nbits_reg <= nbits_next;
            data_reg <= data_next;
            tx_reg <= tx_next;
        end
    
    // State Machine Logic
    always @* begin
        next_state = state;
        tx_done = 1'b0;
        tick_next = tick_reg;
        nbits_next = nbits_reg;
        data_next = data_reg;
        tx_next = tx_reg;
        
        case(state)
            idle: begin                     // no data in FIFO
                tx_next = 1'b1;             // transmit idle
                if(tx_start) begin          // when FIFO is NOT empty
                    next_state = start;
                    tick_next = 0;
                    data_next = data_in;
                end
            end
            
            start: begin
                tx_next = 1'b0;             // start bit
                if(sample_tick)
                    if(tick_reg == 15) begin
                        next_state = data;
                        tick_next = 0;
                        nbits_next = 0;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            data: begin
                tx_next = data_reg[0];
                if(sample_tick)
                    if(tick_reg == 15) begin
                        tick_next = 0;
                        data_next = data_reg >> 1;
                        if(nbits_reg == (DBITS-1))
                            next_state = stop;
                        else
                            nbits_next = nbits_reg + 1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
            
            stop: begin
                tx_next = 1'b1;         // back to idle
                if(sample_tick)
                    if(tick_reg == (SB_TICK-1)) begin
                        next_state = idle;
                        tx_done = 1'b1;
                    end
                    else
                        tick_next = tick_reg + 1;
            end
        endcase    
    end
    
    // Output Logic
    assign tx = tx_reg;
 
endmodule