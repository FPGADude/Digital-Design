`timescale 1ns / 1ps

// ============================================================================
// Sequential SPI Flash Reader
//
// Performs a standard 0x03 READ from START_ADDRESS and returns BYTE_COUNT bytes.
// This module is used at startup to copy the font and sprites from persistent
// flash storage into FPGA block RAM.
//
// The byte-level SPI timing is delegated to spi_byte_engine. This controller
// handles startup delay, CCLK warm-up, command/address transmission, byte
// counting, and the data_valid/data_index interface used by the top level.
// ============================================================================
module flash_reader #(
    parameter integer CLK_HZ         = 100_000_000,
    parameter integer START_DELAY_US = 1000,
    parameter integer WARMUP_CYCLES  = 8,
    parameter [23:0]  START_ADDRESS  = 24'h3E0000,
    parameter integer BYTE_COUNT     = 4096
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        startup_eos,

    input  wire        byte_done,
    input  wire [7:0]  byte_rx,
    output reg         byte_start,
    output reg  [7:0]  byte_tx,

    output reg         flash_cs_n,
    output reg         warmup_active,
    output reg         warmup_sck,

    output reg  [7:0]  data_out,
    output reg  [13:0] data_index,
    output reg         data_valid,

    output reg         busy,
    output reg         complete
);

    localparam integer START_DELAY_CLKS =
        (CLK_HZ / 1_000_000) * START_DELAY_US;

    localparam [7:0] CMD_READ = 8'h03;

    localparam [3:0]
        WAIT_EOS = 4'd0,
        DELAY    = 4'd1,
        WARM     = 4'd2,
        CMD      = 4'd3,
        CMDW     = 4'd4,
        A2       = 4'd5,
        A2W      = 4'd6,
        A1       = 4'd7,
        A1W      = 4'd8,
        A0       = 4'd9,
        A0W      = 4'd10,
        DATA     = 4'd11,
        DATAW    = 4'd12,
        DONE     = 4'd13;

    reg [3:0]  state;
    integer    delay_count;
    integer    warmup_half_count;
    integer    warmup_edge_count;
    reg [13:0] bytes_received;

    // Start one transaction in the shared byte engine.
    task launch_byte;
        input [7:0] value;
        begin
            byte_tx    <= value;
            byte_start <= 1'b1;
        end
    endtask

    always @(posedge clk) begin
        if (reset) begin
            state             <= WAIT_EOS;
            byte_start        <= 1'b0;
            byte_tx           <= 8'h00;
            flash_cs_n        <= 1'b1;
            warmup_active     <= 1'b0;
            warmup_sck        <= 1'b0;
            data_out          <= 8'h00;
            data_index        <= 14'd0;
            data_valid        <= 1'b0;
            busy              <= 1'b0;
            complete          <= 1'b0;
            delay_count       <= 0;
            warmup_half_count <= 0;
            warmup_edge_count <= 0;
            bytes_received    <= 14'd0;
        end else begin
            // These are pulse outputs unless explicitly asserted below.
            byte_start <= 1'b0;
            data_valid <= 1'b0;

            case (state)
                WAIT_EOS: begin
                    flash_cs_n <= 1'b1;

                    if (startup_eos) begin
                        delay_count <= 0;
                        state       <= DELAY;
                    end
                end

                DELAY: begin
                    if (delay_count >= START_DELAY_CLKS - 1) begin
                        delay_count       <= 0;
                        warmup_half_count <= 0;
                        warmup_edge_count <= 0;
                        warmup_active     <= 1'b1;
                        warmup_sck        <= 1'b0;
                        state             <= WARM;
                    end else begin
                        delay_count <= delay_count + 1;
                    end
                end

                WARM: begin
                    // CS# stays high: these are harmless clock pulses, not a
                    // flash command.
                    flash_cs_n <= 1'b1;

                    if (warmup_half_count >= 49) begin
                        warmup_half_count <= 0;
                        warmup_sck        <= ~warmup_sck;

                        if (warmup_edge_count >= (WARMUP_CYCLES * 2) - 1) begin
                            warmup_sck     <= 1'b0;
                            warmup_active  <= 1'b0;
                            bytes_received <= 14'd0;
                            data_index     <= 14'd0;
                            complete       <= 1'b0;
                            busy           <= 1'b1;
                            state          <= CMD;
                        end else begin
                            warmup_edge_count <= warmup_edge_count + 1;
                        end
                    end else begin
                        warmup_half_count <= warmup_half_count + 1;
                    end
                end

                CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_READ);
                    state <= CMDW;
                end

                CMDW: if (byte_done) state <= A2;

                A2: begin
                    launch_byte(START_ADDRESS[23:16]);
                    state <= A2W;
                end

                A2W: if (byte_done) state <= A1;

                A1: begin
                    launch_byte(START_ADDRESS[15:8]);
                    state <= A1W;
                end

                A1W: if (byte_done) state <= A0;

                A0: begin
                    launch_byte(START_ADDRESS[7:0]);
                    state <= A0W;
                end

                A0W: if (byte_done) state <= DATA;

                DATA: begin
                    // MOSI is don't-care during READ data clocks.
                    launch_byte(8'h00);
                    state <= DATAW;
                end

                DATAW: begin
                    if (byte_done) begin
                        data_out   <= byte_rx;
                        data_index <= bytes_received;
                        data_valid <= 1'b1;

                        bytes_received <= bytes_received + 1'b1;

                        if (bytes_received == BYTE_COUNT - 1) begin
                            flash_cs_n <= 1'b1;
                            busy       <= 1'b0;
                            complete   <= 1'b1;
                            state      <= DONE;
                        end else begin
                            state <= DATA;
                        end
                    end
                end

                DONE: begin
                    flash_cs_n <= 1'b1;
                end

                default: begin
                    flash_cs_n <= 1'b1;
                    busy       <= 1'b0;
                    state      <= DONE;
                end
            endcase
        end
    end

endmodule
