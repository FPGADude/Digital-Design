`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - Flash From the Ground Up
// Controlled Page Seed Controller
//
// Purpose
// -------
// Prepare the reserved final flash sector for a later Sector Erase test by
// programming exactly ONE 256-byte page at 0x3FF000.
//
// Test pattern
// ------------
// Byte 0 = A5, byte 1 = 5A, byte 2 = A5, ...
//
// Safety
// ------
// * The destination address is fixed in HDL at 0x3FF000.
// * Before programming, all 256 destination bytes are inspected.
// * Programming is allowed only if the page is completely erased (all FF).
// * If the page already contains the exact A5/5A pattern, programming is
//   skipped and the page is verified instead. This makes BTNR reruns safe.
// * Any other page contents block programming and assert FAIL.
//
// Sequence
// --------
// 1. Wait for EOS and generate the proven 8 warm-up CCLK cycles.
// 2. Read the complete 256-byte target page.
// 3. Decide: erased / already seeded / unsafe mixed data.
// 4. WREN (06h).
// 5. RDSR (05h) and prove WEL=1.
// 6. Page Program (02h), address 0x3FF000, then exactly 256 data bytes.
// 7. Poll RDSR until WIP=0.
// 8. Prove WEL returned to 0.
// 9. Read all 256 bytes back and compare with the expected pattern.
// ============================================================================

module flash_page_seed #(
    parameter integer CLK_HZ         = 100_000_000,
    parameter integer START_DELAY_US = 1000,
    parameter integer WARMUP_CYCLES  = 8,
    parameter integer MAX_POLLS      = 4096,
    parameter [23:0]  PAGE_BASE      = 24'h3FF000
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       startup_eos,

    input  wire       byte_done,
    input  wire [7:0] byte_rx,

    output reg        byte_start,
    output reg [7:0]  byte_tx,
    output reg        flash_cs_n,

    output reg        warmup_active,
    output reg        warmup_sck,

    output reg [8:0]  verify_count,
    output reg [8:0]  mismatch_count,
    output reg [15:0] poll_count_out,
    output reg [7:0]  status_after_wren,
    output reg [7:0]  final_status,

    output reg        page_was_erased,
    output reg        already_seeded,
    output reg        wel_set_seen,
    output reg        wip_seen,
    output reg        wel_cleared,
    output reg        blocked,
    output reg        timeout_error,

    output reg        complete,
    output reg        busy,
    output reg        pass,
    output reg        fail
);

    localparam [7:0] CMD_PAGE_PROGRAM = 8'h02;
    localparam [7:0] CMD_READ         = 8'h03;
    localparam [7:0] CMD_RDSR         = 8'h05;
    localparam [7:0] CMD_WREN         = 8'h06;

    localparam integer START_DELAY_CLKS =
        (CLK_HZ / 1_000_000) * START_DELAY_US;

    // The Page Program target is intentionally fixed and page aligned.
    // This controller is not an arbitrary-address flash writer.
    localparam [23:0] SAFE_PAGE_BASE = 24'h3FF000;

    localparam [5:0]
        ST_WAIT_EOS          = 6'd0,
        ST_START_DELAY       = 6'd1,
        ST_WARMUP            = 6'd2,

        ST_PRE_CMD           = 6'd3,
        ST_PRE_CMD_WAIT      = 6'd4,
        ST_PRE_ADDR2         = 6'd5,
        ST_PRE_ADDR2_WAIT    = 6'd6,
        ST_PRE_ADDR1         = 6'd7,
        ST_PRE_ADDR1_WAIT    = 6'd8,
        ST_PRE_ADDR0         = 6'd9,
        ST_PRE_ADDR0_WAIT    = 6'd10,
        ST_PRE_DATA          = 6'd11,
        ST_PRE_DATA_WAIT     = 6'd12,
        ST_PRE_EVAL          = 6'd13,

        ST_WREN              = 6'd14,
        ST_WREN_WAIT         = 6'd15,
        ST_WEL_CMD           = 6'd16,
        ST_WEL_CMD_WAIT      = 6'd17,
        ST_WEL_DATA          = 6'd18,
        ST_WEL_DATA_WAIT     = 6'd19,
        ST_WEL_CHECK         = 6'd20,

        ST_PP_CMD            = 6'd21,
        ST_PP_CMD_WAIT       = 6'd22,
        ST_PP_ADDR2          = 6'd23,
        ST_PP_ADDR2_WAIT     = 6'd24,
        ST_PP_ADDR1          = 6'd25,
        ST_PP_ADDR1_WAIT     = 6'd26,
        ST_PP_ADDR0          = 6'd27,
        ST_PP_ADDR0_WAIT     = 6'd28,
        ST_PP_DATA           = 6'd29,
        ST_PP_DATA_WAIT      = 6'd30,

        ST_POLL_CMD          = 6'd31,
        ST_POLL_CMD_WAIT     = 6'd32,
        ST_POLL_DATA         = 6'd33,
        ST_POLL_DATA_WAIT    = 6'd34,
        ST_POLL_CHECK        = 6'd35,

        ST_VERIFY_CMD        = 6'd36,
        ST_VERIFY_CMD_WAIT   = 6'd37,
        ST_VERIFY_ADDR2      = 6'd38,
        ST_VERIFY_ADDR2_WAIT = 6'd39,
        ST_VERIFY_ADDR1      = 6'd40,
        ST_VERIFY_ADDR1_WAIT = 6'd41,
        ST_VERIFY_ADDR0      = 6'd42,
        ST_VERIFY_ADDR0_WAIT = 6'd43,
        ST_VERIFY_DATA       = 6'd44,
        ST_VERIFY_DATA_WAIT  = 6'd45,
        ST_EVALUATE          = 6'd46,
        ST_DONE              = 6'd47;

    reg [5:0] state;

    integer delay_count;
    integer warmup_half_count;
    integer warmup_edge_count;
    integer poll_count;

    reg [8:0] page_index;
    reg [8:0] pre_ff_count;
    reg [8:0] pre_match_count;


    // ------------------------------------------------------------------------
    // Expected data pattern for a page offset.
    // Even byte offsets contain A5; odd offsets contain 5A.
    // ------------------------------------------------------------------------

    function [7:0] pattern_byte;
        input [7:0] index;
        begin
            pattern_byte = index[0] ? 8'h5A : 8'hA5;
        end
    endfunction


    task launch_byte;
        input [7:0] value;
        begin
            byte_tx    <= value;
            byte_start <= 1'b1;
        end
    endtask


    always @(posedge clk) begin

        if (reset) begin

            state              <= ST_WAIT_EOS;
            byte_start         <= 1'b0;
            byte_tx            <= 8'h00;
            flash_cs_n         <= 1'b1;

            warmup_active      <= 1'b0;
            warmup_sck         <= 1'b0;

            verify_count       <= 9'd0;
            mismatch_count     <= 9'd0;
            poll_count_out     <= 16'd0;
            status_after_wren  <= 8'h00;
            final_status       <= 8'h00;

            page_was_erased    <= 1'b0;
            already_seeded     <= 1'b0;
            wel_set_seen       <= 1'b0;
            wip_seen           <= 1'b0;
            wel_cleared        <= 1'b0;
            blocked            <= 1'b0;
            timeout_error      <= 1'b0;

            complete           <= 1'b0;
            busy               <= 1'b0;
            pass               <= 1'b0;
            fail               <= 1'b0;

            delay_count        <= 0;
            warmup_half_count  <= 0;
            warmup_edge_count  <= 0;
            poll_count         <= 0;

            page_index         <= 9'd0;
            pre_ff_count       <= 9'd0;
            pre_match_count    <= 9'd0;

        end else begin

            byte_start <= 1'b0;

            case (state)

                // ============================================================
                // Startup / CCLK warm-up
                // ============================================================

                ST_WAIT_EOS: begin

                    flash_cs_n        <= 1'b1;
                    complete          <= 1'b0;
                    busy              <= 1'b0;
                    pass              <= 1'b0;
                    fail              <= 1'b0;
                    blocked           <= 1'b0;
                    timeout_error     <= 1'b0;
                    page_was_erased   <= 1'b0;
                    already_seeded    <= 1'b0;
                    wel_set_seen      <= 1'b0;
                    wip_seen          <= 1'b0;
                    wel_cleared       <= 1'b0;
                    verify_count      <= 9'd0;
                    mismatch_count    <= 9'd0;
                    poll_count_out    <= 16'd0;
                    pre_ff_count      <= 9'd0;
                    pre_match_count   <= 9'd0;
                    page_index        <= 9'd0;

                    if (startup_eos) begin
                        delay_count <= 0;
                        state       <= ST_START_DELAY;
                    end
                end


                ST_START_DELAY: begin

                    if (delay_count >= START_DELAY_CLKS - 1) begin

                        delay_count       <= 0;
                        warmup_half_count <= 0;
                        warmup_edge_count <= 0;
                        warmup_active     <= 1'b1;
                        warmup_sck        <= 1'b0;

                        state <= ST_WARMUP;

                    end else begin
                        delay_count <= delay_count + 1;
                    end
                end


                ST_WARMUP: begin

                    flash_cs_n <= 1'b1;

                    if (warmup_half_count >= 49) begin

                        warmup_half_count <= 0;
                        warmup_sck        <= ~warmup_sck;

                        if (warmup_edge_count >= (WARMUP_CYCLES * 2) - 1) begin
                            warmup_sck    <= 1'b0;
                            warmup_active <= 1'b0;
                            busy          <= 1'b1;
                            page_index    <= 9'd0;
                            state         <= ST_PRE_CMD;
                        end else begin
                            warmup_edge_count <= warmup_edge_count + 1;
                        end

                    end else begin
                        warmup_half_count <= warmup_half_count + 1;
                    end
                end


                // ============================================================
                // Pre-read the entire target page in one sequential READ.
                // ============================================================

                ST_PRE_CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_READ);
                    state <= ST_PRE_CMD_WAIT;
                end

                ST_PRE_CMD_WAIT: begin
                    if (byte_done)
                        state <= ST_PRE_ADDR2;
                end

                ST_PRE_ADDR2: begin
                    launch_byte(PAGE_BASE[23:16]);
                    state <= ST_PRE_ADDR2_WAIT;
                end

                ST_PRE_ADDR2_WAIT: begin
                    if (byte_done)
                        state <= ST_PRE_ADDR1;
                end

                ST_PRE_ADDR1: begin
                    launch_byte(PAGE_BASE[15:8]);
                    state <= ST_PRE_ADDR1_WAIT;
                end

                ST_PRE_ADDR1_WAIT: begin
                    if (byte_done)
                        state <= ST_PRE_ADDR0;
                end

                ST_PRE_ADDR0: begin
                    launch_byte(PAGE_BASE[7:0]);
                    state <= ST_PRE_ADDR0_WAIT;
                end

                ST_PRE_ADDR0_WAIT: begin
                    if (byte_done) begin
                        page_index <= 9'd0;
                        state      <= ST_PRE_DATA;
                    end
                end

                ST_PRE_DATA: begin
                    launch_byte(8'h00);
                    state <= ST_PRE_DATA_WAIT;
                end

                ST_PRE_DATA_WAIT: begin

                    if (byte_done) begin

                        if (byte_rx == 8'hFF)
                            pre_ff_count <= pre_ff_count + 1'b1;

                        if (byte_rx == pattern_byte(page_index[7:0]))
                            pre_match_count <= pre_match_count + 1'b1;

                        if (page_index == 9'd255) begin
                            flash_cs_n <= 1'b1;
                            state      <= ST_PRE_EVAL;
                        end else begin
                            page_index <= page_index + 1'b1;
                            state      <= ST_PRE_DATA;
                        end
                    end
                end


                ST_PRE_EVAL: begin

                    // Structural safety guard. PAGE_BASE is also fixed by the
                    // top level, but this prevents programming if the module
                    // parameter is accidentally changed later.
                    if (PAGE_BASE != SAFE_PAGE_BASE) begin
                        blocked  <= 1'b1;
                        fail     <= 1'b1;
                        complete <= 1'b1;
                        busy     <= 1'b0;
                        state    <= ST_DONE;

                    end else if (pre_ff_count == 9'd256) begin
                        page_was_erased <= 1'b1;
                        state           <= ST_WREN;

                    end else if (pre_match_count == 9'd256) begin
                        already_seeded <= 1'b1;
                        page_index     <= 9'd0;
                        state          <= ST_VERIFY_CMD;

                    end else begin
                        // Unexpected programmed data is present. Do not alter it.
                        blocked  <= 1'b1;
                        fail     <= 1'b1;
                        complete <= 1'b1;
                        busy     <= 1'b0;
                        state    <= ST_DONE;
                    end
                end


                // ============================================================
                // WREN and verify WEL=1.
                // ============================================================

                ST_WREN: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_WREN);
                    state <= ST_WREN_WAIT;
                end

                ST_WREN_WAIT: begin
                    if (byte_done) begin
                        flash_cs_n <= 1'b1;
                        state      <= ST_WEL_CMD;
                    end
                end

                ST_WEL_CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_RDSR);
                    state <= ST_WEL_CMD_WAIT;
                end

                ST_WEL_CMD_WAIT: begin
                    if (byte_done)
                        state <= ST_WEL_DATA;
                end

                ST_WEL_DATA: begin
                    launch_byte(8'h00);
                    state <= ST_WEL_DATA_WAIT;
                end

                ST_WEL_DATA_WAIT: begin
                    if (byte_done) begin
                        status_after_wren <= byte_rx;
                        flash_cs_n       <= 1'b1;
                        state            <= ST_WEL_CHECK;
                    end
                end

                ST_WEL_CHECK: begin
                    if ((status_after_wren[1] == 1'b1) &&
                        (status_after_wren[0] == 1'b0)) begin
                        wel_set_seen <= 1'b1;
                        page_index   <= 9'd0;
                        state        <= ST_PP_CMD;
                    end else begin
                        fail     <= 1'b1;
                        complete <= 1'b1;
                        busy     <= 1'b0;
                        state    <= ST_DONE;
                    end
                end


                // ============================================================
                // Page Program: command + aligned address + exactly 256 bytes.
                // CS# remains LOW through the complete transaction.
                // ============================================================

                ST_PP_CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_PAGE_PROGRAM);
                    state <= ST_PP_CMD_WAIT;
                end

                ST_PP_CMD_WAIT: begin
                    if (byte_done)
                        state <= ST_PP_ADDR2;
                end

                ST_PP_ADDR2: begin
                    launch_byte(PAGE_BASE[23:16]);
                    state <= ST_PP_ADDR2_WAIT;
                end

                ST_PP_ADDR2_WAIT: begin
                    if (byte_done)
                        state <= ST_PP_ADDR1;
                end

                ST_PP_ADDR1: begin
                    launch_byte(PAGE_BASE[15:8]);
                    state <= ST_PP_ADDR1_WAIT;
                end

                ST_PP_ADDR1_WAIT: begin
                    if (byte_done)
                        state <= ST_PP_ADDR0;
                end

                ST_PP_ADDR0: begin
                    launch_byte(PAGE_BASE[7:0]);
                    state <= ST_PP_ADDR0_WAIT;
                end

                ST_PP_ADDR0_WAIT: begin
                    if (byte_done) begin
                        page_index <= 9'd0;
                        state      <= ST_PP_DATA;
                    end
                end

                ST_PP_DATA: begin
                    launch_byte(pattern_byte(page_index[7:0]));
                    state <= ST_PP_DATA_WAIT;
                end

                ST_PP_DATA_WAIT: begin
                    if (byte_done) begin
                        if (page_index == 9'd255) begin
                            // Raising CS# after the 256th byte causes the flash
                            // to begin its internal self-timed program cycle.
                            flash_cs_n <= 1'b1;
                            poll_count <= 0;
                            state      <= ST_POLL_CMD;
                        end else begin
                            page_index <= page_index + 1'b1;
                            state      <= ST_PP_DATA;
                        end
                    end
                end


                // ============================================================
                // Poll Status Register until WIP clears.
                // Each poll is a separate RDSR transaction.
                // ============================================================

                ST_POLL_CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_RDSR);
                    state <= ST_POLL_CMD_WAIT;
                end

                ST_POLL_CMD_WAIT: begin
                    if (byte_done)
                        state <= ST_POLL_DATA;
                end

                ST_POLL_DATA: begin
                    launch_byte(8'h00);
                    state <= ST_POLL_DATA_WAIT;
                end

                ST_POLL_DATA_WAIT: begin
                    if (byte_done) begin
                        final_status <= byte_rx;
                        flash_cs_n   <= 1'b1;
                        state        <= ST_POLL_CHECK;
                    end
                end

                ST_POLL_CHECK: begin

                    poll_count_out <= poll_count[15:0] + 1'b1;

                    if (final_status[0]) begin

                        wip_seen   <= 1'b1;
                        poll_count <= poll_count + 1;

                        if (poll_count >= MAX_POLLS - 1) begin
                            timeout_error <= 1'b1;
                            fail          <= 1'b1;
                            complete      <= 1'b1;
                            busy          <= 1'b0;
                            state         <= ST_DONE;
                        end else begin
                            state <= ST_POLL_CMD;
                        end

                    end else begin

                        // WIP has cleared. Page Program completion should also
                        // automatically clear WEL.
                        if (final_status[1] == 1'b0) begin
                            wel_cleared <= 1'b1;
                            page_index  <= 9'd0;
                            state       <= ST_VERIFY_CMD;
                        end else begin
                            fail     <= 1'b1;
                            complete <= 1'b1;
                            busy     <= 1'b0;
                            state    <= ST_DONE;
                        end
                    end
                end


                // ============================================================
                // Read back all 256 bytes and compare every byte.
                // ============================================================

                ST_VERIFY_CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_READ);
                    state <= ST_VERIFY_CMD_WAIT;
                end

                ST_VERIFY_CMD_WAIT: begin
                    if (byte_done)
                        state <= ST_VERIFY_ADDR2;
                end

                ST_VERIFY_ADDR2: begin
                    launch_byte(PAGE_BASE[23:16]);
                    state <= ST_VERIFY_ADDR2_WAIT;
                end

                ST_VERIFY_ADDR2_WAIT: begin
                    if (byte_done)
                        state <= ST_VERIFY_ADDR1;
                end

                ST_VERIFY_ADDR1: begin
                    launch_byte(PAGE_BASE[15:8]);
                    state <= ST_VERIFY_ADDR1_WAIT;
                end

                ST_VERIFY_ADDR1_WAIT: begin
                    if (byte_done)
                        state <= ST_VERIFY_ADDR0;
                end

                ST_VERIFY_ADDR0: begin
                    launch_byte(PAGE_BASE[7:0]);
                    state <= ST_VERIFY_ADDR0_WAIT;
                end

                ST_VERIFY_ADDR0_WAIT: begin
                    if (byte_done) begin
                        page_index     <= 9'd0;
                        verify_count   <= 9'd0;
                        mismatch_count <= 9'd0;
                        state          <= ST_VERIFY_DATA;
                    end
                end

                ST_VERIFY_DATA: begin
                    launch_byte(8'h00);
                    state <= ST_VERIFY_DATA_WAIT;
                end

                ST_VERIFY_DATA_WAIT: begin

                    if (byte_done) begin

                        verify_count <= verify_count + 1'b1;

                        if (byte_rx != pattern_byte(page_index[7:0]))
                            mismatch_count <= mismatch_count + 1'b1;

                        if (page_index == 9'd255) begin
                            flash_cs_n <= 1'b1;
                            state      <= ST_EVALUATE;
                        end else begin
                            page_index <= page_index + 1'b1;
                            state      <= ST_VERIFY_DATA;
                        end
                    end
                end


                ST_EVALUATE: begin

                    // At entry, verify_count must be 256. The nonblocking
                    // updates from the final received byte have completed.
                    if ((verify_count == 9'd256) &&
                        (mismatch_count == 9'd0)) begin
                        pass <= 1'b1;
                    end else begin
                        fail <= 1'b1;
                    end

                    complete <= 1'b1;
                    busy     <= 1'b0;
                    state    <= ST_DONE;
                end


                ST_DONE: begin
                    flash_cs_n <= 1'b1;
                    busy       <= 1'b0;
                end


                default: begin
                    flash_cs_n <= 1'b1;
                    fail       <= 1'b1;
                    complete   <= 1'b1;
                    busy       <= 1'b0;
                    state      <= ST_DONE;
                end

            endcase
        end
    end

endmodule
