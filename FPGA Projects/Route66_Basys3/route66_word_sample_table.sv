`timescale 1ns / 1ps
module route66_word_sample_table (
    input  logic [5:0]  word_id,
    output logic [17:0] start_address,
    output logic [17:0] sample_length
);
    always_comb begin
        start_address = 18'd0;
        sample_length = 18'd1;
        unique case (word_id)
            6'd0:  begin start_address = 18'd0;      sample_length = 18'd1;     end
            6'd1:  begin start_address = 18'd1;      sample_length = 18'd5386;  end // ROUTE
            6'd2:  begin start_address = 18'd5387;   sample_length = 18'd7987;  end // SIXTY
            6'd3:  begin start_address = 18'd13374;  sample_length = 18'd6625;  end // SIX
            6'd4:  begin start_address = 18'd19999;  sample_length = 18'd7411;  end // BEGIN
            6'd5:  begin start_address = 18'd27410;  sample_length = 18'd7930;  end // ADDITION
            6'd6:  begin start_address = 18'd35340;  sample_length = 18'd12700; end // SUBTRACTION
            6'd7:  begin start_address = 18'd48040;  sample_length = 18'd8081;  end // CORRECT
            6'd8:  begin start_address = 18'd56121;  sample_length = 18'd9584;  end // INCORRECT
            6'd9:  begin start_address = 18'd65705;  sample_length = 18'd6006;  end // TEN
            6'd10: begin start_address = 18'd71711;  sample_length = 18'd9040;  end // SECONDS
            6'd11: begin start_address = 18'd80751;  sample_length = 18'd6595;  end // TIME
            6'd12: begin start_address = 18'd87346;  sample_length = 18'd9526;  end // EXPIRED
            6'd13: begin start_address = 18'd96872;  sample_length = 18'd5979;  end // GAME
            6'd14: begin start_address = 18'd102851; sample_length = 18'd6360;  end // OVER
            default: begin start_address = 18'd0; sample_length = 18'd1; end
        endcase
    end
endmodule
