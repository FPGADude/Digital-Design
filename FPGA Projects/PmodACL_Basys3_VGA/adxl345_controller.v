`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// File: adxl345_controller.v
// Project: Pmod ACL VGA Display for Basys 3
//
// ADXL345/Pmod ACL controller. It configures the accelerometer registers over SPI, 
// then repeatedly performs a multi-byte read of the X, Y, and Z output registers.
//
// Notes:
// - This project reads the ADXL345 accelerometer on the Digilent Pmod ACL.
// - The design displays the three signed acceleration axes on a 640x480 VGA
//   screen as decimal values and center-referenced bar graphs.
// -----------------------------------------------------------------------------

// SPI control state machine for the ADXL345 accelerometer.
// After reset, the module writes the configuration registers needed for
// measurement mode, then continuously reads the six data bytes for X/Y/Z.
module adxl345_controller(
    input  wire              clk,
    input  wire              reset,
    output reg               spi_cs,
    output wire              spi_sclk,
    output wire              spi_mosi,
    input  wire              spi_miso,
    output reg signed [15:0] x_data,
    output reg signed [15:0] y_data,
    output reg signed [15:0] z_data,
    output reg               data_valid,
    output reg               init_done,
    output wire [2:0]        state_dbg
);

    // ADXL345 register addresses used by this demo.
    localparam REG_BW_RATE     = 8'h2C;
    localparam REG_POWER_CTL   = 8'h2D;
    localparam REG_DATA_FORMAT = 8'h31;
    localparam REG_DATAX0      = 8'h32;

    // ADXL345 SPI command bits. READ_BIT selects reads and MB_BIT enables
    // multi-byte transfers so DATAX0 through DATAZ1 can be read in one burst.
    localparam WRITE_BIT = 8'h00;
    localparam READ_BIT  = 8'h80;
    localparam MB_BIT    = 8'h40;

    // Controller state encoding. Three bits are enough for the eight states.
    localparam S_POWERUP_WAIT = 3'd0;
    localparam S_WRITE_ADDR   = 3'd1;
    localparam S_WRITE_DATA   = 3'd2;
    localparam S_NEXT_INIT    = 3'd3;
    localparam S_IDLE_DELAY   = 3'd4;
    localparam S_READ_ADDR    = 3'd5;
    localparam S_READ_BYTE    = 3'd6;
    localparam S_SAVE_BYTE    = 3'd7;

    reg [2:0] state = S_POWERUP_WAIT;
    // Export the current state for LEDs/debugging at the top level.
    assign state_dbg = state;

    reg spi_start = 0;
    reg [7:0] spi_tx = 0;
    wire [7:0] spi_rx;
    wire spi_busy;
    wire spi_done;

    // 1 MHz SPI master derived from the 100 MHz Basys 3 clock.
    spi_master #(.CLK_DIV(50)) u_spi (
        .clk(clk),
        .reset(reset),
        .start(spi_start),
        .tx_data(spi_tx),
        .rx_data(spi_rx),
        .busy(spi_busy),
        .done(spi_done),
        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso)
    );

    reg [23:0] delay_count = 0;
    reg [1:0] init_index = 0;
    reg [2:0] byte_index = 0;
    reg [7:0] data_bytes [0:5];

    reg [7:0] init_addr;
    reg [7:0] init_data;

    // Select which initialization register/value pair should be written.
    always @(*) begin
        case (init_index)
            2'd0: begin init_addr = REG_DATA_FORMAT; init_data = 8'h08; end // full resolution, +/-2g
            2'd1: begin init_addr = REG_BW_RATE;     init_data = 8'h0A; end // 100 Hz output data rate
            2'd2: begin init_addr = REG_POWER_CTL;   init_data = 8'h08; end // measurement mode
            default: begin init_addr = REG_POWER_CTL; init_data = 8'h08; end
        endcase
    end

    // Main ADXL345 configuration/read state machine.
    // data_valid is pulsed for one clock after all six acceleration bytes have
    // been captured and assembled into signed 16-bit X/Y/Z values.
    always @(posedge clk) begin
        if (reset) begin
            state       <= S_POWERUP_WAIT;
            spi_cs      <= 1'b1;
            spi_start   <= 1'b0;
            spi_tx      <= 8'd0;
            delay_count <= 0;
            init_index  <= 0;
            byte_index  <= 0;
            x_data      <= 0;
            y_data      <= 0;
            z_data      <= 0;
            data_valid  <= 1'b0;
            init_done   <= 1'b0;
        end else begin
            spi_start <= 1'b0;
            data_valid <= 1'b0;   // one-clock pulse when a fresh X/Y/Z sample is ready

            case (state)
                // Wait briefly after reset before talking to the sensor.
                S_POWERUP_WAIT: begin
                    spi_cs <= 1'b1;
                    if (delay_count < 24'd5_000_000) begin // 50 ms power-up delay
                        delay_count <= delay_count + 1'b1;
                    end else begin
                        delay_count <= 0;
                        init_index <= 0;
                        state <= S_WRITE_ADDR;
                    end
                end

                // Send the target register address for an initialization write.
                S_WRITE_ADDR: begin
                    spi_cs <= 1'b0;
                    if (!spi_busy) begin
                        spi_tx <= WRITE_BIT | init_addr;
                        spi_start <= 1'b1;
                        state <= S_WRITE_DATA;
                    end
                end

                // Send the data byte for the selected initialization register.
                S_WRITE_DATA: begin
                    if (spi_done) begin
                        spi_tx <= init_data;
                        spi_start <= 1'b1;
                        state <= S_NEXT_INIT;
                    end
                end

                // Advance through the list of initialization writes.
                S_NEXT_INIT: begin
                    if (spi_done) begin
                        spi_cs <= 1'b1;
                        if (init_index == 2'd2) begin
                            init_done <= 1'b1;
                            delay_count <= 0;
                            state <= S_IDLE_DELAY;
                        end else begin
                            init_index <= init_index + 1'b1;
                            state <= S_WRITE_ADDR;
                        end
                    end
                end

                // Small delay between read bursts so the display updates at a
                // comfortable rate and the sensor is not hammered continuously.
                S_IDLE_DELAY: begin
                    spi_cs <= 1'b1;
                    if (delay_count < 24'd1_000_000) begin // 10 ms between reads
                        delay_count <= delay_count + 1'b1;
                    end else begin
                        delay_count <= 0;
                        byte_index <= 0;
                        state <= S_READ_ADDR;
                    end
                end

                // Start a multi-byte read beginning at DATAX0.
                S_READ_ADDR: begin
                    spi_cs <= 1'b0;
                    if (!spi_busy) begin
                        spi_tx <= READ_BIT | MB_BIT | REG_DATAX0;
                        spi_start <= 1'b1;
                        state <= S_READ_BYTE;
                    end
                end

                // Clock one returned data byte from the accelerometer.
                S_READ_BYTE: begin
                    if (spi_done) begin
                        spi_tx <= 8'h00;       // dummy byte to clock data out
                        spi_start <= 1'b1;
                        state <= S_SAVE_BYTE;
                    end
                end

                // Store the received byte. After byte 5, assemble signed
                // little-endian X/Y/Z samples and pulse data_valid.
                S_SAVE_BYTE: begin
                    if (spi_done) begin
                        data_bytes[byte_index] <= spi_rx;

                        if (byte_index == 3'd5) begin
                            spi_cs <= 1'b1;
                            x_data <= {data_bytes[1], data_bytes[0]};
                            y_data <= {data_bytes[3], data_bytes[2]};
                            z_data <= {spi_rx, data_bytes[4]};
                            data_valid <= 1'b1;
                            state <= S_IDLE_DELAY;
                        end else begin
                            byte_index <= byte_index + 1'b1;
                            spi_tx <= 8'h00;
                            spi_start <= 1'b1;
                            state <= S_SAVE_BYTE;
                        end
                    end
                end

                default: state <= S_POWERUP_WAIT;
            endcase
        end
    end

endmodule

