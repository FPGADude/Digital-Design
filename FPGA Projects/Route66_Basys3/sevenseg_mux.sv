module sevenseg_mux (
    input  logic       clk,
    input  logic       rst,
    input  logic       refresh_tick,
    input  logic [4:0] digit3_code,
    input  logic [4:0] digit2_code,
    input  logic [4:0] digit1_code,
    input  logic [4:0] digit0_code,
    output logic [6:0] seg,
    output logic [3:0] an
);

    logic [1:0] sel;
    logic [4:0] current_code;

    sevenseg_decoder u_dec (
        .char_code(current_code),
        .seg(seg)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            sel <= 2'd0;
        end else if (refresh_tick) begin
            sel <= sel + 1'b1;
        end
    end

    always_comb begin
        current_code = 5'd19;
        an = 4'b1111;

        unique case (sel)
            2'd0: begin
                current_code = digit0_code;
                an = 4'b1110;
            end
            2'd1: begin
                current_code = digit1_code;
                an = 4'b1101;
            end
            2'd2: begin
                current_code = digit2_code;
                an = 4'b1011;
            end
            2'd3: begin
                current_code = digit3_code;
                an = 4'b0111;
            end
        endcase
    end

endmodule