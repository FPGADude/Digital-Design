`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - Flash From the Ground Up
// Sector Erase Verification Controller
//
// Non-destructively verifies that every byte in the reserved final 4 KB
// sector is erased (8'hFF).
//
// Reserved sector:
//     0x3FF000 - 0x3FFFFF
//
// Operation:
//     READ 03h at 0x3FF000
//     Keep CS# LOW
//     Read exactly 4096 sequential bytes
//     PASS only if every byte == 8'hFF
//
// This controller contains NO WREN, Page Program, or Erase command.
// ============================================================================

module flash_sector_verify #(
    parameter integer CLK_HZ         = 100_000_000,
    parameter integer START_DELAY_US = 1000,
    parameter integer WARMUP_CYCLES  = 8
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

    output reg  [12:0] bytes_checked,
    output reg  [12:0] ff_count,
    output reg  [12:0] mismatch_count,
    output reg  [23:0] first_bad_address,
    output reg  [7:0]  first_bad_data,
    output reg         first_bad_valid,

    output reg         complete,
    output reg         busy,
    output reg         pass,
    output reg         fail
);

    // ------------------------------------------------------------------------
    // Safety: the verification target is fixed in HDL.
    // ------------------------------------------------------------------------
    localparam [23:0] SECTOR_BASE  = 24'h3FF000;
    localparam integer SECTOR_BYTES = 4096;
    localparam [7:0] CMD_READ = 8'h03;

    localparam integer START_DELAY_CLKS =
        (CLK_HZ / 1_000_000) * START_DELAY_US;

    localparam [3:0]
        ST_WAIT_EOS        = 4'd0,
        ST_START_DELAY     = 4'd1,
        ST_WARMUP          = 4'd2,
        ST_READ_CMD        = 4'd3,
        ST_READ_CMD_WAIT   = 4'd4,
        ST_READ_ADDR2      = 4'd5,
        ST_READ_ADDR2_WAIT = 4'd6,
        ST_READ_ADDR1      = 4'd7,
        ST_READ_ADDR1_WAIT = 4'd8,
        ST_READ_ADDR0      = 4'd9,
        ST_READ_ADDR0_WAIT = 4'd10,
        ST_READ_DATA       = 4'd11,
        ST_READ_DATA_WAIT  = 4'd12,
        ST_FINISH          = 4'd13,
        ST_DONE            = 4'd14;

    reg [3:0] state;

    integer delay_count;
    integer warmup_half_count;
    integer warmup_edge_count;

    // Byte offset within the 4 KB sector: 0 through 4095.
    reg [11:0] read_offset;


    task launch_byte;
        input [7:0] value;
        begin
            byte_tx    <= value;
            byte_start <= 1'b1;
        end
    endtask


    always @(posedge clk) begin

        if (reset) begin

            state             <= ST_WAIT_EOS;

            byte_start        <= 1'b0;
            byte_tx           <= 8'h00;
            flash_cs_n        <= 1'b1;

            warmup_active     <= 1'b0;
            warmup_sck        <= 1'b0;

            bytes_checked     <= 13'd0;
            ff_count          <= 13'd0;
            mismatch_count    <= 13'd0;
            first_bad_address <= 24'h000000;
            first_bad_data    <= 8'h00;
            first_bad_valid   <= 1'b0;

            complete          <= 1'b0;
            busy              <= 1'b0;
            pass              <= 1'b0;
            fail              <= 1'b0;

            delay_count       <= 0;
            warmup_half_count <= 0;
            warmup_edge_count <= 0;
            read_offset       <= 12'd0;

        end else begin

            // Default: byte_start is a one-clock launch pulse.
            byte_start <= 1'b0;

            case (state)

                // ============================================================
                // Wait for FPGA configuration to finish.
                // ============================================================
                ST_WAIT_EOS: begin
                    flash_cs_n <= 1'b1;

                    if (startup_eos) begin
                        delay_count <= 0;
                        state       <= ST_START_DELAY;
                    end
                end


                // ============================================================
                // Retain the proven post-EOS delay from earlier parts.
                // ============================================================
                ST_START_DELAY: begin
                    if (delay_count >= START_DELAY_CLKS - 1) begin
                        delay_count       <= 0;
                        warmup_half_count <= 0;
                        warmup_edge_count <= 0;
                        warmup_active     <= 1'b1;
                        warmup_sck        <= 1'b0;
                        state             <= ST_WARMUP;
                    end else begin
                        delay_count <= delay_count + 1;
                    end
                end


                // ============================================================
                // Eight harmless CCLK cycles with CS# HIGH.
                // ============================================================
                ST_WARMUP: begin
                    flash_cs_n <= 1'b1;

                    if (warmup_half_count >= 49) begin
                        warmup_half_count <= 0;
                        warmup_sck        <= ~warmup_sck;

                        if (warmup_edge_count >= (WARMUP_CYCLES * 2) - 1) begin
                            warmup_sck        <= 1'b0;
                            warmup_active     <= 1'b0;

                            bytes_checked     <= 13'd0;
                            ff_count          <= 13'd0;
                            mismatch_count    <= 13'd0;
                            first_bad_address <= 24'h000000;
                            first_bad_data    <= 8'h00;
                            first_bad_valid   <= 1'b0;
                            read_offset       <= 12'd0;

                            complete          <= 1'b0;
                            busy              <= 1'b1;
                            pass              <= 1'b0;
                            fail              <= 1'b0;

                            state             <= ST_READ_CMD;
                        end else begin
                            warmup_edge_count <= warmup_edge_count + 1;
                        end
                    end else begin
                        warmup_half_count <= warmup_half_count + 1;
                    end
                end


                // ============================================================
                // READ 03h + fixed address 0x3FF000.
                // ============================================================
                ST_READ_CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_READ);
                    state <= ST_READ_CMD_WAIT;
                end

                ST_READ_CMD_WAIT: begin
                    if (byte_done)
                        state <= ST_READ_ADDR2;
                end

                ST_READ_ADDR2: begin
                    launch_byte(SECTOR_BASE[23:16]);
                    state <= ST_READ_ADDR2_WAIT;
                end

                ST_READ_ADDR2_WAIT: begin
                    if (byte_done)
                        state <= ST_READ_ADDR1;
                end

                ST_READ_ADDR1: begin
                    launch_byte(SECTOR_BASE[15:8]);
                    state <= ST_READ_ADDR1_WAIT;
                end

                ST_READ_ADDR1_WAIT: begin
                    if (byte_done)
                        state <= ST_READ_ADDR0;
                end

                ST_READ_ADDR0: begin
                    launch_byte(SECTOR_BASE[7:0]);
                    state <= ST_READ_ADDR0_WAIT;
                end

                ST_READ_ADDR0_WAIT: begin
                    if (byte_done)
                        state <= ST_READ_DATA;
                end


                // ============================================================
                // Sequentially read all 4096 bytes while keeping CS# LOW.
                // ============================================================
                ST_READ_DATA: begin
                    launch_byte(8'h00);
                    state <= ST_READ_DATA_WAIT;
                end

                ST_READ_DATA_WAIT: begin
                    if (byte_done) begin

                        bytes_checked <= bytes_checked + 1'b1;

                        if (byte_rx == 8'hFF) begin
                            ff_count <= ff_count + 1'b1;
                        end else begin
                            mismatch_count <= mismatch_count + 1'b1;

                            // Preserve the first failure for diagnosis.
                            if (!first_bad_valid) begin
                                first_bad_valid   <= 1'b1;
                                first_bad_address <= SECTOR_BASE + read_offset;
                                first_bad_data    <= byte_rx;
                            end
                        end

                        // Offset FFF is the 4096th and final byte.
                        if (read_offset == 12'hFFF) begin
                            flash_cs_n <= 1'b1;
                            state      <= ST_FINISH;
                        end else begin
                            read_offset <= read_offset + 1'b1;
                            state       <= ST_READ_DATA;
                        end
                    end
                end


                // ============================================================
                // PASS requires BOTH:
                //   1. all 4096 bytes were checked
                //   2. there were zero non-FF bytes
                // ============================================================
                ST_FINISH: begin
                    busy     <= 1'b0;
                    complete <= 1'b1;

                    if ((bytes_checked == SECTOR_BYTES) &&
                        (mismatch_count == 13'd0)) begin
                        pass <= 1'b1;
                        fail <= 1'b0;
                    end else begin
                        pass <= 1'b0;
                        fail <= 1'b1;
                    end

                    state <= ST_DONE;
                end


                ST_DONE: begin
                    flash_cs_n <= 1'b1;
                end


                default: begin
                    flash_cs_n <= 1'b1;
                    busy       <= 1'b0;
                    pass       <= 1'b0;
                    fail       <= 1'b1;
                    state      <= ST_DONE;
                end

            endcase
        end
    end

endmodule
