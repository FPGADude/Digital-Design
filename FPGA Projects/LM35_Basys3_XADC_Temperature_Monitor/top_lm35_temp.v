module top_lm35_temp(
    input  wire clk_100MHz,
    input  wire [15:0] sw,

    input  wire vauxp6,
    input  wire vauxn6,

    output wire [6:0] seg,
    output wire [3:0] an
);

    wire [11:0] adc_value;
    wire        adc_ready;

    wire [9:0] temp_value;
    wire       unit_f;

    xadc_reader u_xadc_reader (
        .clk(clk_100MHz),
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .adc_value(adc_value),
        .adc_ready(adc_ready)
    );

    temp_converter u_temp_converter (
        .adc_value(adc_value),
        .unit_select(sw[15]),
        .temp_value(temp_value),
        .unit_f(unit_f)
    );

    sevenseg_driver u_sevenseg_driver (
        .clk(clk_100MHz),
        .temp_value(temp_value),
        .unit_f(unit_f),
        .seg(seg),
        .an(an)
    );

endmodule
