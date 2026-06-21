module xadc_reader(
    input  wire clk,
    input  wire vauxp6,
    input  wire vauxn6,

    output reg [11:0] adc_value,
    output reg        adc_ready
);

    wire [15:0] do_out;
    wire        drdy_out;
    wire        eoc_out;

    always @(posedge clk) begin
        if (drdy_out) begin
            adc_value <= do_out[15:4];
            adc_ready <= 1'b1;
        end
    end

    xadc_wiz_0 xadc_inst (
        .daddr_in(7'h16),       // VAUX6 register
        .dclk_in(clk),
        .den_in(eoc_out),
        .di_in(16'h0000),
        .dwe_in(1'b0),

        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .vp_in(1'b0),
        .vn_in(1'b0),

        .busy_out(),
        .channel_out(),
        .do_out(do_out),
        .drdy_out(drdy_out),
        .eoc_out(eoc_out),
        .eos_out(),
        .alarm_out()
    );

endmodule
