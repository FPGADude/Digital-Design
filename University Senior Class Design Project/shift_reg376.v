`timescale 1ns / 1ps

// LiDAR data receiver shift register
// 376-bit shift register to hold one complete LiDAR data packet
// Authored by David J Marion

module shift_reg376(
    input data_in,              // Data bit from oversampler DFF
    input reset,                // Asynchronous system reset
    input latch,                // Latch data in, from tick24 signal
    output [183:0] data_out,    // Extrapolated 184-bit data parallel out
    output reg sig542c          // Signals a complete LiDAR packet received
    );
    
    reg [375:0] data_packet;    // Internal register to hold LiDAR data packet
    
    always @(posedge latch or posedge reset) begin
        if(reset)
            data_packet <= 376'd0;
        else
            data_packet[0] <= data_in;
            data_packet[375:1] <= data_packet[374:0];
    end
    
    always @(posedge latch) begin
        if(data_packet[375:360] == 16'h542c)
            sig542c <= 1'b1;
        else
            sig542c <= 1'b0;
    end
    
    // Rearranging LiDAR data packet into a custom data packet
    // Since the inside diameter of a 4" sewer pipe is ~100mm,
    // we do not need the MSB of each point, since they will all be 0 anyway.
    // We also do not really need the confidence value of each point.
    // Assign data_out bits to data_packet bits
    assign data_out[183:168] = data_packet[375:360];    // Packet Header    - 2 bytes "542c"
    assign data_out[167:160] = data_packet[351:344];    // Radar Speed MSB  - 1 byte
    assign data_out[159:152] = data_packet[359:352];    // Radar Speed LSB  - 1 byte
    assign data_out[151:144] = data_packet[335:328];    // Start Angle MSB  - 1 byte
    assign data_out[143:136] = data_packet[343:336];    // Start Angle LSB  - 1 byte
    assign data_out[135:128] = data_packet[327:320];    // Point 1 LSB      - 1 byte
    assign data_out[127:120] = data_packet[303:296];    // Point 2 LSB      - 1 byte
    assign data_out[119:112] = data_packet[279:272];    // Point 3 LSB      - 1 byte
    assign data_out[111:104] = data_packet[255:248];    // Point 4 LSB      - 1 byte
    assign data_out[103:96]  = data_packet[231:224];    // Point 5 LSB      - 1 byte
    assign data_out[95:88]   = data_packet[207:200];    // Point 6 LSB      - 1 byte
    assign data_out[87:80]   = data_packet[183:176];    // Point 7 LSB      - 1 byte
    assign data_out[79:72]   = data_packet[159:152];    // Point 8 LSB      - 1 byte
    assign data_out[71:64]   = data_packet[135:128];    // Point 9 LSB      - 1 byte
    assign data_out[63:56]   = data_packet[111:104];    // Point 10 LSB     - 1 byte
    assign data_out[55:48]   = data_packet[87:80];      // Point 11 LSB     - 1 byte
    assign data_out[47:40]   = data_packet[63:56];      // Point 12 LSB     - 1 byte
    assign data_out[39:32]   = data_packet[31:24];      // End Angle MSB    - 1 byte
    assign data_out[31:24]   = data_packet[39:32];      // End Angle LSB    - 1 byte
    assign data_out[23:16]   = data_packet[15:8];       // Time Stamp MSB   - 1 byte
    assign data_out[15:8]    = data_packet[23:16];      // Time Stamp LSB   - 1 byte
    assign data_out[7:0]     = data_packet[7:0];        // CRC Check        - 1 byte
    
endmodule
