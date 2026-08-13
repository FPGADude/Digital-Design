module sevenseg_decoder (
    input  logic [4:0] char_code,
    output logic [6:0] seg
);

    // seg = {a,b,c,d,e,f,g}, active low
    always_comb begin
        unique case (char_code)
            // numbers
            5'd0 : seg = 7'b1000000;
            5'd1 : seg = 7'b1111001;
            5'd2 : seg = 7'b0100100;
            5'd3 : seg = 7'b0110000;
            5'd4 : seg = 7'b0011001;
            5'd5 : seg = 7'b0010010;
            5'd6 : seg = 7'b0000010;
            5'd7 : seg = 7'b1111000;
            5'd8 : seg = 7'b0000000;
            5'd9 : seg = 7'b0010000;

            // custom letters
            5'd10: seg = 7'b0101111; // r approximation
            5'd11: seg = 7'b0000111; // t approximation
            5'd12: seg = 7'b0001000; // A
            5'd13: seg = 7'b0100001; // d
            5'd14: seg = 7'b0010010; // S (same as 5)
            5'd15: seg = 7'b0000011; // b
            5'd16: seg = 7'b1000110; // C
            5'd17: seg = 7'b0000110; // E
            5'd18: seg = 7'b0101011; // n approximation
            5'd19: seg = 7'b1111111; // blank

            default: seg = 7'b1111111;
        endcase
    end

endmodule
