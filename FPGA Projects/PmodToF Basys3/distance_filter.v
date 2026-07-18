`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: distance_filter
//
// Purpose:
//   Smooth the raw centimeter readings produced by the Pmod ToF controller.
//
// Method:
//   An eight-sample moving average is maintained in a circular sample buffer.
//   While the buffer is filling, the average is calculated from only the
//   samples that have actually arrived. Once eight samples are present, each
//   new sample replaces the oldest sample and the average becomes sum / 8.
//
// Notes:
//   - sample_strobe must pulse for one clock cycle whenever distance_in_cm
//     contains a newly completed measurement.
//   - filtered_valid remains low until the first sample has been processed.
//   - No deadband is used, so both odd and even centimeter values can appear.
//   - Blocking assignments are used only for the temporary combinational
//     calculations next_sum and next_average inside the clocked process.
// 
// Ports:
//   clk              - 100 MHz Basys 3 system clock
//   reset            - synchronous active-high reset
//   sample_strobe    - one-clock indication that a new sample is available
//   distance_in_cm   - unfiltered distance measurement in centimeters
//   distance_out_cm  - eight-sample averaged distance
//   filtered_valid   - high after at least one filtered result is available
//////////////////////////////////////////////////////////////////////////////////

module distance_filter(
    input  wire        clk,
    input  wire        reset,
    input  wire        sample_strobe,
    input  wire [13:0] distance_in_cm,
    output reg  [13:0] distance_out_cm,
    output reg         filtered_valid
);

    // Circular buffer containing the eight most recent centimeter samples.
    reg [13:0] samples [0:7];
    // Index of the buffer element that will be replaced by the next sample.
    reg [2:0]  write_index;
    // Number of valid samples currently stored. Saturates at eight.
    reg [3:0]  sample_count;
    // Running sum of the samples. Keeping the sum avoids re-adding all
    // eight buffer entries on every new measurement.
    reg [17:0] sample_sum;

    // Temporary values used to calculate the next registered result.
    reg [17:0] next_sum;
    reg [13:0] next_average;

    // Loop variable used only to clear the sample memory during reset.
    integer i;

    // The filter updates only when a complete sensor measurement arrives.
    // Between sample strobes, all stored values remain unchanged.
    always @(posedge clk) begin
        if (reset) begin
            // Return the circular buffer and all validity tracking to the
            // empty startup condition.
            write_index     <= 3'd0;
            sample_count    <= 4'd0;
            sample_sum      <= 18'd0;
            distance_out_cm <= 14'd0;
            filtered_valid  <= 1'b0;

            for (i = 0; i < 8; i = i + 1)
                samples[i] <= 14'd0;
        end else if (sample_strobe) begin
            if (sample_count < 4'd8) begin
                // Startup fill phase: add the new sample without subtracting
                // an old value because the entire window is not full yet.
                next_sum = sample_sum + distance_in_cm;

                samples[write_index] <= distance_in_cm;
                sample_sum           <= next_sum;
                write_index          <= write_index + 1'b1;
                sample_count         <= sample_count + 1'b1;

                next_average = next_sum / (sample_count + 1'b1);
            end else begin
                // Steady-state phase: remove the oldest sample from the sum,
                // add the newest sample, and overwrite that buffer location.
                next_sum = sample_sum
                         - samples[write_index]
                         + distance_in_cm;

                samples[write_index] <= distance_in_cm;
                sample_sum           <= next_sum;
                write_index          <= write_index + 1'b1;

                next_average = next_sum >> 3;
            end

            // Publish the newest averaged result on the same sample event.
            distance_out_cm <= next_average;
            filtered_valid  <= 1'b1;
        end
    end

endmodule
