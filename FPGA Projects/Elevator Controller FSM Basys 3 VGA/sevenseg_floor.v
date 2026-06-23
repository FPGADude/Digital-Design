// ================================================================
// sevenseg_floor.v
// ================================================================
// Creator : David J. Marion
// Date    : 6.20.2026
// Project : Basys 3 FPGA Elevator Controller
// Purpose : Drives the Basys 3 four-digit seven-segment display
//           with the current floor.
//
// Notes   : The internal floor value is 0-3, but the displayed
//           value is floor+1.
//
// Board   : Digilent Basys 3, 100 MHz system clock
// Language: Verilog HDL
// ================================================================

module sevenseg_floor(
    input  wire       clk,
    input  wire [1:0] floor,
    input  wire emergency_stop,
    output reg  [6:0] seg,
    output reg  [3:0] an
);

    // Refresh counter selects one digit at a time fast enough that
    // persistence of vision makes all four digits appear continuously on.
    reg [16:0] refresh_counter = 0;
    wire [1:0] digit_select = refresh_counter[16:15];
    reg [3:0] digit;

    always @(posedge clk)
        refresh_counter <= refresh_counter + 1;

    // Multiplex the display. The rightmost digit shows the current floor.
    // The other three digits are displayed as 0, giving 0001 through 0004.
    always @(*) begin
        if (!emergency_stop) begin
            case (digit_select)
                2'b00: begin 
                    an = 4'b1110; 
                    digit = floor + 1; 
                    end
                2'b01: begin 
                    an = 4'b1101; 
                    digit = 4'd0; 
                    end
                2'b10: begin 
                    an = 4'b1011; 
                    digit = 4'd0; 
                    end
                2'b11: begin 
                    an = 4'b0111; 
                    digit = 4'd0; 
                    end
                default: begin 
                    an = 4'b1111; 
                    digit = 4'd0; 
                    end
             endcase
             seg = digit_to_seg(digit);
             
         end else begin
            case (digit_select)
                2'b00: begin 
                    an = 4'b1110; 
                    seg = 7'b0111111;
                    end
                2'b01: begin 
                    an = 4'b1101; 
                    seg = 7'b0111111; 
                    end
                2'b10: begin 
                    an = 4'b1011; 
                    seg = 7'b0111111; 
                    end
                2'b11: begin 
                    an = 4'b0111; 
                    seg = 7'b0111111;
                    end
                default: begin 
                    an = 4'b1111; 
                    seg = 7'b1111111; 
                    end
             endcase
         end   
    end

    // Seven-segment decoder for Basys 3 active-low segment signals.
    // seg[6:0] corresponds to gfedcba style patterns used by the board.
    function [6:0] digit_to_seg;
        input [3:0] d;
        begin
            case (d)
                4'd0: digit_to_seg = 7'b1000000;
                4'd1: digit_to_seg = 7'b1111001;
                4'd2: digit_to_seg = 7'b0100100;
                4'd3: digit_to_seg = 7'b0110000;
                4'd4: digit_to_seg = 7'b0011001;
                4'd5: digit_to_seg = 7'b0010010;
                4'd6: digit_to_seg = 7'b0000010;
                4'd7: digit_to_seg = 7'b1111000;
                4'd8: digit_to_seg = 7'b0000000;
                4'd9: digit_to_seg = 7'b0010000;
                default: digit_to_seg = 7'b1111111;
            endcase
        end
    endfunction

endmodule



