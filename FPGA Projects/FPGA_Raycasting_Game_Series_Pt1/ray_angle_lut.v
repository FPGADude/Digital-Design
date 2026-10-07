`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// ANGLE LOOKUP TABLE
//
// Converts a 6-bit player angle (0..63 around a full circle) into:
//   dir_x / dir_y     : forward viewing vector
//   plane_x / plane_y : perpendicular camera-plane vector
//
// Outputs are signed fixed-point values. Precomputing these 64 cases avoids
// synthesizing sine/cosine hardware. The camera plane establishes the field of
// view; individual screen rays are forward + plane * camera_position.
//
// Think of this module as the FPGA equivalent of a tiny precalculated trig
// table.
///////////////////////////////////////////////////////////////////////////////

// 64-entry viewing-angle lookup table.
// Direction and camera-plane components use signed Q1.8 fixed point.
module ray_angle_lut(
    input  wire [5:0] angle,
    output reg signed [9:0] dir_x,
    output reg signed [9:0] dir_y,
    output reg signed [9:0] plane_x,
    output reg signed [9:0] plane_y
);
    always @* begin
        case (angle)
            6'd0: begin dir_x=10'sd256; dir_y=10'sd0; plane_x=10'sd0; plane_y=10'sd169; end
            6'd1: begin dir_x=10'sd255; dir_y=10'sd25; plane_x=-10'sd17; plane_y=10'sd168; end
            6'd2: begin dir_x=10'sd251; dir_y=10'sd50; plane_x=-10'sd33; plane_y=10'sd166; end
            6'd3: begin dir_x=10'sd245; dir_y=10'sd74; plane_x=-10'sd49; plane_y=10'sd162; end
            6'd4: begin dir_x=10'sd237; dir_y=10'sd98; plane_x=-10'sd65; plane_y=10'sd156; end
            6'd5: begin dir_x=10'sd226; dir_y=10'sd121; plane_x=-10'sd80; plane_y=10'sd149; end
            6'd6: begin dir_x=10'sd213; dir_y=10'sd142; plane_x=-10'sd94; plane_y=10'sd141; end
            6'd7: begin dir_x=10'sd198; dir_y=10'sd162; plane_x=-10'sd107; plane_y=10'sd131; end
            6'd8: begin dir_x=10'sd181; dir_y=10'sd181; plane_x=-10'sd120; plane_y=10'sd120; end
            6'd9: begin dir_x=10'sd162; dir_y=10'sd198; plane_x=-10'sd131; plane_y=10'sd107; end
            6'd10: begin dir_x=10'sd142; dir_y=10'sd213; plane_x=-10'sd141; plane_y=10'sd94; end
            6'd11: begin dir_x=10'sd121; dir_y=10'sd226; plane_x=-10'sd149; plane_y=10'sd80; end
            6'd12: begin dir_x=10'sd98; dir_y=10'sd237; plane_x=-10'sd156; plane_y=10'sd65; end
            6'd13: begin dir_x=10'sd74; dir_y=10'sd245; plane_x=-10'sd162; plane_y=10'sd49; end
            6'd14: begin dir_x=10'sd50; dir_y=10'sd251; plane_x=-10'sd166; plane_y=10'sd33; end
            6'd15: begin dir_x=10'sd25; dir_y=10'sd255; plane_x=-10'sd168; plane_y=10'sd17; end
            6'd16: begin dir_x=10'sd0; dir_y=10'sd256; plane_x=-10'sd169; plane_y=10'sd0; end
            6'd17: begin dir_x=-10'sd25; dir_y=10'sd255; plane_x=-10'sd168; plane_y=-10'sd17; end
            6'd18: begin dir_x=-10'sd50; dir_y=10'sd251; plane_x=-10'sd166; plane_y=-10'sd33; end
            6'd19: begin dir_x=-10'sd74; dir_y=10'sd245; plane_x=-10'sd162; plane_y=-10'sd49; end
            6'd20: begin dir_x=-10'sd98; dir_y=10'sd237; plane_x=-10'sd156; plane_y=-10'sd65; end
            6'd21: begin dir_x=-10'sd121; dir_y=10'sd226; plane_x=-10'sd149; plane_y=-10'sd80; end
            6'd22: begin dir_x=-10'sd142; dir_y=10'sd213; plane_x=-10'sd141; plane_y=-10'sd94; end
            6'd23: begin dir_x=-10'sd162; dir_y=10'sd198; plane_x=-10'sd131; plane_y=-10'sd107; end
            6'd24: begin dir_x=-10'sd181; dir_y=10'sd181; plane_x=-10'sd120; plane_y=-10'sd120; end
            6'd25: begin dir_x=-10'sd198; dir_y=10'sd162; plane_x=-10'sd107; plane_y=-10'sd131; end
            6'd26: begin dir_x=-10'sd213; dir_y=10'sd142; plane_x=-10'sd94; plane_y=-10'sd141; end
            6'd27: begin dir_x=-10'sd226; dir_y=10'sd121; plane_x=-10'sd80; plane_y=-10'sd149; end
            6'd28: begin dir_x=-10'sd237; dir_y=10'sd98; plane_x=-10'sd65; plane_y=-10'sd156; end
            6'd29: begin dir_x=-10'sd245; dir_y=10'sd74; plane_x=-10'sd49; plane_y=-10'sd162; end
            6'd30: begin dir_x=-10'sd251; dir_y=10'sd50; plane_x=-10'sd33; plane_y=-10'sd166; end
            6'd31: begin dir_x=-10'sd255; dir_y=10'sd25; plane_x=-10'sd17; plane_y=-10'sd168; end
            6'd32: begin dir_x=-10'sd256; dir_y=10'sd0; plane_x=10'sd0; plane_y=-10'sd169; end
            6'd33: begin dir_x=-10'sd255; dir_y=-10'sd25; plane_x=10'sd17; plane_y=-10'sd168; end
            6'd34: begin dir_x=-10'sd251; dir_y=-10'sd50; plane_x=10'sd33; plane_y=-10'sd166; end
            6'd35: begin dir_x=-10'sd245; dir_y=-10'sd74; plane_x=10'sd49; plane_y=-10'sd162; end
            6'd36: begin dir_x=-10'sd237; dir_y=-10'sd98; plane_x=10'sd65; plane_y=-10'sd156; end
            6'd37: begin dir_x=-10'sd226; dir_y=-10'sd121; plane_x=10'sd80; plane_y=-10'sd149; end
            6'd38: begin dir_x=-10'sd213; dir_y=-10'sd142; plane_x=10'sd94; plane_y=-10'sd141; end
            6'd39: begin dir_x=-10'sd198; dir_y=-10'sd162; plane_x=10'sd107; plane_y=-10'sd131; end
            6'd40: begin dir_x=-10'sd181; dir_y=-10'sd181; plane_x=10'sd120; plane_y=-10'sd120; end
            6'd41: begin dir_x=-10'sd162; dir_y=-10'sd198; plane_x=10'sd131; plane_y=-10'sd107; end
            6'd42: begin dir_x=-10'sd142; dir_y=-10'sd213; plane_x=10'sd141; plane_y=-10'sd94; end
            6'd43: begin dir_x=-10'sd121; dir_y=-10'sd226; plane_x=10'sd149; plane_y=-10'sd80; end
            6'd44: begin dir_x=-10'sd98; dir_y=-10'sd237; plane_x=10'sd156; plane_y=-10'sd65; end
            6'd45: begin dir_x=-10'sd74; dir_y=-10'sd245; plane_x=10'sd162; plane_y=-10'sd49; end
            6'd46: begin dir_x=-10'sd50; dir_y=-10'sd251; plane_x=10'sd166; plane_y=-10'sd33; end
            6'd47: begin dir_x=-10'sd25; dir_y=-10'sd255; plane_x=10'sd168; plane_y=-10'sd17; end
            6'd48: begin dir_x=10'sd0; dir_y=-10'sd256; plane_x=10'sd169; plane_y=10'sd0; end
            6'd49: begin dir_x=10'sd25; dir_y=-10'sd255; plane_x=10'sd168; plane_y=10'sd17; end
            6'd50: begin dir_x=10'sd50; dir_y=-10'sd251; plane_x=10'sd166; plane_y=10'sd33; end
            6'd51: begin dir_x=10'sd74; dir_y=-10'sd245; plane_x=10'sd162; plane_y=10'sd49; end
            6'd52: begin dir_x=10'sd98; dir_y=-10'sd237; plane_x=10'sd156; plane_y=10'sd65; end
            6'd53: begin dir_x=10'sd121; dir_y=-10'sd226; plane_x=10'sd149; plane_y=10'sd80; end
            6'd54: begin dir_x=10'sd142; dir_y=-10'sd213; plane_x=10'sd141; plane_y=10'sd94; end
            6'd55: begin dir_x=10'sd162; dir_y=-10'sd198; plane_x=10'sd131; plane_y=10'sd107; end
            6'd56: begin dir_x=10'sd181; dir_y=-10'sd181; plane_x=10'sd120; plane_y=10'sd120; end
            6'd57: begin dir_x=10'sd198; dir_y=-10'sd162; plane_x=10'sd107; plane_y=10'sd131; end
            6'd58: begin dir_x=10'sd213; dir_y=-10'sd142; plane_x=10'sd94; plane_y=10'sd141; end
            6'd59: begin dir_x=10'sd226; dir_y=-10'sd121; plane_x=10'sd80; plane_y=10'sd149; end
            6'd60: begin dir_x=10'sd237; dir_y=-10'sd98; plane_x=10'sd65; plane_y=10'sd156; end
            6'd61: begin dir_x=10'sd245; dir_y=-10'sd74; plane_x=10'sd49; plane_y=10'sd162; end
            6'd62: begin dir_x=10'sd251; dir_y=-10'sd50; plane_x=10'sd33; plane_y=10'sd166; end
            6'd63: begin dir_x=10'sd255; dir_y=-10'sd25; plane_x=10'sd17; plane_y=10'sd168; end
            default: begin dir_x=10'sd256; dir_y=10'sd0; plane_x=10'sd0; plane_y=10'sd169; end
        endcase
    end
endmodule
