module sevenseg_driver(
    input  wire clk,
    input  wire [9:0] temp_value,
    input  wire unit_f,

    output reg [6:0] seg,
    output reg [3:0] an
);

    reg [16:0] refresh_counter = 0;
    wire [1:0] digit_select;

    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;
    reg [3:0] current_digit;

    assign digit_select = refresh_counter[16:15];

    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
    end

    always @(*) begin
        hundreds = (temp_value / 100) % 10;
        tens     = (temp_value / 10)  % 10;
        ones     = temp_value % 10;
    end

    always @(*) begin
        case (digit_select)
            2'b00: begin
                an = 4'b1110;
                if (unit_f)
                    seg = 7'b0001110; // F
                else
                    seg = 7'b1000110; // C
            end

            2'b01: begin
                an = 4'b1101;
                current_digit = ones;
                seg = digit_to_seg(current_digit);
            end

            2'b10: begin
                an = 4'b1011;
                current_digit = tens;
                seg = digit_to_seg(current_digit);
            end

            2'b11: begin
                an = 4'b0111;
                current_digit = hundreds;
                seg = digit_to_seg(current_digit);
            end
        endcase
    end

    function [6:0] digit_to_seg;
        input [3:0] digit;
        begin
            case (digit)
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
