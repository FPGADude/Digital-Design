`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module: flame_alarm_controller
//
// Purpose:
//   Latches the alarm after a validated flame event and counts separate flame
//   detections. A rising-edge detector ensures that one continuous flame event
//   increments the counter only once.
//
// Alarm acknowledgement:
//   The alarm can be cleared only when acknowledge is asserted AND the validated
//   flame signal has returned low. This prevents an active flame from being
//   hidden by pressing the acknowledge button.
//
// Counter behavior:
//   detection_count saturates at 16'hFFFF instead of wrapping back to zero.
//////////////////////////////////////////////////////////////////////////////////
module flame_alarm_controller (
    input  wire       clk,
    input  wire       reset,
    input  wire       acknowledge,
    input  wire       flame_detected,
    output reg        alarm_active,
    output reg [15:0] detection_count
);

    // Delayed validated sensor state used to recognize a new event edge.
    reg flame_detected_d;
    wire new_detection = flame_detected & ~flame_detected_d;

    // Alarm latch, event counter, and acknowledgement logic.
    always @(posedge clk) begin
        if (reset) begin
            flame_detected_d <= 1'b0;
            alarm_active     <= 1'b0;
            detection_count  <= 16'd0;
        end
        else begin
            flame_detected_d <= flame_detected;

            // A low-to-high transition marks the start of a separate event.
            if (new_detection) begin
                alarm_active <= 1'b1;

                // Saturate at the maximum 16-bit value.
                if (detection_count != 16'hFFFF)
                    detection_count <= detection_count + 1'b1;
            end

            // Clear only after the sensor has reported that the flame is gone.
            if (acknowledge && !flame_detected)
                alarm_active <= 1'b0;
        end
    end

endmodule
