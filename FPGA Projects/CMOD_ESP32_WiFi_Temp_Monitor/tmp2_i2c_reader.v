`timescale 1ns / 1ps
//==============================================================================
// Module:      tmp2_i2c_reader
// Project:     FPGA Wi-Fi Temperature Monitor
// Target:      Digilent Cmod A7 (12 MHz system clock)
// Sensor:      Digilent Pmod TMP2 / Analog Devices ADT7420
//
// Description:
//   Reads the TMP2 temperature register over I2C at a programmable sample rate.
//   The controller performs a direct two-byte read because the ADT7420 powers
//   up with its internal register pointer selecting the temperature register.
//
//   The returned 16-bit word is passed to the packet transmitter unchanged.
//   Temperature conversion is intentionally performed by the ESP32, allowing
//   the FPGA to focus on deterministic sensor communication and data transport.
//
// I2C transaction:
//   START
//   Address + Read (0x97)
//   ACK from sensor
//   Read MSB
//   ACK from FPGA
//   Read LSB
//   NACK from FPGA
//   STOP
//
// Electrical behavior:
//   I2C uses open-drain signaling. The FPGA only drives SCL or SDA LOW; a logic
//   HIGH is produced by releasing the line to high impedance. Pull-ups are
//   enabled in the XDC constraints.
//
// Outputs:
//   raw_temperature - Exact 16-bit ADT7420 temperature register word.
//   data_valid      - One-clock pulse after a complete successful read cycle.
//   sensor_error    - HIGH when the TMP2 fails to acknowledge its address.
//==============================================================================

module tmp2_i2c_reader #(
    parameter integer CLK_FREQ_HZ = 12_000_000,
    parameter integer I2C_FREQ_HZ = 100_000,
    parameter integer SAMPLE_HZ   = 1
)(
    input  wire        clk,
    input  wire        reset,

    inout  wire        i2c_scl,
    inout  wire        i2c_sda,

    output reg [15:0]  raw_temperature,
    output reg         data_valid,
    output reg         sensor_error
);

    //--------------------------------------------------------------------------
    // TMP2 / ADT7420 address
    //
    // The original working TMP2 configuration uses the 7-bit address 0x4B.
    // Appending the read bit produces the transmitted address byte 0x97.
    //--------------------------------------------------------------------------
    localparam [7:0] TMP2_ADDRESS_READ = 8'h97;

    // Four timing phases form one complete I2C clock:
    //   phase 0: SCL low, prepare SDA
    //   phase 1: release SCL high
    //   phase 2: sample or hold data while SCL is high
    //   phase 3: return SCL low and advance
    localparam integer QUARTER_CYCLES =
        CLK_FREQ_HZ / (I2C_FREQ_HZ * 4);

    // Number of system-clock cycles between temperature transactions.
    localparam integer SAMPLE_CYCLES =
        CLK_FREQ_HZ / SAMPLE_HZ;

    // Short power-up delay of approximately 100 ms.
    localparam integer POWER_WAIT_CYCLES =
        CLK_FREQ_HZ / 10;

    //--------------------------------------------------------------------------
    // Controller states
    //--------------------------------------------------------------------------
    localparam [3:0]
        ST_POWER_WAIT  = 4'd0,
        ST_START       = 4'd1,
        ST_SEND_ADDR   = 4'd2,
        ST_ADDR_ACK    = 4'd3,
        ST_READ_MSB    = 4'd4,
        ST_SEND_ACK    = 4'd5,
        ST_READ_LSB    = 4'd6,
        ST_SEND_NACK   = 4'd7,
        ST_STOP        = 4'd8,
        ST_STORE       = 4'd9,
        ST_SAMPLE_WAIT = 4'd10;

    reg [3:0] state;
    reg [1:0] phase;
    reg [2:0] bit_index;

    reg [15:0] quarter_counter;
    reg [31:0] sample_counter;

    reg [7:0] received_msb;
    reg [7:0] received_lsb;

    // Open-drain control flags:
    //   1 = actively pull the bus line LOW
    //   0 = release the line; pull-up creates HIGH
    reg scl_drive_low;
    reg sda_drive_low;

    wire sda_input = i2c_sda;

    assign i2c_scl = scl_drive_low ? 1'b0 : 1'bz;
    assign i2c_sda = sda_drive_low ? 1'b0 : 1'bz;

    wire quarter_tick =
        (quarter_counter == QUARTER_CYCLES - 1);

    //--------------------------------------------------------------------------
    // I2C phase timer
    //
    // The counter runs only during active bus transactions. It is held at zero
    // during the power-up delay, sample delay, and result-storage state.
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            quarter_counter <= 16'd0;
        end
        else if ((state == ST_POWER_WAIT)  ||
                 (state == ST_SAMPLE_WAIT) ||
                 (state == ST_STORE)) begin
            quarter_counter <= 16'd0;
        end
        else if (quarter_tick) begin
            quarter_counter <= 16'd0;
        end
        else begin
            quarter_counter <= quarter_counter + 1'b1;
        end
    end

    //--------------------------------------------------------------------------
    // I2C transaction state machine
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            state            <= ST_POWER_WAIT;
            phase            <= 2'd0;
            bit_index        <= 3'd7;
            sample_counter   <= 32'd0;
            received_msb     <= 8'h00;
            received_lsb     <= 8'h00;
            raw_temperature  <= 16'h0000;
            data_valid       <= 1'b0;
            sensor_error     <= 1'b0;
            scl_drive_low    <= 1'b0;
            sda_drive_low    <= 1'b0;
        end
        else begin
            // data_valid is a one-clock notification pulse.
            data_valid <= 1'b0;

            case (state)

                //------------------------------------------------------------------
                // Allow the TMP2 and the I2C pull-ups to settle after reset.
                //------------------------------------------------------------------
                ST_POWER_WAIT: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;

                    if (sample_counter == POWER_WAIT_CYCLES - 1) begin
                        sample_counter <= 32'd0;
                        phase          <= 2'd0;
                        state          <= ST_START;
                    end
                    else begin
                        sample_counter <= sample_counter + 1'b1;
                    end
                end

                //------------------------------------------------------------------
                // Generate START: SDA transitions HIGH-to-LOW while SCL is HIGH.
                //------------------------------------------------------------------
                ST_START: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd1;
                            end

                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd2;
                            end

                            2'd2: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd3;
                            end

                            default: begin
                                bit_index <= 3'd7;
                                phase     <= 2'd0;
                                state     <= ST_SEND_ADDR;
                            end
                        endcase
                    end
                end

                //------------------------------------------------------------------
                // Transmit the address byte 0x97, most-significant bit first.
                //------------------------------------------------------------------
                ST_SEND_ADDR: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                // Change SDA only while SCL is LOW.
                                scl_drive_low <= 1'b1;
                                sda_drive_low <=
                                    ~TMP2_ADDRESS_READ[bit_index];
                                phase <= 2'd1;
                            end

                            2'd1: begin
                                // Release SCL so the pull-up takes it HIGH.
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end

                            2'd2: begin
                                // Hold the transmitted bit stable while SCL is HIGH.
                                phase <= 2'd3;
                            end

                            default: begin
                                scl_drive_low <= 1'b1;

                                if (bit_index == 0) begin
                                    // Release SDA for the sensor ACK bit.
                                    sda_drive_low <= 1'b0;
                                    phase         <= 2'd0;
                                    state         <= ST_ADDR_ACK;
                                end
                                else begin
                                    bit_index <= bit_index - 1'b1;
                                    phase     <= 2'd0;
                                end
                            end
                        endcase
                    end
                end

                //------------------------------------------------------------------
                // Sample the sensor ACK. ACK is active LOW.
                //------------------------------------------------------------------
                ST_ADDR_ACK: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd1;
                            end

                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end

                            2'd2: begin
                                // SDA HIGH means the device did not acknowledge.
                                sensor_error <= sda_input;
                                phase        <= 2'd3;
                            end

                            default: begin
                                scl_drive_low <= 1'b1;
                                bit_index     <= 3'd7;
                                phase         <= 2'd0;
                                state         <= ST_READ_MSB;
                            end
                        endcase
                    end
                end

                //------------------------------------------------------------------
                // Receive the temperature-register MSB.
                //------------------------------------------------------------------
                ST_READ_MSB: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd1;
                            end

                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end

                            2'd2: begin
                                // Sample SDA near the middle of SCL HIGH.
                                received_msb[bit_index] <= sda_input;
                                phase                   <= 2'd3;
                            end

                            default: begin
                                scl_drive_low <= 1'b1;

                                if (bit_index == 0) begin
                                    phase <= 2'd0;
                                    state <= ST_SEND_ACK;
                                end
                                else begin
                                    bit_index <= bit_index - 1'b1;
                                    phase     <= 2'd0;
                                end
                            end
                        endcase
                    end
                end

                //------------------------------------------------------------------
                // ACK the first byte so the TMP2 sends the second byte.
                //------------------------------------------------------------------
                ST_SEND_ACK: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd1;
                            end

                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end

                            2'd2: begin
                                phase <= 2'd3;
                            end

                            default: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                bit_index     <= 3'd7;
                                phase         <= 2'd0;
                                state         <= ST_READ_LSB;
                            end
                        endcase
                    end
                end

                //------------------------------------------------------------------
                // Receive the temperature-register LSB.
                //------------------------------------------------------------------
                ST_READ_LSB: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd1;
                            end

                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end

                            2'd2: begin
                                received_lsb[bit_index] <= sda_input;
                                phase                   <= 2'd3;
                            end

                            default: begin
                                scl_drive_low <= 1'b1;

                                if (bit_index == 0) begin
                                    phase <= 2'd0;
                                    state <= ST_SEND_NACK;
                                end
                                else begin
                                    bit_index <= bit_index - 1'b1;
                                    phase     <= 2'd0;
                                end
                            end
                        endcase
                    end
                end

                //------------------------------------------------------------------
                // NACK the final byte by leaving SDA released during the ninth
                // clock. This tells the TMP2 that no additional byte is needed.
                //------------------------------------------------------------------
                ST_SEND_NACK: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd1;
                            end

                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end

                            2'd2: begin
                                phase <= 2'd3;
                            end

                            default: begin
                                scl_drive_low <= 1'b1;
                                phase         <= 2'd0;
                                state         <= ST_STOP;
                            end
                        endcase
                    end
                end

                //------------------------------------------------------------------
                // Generate STOP: SDA transitions LOW-to-HIGH while SCL is HIGH.
                //------------------------------------------------------------------
                ST_STOP: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd1;
                            end

                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd2;
                            end

                            2'd2: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd3;
                            end

                            default: begin
                                phase <= 2'd0;
                                state <= ST_STORE;
                            end
                        endcase
                    end
                end

                //------------------------------------------------------------------
                // Publish the complete word and notify downstream logic.
                //------------------------------------------------------------------
                ST_STORE: begin
                    raw_temperature <= {received_msb, received_lsb};
                    data_valid      <= 1'b1;
                    sample_counter  <= 32'd0;
                    state           <= ST_SAMPLE_WAIT;
                end

                //------------------------------------------------------------------
                // Keep the bus idle until the next scheduled measurement.
                //------------------------------------------------------------------
                ST_SAMPLE_WAIT: begin
                    scl_drive_low <= 1'b0;
                    sda_drive_low <= 1'b0;

                    if (sample_counter == SAMPLE_CYCLES - 1) begin
                        sample_counter <= 32'd0;
                        phase          <= 2'd0;
                        state          <= ST_START;
                    end
                    else begin
                        sample_counter <= sample_counter + 1'b1;
                    end
                end

                default: begin
                    state <= ST_POWER_WAIT;
                end
            endcase
        end
    end

endmodule
