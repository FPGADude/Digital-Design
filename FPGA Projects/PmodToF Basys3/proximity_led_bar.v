`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: proximity_led_bar
//
// Sixteen-level proximity bar.
//
// Farther than or equal to 300 cm: all LEDs off.
// Closer than or equal to 30 cm: all LEDs on.
// Between those limits, the number of illuminated LEDs increases linearly as
// the object approaches the sensor.
//
// The output is thermometer-coded: illuminated LEDs always begin at LED0 and
// extend upward as distance decreases. The 30-to-300 cm working interval spans
// 270 cm and is divided into 16 approximately equal visual levels.
//
// When valid is low, all LEDs are intentionally blanked so stale or startup
// data is not presented as a real proximity measurement.
//////////////////////////////////////////////////////////////////////////////////

module proximity_led_bar(
    input  wire [13:0] distance_cm,
    input  wire        valid,
    output reg  [15:0] led_bar
);

    // Temporary integer representation of the desired number of lit LEDs.
    integer level;

    // Pure combinational mapping from filtered distance to LED pattern.
    always @(*) begin
        led_bar = 16'h0000;
        level = 0;

        if (valid) begin
            // Clamp the two ends of the useful display range, then linearly
            // interpolate the number of illuminated LEDs in between.
            if (distance_cm <= 14'd30)
                level = 16;
            else if (distance_cm >= 14'd300)
                level = 0;
            else
                level = ((300 - distance_cm) * 16) / 270;

            // Convert the numeric level into a contiguous LED bar.
            case (level)
                 0: led_bar = 16'h0000;
                 1: led_bar = 16'h0001;
                 2: led_bar = 16'h0003;
                 3: led_bar = 16'h0007;
                 4: led_bar = 16'h000F;
                 5: led_bar = 16'h001F;
                 6: led_bar = 16'h003F;
                 7: led_bar = 16'h007F;
                 8: led_bar = 16'h00FF;
                 9: led_bar = 16'h01FF;
                10: led_bar = 16'h03FF;
                11: led_bar = 16'h07FF;
                12: led_bar = 16'h0FFF;
                13: led_bar = 16'h1FFF;
                14: led_bar = 16'h3FFF;
                15: led_bar = 16'h7FFF;
                default: led_bar = 16'hFFFF;
            endcase
        end
    end
endmodule
