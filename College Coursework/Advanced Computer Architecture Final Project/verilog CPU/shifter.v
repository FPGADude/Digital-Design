`include bit_selector.v

module shifter( shifter_select, shifter_enable, x_input, y_input, shifter_output );
  input     [2:0]  	shifter_select;
  input            	shifter_enable;
  input     [15:0] 	x_input;
  input     [3:0]  	y_input;
  output    [15:0] 	shifter_output;


always @*
begin
  if( shifter_enable )
    begin
      case( shifter_select )
      3'b000:  shifter_output = x_input >> y_input; 		//LSR shifter_output=x_input << y_input;     
      3'b001:  shifter_output = x_input << y_input; 		//LSL shifter_output=x_input >> y_input;
      3'b010:  shifter_output = {15, x_input[15:1]}; 		//ASR shifter_output=x_input >>> y_input;     
      3'b011:  shifter_output = {x_input[14:0], x_input[15]}; 	//ROTL shifter_output=x_input rot> y_input;    
      3'b100:  shifter_output = {x_input[0], x_input[15:1]}; 	//ROTR shifter_output=x_input <rot y_input;
      endcase
    end
end

endmodule 
