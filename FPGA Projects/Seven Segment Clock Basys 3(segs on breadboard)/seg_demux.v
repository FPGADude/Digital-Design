`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module seg_demux(
    input [6:0] mux_in,
    input [1:0] select,
    output reg [6:0] out0,
    output reg [6:0] out1,
    output reg [6:0] out2,
    output reg [6:0] out3
    );
    
    always @(select) begin
        case(select)
            2'b00:  begin
                    out0 = mux_in;
                    out1 = 7'b000_0000;
                    out2 = 7'b000_0000;
                    out3 = 7'b000_0000;
                    end
            2'b01:  begin
                    out0 = 7'b000_0000;
                    out1 = mux_in;
                    out2 = 7'b000_0000;
                    out3 = 7'b000_0000;
                    end
            2'b10:  begin
                    out0 = 7'b000_0000;
                    out1 = 7'b000_0000;
                    out2 = mux_in;
                    out3 = 7'b000_0000;
                    end
            2'b11:  begin
                    out0 = 7'b000_0000;
                    out1 = 7'b000_0000;
                    out2 = 7'b000_0000;
                    out3 = mux_in;
                    end
        endcase
    end 
endmodule


