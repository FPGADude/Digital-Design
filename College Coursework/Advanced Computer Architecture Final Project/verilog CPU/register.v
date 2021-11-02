module register(clock, enable, data_in, data_out);
  input			clock;
  input			enable;
  input      [15:0] 	data_in;
  output reg [15:0] 	data_out;

always @(negedge clock)
  begin
    if( enable )
    begin
      data_out <= data_in;
    end
  end

endmodule