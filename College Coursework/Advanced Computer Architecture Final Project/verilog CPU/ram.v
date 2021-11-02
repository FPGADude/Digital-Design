module ram( data_out, data_in, address, write, select, clock );
  output[31:0] 	data_out;
  input [31:0]  data_in;
  input [15:0]  address;
  input 	write;
  input		select;
  input		clock;

  reg [31:0] mem [65535:0]; //memory
  reg [31:0] data_out;

always @ ( data_in, address, write, select )
  begin
    if ( write && select )
      begin
        mem[address] = data_in;
	//$display( "write %8X into DM[%3X]", data_in, address );
      end
    assign data_out = select ? mem[address] : 32'hzzzzzzzz;
  end

endmodule