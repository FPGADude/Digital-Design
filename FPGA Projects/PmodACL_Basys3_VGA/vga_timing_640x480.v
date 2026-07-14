`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// File: vga_timing_640x480.v
// Project: Pmod ACL VGA Display for Basys 3
//
// VGA timing generator for 640x480 at approximately 60 Hz. It divides the 100 MHz 
// clock to a 25 MHz pixel tick and generates counters, sync pulses, and visible-area enable.
//
// Notes:
// - This project reads the ADXL345 accelerometer on the Digilent Pmod ACL.
// - The design displays the three signed acceleration axes on a 640x480 VGA
//   screen as decimal values and center-referenced bar graphs.
// -----------------------------------------------------------------------------

// Standard 640x480 VGA timing block.
// The counters advance only on p_tick, so the rest of the design can still run
// from the main 100 MHz clock while pixels update at 25 MHz.
module vga_timing_640x480(
    input  wire       clk,
    input  wire       reset,
    output wire       video_on,
    output wire       p_tick,
    output wire       hsync,
    output wire       vsync,
    output wire [9:0] x,
    output wire [9:0] y
);

    // 640x480 @ 60 Hz VGA timing using 25 MHz pixel enable from 100 MHz clock.
    // Horizontal and vertical timing constants.
    // HD/VD are the visible dimensions; front porch, sync, and back porch
    // complete the total VGA line/frame timing.
    localparam HD = 640;
    localparam HF = 16;
    localparam HB = 48;
    localparam HR = 96;
    localparam VD = 480;
    localparam VF = 10;
    localparam VB = 33;
    localparam VR = 2;

    reg [1:0] div_reg = 0;
    // Free-running 2-bit divider for the pixel tick.
    // Horizontal/vertical counter update.
    // h_count advances every pixel tick. v_count advances at the end of a line.
    always @(posedge clk) begin
        if (reset) div_reg <= 0;
        else       div_reg <= div_reg + 1'b1;
    end
    // One-clock enable pulse used to advance the VGA counters.
    assign p_tick = (div_reg == 2'b00);

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    always @(posedge clk) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
        end else if (p_tick) begin
            if (h_count == (HD + HF + HB + HR - 1)) begin
                h_count <= 0;
                if (v_count == (VD + VF + VB + VR - 1))
                    v_count <= 0;
                else
                    v_count <= v_count + 1'b1;
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    // VGA sync pulses are active-low for this timing mode.
    assign hsync = ~((h_count >= (HD + HF)) && (h_count < (HD + HF + HR)));
    assign vsync = ~((v_count >= (VD + VF)) && (v_count < (VD + VF + VR)));
    // video_on is high only for pixels inside the visible 640x480 region.
    assign video_on = (h_count < HD) && (v_count < VD);
    assign x = h_count;
    assign y = v_count;

endmodule

