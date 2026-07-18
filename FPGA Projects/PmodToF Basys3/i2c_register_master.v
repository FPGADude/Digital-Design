`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: i2c_register_master
//
// Reusable single-register I2C master
//
// Supports:
//   - One-byte register write:
//       START -> address+W -> register -> data -> STOP
//
//   - One-byte register read:
//       START -> address+W -> register -> repeated START
//       -> address+R -> read byte -> NACK -> STOP
//
// The SCL and SDA outputs are open-drain.  A logic 0 actively pulls the line
// low; a logic 1 releases the line so the external pull-up resistor can raise it.
//
// Default timing:
//   100 MHz FPGA clock
//   100 kHz I2C serial clock
//
// Command handshake:
//   - The client presents address/data/rw and pulses start for one clock.
//   - busy remains high for the complete bus transaction.
//   - done pulses for one clock after STOP has completed.
//   - ack_error is cleared at the start of each command and latches high if
//     any transmitted byte is not acknowledged by the addressed slave.
//
// Electrical behavior:
//   I2C is an open-drain bus. This module never actively drives a logic high.
//   It either pulls SCL/SDA low or releases the line to the external pull-up.
//
// Clocking approach:
//   Each I2C bit is divided into four quarter-cycle state-machine intervals.
//   This gives explicit setup, high, sample, and low phases and keeps all bus
//   transitions synchronous to the FPGA system clock.
//////////////////////////////////////////////////////////////////////////////////

module i2c_register_master #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer I2C_FREQ_HZ = 100_000
)(
    input  wire       clk,
    input  wire       reset,

    // Transaction request interface. All command fields must remain stable
    // during the one-clock start pulse.
    input  wire       start,
    input  wire       rw,             // 0 = register write, 1 = register read
    input  wire [6:0] device_addr,
    input  wire [7:0] register_addr,
    input  wire [7:0] write_data,

    // Transaction completion and result interface.
    output reg  [7:0] read_data,
    output reg        busy,
    output reg        done,
    output reg        ack_error,

    // Physical open-drain I2C bus lines.
    inout  wire       i2c_scl,
    inout  wire       i2c_sda
);

    // Four timing phases are used for every I2C bit.
    localparam integer QUARTER_DIV = CLK_FREQ_HZ / (I2C_FREQ_HZ * 4);
    localparam integer COUNT_WIDTH = $clog2(QUARTER_DIV);

    reg [COUNT_WIDTH-1:0] quarter_count;
    reg                   quarter_tick;

    // Open-drain controls:
    //   1 = actively pull the bus line low
    //   0 = release the line
    reg scl_pull_low;
    reg sda_pull_low;

    assign i2c_scl = scl_pull_low ? 1'b0 : 1'bz;
    assign i2c_sda = sda_pull_low ? 1'b0 : 1'bz;

    wire sda_in = i2c_sda;

    // Main bus-level state machine. The state names describe the bus action
    // performed during each quarter-cycle interval.
    localparam [4:0]
        ST_IDLE             = 5'd0,
        ST_START_A          = 5'd1,
        ST_START_B          = 5'd2,
        ST_SEND_SETUP       = 5'd3,
        ST_SEND_SCL_HIGH    = 5'd4,
        ST_SEND_SCL_LOW     = 5'd5,
        ST_ACK_RELEASE      = 5'd6,
        ST_ACK_SCL_HIGH     = 5'd7,
        ST_ACK_SCL_LOW      = 5'd8,
        ST_RESTART_RELEASE  = 5'd9,
        ST_RESTART_SDA_LOW  = 5'd10,
        ST_RESTART_SCL_LOW  = 5'd11,
        ST_READ_RELEASE     = 5'd12,
        ST_READ_SCL_HIGH    = 5'd13,
        ST_READ_SCL_LOW     = 5'd14,
        ST_MASTER_NACK_LOW  = 5'd15,
        ST_MASTER_NACK_HIGH = 5'd16,
        ST_STOP_SDA_LOW     = 5'd17,
        ST_STOP_SCL_HIGH    = 5'd18,
        ST_STOP_RELEASE     = 5'd19,
        ST_FINISH           = 5'd20;

    // Identifies which byte of the higher-level register transaction is
    // currently being transferred.
    localparam [2:0]
        BYTE_DEV_WRITE = 3'd0,
        BYTE_REGISTER  = 3'd1,
        BYTE_WRITE_DATA= 3'd2,
        BYTE_DEV_READ  = 3'd3;

    // State and shift-register storage for the active command.
    reg [4:0] state;
    reg [2:0] byte_stage;
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;
    reg [2:0] bit_index;
    reg       transaction_rw;

    // Generate a pulse at four times the requested I2C clock frequency.
    always @(posedge clk) begin
        if (reset) begin
            quarter_count <= {COUNT_WIDTH{1'b0}};
            quarter_tick  <= 1'b0;
        end else if (busy) begin
            if (quarter_count == QUARTER_DIV - 1) begin
                quarter_count <= {COUNT_WIDTH{1'b0}};
                quarter_tick  <= 1'b1;
            end else begin
                quarter_count <= quarter_count + 1'b1;
                quarter_tick  <= 1'b0;
            end
        end else begin
            quarter_count <= {COUNT_WIDTH{1'b0}};
            quarter_tick  <= 1'b0;
        end
    end

    // Main I2C protocol state machine.
    always @(posedge clk) begin
        if (reset) begin
            // Release both bus lines and return the interface to idle.
            state          <= ST_IDLE;
            byte_stage     <= BYTE_DEV_WRITE;
            tx_shift       <= 8'h00;
            rx_shift       <= 8'h00;
            read_data      <= 8'h00;
            bit_index      <= 3'd7;
            transaction_rw <= 1'b0;
            busy           <= 1'b0;
            done           <= 1'b0;
            ack_error      <= 1'b0;
            scl_pull_low   <= 1'b0;
            sda_pull_low   <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                // Wait for a new register command. SCL and SDA are both
                // released so the bus is in its normal idle-high condition.
                ST_IDLE: begin
                    busy         <= 1'b0;
                    scl_pull_low <= 1'b0;
                    sda_pull_low <= 1'b0;

                    if (start) begin
                        busy           <= 1'b1;
                        ack_error      <= 1'b0;
                        transaction_rw <= rw;
                        byte_stage     <= BYTE_DEV_WRITE;
                        tx_shift       <= {device_addr, 1'b0};
                        bit_index      <= 3'd7;
                        state          <= ST_START_A;
                    end
                end

                // START: SDA falls while SCL is released high.
                ST_START_A: if (quarter_tick) begin
                    scl_pull_low <= 1'b0;
                    sda_pull_low <= 1'b1;
                    state        <= ST_START_B;
                end

                ST_START_B: if (quarter_tick) begin
                    scl_pull_low <= 1'b1;
                    state        <= ST_SEND_SETUP;
                end

                // Set the next data bit while SCL is low.
                ST_SEND_SETUP: if (quarter_tick) begin
                    sda_pull_low <= ~tx_shift[bit_index];
                    state        <= ST_SEND_SCL_HIGH;
                end

                // Release SCL high. Data remains stable during the high period.
                ST_SEND_SCL_HIGH: if (quarter_tick) begin
                    scl_pull_low <= 1'b0;
                    state        <= ST_SEND_SCL_LOW;
                end

                // Pull SCL low and either continue or sample the slave ACK.
                ST_SEND_SCL_LOW: if (quarter_tick) begin
                    scl_pull_low <= 1'b1;
                    if (bit_index == 3'd0) begin
                        state <= ST_ACK_RELEASE;
                    end else begin
                        bit_index <= bit_index - 1'b1;
                        state     <= ST_SEND_SETUP;
                    end
                end

                // Release SDA for the ninth clock so the slave can pull it
                // low to acknowledge the byte.
                ST_ACK_RELEASE: if (quarter_tick) begin
                    sda_pull_low <= 1'b0;
                    state        <= ST_ACK_SCL_HIGH;
                end

                // Sample the slave ACK while SCL is high. A released/high
                // SDA line means NACK and is latched in ack_error.
                ST_ACK_SCL_HIGH: if (quarter_tick) begin
                    scl_pull_low <= 1'b0;
                    if (sda_in)
                        ack_error <= 1'b1;
                    state <= ST_ACK_SCL_LOW;
                end

                ST_ACK_SCL_LOW: if (quarter_tick) begin
                    scl_pull_low <= 1'b1;

                    case (byte_stage)
                        BYTE_DEV_WRITE: begin
                            byte_stage <= BYTE_REGISTER;
                            tx_shift   <= register_addr;
                            bit_index  <= 3'd7;
                            state      <= ST_SEND_SETUP;
                        end

                        BYTE_REGISTER: begin
                            if (transaction_rw) begin
                                state <= ST_RESTART_RELEASE;
                            end else begin
                                byte_stage <= BYTE_WRITE_DATA;
                                tx_shift   <= write_data;
                                bit_index  <= 3'd7;
                                state      <= ST_SEND_SETUP;
                            end
                        end

                        BYTE_WRITE_DATA: begin
                            state <= ST_STOP_SDA_LOW;
                        end

                        BYTE_DEV_READ: begin
                            bit_index <= 3'd7;
                            rx_shift  <= 8'h00;
                            state     <= ST_READ_RELEASE;
                        end

                        default: state <= ST_STOP_SDA_LOW;
                    endcase
                end

                // Repeated START used by a register read.
                ST_RESTART_RELEASE: if (quarter_tick) begin
                    sda_pull_low <= 1'b0;
                    scl_pull_low <= 1'b0;
                    state        <= ST_RESTART_SDA_LOW;
                end

                ST_RESTART_SDA_LOW: if (quarter_tick) begin
                    sda_pull_low <= 1'b1;
                    state        <= ST_RESTART_SCL_LOW;
                end

                ST_RESTART_SCL_LOW: if (quarter_tick) begin
                    scl_pull_low <= 1'b1;
                    byte_stage   <= BYTE_DEV_READ;
                    tx_shift     <= {device_addr, 1'b1};
                    bit_index    <= 3'd7;
                    state        <= ST_SEND_SETUP;
                end

                // Release SDA so the slave can drive the read data.
                // During reads the master releases SDA and the slave drives
                // each data bit. The bit is sampled while SCL is high.
                ST_READ_RELEASE: if (quarter_tick) begin
                    sda_pull_low <= 1'b0;
                    state        <= ST_READ_SCL_HIGH;
                end

                ST_READ_SCL_HIGH: if (quarter_tick) begin
                    scl_pull_low        <= 1'b0;
                    rx_shift[bit_index] <= sda_in;
                    state               <= ST_READ_SCL_LOW;
                end

                ST_READ_SCL_LOW: if (quarter_tick) begin
                    scl_pull_low <= 1'b1;
                    if (bit_index == 3'd0) begin
                        read_data <= rx_shift;
                        state     <= ST_MASTER_NACK_LOW;
                    end else begin
                        bit_index <= bit_index - 1'b1;
                        state     <= ST_READ_RELEASE;
                    end
                end

                // NACK the single received byte to tell the slave the read is done.
                ST_MASTER_NACK_LOW: if (quarter_tick) begin
                    sda_pull_low <= 1'b0;
                    state        <= ST_MASTER_NACK_HIGH;
                end

                ST_MASTER_NACK_HIGH: if (quarter_tick) begin
                    scl_pull_low <= 1'b0;
                    state        <= ST_STOP_SDA_LOW;
                end

                // STOP: SDA rises while SCL is released high.
                ST_STOP_SDA_LOW: if (quarter_tick) begin
                    scl_pull_low <= 1'b1;
                    sda_pull_low <= 1'b1;
                    state        <= ST_STOP_SCL_HIGH;
                end

                ST_STOP_SCL_HIGH: if (quarter_tick) begin
                    scl_pull_low <= 1'b0;
                    state        <= ST_STOP_RELEASE;
                end

                ST_STOP_RELEASE: if (quarter_tick) begin
                    sda_pull_low <= 1'b0;
                    state        <= ST_FINISH;
                end

                // Produce a one-clock completion pulse after the STOP
                // condition and return control to the requesting module.
                ST_FINISH: begin
                    busy  <= 1'b0;
                    done  <= 1'b1;
                    state <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
