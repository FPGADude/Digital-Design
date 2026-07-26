`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: i2c_master
//
// Purpose:
//   Reusable low-level I2C command engine for the Pmod HYGRO controller.
//
// Command interface:
//   A higher-level controller presents one command, pulses command_valid, and
//   waits for done. Commands include START, STOP, WRITE byte, READ with ACK,
//   and READ with NACK.
//
// Timing:
//   The system clock is divided into four clock-enable phases per I2C bit.
//   This keeps all logic synchronous to clk while producing a 100 kHz bus.
//
// Open-drain interface:
//   A logic high is never actively driven. Each bus line is either pulled low
//   or released to its external pull-up resistor.
//       drive_low = 1 : pull the line low
//       drive_low = 0 : release the line to high impedance
//
// SCL is output-only because this design does not use clock stretching.
// SDA is bidirectional because it carries both transmitted and received data.
//
// Status:
//   busy      remains high while a command is executing.
//   done      pulses for one system clock when the command finishes.
//   ack_error captures a slave NACK after a transmitted byte.
//////////////////////////////////////////////////////////////////////////////////

module i2c_master #(
    parameter integer CLOCK_FREQ_HZ = 100_000_000,
    parameter integer I2C_FREQ_HZ   = 100_000
)(
    input  wire       clk,
    input  wire       reset,

    input  wire       command_valid,
    input  wire [2:0] command,
    input  wire [7:0] tx_data,

    output reg  [7:0] rx_data,
    output reg        busy,
    output reg        done,
    output reg        ack_error,

    output wire       scl,
    inout  wire       sda
);

    // Command encodings shared with the sensor controller.
    localparam [2:0] CMD_START     = 3'd0;
    localparam [2:0] CMD_STOP      = 3'd1;
    localparam [2:0] CMD_WRITE     = 3'd2;
    localparam [2:0] CMD_READ_ACK  = 3'd3;
    localparam [2:0] CMD_READ_NACK = 3'd4;

    // Four equal phases form one complete I2C clock period.
    // At 100 MHz and 100 kHz, each phase lasts 250 system clocks.
    localparam integer QUARTER_COUNT =
        CLOCK_FREQ_HZ / (I2C_FREQ_HZ * 4);

    // Internal command-engine states.
    localparam [3:0] ST_IDLE       = 4'd0;
    localparam [3:0] ST_START      = 4'd1;
    localparam [3:0] ST_STOP       = 4'd2;
    localparam [3:0] ST_WRITE_BIT  = 4'd3;
    localparam [3:0] ST_WRITE_ACK  = 4'd4;
    localparam [3:0] ST_READ_BIT   = 4'd5;
    localparam [3:0] ST_READ_ACK   = 4'd6;

    // Registers that retain the active command and byte.
    reg [3:0]  state;
    reg [2:0]  active_command;
    reg [7:0]  shift_reg;
    reg [2:0]  bit_index;
    reg [1:0]  phase;

    reg [15:0] quarter_counter;
    reg        quarter_tick;

    // Open-drain output-enable controls.
    reg scl_drive_low;
    reg sda_drive_low;

    // Tri-state assignments implement open-drain signaling.
    assign scl = scl_drive_low ? 1'b0 : 1'bz;
    assign sda = sda_drive_low ? 1'b0 : 1'bz;

    // Synchronize the externally driven SDA level before sampling it.
    reg sda_meta;
    reg sda_sync;

    always @(posedge clk) begin
        if (reset) begin
            sda_meta <= 1'b1;
            sda_sync <= 1'b1;
        end else begin
            sda_meta <= sda;
            sda_sync <= sda_meta;
        end
    end

    wire sda_in = sda_sync;

    // Generate one clock-enable pulse per quarter of an I2C bit period.
    // No fabric-generated clock is created.
    always @(posedge clk) begin
        if (reset) begin
            quarter_counter <= 16'd0;
            quarter_tick    <= 1'b0;
        end else begin
            quarter_tick <= 1'b0;

            if (busy) begin
                if (quarter_counter == QUARTER_COUNT - 1) begin
                    quarter_counter <= 16'd0;
                    quarter_tick    <= 1'b1;
                end else begin
                    quarter_counter <= quarter_counter + 1'b1;
                end
            end else begin
                quarter_counter <= 16'd0;
            end
        end
    end

    // Main I2C command state machine.
    // For byte transfers:
    //   phase 0: SCL low; prepare SDA
    //   phase 1: release SCL high
    //   phase 2: hold high and sample SDA when receiving
    //   phase 3: pull SCL low and advance
    always @(posedge clk) begin
        if (reset) begin
            state          <= ST_IDLE;
            active_command <= CMD_START;
            shift_reg      <= 8'd0;
            rx_data        <= 8'd0;
            bit_index      <= 3'd7;
            phase          <= 2'd0;
            busy           <= 1'b0;
            done           <= 1'b0;
            ack_error      <= 1'b0;
            scl_drive_low  <= 1'b0;
            sda_drive_low  <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;

                    if (command_valid) begin
                        active_command <= command;
                        shift_reg      <= tx_data;
                        bit_index      <= 3'd7;
                        phase          <= 2'd0;
                        busy           <= 1'b1;

                        case (command)
                            CMD_START: begin
                                state <= ST_START;
                            end

                            CMD_STOP: begin
                                state <= ST_STOP;
                            end

                            CMD_WRITE: begin
                                state <= ST_WRITE_BIT;
                            end

                            CMD_READ_ACK,
                            CMD_READ_NACK: begin
                                shift_reg <= 8'd0;
                                state     <= ST_READ_BIT;
                            end

                            default: begin
                                busy <= 1'b0;
                                done <= 1'b1;
                            end
                        endcase
                    end
                end

                // START: SDA transitions high-to-low while SCL is high.
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
                                sda_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end
                            2'd2: begin
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b1;
                                phase         <= 2'd3;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b1;
                                state         <= ST_IDLE;
                                busy          <= 1'b0;
                                done          <= 1'b1;
                            end
                        endcase
                    end
                end

                // STOP: SDA transitions low-to-high while SCL is high.
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
                                scl_drive_low <= 1'b0;
                                sda_drive_low <= 1'b0;
                                state         <= ST_IDLE;
                                busy          <= 1'b0;
                                done          <= 1'b1;
                            end
                        endcase
                    end
                end

                // Send one byte, MSB first.
                ST_WRITE_BIT: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= ~shift_reg[bit_index];
                                phase         <= 2'd1;
                            end
                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end
                            2'd2: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd3;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                phase         <= 2'd0;

                                if (bit_index == 0) begin
                                    sda_drive_low <= 1'b0;
                                    state         <= ST_WRITE_ACK;
                                end else begin
                                    bit_index <= bit_index - 1'b1;
                                end
                            end
                        endcase
                    end
                end

                // Release SDA so the slave can acknowledge the transmitted byte.
                ST_WRITE_ACK: begin
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
                                scl_drive_low <= 1'b0;
                                ack_error     <= sda_in;
                                phase         <= 2'd3;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                state         <= ST_IDLE;
                                busy          <= 1'b0;
                                done          <= 1'b1;
                            end
                        endcase
                    end
                end

                // Receive one byte, MSB first.
                ST_READ_BIT: begin
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
                                scl_drive_low       <= 1'b0;
                                shift_reg[bit_index] <= sda_in;
                                phase               <= 2'd3;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                phase         <= 2'd0;

                                if (bit_index == 0) begin
                                    state <= ST_READ_ACK;
                                end else begin
                                    bit_index <= bit_index - 1'b1;
                                end
                            end
                        endcase
                    end
                end

                // Send ACK after bytes 1-3, or NACK after the final byte.
                ST_READ_ACK: begin
                    if (quarter_tick) begin
                        case (phase)
                            2'd0: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <=
                                    (active_command == CMD_READ_ACK);
                                phase <= 2'd1;
                            end
                            2'd1: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd2;
                            end
                            2'd2: begin
                                scl_drive_low <= 1'b0;
                                phase         <= 2'd3;
                            end
                            default: begin
                                scl_drive_low <= 1'b1;
                                sda_drive_low <= 1'b0;
                                rx_data       <= shift_reg;
                                state         <= ST_IDLE;
                                busy          <= 1'b0;
                                done          <= 1'b1;
                            end
                        endcase
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
