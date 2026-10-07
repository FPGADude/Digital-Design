`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// TUTORIAL MAP ROM
//
// Combinational 8x8 occupancy map used by BOTH collision and ray traversal.
// wall=1 means solid; wall=0 means walkable.
//
// Keeping the map in one explicit module makes it easy for a learner to alter
// the maze without understanding the raycaster internals. Coordinates outside
// the legal map are treated as walls as a defensive boundary condition.
///////////////////////////////////////////////////////////////////////////////
// Tutorial 8x8 map ROM. Coordinates outside 0..7 are treated as walls.
module ray_map_rom(
 input wire [3:0] map_x,
 input wire [3:0] map_y,
 output reg wall,
 output reg [1:0] wall_type
);
 always @* begin
  wall_type=2'd0;
  if(map_x>7 || map_y>7) wall=1'b1;
  else begin
   case({map_y[2:0],map_x[2:0]})
    6'o00,6'o01,6'o02,6'o03,6'o04,6'o05,6'o06,6'o07,
    6'o10,6'o17,
    6'o20,6'o22,6'o23,6'o27,
    6'o30,6'o35,6'o37,
    6'o40,6'o47,
    6'o50,6'o52,6'o57,
    6'o60,6'o64,6'o67,
    6'o70,6'o71,6'o72,6'o73,6'o74,6'o75,6'o76,6'o77: wall=1'b1;
    default: wall=1'b0;
   endcase
  end
 end
endmodule
