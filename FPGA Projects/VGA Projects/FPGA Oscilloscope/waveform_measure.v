`timescale 1ns / 1ps

module waveform_measure (
    input  wire        clk,
    input  wire        sample_tick,
    input  wire [11:0] adc_sample,

    output reg  [11:0] min_sample = 12'h000,
    output reg  [11:0] max_sample = 12'h000,
    output reg  [11:0] vpp_sample = 12'h000
);

    reg [9:0] sample_count = 10'd0;

    reg [11:0] working_min = 12'hFFF;
    reg [11:0] working_max = 12'h000;

    wire [11:0] next_min;
    wire [11:0] next_max;

    assign next_min =
        (adc_sample < working_min)
        ? adc_sample
        : working_min;

    assign next_max =
        (adc_sample > working_max)
        ? adc_sample
        : working_max;


    always @(posedge clk) begin

        if (sample_tick) begin

            if (sample_count == 10'd639) begin

                // Include the final sample in the completed
                // measurement before publishing results.

                min_sample <= next_min;
                max_sample <= next_max;
                vpp_sample <= next_max - next_min;

                // Start next 640-sample measurement window.

                sample_count <= 10'd0;
                working_min  <= 12'hFFF;
                working_max  <= 12'h000;

            end
            else begin

                sample_count <= sample_count + 1'b1;
                working_min  <= next_min;
                working_max  <= next_max;

            end

        end

    end

endmodule
