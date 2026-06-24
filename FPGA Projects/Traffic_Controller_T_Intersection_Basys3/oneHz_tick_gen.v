`timescale 1ns / 1ps

module oneHz_tick_gen #(
        parameter CLK_HZ = 100_000_000
)(
    input wire clk,  // 100MHz
    input wire reset,
    output wire tick
    );
    
    reg [31:0] counter;
    
    always @(posedge clk)
        if(reset)
            counter <= 32'd0;
        else
            if(counter == CLK_HZ)
                counter <= 32'd0;
            else
                counter <= counter + 1'b1;
    
    assign tick = (counter == CLK_HZ) ? 1'b1 : 1'b0;
    
    
endmodule
