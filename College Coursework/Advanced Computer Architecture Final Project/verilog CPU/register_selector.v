// Decoder for register file

module reg_selector(enable, select_reg, reg_en,);

    input 	  enable;		// enables writing to a register (vs. RAM)
    input  [2:0]  select_reg;		// selects the register to enable
    output [7:0]  reg_en;

always @*
  begin
    if( enable )
      begin
	case( select )
	  3'b000: reg_en = 8'b0000_0001;
	  3'b001: reg_en = 8'b0000_0010;
	  3'b010: reg_en = 8'b0000_0100;
	  3'b011: reg_en = 8'b0000_1000;
	  3'b100: reg_en = 8'b0001_0000;
	  3'b101: reg_en = 8'b0010_0000;
	  3'b110: reg_en = 8'b0100_0000;
	  3'b111: reg_en = 8'b1000_0000;	
        endcase 
      end
  end

endmodule

	