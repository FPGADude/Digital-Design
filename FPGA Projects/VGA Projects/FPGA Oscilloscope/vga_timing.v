`timescale 1ns / 1ps

module vga_timing (
    input  wire       clk,

    output wire       pixel_tick,
    output reg  [9:0] x = 10'd0,
    output reg  [9:0] y = 10'd0,

    output wire       hsync,
    output wire       vsync,
    output wire       active
);

    // ============================================================
    // 25 MHz PIXEL ENABLE
    //
    // FPGA logic remains synchronous to 100 MHz.
    // Pixel counters advance once every four clocks.
    // ============================================================

    reg [1:0] pixel_div = 2'd0;

    always @(posedge clk)
        pixel_div <= pixel_div + 1'b1;

    assign pixel_tick = (pixel_div == 2'b11);


    // ============================================================
    // VGA TIMING
    //
    // 640 x 480 @ approximately 60 Hz
    //
    // Horizontal:
    //   Visible     640
    //   Front porch  16
    //   Sync         96
    //   Back porch   48
    //   Total       800
    //
    // Vertical:
    //   Visible     480
    //   Front porch  10
    //   Sync          2
    //   Back porch   33
    //   Total       525
    // ============================================================

    always @(posedge clk) begin

        if (pixel_tick) begin

            if (x == 10'd799) begin

                x <= 10'd0;

                if (y == 10'd524)
                    y <= 10'd0;
                else
                    y <= y + 1'b1;

            end
            else begin

                x <= x + 1'b1;

            end

        end

    end


    assign active =
        (x < 10'd640) &&
        (y < 10'd480);


    assign hsync =
        ~((x >= 10'd656) &&
          (x <  10'd752));


    assign vsync =
        ~((y >= 10'd490) &&
          (y <  10'd492));

endmodule
