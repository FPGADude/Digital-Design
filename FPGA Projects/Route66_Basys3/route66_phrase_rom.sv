`timescale 1ns / 1ps
`include "route66_voice_defs.vh"

module route66_phrase_rom (
    input  logic [3:0] phrase_id,
    input  logic [3:0] word_index,
    output logic [5:0] word_id
);
    always_comb begin
        word_id = `WORD_END;
        unique case (phrase_id)
            `PHRASE_ROUTE_66: begin
                unique case (word_index)
                    4'd0: word_id = `WORD_ROUTE;
                    4'd1: word_id = `WORD_SIXTY;
                    4'd2: word_id = `WORD_SIX;
                    default: word_id = `WORD_END;
                endcase
            end
            `PHRASE_BEGIN: begin
                if (word_index == 4'd0) word_id = `WORD_BEGIN;
            end
            `PHRASE_ADDITION: begin
                if (word_index == 4'd0) word_id = `WORD_ADDITION;
            end
            `PHRASE_SUBTRACTION: begin
                if (word_index == 4'd0) word_id = `WORD_SUBTRACTION;
            end
            `PHRASE_CORRECT: begin
                if (word_index == 4'd0) word_id = `WORD_CORRECT;
            end
            `PHRASE_INCORRECT: begin
                if (word_index == 4'd0) word_id = `WORD_INCORRECT;
            end
            `PHRASE_TEN_SECONDS: begin
                unique case (word_index)
                    4'd0: word_id = `WORD_TEN;
                    4'd1: word_id = `WORD_SECONDS;
                    default: word_id = `WORD_END;
                endcase
            end
            `PHRASE_TIME_EXPIRED: begin
                unique case (word_index)
                    4'd0: word_id = `WORD_TIME;
                    4'd1: word_id = `WORD_EXPIRED;
                    default: word_id = `WORD_END;
                endcase
            end
            `PHRASE_GAME_OVER: begin
                unique case (word_index)
                    4'd0: word_id = `WORD_GAME;
                    4'd1: word_id = `WORD_OVER;
                    default: word_id = `WORD_END;
                endcase
            end
            default: word_id = `WORD_END;
        endcase
    end
endmodule
