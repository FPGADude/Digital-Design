`timescale 1ns / 1ps
module fibonacci_rom(
    input [7:0] addr,
    input set_addr,
    input en_data,
    output reg [7:0] noi = 8'd20,
    output reg [7:0] data = 8'b0
);

    reg [7:0] addr_reg = 8'b0;

    always @(*) begin
        if(set_addr)
            addr_reg <= addr;
        else if(en_data)
            case(addr_reg)
                8'd0: data = 8'b00100000;
                8'd1: data = 8'b00000000;
                8'd2: data = 8'b00100001;
                8'd3: data = 8'b00000001;
                8'd4: data = 8'b00100010;
                8'd5: data = 8'b11111111;
                8'd6: data = 8'b00100011;
                8'd7: data = 8'b00000110;
                8'd8: data = 8'b10000100;
                8'd9: data = 8'b01111000;
                8'd10: data = 8'b10000001;
                8'd11: data = 8'b01111001;
                8'd12: data = 8'b10001011;
                8'd13: data = 8'b01010001;
                8'd14: data = 8'b00010001;
                8'd15: data = 8'b01000000;
                8'd16: data = 8'b00001000;
                8'd17: data = 8'b01000000;
                8'd18: data = 8'b00010001;
                8'd19: data = 8'b00000000;
                default: data = 8'b0;
            endcase
    end

endmodule