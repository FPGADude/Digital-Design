`timescale 1ns / 1ps

module xadc_scope_top (
    input  wire       CLK100MHZ,

    input  wire       vauxp6,
    input  wire       vauxn6,

    output wire       Hsync,
    output wire       Vsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue
);

    // ============================================================
    // XADC
    // ============================================================

    wire [11:0] adc_sample;
    wire        adc_valid;

    xadc_reader xadc_reader_inst (
        .clk          (CLK100MHZ),
        .vauxp6       (vauxp6),
        .vauxn6       (vauxn6),
        .adc_sample   (adc_sample),
        .sample_valid (adc_valid)
    );


    // ============================================================
    // 16-SAMPLE MOVING AVERAGE
    // ============================================================

    wire [11:0] filtered_sample;
    wire        filtered_valid;

    xadc_average xadc_average_inst (
        .clk              (CLK100MHZ),
        .sample_in        (adc_sample),
        .sample_valid_in  (adc_valid),
        .sample_out       (filtered_sample),
        .sample_valid_out (filtered_valid)
    );


    // ============================================================
    // SHARED 64 kHz SAMPLE RATE
    // ============================================================

    wire sample_tick;

    sample_rate_gen sample_rate_inst (
        .clk         (CLK100MHZ),
        .sample_tick (sample_tick)
    );


    // ============================================================
    // WAVEFORM MEASUREMENTS
    // ============================================================

    wire [11:0] min_sample;
    wire [11:0] max_sample;
    wire [11:0] vpp_sample;

    waveform_measure measure_inst (
        .clk         (CLK100MHZ),
        .sample_tick (sample_tick),
        .adc_sample  (filtered_sample),

        .min_sample  (min_sample),
        .max_sample  (max_sample),
        .vpp_sample  (vpp_sample)
    );


    // ============================================================
    // VGA TIMING
    // ============================================================

    wire       pixel_tick;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire       video_active;

    vga_timing vga_timing_inst (
        .clk        (CLK100MHZ),
        .pixel_tick (pixel_tick),
        .x          (pixel_x),
        .y          (pixel_y),
        .hsync      (Hsync),
        .vsync      (Vsync),
        .active     (video_active)
    );


    // ============================================================
    // VGA PLOT -> WAVEFORM MEMORY ADDRESS MAPPER
    //
    // Plot width:
    //
    //     X = 70 through 619
    //     550 visible pixels
    //
    // Capture buffer:
    //
    //     640 samples
    //
    // Previous implementation used:
    //
    //     ((pixel_x - 70) * 639) / 549
    //
    // That created a large combinational divider and caused severe
    // setup timing violations at the BRAM address input.
    //
    // Instead, use a fractional accumulator.
    //
    // For every plot pixel:
    //
    //     accumulator += 640
    //
    // Whenever accumulator >= 550:
    //
    //     accumulator -= 550
    //     address++
    //
    // Because 640 / 550 = 1.1636..., some display pixels advance
    // one sample and some advance two samples.
    //
    // No multiplier.
    // No divider.
    // ============================================================

    reg [9:0]  waveform_address = 10'd0;
    reg [10:0] address_fraction = 11'd0;

    wire [10:0] fraction_plus_640;

    assign fraction_plus_640 =
        address_fraction + 11'd640;


    always @(posedge CLK100MHZ) begin

        // Only update once per VGA pixel.
        if (pixel_tick) begin

            // ----------------------------------------------------
            // Beginning of plot row
            // ----------------------------------------------------

            if (pixel_x == 10'd70) begin

                waveform_address <= 10'd0;
                address_fraction <= 11'd0;

            end

            // ----------------------------------------------------
            // Inside plot
            // ----------------------------------------------------

            else if ((pixel_x > 10'd70) &&
                     (pixel_x <= 10'd619)) begin

                if (fraction_plus_640 >= 11'd1100) begin

                    // Advance TWO capture samples.
                    address_fraction <=
                        fraction_plus_640 - 11'd1100;

                    if (waveform_address <= 10'd637)
                        waveform_address <=
                            waveform_address + 10'd2;
                    else
                        waveform_address <= 10'd639;

                end
                else begin

                    // Advance ONE capture sample.
                    address_fraction <=
                        fraction_plus_640 - 11'd550;

                    if (waveform_address < 10'd639)
                        waveform_address <=
                            waveform_address + 10'd1;
                    else
                        waveform_address <= 10'd639;

                end

            end

            // ----------------------------------------------------
            // Outside plot
            // ----------------------------------------------------

            else begin

                waveform_address <= 10'd0;
                address_fraction <= 11'd0;

            end

        end

    end


    // ============================================================
    // WAVEFORM CAPTURE
    // ============================================================

    wire [11:0] waveform_sample;

    waveform_capture capture_inst (
        .clk         (CLK100MHZ),
        .sample_tick (sample_tick),
        .adc_sample  (filtered_sample),

        .read_addr   (waveform_address),
        .read_data   (waveform_sample)
    );


    // ============================================================
    // VGA RENDERER
    // ============================================================

    waveform_renderer renderer_inst (
        .active      (video_active),
        .x           (pixel_x),
        .y           (pixel_y),

        .sample      (waveform_sample),

        .min_sample  (min_sample),
        .max_sample  (max_sample),
        .vpp_sample  (vpp_sample),

        .vga_r       (vgaRed),
        .vga_g       (vgaGreen),
        .vga_b       (vgaBlue)
    );

endmodule