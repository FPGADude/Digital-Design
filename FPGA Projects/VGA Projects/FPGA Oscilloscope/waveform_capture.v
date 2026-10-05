`timescale 1ns / 1ps

module waveform_capture (
    input  wire        clk,
    input  wire        sample_tick,

    input  wire [11:0] adc_sample,

    input  wire [9:0]  read_addr,
    output reg  [11:0] read_data = 12'h000
);

    // ============================================================
    // 640 x 12-bit WAVEFORM MEMORY
    // ============================================================

    (* ram_style = "block" *)
    reg [11:0] sample_mem [0:639];

    reg [9:0] write_addr = 10'd0;


    // ============================================================
    // CAPTURE
    //
    // One sample is stored on every shared 64 kHz sample tick.
    // ============================================================

    always @(posedge clk) begin

        if (sample_tick) begin

            sample_mem[write_addr] <= adc_sample;

            if (write_addr == 10'd639)
                write_addr <= 10'd0;
            else
                write_addr <= write_addr + 1'b1;

        end

    end


    // ============================================================
    // VGA READ
    // ============================================================

    always @(posedge clk) begin

        if (read_addr < 10'd640)
            read_data <= sample_mem[read_addr];
        else
            read_data <= 12'h000;

    end

endmodule