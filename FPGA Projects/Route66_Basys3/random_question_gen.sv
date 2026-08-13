module random_question_gen (
    input  logic clk,
    input  logic rst,
    input  logic load_new_question,
    output route66_pkg::question_t question
);
    import route66_pkg::*;

    logic [7:0] lfsr;
    logic       feedback;
    logic [7:0] next_lfsr;

    // Maximal-length 8-bit LFSR.  It free-runs continuously so the
    // human timing of START/SUBMIT changes the question sequence.
    assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];
    assign next_lfsr = {lfsr[6:0], feedback};

    always_ff @(posedge clk) begin
        if (rst) begin
            lfsr     <= 8'hA5; // non-zero seed
            question <= '{op: OP_ADD, operand: 8'd10};
        end else begin
            // Free-run instead of advancing only once per question.
            // This prevents every reset from producing the same game.
            lfsr <= next_lfsr;

            if (load_new_question) begin
                if (next_lfsr[0] == 1'b0) begin
                    // ADD: operand is 0..66, so X = 66 - operand is valid.
                    question.op      <= OP_ADD;
                    question.operand <= next_lfsr % 8'd67;
                end else begin
                    // SUB: operand is 66..255, so X = operand - 66 is valid.
                    question.op      <= OP_SUB;
                    question.operand <= 8'd66 + (next_lfsr % 8'd190);
                end
            end
        end
    end

endmodule
