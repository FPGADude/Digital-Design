`timescale 1ns / 1ps

// Having fun with BASYS 3 FPGA board
// Control RGB led using 3 switches
// David J Marion

module RGB_controller(
    input [2:0] sw,
    output [2:0] rgb    //rgb[0] = red
    );                  //rgb[1] = green
                        //rgb[2] = blue
assign rgb = sw;
    
endmodule
