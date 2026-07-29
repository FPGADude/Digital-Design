`timescale 1ns / 1ps

// ============================================================================
// COMPLETE-WORD ADDRESS/LENGTH LOOKUP TABLE
// ============================================================================
// Maps each word ID to its starting byte and sample count in retro_word_pcm.mem.
//
// These constants are generated together with the PCM memory image. When the
// vocabulary changes, both this table and the .mem file must be replaced.
// ============================================================================


module retro_word_sample_table (
    input  wire [5:0]  word_id,
    output reg  [17:0] start_address,
    output reg  [17:0] sample_length
);

    always @* begin
        // Safe default points to one silent sample.
        start_address = 18'd0;
        sample_length = 18'd1;
        // Word IDs match retro_voice_defs.vh.
        case (word_id)
                6'd0: begin start_address = 18'd0; sample_length = 18'd1; end
                6'd1: begin start_address = 18'd1; sample_length = 18'd9787; end
                6'd2: begin start_address = 18'd9788; sample_length = 18'd9635; end
                6'd3: begin start_address = 18'd19423; sample_length = 18'd8682; end
                6'd4: begin start_address = 18'd28105; sample_length = 18'd8276; end
                6'd5: begin start_address = 18'd36381; sample_length = 18'd8213; end
                6'd6: begin start_address = 18'd44594; sample_length = 18'd9536; end
                6'd7: begin start_address = 18'd54130; sample_length = 18'd7916; end
                6'd8: begin start_address = 18'd62046; sample_length = 18'd11871; end
                6'd9: begin start_address = 18'd73917; sample_length = 18'd9009; end
                6'd10: begin start_address = 18'd82926; sample_length = 18'd9965; end
                6'd11: begin start_address = 18'd92891; sample_length = 18'd9738; end
                6'd12: begin start_address = 18'd102629; sample_length = 18'd8290; end
                6'd13: begin start_address = 18'd110919; sample_length = 18'd8509; end
                6'd14: begin start_address = 18'd119428; sample_length = 18'd8081; end
                6'd15: begin start_address = 18'd127509; sample_length = 18'd8873; end
            default: begin
                start_address = 18'd0;
                sample_length = 18'd1;
            end
        endcase
    end
    
endmodule
