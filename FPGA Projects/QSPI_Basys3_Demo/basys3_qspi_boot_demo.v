`timescale 1ns / 1ps
//==============================================================================
// Basys 3 QSPI Boot Demonstration
//------------------------------------------------------------------------------
// Purpose:
//   Drives the 16 onboard LEDs as a "Knight Rider" scanner.
//
// Hardware:
//   Digilent Basys 3
//   100 MHz onboard clock
//   16 onboard LEDs
//   Center pushbutton provides a synchronous reset
//
// Notes:
//   No user HDL connection to the QSPI pins is required. During normal boot,
//   the Artix-7 configuration circuitry reads the flash automatically.
//==============================================================================

module basys3_qspi_boot_demo (
    input  wire        clk,       // 100 MHz onboard oscillator
    input  wire        btnC,      // Center button: restart scanner at LED0
    output reg  [15:0] led
);

    // 100 MHz / 6,250,000 = 16 Hz counter event.
    // Because the LED moves once per terminal count, the visible scanner
    // advances 16 positions per second.
    localparam integer STEP_COUNT_MAX = 6_250_000 - 1;

    reg [22:0] step_counter = 23'd0;
    reg [3:0]  position     = 4'd0;
    reg        direction    = 1'b0;  // 0 = toward LED15, 1 = toward LED0

    always @(posedge clk) begin
        if (btnC) begin
            step_counter <= 23'd0;
            position     <= 4'd0;
            direction    <= 1'b0;
        end else if (step_counter == STEP_COUNT_MAX) begin
            step_counter <= 23'd0;

            if (!direction) begin
                if (position == 4'd15) begin
                    position  <= 4'd14;
                    direction <= 1'b1;
                end else begin
                    position <= position + 1'b1;
                end
            end else begin
                if (position == 4'd0) begin
                    position  <= 4'd1;
                    direction <= 1'b0;
                end else begin
                    position <= position - 1'b1;
                end
            end
        end else begin
            step_counter <= step_counter + 1'b1;
        end
    end

    // Decode the current position into a one-hot LED pattern.
    always @* begin
        led = 16'b0000_0000_0000_0001 << position;
    end

endmodule
