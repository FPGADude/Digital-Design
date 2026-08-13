`timescale 1ns / 1ps
module route66_pwm_dac (
    input  logic               clk,
    input  logic               reset,
    input  logic signed [15:0] pcm_sample,
    input  logic               sample_valid,
    output logic               pwm_out
);
    logic [7:0] held_unsigned_sample;
    logic [7:0] pwm_counter;
    wire [15:0] unsigned_sample = pcm_sample + 16'h8000;

    always_ff @(posedge clk) begin
        if (reset) begin
            held_unsigned_sample <= 8'h80;
            pwm_counter <= 8'h00;
        end else begin
            pwm_counter <= pwm_counter + 1'b1;
            if (sample_valid) held_unsigned_sample <= unsigned_sample[15:8];
        end
    end
    assign pwm_out = (pwm_counter < held_unsigned_sample);
endmodule
