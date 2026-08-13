module answer_checker (
    input  route66_pkg::op_t op,
    input  logic [7:0] operand,
    input  logic [7:0] switches_value,
    output logic [7:0] correct_answer,
    output logic       is_correct
);
    import route66_pkg::*;

    always_comb begin
        unique case (op)
            OP_ADD: correct_answer = TARGET_VALUE - operand;
            OP_SUB: correct_answer = operand - TARGET_VALUE;
            default: correct_answer = 8'd0;
        endcase
    end

    assign is_correct = (switches_value == correct_answer);

endmodule
