`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// RAY COLUMN DOUBLE BUFFER
//
// Stores the result of each of the 320 rays. Each entry contains projected
// height plus shading/texture/depth/map metadata.
//
// Two banks are used:
//   render bank  - raycaster writes the next completed frame
//   display bank - VGA reads the previous completed frame
//
// The top module swaps roles only when a complete frame is ready. This is the
// hardware-rendering equivalent of double buffering and prevents tearing or
// partially updated geometry from appearing on screen.
///////////////////////////////////////////////////////////////////////////////

// -----------------------------------------------------------------------------
// Double-buffered 320-column render memory.
//
// Each entry stores everything needed to draw one two-pixel-wide screen column,
// including the perpendicular wall distance.  That distance is the engine's
// Z-buffer and will be used by the upcoming sprite renderer for wall occlusion.
// -----------------------------------------------------------------------------
module ray_column_buffer(
    input  wire        clk,
    input  wire        write_bank,
    input  wire [8:0]  write_addr,
    input  wire [8:0]  write_height,
    input  wire [1:0]  write_shade,
    input  wire [5:0]  write_texture_x,
    input  wire [9:0]  write_texture_step,
    input  wire [1:0]  write_wall_type,
    input  wire [15:0] write_depth,
    input  wire [3:0]  write_map_x,
    input  wire [3:0]  write_map_y,
    input  wire        write_hit_side,
    input  wire        write_enable,
    input  wire        read_bank,
    input  wire [8:0]  read_addr,
    output wire [8:0]  read_height,
    output wire [1:0]  read_shade,
    output wire [5:0]  read_texture_x,
    output wire [9:0]  read_texture_step,
    output wire [1:0]  read_wall_type,
    output wire [15:0] read_depth,
    output wire [3:0]  read_map_x,
    output wire [3:0]  read_map_y,
    output wire        read_hit_side
);
    // 54 bits = 4 map X + 4 map Y + 1 hit side + the original 45 bits.
    // This still fits comfortably in one 36-Kbit BRAM across both 320-column banks.
    reg [53:0] bank0 [0:319];
    reg [53:0] bank1 [0:319];

    wire [53:0] read_word = read_bank ? bank1[read_addr] : bank0[read_addr];

    always @(posedge clk) begin
        if (write_enable && (write_addr < 9'd320)) begin
            if (write_bank)
                bank1[write_addr] <= {write_map_x, write_map_y, write_hit_side,
                                      write_depth, write_wall_type,
                                      write_texture_step, write_texture_x,
                                      write_shade, write_height};
            else
                bank0[write_addr] <= {write_map_x, write_map_y, write_hit_side,
                                      write_depth, write_wall_type,
                                      write_texture_step, write_texture_x,
                                      write_shade, write_height};
        end
    end

    assign {read_map_x, read_map_y, read_hit_side,
            read_depth, read_wall_type, read_texture_step,
            read_texture_x, read_shade, read_height} = read_word;
endmodule

