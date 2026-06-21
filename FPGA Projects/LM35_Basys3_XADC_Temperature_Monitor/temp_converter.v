module temp_converter(
    input  wire [11:0] adc_value,
    input  wire        unit_select,     // sw[15]

    output reg  [9:0]  temp_value,
    output reg         unit_f
);

    reg [21:0] celsius;
    reg [21:0] fahrenheit;

    always @(*) begin
        // XADC: 0 to 4095 represents 0V to 1V
        // LM35: 10mV per degree C
        //
        // Celsius = adc_value * 100 / 4095

        celsius = (adc_value * 100) / 4095;
        fahrenheit = ((celsius * 9) / 5) + 32;

        if (unit_select == 1'b0) begin
            temp_value = celsius[9:0];
            unit_f = 1'b0;
        end else begin
            temp_value = fahrenheit[9:0];
            unit_f = 1'b1;
        end
    end

endmodule