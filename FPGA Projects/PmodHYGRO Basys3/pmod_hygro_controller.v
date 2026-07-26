`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: pmod_hygro_controller
//
// Device:
//   Digilent Pmod HYGRO using the Texas Instruments HDC1080.
//
// Purpose:
//   Controls the complete measurement sequence, captures four returned bytes,
//   converts raw data into engineering units, and reports status to the rest of
//   the design.
//
// Pmod HYGRO / HDC1080 Controller
//
// Measurement sequence:
//   1. Wait at least 15 ms after power-up.
//   2. START + write slave address 0x40 with W bit.
//   3. Write pointer register 0x00 to trigger temperature measurement.
//      The HDC1080 default MODE bit causes temperature and humidity to be
//      measured sequentially.
//   4. STOP and wait longer than the required 12.85 ms conversion time.
//   5. START + write slave address 0x40 with R bit.
//   6. Read four bytes:
//        temperature MSB, temperature LSB,
//        humidity MSB, humidity LSB.
//   7. Wait at least one second before starting another measurement.
//
// Raw conversion formulas:
//   Temperature C = raw * 165 / 65536 - 40
//   Humidity %RH  = raw * 100 / 65536
//
// Outputs are scaled by ten:
//   234 = 23.4 degrees C
//   456 = 45.6 %RH
//////////////////////////////////////////////////////////////////////////////////

(* keep_hierarchy = "yes" *) module pmod_hygro_controller #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000
)(
    input  wire        clk,
    input  wire        reset,

    output wire        hyg_scl,
    inout  wire        hyg_sda,

    output reg  [15:0] raw_temperature,
    output reg  [15:0] raw_humidity,

    output reg  signed [15:0] temperature_c_tenths,
    output reg  signed [15:0] temperature_f_tenths,
    output reg         [15:0] humidity_tenths,

    output reg         data_valid,
    output reg         sensor_error,
    output reg         measurement_pulse
);

    // Commands understood by the low-level I2C engine.
    localparam [2:0] CMD_START     = 3'd0;
    localparam [2:0] CMD_STOP      = 3'd1;
    localparam [2:0] CMD_WRITE     = 3'd2;
    localparam [2:0] CMD_READ_ACK  = 3'd3;
    localparam [2:0] CMD_READ_NACK = 3'd4;

    // Fixed HDC1080 7-bit address 0x40 plus the R/W bit.
    localparam [7:0] HYGRO_WRITE_ADDRESS = 8'h80;
    localparam [7:0] HYGRO_READ_ADDRESS  = 8'h81;
    localparam [7:0] TEMPERATURE_POINTER = 8'h00;

    // Conservative startup, conversion, and sample-spacing delays.
    localparam integer POWERUP_WAIT_CYCLES =
        CLOCK_FREQ_HZ / 50;       // 20 ms

    localparam integer CONVERSION_WAIT_CYCLES =
        CLOCK_FREQ_HZ / 50;       // 20 ms, safely above 12.85 ms

    localparam integer SAMPLE_WAIT_CYCLES =
        CLOCK_FREQ_HZ;            // 1 second

    // High-level sensor transaction states.
    localparam [5:0] ST_POWERUP_WAIT  = 6'd0;
    localparam [5:0] ST_START_WRITE   = 6'd1;
    localparam [5:0] ST_SEND_ADDR_W   = 6'd2;
    localparam [5:0] ST_SEND_POINTER  = 6'd3;
    localparam [5:0] ST_STOP_TRIGGER  = 6'd4;
    localparam [5:0] ST_CONVERT_WAIT  = 6'd5;
    localparam [5:0] ST_START_READ    = 6'd6;
    localparam [5:0] ST_SEND_ADDR_R   = 6'd7;
    localparam [5:0] ST_READ_TEMP_MSB = 6'd8;
    localparam [5:0] ST_READ_TEMP_LSB = 6'd9;
    localparam [5:0] ST_READ_HUM_MSB  = 6'd10;
    localparam [5:0] ST_READ_HUM_LSB  = 6'd11;
    localparam [5:0] ST_STOP_READ     = 6'd12;
    localparam [5:0] ST_CALC_SCALE   = 6'd13;
    localparam [5:0] ST_CALC_CONVERT = 6'd14;
    localparam [5:0] ST_CALC_COMMIT  = 6'd15;
    localparam [5:0] ST_SAMPLE_WAIT  = 6'd16;
    localparam [5:0] ST_RECOVERY_STOP = 6'd17;

    // Measurement-sequencer state and delay counter.
    reg [5:0] state;
    reg [31:0] wait_counter;

    // Interface to the reusable I2C command engine.
    reg        command_valid;
    reg [2:0]  command;
    reg [7:0]  tx_data;
    wire [7:0] rx_data;
    wire       i2c_busy;
    wire       i2c_done;
    wire       i2c_ack_error;

    reg command_issued;

    // Four bytes received in MSB-first order.
    reg [7:0] temp_msb;
    reg [7:0] temp_lsb;
    reg [7:0] hum_msb;
    reg [7:0] hum_lsb;

    // Pipelined fixed-point arithmetic:
    //   C_tenths  = raw_temperature * 1650 / 65536 - 400
    //   F_tenths  = raw_temperature * 2970 / 65536 - 400
    //   RH_tenths = raw_humidity    * 1000 / 65536
    //
    // Division by 65536 is implemented by selecting bits [31:16].
    reg [31:0] temp_c_scaled;
    reg [31:0] temp_f_scaled;
    reg [31:0] hum_scaled;
    reg signed [15:0] temp_c_pipeline;
    reg signed [15:0] temp_f_pipeline;

    i2c_master #(
        .CLOCK_FREQ_HZ(CLOCK_FREQ_HZ),
        .I2C_FREQ_HZ(100_000)
    ) i2c_bus (
        .clk(clk),
        .reset(reset),
        .command_valid(command_valid),
        .command(command),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .busy(i2c_busy),
        .done(i2c_done),
        .ack_error(i2c_ack_error),
        .scl(hyg_scl),
        .sda(hyg_sda)
    );

    // Launch exactly one command; command_issued prevents repeated launches.
    task launch_command;
        input [2:0] requested_command;
        input [7:0] requested_data;
        begin
            if (!command_issued && !i2c_busy) begin
                command        <= requested_command;
                tx_data        <= requested_data;
                command_valid  <= 1'b1;
                command_issued <= 1'b1;
            end
        end
    endtask

    always @(posedge clk) begin
        if (reset) begin
            state                  <= ST_POWERUP_WAIT;
            wait_counter           <= 32'd0;
            command_valid          <= 1'b0;
            command                <= CMD_START;
            tx_data                <= 8'd0;
            command_issued         <= 1'b0;

            temp_msb               <= 8'd0;
            temp_lsb               <= 8'd0;
            hum_msb                <= 8'd0;
            hum_lsb                <= 8'd0;

            raw_temperature        <= 16'd0;
            raw_humidity           <= 16'd0;
            temperature_c_tenths   <= 16'sd0;
            temperature_f_tenths   <= 16'sd0;
            humidity_tenths        <= 16'd0;

            temp_c_scaled          <= 32'd0;
            temp_f_scaled          <= 32'd0;
            hum_scaled             <= 32'd0;
            temp_c_pipeline        <= 16'sd0;
            temp_f_pipeline        <= 16'sd0;

            data_valid             <= 1'b0;
            sensor_error           <= 1'b0;
            measurement_pulse      <= 1'b0;
        end else begin
            command_valid     <= 1'b0;
            measurement_pulse <= 1'b0;

            case (state)
                // Wait for sensor startup.
                ST_POWERUP_WAIT: begin
                    if (wait_counter >= POWERUP_WAIT_CYCLES - 1) begin
                        wait_counter   <= 32'd0;
                        command_issued <= 1'b0;
                        state          <= ST_START_WRITE;
                    end else begin
                        wait_counter <= wait_counter + 1'b1;
                    end
                end

                // Begin pointer-write transaction.
                ST_START_WRITE: begin
                    launch_command(CMD_START, 8'h00);
                    if (i2c_done && command_issued) begin
                        command_issued <= 1'b0;
                        state          <= ST_SEND_ADDR_W;
                    end
                end

                // Send sensor address with write bit.
                ST_SEND_ADDR_W: begin
                    launch_command(CMD_WRITE, HYGRO_WRITE_ADDRESS);
                    if (i2c_done && command_issued) begin
                        command_issued <= 1'b0;
                        if (i2c_ack_error) begin
                            sensor_error <= 1'b1;
                            state        <= ST_RECOVERY_STOP;
                        end else begin
                            state <= ST_SEND_POINTER;
                        end
                    end
                end

                // Pointer 0x00 triggers temperature then humidity.
                ST_SEND_POINTER: begin
                    launch_command(CMD_WRITE, TEMPERATURE_POINTER);
                    if (i2c_done && command_issued) begin
                        command_issued <= 1'b0;
                        if (i2c_ack_error) begin
                            sensor_error <= 1'b1;
                            state        <= ST_RECOVERY_STOP;
                        end else begin
                            state <= ST_STOP_TRIGGER;
                        end
                    end
                end

                ST_STOP_TRIGGER: begin
                    launch_command(CMD_STOP, 8'h00);
                    if (i2c_done && command_issued) begin
                        command_issued <= 1'b0;
                        wait_counter   <= 32'd0;
                        state          <= ST_CONVERT_WAIT;
                    end
                end

                // Wait for both 14-bit conversions.
                ST_CONVERT_WAIT: begin
                    if (wait_counter >= CONVERSION_WAIT_CYCLES - 1) begin
                        wait_counter   <= 32'd0;
                        command_issued <= 1'b0;
                        state          <= ST_START_READ;
                    end else begin
                        wait_counter <= wait_counter + 1'b1;
                    end
                end

                ST_START_READ: begin
                    launch_command(CMD_START, 8'h00);
                    if (i2c_done && command_issued) begin
                        command_issued <= 1'b0;
                        state          <= ST_SEND_ADDR_R;
                    end
                end

                // Send sensor address with read bit.
                ST_SEND_ADDR_R: begin
                    launch_command(CMD_WRITE, HYGRO_READ_ADDRESS);
                    if (i2c_done && command_issued) begin
                        command_issued <= 1'b0;
                        if (i2c_ack_error) begin
                            sensor_error <= 1'b1;
                            state        <= ST_RECOVERY_STOP;
                        end else begin
                            state <= ST_READ_TEMP_MSB;
                        end
                    end
                end

                // Read temperature MSB; ACK for more data.
                ST_READ_TEMP_MSB: begin
                    launch_command(CMD_READ_ACK, 8'h00);
                    if (i2c_done && command_issued) begin
                        temp_msb       <= rx_data;
                        command_issued <= 1'b0;
                        state          <= ST_READ_TEMP_LSB;
                    end
                end

                // Read temperature LSB; ACK for more data.
                ST_READ_TEMP_LSB: begin
                    launch_command(CMD_READ_ACK, 8'h00);
                    if (i2c_done && command_issued) begin
                        temp_lsb       <= rx_data;
                        command_issued <= 1'b0;
                        state          <= ST_READ_HUM_MSB;
                    end
                end

                // Read humidity MSB; ACK for final byte.
                ST_READ_HUM_MSB: begin
                    launch_command(CMD_READ_ACK, 8'h00);
                    if (i2c_done && command_issued) begin
                        hum_msb        <= rx_data;
                        command_issued <= 1'b0;
                        state          <= ST_READ_HUM_LSB;
                    end
                end

                // Read humidity LSB; NACK ends burst.
                ST_READ_HUM_LSB: begin
                    launch_command(CMD_READ_NACK, 8'h00);
                    if (i2c_done && command_issued) begin
                        hum_lsb        <= rx_data;
                        command_issued <= 1'b0;
                        state          <= ST_STOP_READ;
                    end
                end

                ST_STOP_READ: begin
                    launch_command(CMD_STOP, 8'h00);
                    if (i2c_done && command_issued) begin
                        command_issued  <= 1'b0;
                        raw_temperature <= {temp_msb, temp_lsb};
                        raw_humidity    <= {hum_msb, hum_lsb};
                        state           <= ST_CALC_SCALE;
                    end
                end

                // Stage 1: scale each raw sensor value independently.
                //
                // Direct Fahrenheit derivation:
                //   F_tenths = raw * 2970 / 65536 - 400
                //
                // This avoids synthesizing a signed divide-by-five circuit.
                // Pipeline stage 1: multiply and round.
                ST_CALC_SCALE: begin
                    temp_c_scaled <= raw_temperature * 32'd1650 + 32'd32768;
                    temp_f_scaled <= raw_temperature * 32'd2970 + 32'd32768;
                    hum_scaled    <= raw_humidity    * 32'd1000 + 32'd32768;
                    state         <= ST_CALC_CONVERT;
                end

                // Stage 2: division by 65536 is a simple right shift.
                // Pipeline stage 2: shift and apply offsets.
                ST_CALC_CONVERT: begin
                    temp_c_pipeline <= $signed(temp_c_scaled[31:16]) - 16'sd400;
                    temp_f_pipeline <= $signed(temp_f_scaled[31:16]) - 16'sd400;
                    humidity_tenths <= hum_scaled[31:16];
                    state           <= ST_CALC_COMMIT;
                end

                // Stage 3: publish the completed readings together.
                // Publish all new measurements together.
                ST_CALC_COMMIT: begin
                    temperature_c_tenths <= temp_c_pipeline;
                    temperature_f_tenths <= temp_f_pipeline;

                    data_valid        <= 1'b1;
                    sensor_error      <= 1'b0;
                    measurement_pulse <= 1'b1;
                    wait_counter      <= 32'd0;
                    state             <= ST_SAMPLE_WAIT;
                end

                // One-second spacing reduces self-heating.
                ST_SAMPLE_WAIT: begin
                    if (wait_counter >= SAMPLE_WAIT_CYCLES - 1) begin
                        wait_counter   <= 32'd0;
                        command_issued <= 1'b0;
                        state          <= ST_START_WRITE;
                    end else begin
                        wait_counter <= wait_counter + 1'b1;
                    end
                end

                // Generate a STOP even if a slave NACK occurred, then retry later.
                // Cleanly stop after a NACK before retrying.
                ST_RECOVERY_STOP: begin
                    launch_command(CMD_STOP, 8'h00);
                    if (i2c_done && command_issued) begin
                        command_issued <= 1'b0;
                        wait_counter   <= 32'd0;
                        state          <= ST_SAMPLE_WAIT;
                    end
                end

                default: begin
                    state <= ST_POWERUP_WAIT;
                end
            endcase
        end
    end

endmodule
