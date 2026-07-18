`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: pmod_tof_distance_controller
//
// Pmod ToF complete distance controller
//
// This module extends the previously verified initialization + IRQ controller.
// The proven sequence is preserved:
//   1. Write the eight Digilent initialization registers.
//   2. Read the 16-byte user calibration structure from EEPROM.
//   3. Validate magic byte and checksum.
//   4. Load 13 calibration bytes into ISL29501 registers 0x24-0x30.
//   5. Configure distance-measurement mode.
//   6. Trigger a measurement with SS and wait for active-low IRQ.
//
// After IRQ asserts, this version:
//   7. Reads distance MSB register 0xD1.
//   8. Reads distance LSB register 0xD2.
//   9. Converts the 16-bit raw result to centimeters.
//  10. Repeats measurements continuously.
//
// Digilent distance formula:
//   distance_meters = raw / 65536 * 33.31
//
// Therefore:
//   distance_cm = raw * 3331 / 65536
//
// Device addresses:
//   ISL29501 ToF processor : 7'h57
//   AT24C04D EEPROM        : 7'h50
//
// Calibration structure stored at EEPROM address 0x10:
//   byte 0      : magic value 0xEB
//   bytes 1-13 : calibration values for ISL29501 registers 0x24-0x30
//   byte 14     : checksum
//   byte 15     : dummy/padding byte
//
// The checksum is the 8-bit sum of all 16 bytes with byte 14 treated as zero.
//
// Hardware measurement handshake:
//   - The FPGA drives SS low for 5.600 ms.
//   - SS then returns high for 14.400 ms.
//   - The sensor asserts active-low IRQ when the measurement is complete.
//   - Registers 0xD1 and 0xD2 contain the resulting 16-bit distance code.
//
// Status codes:
//   E001 initialization register write failure
//   E002 EEPROM read failure
//   E003 invalid calibration magic/checksum
//   E004 calibration-register write failure
//   E005 measurement-mode I2C failure
//   E006 IRQ remained low before starting a new measurement
//   E007 IRQ did not assert after SS was pulsed
//   E008 distance-register read failure
//////////////////////////////////////////////////////////////////////////////////

module pmod_tof_distance_controller #(
    parameter integer CLK_FREQ_HZ = 100_000_000
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        irq_n,
    output reg         ss,

    output reg         i2c_start,
    output reg         i2c_rw,
    output reg  [6:0]  i2c_device_addr,
    output reg  [7:0]  i2c_register_addr,
    output reg  [7:0]  i2c_write_data,
    input  wire [7:0]  i2c_read_data,
    input  wire        i2c_busy,
    input  wire        i2c_done,
    input  wire        i2c_ack_error,

    output reg  [15:0] raw_distance,
    output reg  [13:0] distance_cm,
    output reg         measurement_valid,
    output reg         sample_strobe,
    output reg  [15:0] status_code,
    output reg         error
);

    // ---------------------------------------------------------------------
    // I2C device addresses
    // ---------------------------------------------------------------------
    localparam [6:0] TOF_ADDR    = 7'h57;
    localparam [6:0] EEPROM_ADDR = 7'h50;

    // ---------------------------------------------------------------------
    // Timing constants derived from the 100 MHz system clock
    // ---------------------------------------------------------------------
    localparam integer POWERUP_COUNT   = CLK_FREQ_HZ / 10; // 100 ms
    localparam integer SS_LOW_COUNT    = 560_000;          // 5.600 ms
    localparam integer SS_HIGH_COUNT   = 1_440_000;        // 14.400 ms
    localparam integer IRQ_TIMEOUT     = CLK_FREQ_HZ / 2;  // 500 ms
    localparam integer SAMPLE_INTERVAL = CLK_FREQ_HZ / 20; // 50 ms pause

    // ---------------------------------------------------------------------
    // Main controller states
    // ---------------------------------------------------------------------
    // Most I2C operations use an ISSUE state to launch a command and a WAIT
    // state to receive the master's done/ack_error response.
    localparam [5:0]
        ST_POWERUP          = 6'd0,
        ST_INIT_ISSUE       = 6'd1,
        ST_INIT_WAIT        = 6'd2,
        ST_EEPROM_ISSUE     = 6'd3,
        ST_EEPROM_WAIT      = 6'd4,
        ST_VALIDATE         = 6'd5,
        ST_CAL_ISSUE        = 6'd6,
        ST_CAL_WAIT         = 6'd7,
        ST_MODE13_ISSUE     = 6'd8,
        ST_MODE13_WAIT      = 6'd9,
        ST_MODE60_ISSUE     = 6'd10,
        ST_MODE60_WAIT      = 6'd11,
        ST_REG69_ISSUE      = 6'd12,
        ST_REG69_WAIT       = 6'd13,
        ST_WAIT_IRQ_HIGH    = 6'd14,
        ST_SS_LOW           = 6'd15,
        ST_SS_HIGH_DELAY    = 6'd16,
        ST_WAIT_IRQ_LOW     = 6'd17,
        ST_READ_D1_ISSUE    = 6'd18,
        ST_READ_D1_WAIT     = 6'd19,
        ST_READ_D2_ISSUE    = 6'd20,
        ST_READ_D2_WAIT     = 6'd21,
        ST_CONVERT          = 6'd22,
        ST_SAMPLE_INTERVAL  = 6'd23,
        ST_FAIL             = 6'd24;

    // ---------------------------------------------------------------------
    // State-machine storage and calibration workspace
    // ---------------------------------------------------------------------
    reg [5:0]  state;
    reg [27:0] timer;
    reg [3:0]  init_index;
    reg [4:0]  eeprom_index;
    reg [4:0]  cal_index;
    reg [7:0]  checksum;
    reg [7:0]  calibration [0:15];
    reg [7:0]  distance_msb;
    reg [31:0] scaled_distance;

    integer i;

    // Maps an initialization-table index to the corresponding ISL29501
    // register address.
    function [7:0] init_reg;
        input [3:0] n;
        begin
            case (n)
                4'd0: init_reg = 8'h10;
                4'd1: init_reg = 8'h11;
                4'd2: init_reg = 8'h13;
                4'd3: init_reg = 8'h60;
                4'd4: init_reg = 8'h18;
                4'd5: init_reg = 8'h19;
                4'd6: init_reg = 8'h90;
                default: init_reg = 8'h91;
            endcase
        end
    endfunction

    // Maps the same initialization-table index to Digilent's required data.
    function [7:0] init_data;
        input [3:0] n;
        begin
            case (n)
                4'd0: init_data = 8'h04;
                4'd1: init_data = 8'h6E;
                4'd2: init_data = 8'h71;
                4'd3: init_data = 8'h01;
                4'd4: init_data = 8'h22;
                4'd5: init_data = 8'h22;
                4'd6: init_data = 8'h0F;
                default: init_data = 8'hFF;
            endcase
        end
    endfunction

    // ---------------------------------------------------------------------
    // Initialization and continuous-measurement state machine
    // ---------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            // Restore all control outputs, counters, stored calibration values,
            // and measurement-valid flags to their startup conditions.
            state             <= ST_POWERUP;
            timer             <= 0;
            init_index        <= 0;
            eeprom_index      <= 0;
            cal_index         <= 0;
            checksum          <= 0;
            ss                <= 1'b1;
            i2c_start         <= 1'b0;
            i2c_rw            <= 1'b0;
            i2c_device_addr   <= TOF_ADDR;
            i2c_register_addr <= 0;
            i2c_write_data    <= 0;
            raw_distance      <= 0;
            distance_cm       <= 0;
            measurement_valid <= 1'b0;
            sample_strobe     <= 1'b0;
            status_code       <= 16'h0000;
            error             <= 1'b0;
            distance_msb      <= 0;
            scaled_distance   <= 0;

            for (i = 0; i < 16; i = i + 1)
                calibration[i] <= 0;
        end else begin
            i2c_start     <= 1'b0;
            sample_strobe <= 1'b0;

            case (state)
                // Allow the Pmod electronics and I2C devices to settle after reset.
                ST_POWERUP: begin
                    status_code <= 16'h0000;
                    if (timer == POWERUP_COUNT - 1) begin
                        timer      <= 0;
                        init_index <= 0;
                        state      <= ST_INIT_ISSUE;
                    end else
                        timer <= timer + 1'b1;
                end

                // Launch one write from the eight-entry Digilent initialization table.
                ST_INIT_ISSUE: begin
                    status_code <= {8'h10, 4'h0, init_index};
                    if (!i2c_busy) begin
                        i2c_device_addr   <= TOF_ADDR;
                        i2c_rw            <= 1'b0;
                        i2c_register_addr <= init_reg(init_index);
                        i2c_write_data    <= init_data(init_index);
                        i2c_start         <= 1'b1;
                        state             <= ST_INIT_WAIT;
                    end
                end

                // Wait for completion of the current initialization-register write.
                ST_INIT_WAIT: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            status_code <= 16'hE001;
                            state <= ST_FAIL;
                        end else if (init_index == 4'd7) begin
                            eeprom_index <= 0;
                            checksum <= 0;
                            state <= ST_EEPROM_ISSUE;
                        end else begin
                            init_index <= init_index + 1'b1;
                            state <= ST_INIT_ISSUE;
                        end
                    end
                end

                // Read one byte from the 16-byte user calibration block.
                ST_EEPROM_ISSUE: begin
                    status_code <= {8'h20, 3'b000, eeprom_index};
                    if (!i2c_busy) begin
                        i2c_device_addr   <= EEPROM_ADDR;
                        i2c_rw            <= 1'b1;
                        i2c_register_addr <= 8'h10 + eeprom_index[3:0];
                        i2c_write_data    <= 8'h00;
                        i2c_start         <= 1'b1;
                        state             <= ST_EEPROM_WAIT;
                    end
                end

                // Store the returned EEPROM byte and accumulate the checksum.
                ST_EEPROM_WAIT: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            status_code <= 16'hE002;
                            state <= ST_FAIL;
                        end else begin
                            calibration[eeprom_index] <= i2c_read_data;

                            // Store each byte in its exact packed-structure
                            // position while calculating the expected checksum.
                            // Exact packed structure:
                            // byte 0 magic, bytes 1-13 regs,
                            // byte 14 CRC, byte 15 dummy.
                            if (eeprom_index != 5'd14)
                                checksum <= checksum + i2c_read_data;

                            if (eeprom_index == 5'd15)
                                state <= ST_VALIDATE;
                            else begin
                                eeprom_index <= eeprom_index + 1'b1;
                                state <= ST_EEPROM_ISSUE;
                            end
                        end
                    end
                end

                // Verify the 0xEB magic byte and the packed-structure checksum.
                ST_VALIDATE: begin
                    status_code <= {calibration[14], checksum};
                    if ((calibration[0] == 8'hEB) &&
                        (calibration[14] == checksum)) begin
                        cal_index <= 0;
                        state <= ST_CAL_ISSUE;
                    end else begin
                        status_code <= 16'hE003;
                        state <= ST_FAIL;
                    end
                end

                // Write one stored calibration byte into ISL29501 register 0x24-0x30.
                ST_CAL_ISSUE: begin
                    status_code <= {8'h30, 3'b000, cal_index};
                    if (!i2c_busy) begin
                        i2c_device_addr   <= TOF_ADDR;
                        i2c_rw            <= 1'b0;
                        i2c_register_addr <= 8'h24 + cal_index;
                        i2c_write_data    <= calibration[cal_index + 1'b1];
                        i2c_start         <= 1'b1;
                        state             <= ST_CAL_WAIT;
                    end
                end

                // Wait for the current calibration-register write to complete.
                ST_CAL_WAIT: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            status_code <= 16'hE004;
                            state <= ST_FAIL;
                        end else if (cal_index == 5'd12)
                            state <= ST_MODE13_ISSUE;
                        else begin
                            cal_index <= cal_index + 1'b1;
                            state <= ST_CAL_ISSUE;
                        end
                    end
                end

                // Select distance-measurement operating mode in register 0x13.
                ST_MODE13_ISSUE: begin
                    status_code <= 16'h4013;
                    if (!i2c_busy) begin
                        i2c_device_addr   <= TOF_ADDR;
                        i2c_rw            <= 1'b0;
                        i2c_register_addr <= 8'h13;
                        i2c_write_data    <= 8'h7D;
                        i2c_start         <= 1'b1;
                        state             <= ST_MODE13_WAIT;
                    end
                end

                ST_MODE13_WAIT: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            status_code <= 16'hE005;
                            state <= ST_FAIL;
                        end else
                            state <= ST_MODE60_ISSUE;
                    end
                end

                // Enable the required measurement setting in register 0x60.
                ST_MODE60_ISSUE: begin
                    status_code <= 16'h4060;
                    if (!i2c_busy) begin
                        i2c_device_addr   <= TOF_ADDR;
                        i2c_rw            <= 1'b0;
                        i2c_register_addr <= 8'h60;
                        i2c_write_data    <= 8'h01;
                        i2c_start         <= 1'b1;
                        state             <= ST_MODE60_WAIT;
                    end
                end

                ST_MODE60_WAIT: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            status_code <= 16'hE005;
                            state <= ST_FAIL;
                        end else
                            state <= ST_REG69_ISSUE;
                    end
                end

                // Perform Digilent's required dummy read of register 0x69.
                ST_REG69_ISSUE: begin
                    status_code <= 16'h4069;
                    if (!i2c_busy) begin
                        i2c_device_addr   <= TOF_ADDR;
                        i2c_rw            <= 1'b1;
                        i2c_register_addr <= 8'h69;
                        i2c_write_data    <= 8'h00;
                        i2c_start         <= 1'b1;
                        state             <= ST_REG69_WAIT;
                    end
                end

                ST_REG69_WAIT: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            status_code <= 16'hE005;
                            state <= ST_FAIL;
                        end else begin
                            timer <= 0;
                            state <= ST_WAIT_IRQ_HIGH;
                        end
                    end
                end

                // Confirm IRQ is inactive before beginning a fresh measurement.
                ST_WAIT_IRQ_HIGH: begin
                    status_code <= 16'h5000;
                    if (irq_n) begin
                        timer <= 0;
                        ss <= 1'b0;
                        state <= ST_SS_LOW;
                    end else if (timer == IRQ_TIMEOUT - 1) begin
                        status_code <= 16'hE006;
                        state <= ST_FAIL;
                    end else
                        timer <= timer + 1'b1;
                end

                // Hold Sample Start low for exactly 5.600 ms.
                ST_SS_LOW: begin
                    status_code <= 16'h5056;
                    if (timer == SS_LOW_COUNT - 1) begin
                        timer <= 0;
                        ss <= 1'b1;
                        state <= ST_SS_HIGH_DELAY;
                    end else
                        timer <= timer + 1'b1;
                end

                // Return SS high and complete the 20 ms trigger period.
                ST_SS_HIGH_DELAY: begin
                    status_code <= 16'h5144;
                    if (timer == SS_HIGH_COUNT - 1) begin
                        timer <= 0;
                        state <= ST_WAIT_IRQ_LOW;
                    end else
                        timer <= timer + 1'b1;
                end

                // Wait for active-low IRQ to indicate that data is ready.
                ST_WAIT_IRQ_LOW: begin
                    status_code <= 16'h6000;
                    if (!irq_n) begin
                        timer <= 0;
                        state <= ST_READ_D1_ISSUE;
                    end else if (timer == IRQ_TIMEOUT - 1) begin
                        status_code <= 16'hE007;
                        state <= ST_FAIL;
                    end else
                        timer <= timer + 1'b1;
                end

                // Read the most-significant distance byte from register 0xD1.
                ST_READ_D1_ISSUE: begin
                    status_code <= 16'h70D1;
                    if (!i2c_busy) begin
                        i2c_device_addr   <= TOF_ADDR;
                        i2c_rw            <= 1'b1;
                        i2c_register_addr <= 8'hD1;
                        i2c_write_data    <= 8'h00;
                        i2c_start         <= 1'b1;
                        state             <= ST_READ_D1_WAIT;
                    end
                end

                ST_READ_D1_WAIT: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            status_code <= 16'hE008;
                            state <= ST_FAIL;
                        end else begin
                            distance_msb <= i2c_read_data;
                            state <= ST_READ_D2_ISSUE;
                        end
                    end
                end

                // Read the least-significant distance byte from register 0xD2.
                ST_READ_D2_ISSUE: begin
                    status_code <= 16'h70D2;
                    if (!i2c_busy) begin
                        i2c_device_addr   <= TOF_ADDR;
                        i2c_rw            <= 1'b1;
                        i2c_register_addr <= 8'hD2;
                        i2c_write_data    <= 8'h00;
                        i2c_start         <= 1'b1;
                        state             <= ST_READ_D2_WAIT;
                    end
                end

                ST_READ_D2_WAIT: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            status_code <= 16'hE008;
                            state <= ST_FAIL;
                        end else begin
                            // Preserve the raw 16-bit result for debugging and
                            // form raw * 3331 for the centimeter conversion.
                            raw_distance    <= {distance_msb, i2c_read_data};
                            scaled_distance <= {distance_msb, i2c_read_data} * 32'd3331;
                            state <= ST_CONVERT;
                        end
                    end
                end

                // Publish centimeters by dividing the scaled product by 65536.
                ST_CONVERT: begin
                    // Division by 65536 is a right shift by 16 bits. Bits
                    // [29:16] contain the useful whole-centimeter result.
                    distance_cm       <= scaled_distance[29:16];
                    measurement_valid <= 1'b1;
                    sample_strobe     <= 1'b1;
                    timer             <= 0;
                    state             <= ST_SAMPLE_INTERVAL;
                end

                // Pause briefly before initiating the next measurement cycle.
                ST_SAMPLE_INTERVAL: begin
                    if (timer == SAMPLE_INTERVAL - 1) begin
                        timer <= 0;
                        state <= ST_REG69_ISSUE;
                    end else
                        timer <= timer + 1'b1;
                end

                // Latch the controller in a safe error state until reset.
                ST_FAIL: begin
                    error <= 1'b1;
                    ss <= 1'b1;
                end

                default: begin
                    status_code <= 16'hE0FF;
                    state <= ST_FAIL;
                end
            endcase
        end
    end
endmodule
