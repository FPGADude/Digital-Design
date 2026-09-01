`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - Part 5
// Macronix MX25L3273E Page Program Demonstration
//
// Fixed flash address:
//     0x3FF200
//
// Data:
//     Selected with SW[7:0] and latched at startup.
//
// FIRST RUN:
//
//     Pre-read target byte
//          |
//          v
//     Require erased value FF
//          |
//          v
//     WRDI (04h)
//          |
//          v
//     RDSR (05h) -> verify WEL = 0
//          |
//          v
//     WREN (06h)
//          |
//          v
//     RDSR (05h) -> verify WEL = 1
//          |
//          v
//     PAGE PROGRAM (02h)
//          |
//          +--> 24-bit address
//          |
//          +--> selected data byte
//          |
//          v
//     Poll RDSR until WIP = 0
//          |
//          v
//     Verify WEL returned to 0
//          |
//          v
//     READ (03h)
//          |
//          v
//     Compare readback with selected byte
//          |
//          v
//        PASS
//
// SAFE RERUN:
//
// If the target already contains exactly the selected byte, Page Program is
// skipped. The byte is read and verified instead.
//
// If the target contains some OTHER non-FF value, programming is blocked.
// This avoids attempting an unsafe 0 -> 1 flash transition.
// ============================================================================

module mx25l3273e_part5_demo #(
    parameter integer CLK_HZ          = 100_000_000,
    parameter integer START_DELAY_US  = 1000,
    parameter integer WARMUP_CYCLES   = 8,
    parameter integer MAX_POLLS       = 2048,

    parameter [23:0] TEST_ADDR        = 24'h3FF200
)(
    input  wire       clk,
    input  wire       reset,

    input  wire       startup_eos,

    input  wire [7:0] user_data,

    // Interface to the byte-oriented SPI engine.
    input  wire       byte_done,
    input  wire [7:0] byte_rx,

    output reg        byte_start,
    output reg [7:0]  byte_tx,

    output reg        flash_cs_n,

    // STARTUPE2 warm-up clock control.
    output reg        warmup_active,
    output reg        warmup_sck,

    // Useful values retained for LEDs / ILA.
    output reg [7:0]  latched_data,
    output reg [7:0]  readback_data,

    output reg [7:0]  status_before,
    output reg [7:0]  status_after_wren,
    output reg [7:0]  final_status,

    // Demo result flags.
    output reg        target_erased,
    output reg        already_programmed,
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

    // ------------------------------------------------------------------------
    // MX25L3273E commands used by this demonstration.
    // ------------------------------------------------------------------------

    localparam [7:0] CMD_PAGE_PROGRAM = 8'h02;
    localparam [7:0] CMD_READ         = 8'h03;
    localparam [7:0] CMD_WRDI         = 8'h04;
    localparam [7:0] CMD_RDSR         = 8'h05;
    localparam [7:0] CMD_WREN         = 8'h06;


    // Number of 100 MHz clocks in the startup delay.
    localparam integer START_DELAY_CLKS =
        (CLK_HZ / 1_000_000) * START_DELAY_US;


    // ------------------------------------------------------------------------
    // State machine
    // ------------------------------------------------------------------------

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
        ST_PRE_EVALUATE      = 6'd13,

        ST_WRDI              = 6'd14,
        ST_WRDI_WAIT         = 6'd15,

        ST_STATUS0_CMD       = 6'd16,
        ST_STATUS0_CMD_WAIT  = 6'd17,
        ST_STATUS0_DATA      = 6'd18,
        ST_STATUS0_DATA_WAIT = 6'd19,
        ST_STATUS0_CHECK     = 6'd20,

        ST_WREN              = 6'd21,
        ST_WREN_WAIT         = 6'd22,

        ST_STATUS1_CMD       = 6'd23,
        ST_STATUS1_CMD_WAIT  = 6'd24,
        ST_STATUS1_DATA      = 6'd25,
        ST_STATUS1_DATA_WAIT = 6'd26,
        ST_STATUS1_CHECK     = 6'd27,

        ST_PP_CMD            = 6'd28,
        ST_PP_CMD_WAIT       = 6'd29,
        ST_PP_ADDR2          = 6'd30,
        ST_PP_ADDR2_WAIT     = 6'd31,
        ST_PP_ADDR1          = 6'd32,
        ST_PP_ADDR1_WAIT     = 6'd33,
        ST_PP_ADDR0          = 6'd34,
        ST_PP_ADDR0_WAIT     = 6'd35,
        ST_PP_DATA           = 6'd36,
        ST_PP_DATA_WAIT      = 6'd37,

        ST_POLL_CMD          = 6'd38,
        ST_POLL_CMD_WAIT     = 6'd39,
        ST_POLL_DATA         = 6'd40,
        ST_POLL_DATA_WAIT    = 6'd41,
        ST_POLL_CHECK        = 6'd42,

        ST_READ_CMD          = 6'd43,
        ST_READ_CMD_WAIT     = 6'd44,
        ST_READ_ADDR2        = 6'd45,
        ST_READ_ADDR2_WAIT   = 6'd46,
        ST_READ_ADDR1        = 6'd47,
        ST_READ_ADDR1_WAIT   = 6'd48,
        ST_READ_ADDR0        = 6'd49,
        ST_READ_ADDR0_WAIT   = 6'd50,
        ST_READ_DATA         = 6'd51,
        ST_READ_DATA_WAIT    = 6'd52,

        ST_EVALUATE          = 6'd53,
        ST_DONE              = 6'd54;


    reg [5:0] state;

    integer delay_count;
    integer warmup_half_count;
    integer warmup_edge_count;
    integer poll_count;


    // ------------------------------------------------------------------------
    // Helper task: launch one byte through the SPI byte engine.
    // ------------------------------------------------------------------------

    task launch_byte;

        input [7:0] value;

        begin
            byte_tx    <= value;
            byte_start <= 1'b1;
        end

    endtask


    // ------------------------------------------------------------------------
    // Main controller
    // ------------------------------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            state               <= ST_WAIT_EOS;

            byte_start          <= 1'b0;
            byte_tx             <= 8'h00;
            flash_cs_n          <= 1'b1;

            warmup_active       <= 1'b0;
            warmup_sck          <= 1'b0;

            latched_data        <= 8'h00;
            readback_data       <= 8'h00;

            status_before       <= 8'h00;
            status_after_wren   <= 8'h00;
            final_status        <= 8'h00;

            target_erased       <= 1'b0;
            already_programmed  <= 1'b0;
            wel_set_seen        <= 1'b0;
            wip_seen            <= 1'b0;
            wel_cleared         <= 1'b0;

            blocked             <= 1'b0;
            timeout_error       <= 1'b0;

            complete            <= 1'b0;
            busy                <= 1'b0;
            pass                <= 1'b0;
            fail                <= 1'b0;

            delay_count         <= 0;
            warmup_half_count   <= 0;
            warmup_edge_count   <= 0;
            poll_count          <= 0;

        end else begin

            // Default value. States that launch a byte pulse this high.
            byte_start <= 1'b0;


            case (state)

                // ============================================================
                // STARTUP
                // ============================================================

                ST_WAIT_EOS: begin

                    flash_cs_n         <= 1'b1;

                    complete           <= 1'b0;
                    busy               <= 1'b0;
                    pass               <= 1'b0;
                    fail               <= 1'b0;

                    blocked            <= 1'b0;
                    timeout_error      <= 1'b0;

                    target_erased      <= 1'b0;
                    already_programmed <= 1'b0;
                    wel_set_seen       <= 1'b0;
                    wip_seen           <= 1'b0;
                    wel_cleared        <= 1'b0;

                    if (startup_eos) begin

                        // Capture the switch value once for the entire run.
                        latched_data <= user_data;

                        delay_count <= 0;
                        state       <= ST_START_DELAY;

                    end
                end


                ST_START_DELAY: begin

                    if (delay_count >= START_DELAY_CLKS - 1) begin

                        delay_count       <= 0;
                        warmup_half_count <= 0;
                        warmup_edge_count <= 0;

                        warmup_active <= 1'b1;
                        warmup_sck    <= 1'b0;

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

                        if (warmup_edge_count >=
                            (WARMUP_CYCLES * 2) - 1) begin

                            warmup_sck    <= 1'b0;
                            warmup_active <= 1'b0;

                            busy  <= 1'b1;
                            state <= ST_PRE_CMD;

                        end else begin

                            warmup_edge_count <= warmup_edge_count + 1;

                        end

                    end else begin

                        warmup_half_count <= warmup_half_count + 1;

                    end
                end


                // ============================================================
                // PRE-READ TARGET BYTE
                //
                // Before modifying flash, read the destination.
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

                    launch_byte(TEST_ADDR[23:16]);

                    state <= ST_PRE_ADDR2_WAIT;

                end


                ST_PRE_ADDR2_WAIT: begin

                    if (byte_done)
                        state <= ST_PRE_ADDR1;

                end


                ST_PRE_ADDR1: begin

                    launch_byte(TEST_ADDR[15:8]);

                    state <= ST_PRE_ADDR1_WAIT;

                end


                ST_PRE_ADDR1_WAIT: begin

                    if (byte_done)
                        state <= ST_PRE_ADDR0;

                end


                ST_PRE_ADDR0: begin

                    launch_byte(TEST_ADDR[7:0]);

                    state <= ST_PRE_ADDR0_WAIT;

                end


                ST_PRE_ADDR0_WAIT: begin

                    if (byte_done)
                        state <= ST_PRE_DATA;

                end


                ST_PRE_DATA: begin

                    launch_byte(8'h00);

                    state <= ST_PRE_DATA_WAIT;

                end


                ST_PRE_DATA_WAIT: begin

                    if (byte_done) begin

                        readback_data <= byte_rx;
                        flash_cs_n    <= 1'b1;

                        state <= ST_PRE_EVALUATE;

                    end
                end


                ST_PRE_EVALUATE: begin

                    // Fresh erased byte: safe to program.
                    if (readback_data == 8'hFF) begin

                        target_erased <= 1'b1;
                        state         <= ST_WRDI;


                    // Already contains exactly the selected byte:
                    // skip Page Program and verify it.
                    end else if (readback_data == latched_data) begin

                        already_programmed <= 1'b1;
                        state              <= ST_READ_CMD;


                    // Some other programmed value is present.
                    // Refuse to modify the location.
                    end else begin

                        blocked  <= 1'b1;
                        fail     <= 1'b1;
                        busy     <= 1'b0;
                        complete <= 1'b1;

                        state <= ST_DONE;

                    end
                end


                // ============================================================
                // WRDI + STATUS CHECK
                //
                // Explicitly establish WEL = 0 before beginning.
                // ============================================================

                ST_WRDI: begin

                    flash_cs_n <= 1'b0;

                    launch_byte(CMD_WRDI);

                    state <= ST_WRDI_WAIT;

                end


                ST_WRDI_WAIT: begin

                    if (byte_done) begin

                        flash_cs_n <= 1'b1;
                        state      <= ST_STATUS0_CMD;

                    end
                end


                ST_STATUS0_CMD: begin

                    flash_cs_n <= 1'b0;

                    launch_byte(CMD_RDSR);

                    state <= ST_STATUS0_CMD_WAIT;

                end


                ST_STATUS0_CMD_WAIT: begin

                    if (byte_done)
                        state <= ST_STATUS0_DATA;

                end


                ST_STATUS0_DATA: begin

                    launch_byte(8'h00);

                    state <= ST_STATUS0_DATA_WAIT;

                end


                ST_STATUS0_DATA_WAIT: begin

                    if (byte_done) begin

                        status_before <= byte_rx;
                        flash_cs_n    <= 1'b1;

                        state <= ST_STATUS0_CHECK;

                    end
                end


                ST_STATUS0_CHECK: begin

                    // WIP=0 and WEL=0 are required here.
                    if (status_before[1:0] != 2'b00) begin

                        fail     <= 1'b1;
                        busy     <= 1'b0;
                        complete <= 1'b1;

                        state <= ST_DONE;

                    end else begin

                        state <= ST_WREN;

                    end
                end


                // ============================================================
                // WREN + STATUS CHECK
                //
                // WREN must set WEL before Page Program can be accepted.
                // ============================================================

                ST_WREN: begin

                    flash_cs_n <= 1'b0;

                    launch_byte(CMD_WREN);

                    state <= ST_WREN_WAIT;

                end


                ST_WREN_WAIT: begin

                    if (byte_done) begin

                        flash_cs_n <= 1'b1;
                        state      <= ST_STATUS1_CMD;

                    end
                end


                ST_STATUS1_CMD: begin

                    flash_cs_n <= 1'b0;

                    launch_byte(CMD_RDSR);

                    state <= ST_STATUS1_CMD_WAIT;

                end


                ST_STATUS1_CMD_WAIT: begin

                    if (byte_done)
                        state <= ST_STATUS1_DATA;

                end


                ST_STATUS1_DATA: begin

                    launch_byte(8'h00);

                    state <= ST_STATUS1_DATA_WAIT;

                end


                ST_STATUS1_DATA_WAIT: begin

                    if (byte_done) begin

                        status_after_wren <= byte_rx;
                        flash_cs_n        <= 1'b1;

                        state <= ST_STATUS1_CHECK;

                    end
                end


                ST_STATUS1_CHECK: begin

                    // Expected low status bits:
                    // WIP = 0
                    // WEL = 1
                    if (status_after_wren[1:0] == 2'b10) begin

                        wel_set_seen <= 1'b1;
                        state        <= ST_PP_CMD;

                    end else begin

                        fail     <= 1'b1;
                        busy     <= 1'b0;
                        complete <= 1'b1;

                        state <= ST_DONE;

                    end
                end


                // ============================================================
                // PAGE PROGRAM
                //
                // CS# remains LOW across:
                //   02h + address[23:0] + data byte
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

                    launch_byte(TEST_ADDR[23:16]);

                    state <= ST_PP_ADDR2_WAIT;

                end


                ST_PP_ADDR2_WAIT: begin

                    if (byte_done)
                        state <= ST_PP_ADDR1;

                end


                ST_PP_ADDR1: begin

                    launch_byte(TEST_ADDR[15:8]);

                    state <= ST_PP_ADDR1_WAIT;

                end


                ST_PP_ADDR1_WAIT: begin

                    if (byte_done)
                        state <= ST_PP_ADDR0;

                end


                ST_PP_ADDR0: begin

                    launch_byte(TEST_ADDR[7:0]);

                    state <= ST_PP_ADDR0_WAIT;

                end


                ST_PP_ADDR0_WAIT: begin

                    if (byte_done)
                        state <= ST_PP_DATA;

                end


                ST_PP_DATA: begin

                    launch_byte(latched_data);

                    state <= ST_PP_DATA_WAIT;

                end


                ST_PP_DATA_WAIT: begin

                    if (byte_done) begin

                        // Raising CS# starts the flash's internal
                        // self-timed Page Program operation.
                        flash_cs_n <= 1'b1;

                        poll_count <= 0;
                        state      <= ST_POLL_CMD;

                    end
                end


                // ============================================================
                // POLL STATUS REGISTER
                //
                // Keep reading RDSR until WIP becomes zero.
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

                        state <= ST_POLL_CHECK;

                    end
                end


                ST_POLL_CHECK: begin

                    // WIP = 1: internal programming is still active.
                    if (final_status[0]) begin

                        wip_seen <= 1'b1;

                        if (poll_count >= MAX_POLLS - 1) begin

                            timeout_error <= 1'b1;
                            fail          <= 1'b1;
                            busy          <= 1'b0;
                            complete      <= 1'b1;

                            state <= ST_DONE;

                        end else begin

                            poll_count <= poll_count + 1;
                            state      <= ST_POLL_CMD;

                        end


                    // WIP is clear, but WEL should also have auto-cleared.
                    end else if (final_status[1]) begin

                        fail     <= 1'b1;
                        busy     <= 1'b0;
                        complete <= 1'b1;

                        state <= ST_DONE;


                    // Programming finished correctly.
                    end else begin

                        wel_cleared <= 1'b1;
                        state       <= ST_READ_CMD;

                    end
                end


                // ============================================================
                // READ BACK THE PROGRAMMED BYTE
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

                    launch_byte(TEST_ADDR[23:16]);

                    state <= ST_READ_ADDR2_WAIT;

                end


                ST_READ_ADDR2_WAIT: begin

                    if (byte_done)
                        state <= ST_READ_ADDR1;

                end


                ST_READ_ADDR1: begin

                    launch_byte(TEST_ADDR[15:8]);

                    state <= ST_READ_ADDR1_WAIT;

                end


                ST_READ_ADDR1_WAIT: begin

                    if (byte_done)
                        state <= ST_READ_ADDR0;

                end


                ST_READ_ADDR0: begin

                    launch_byte(TEST_ADDR[7:0]);

                    state <= ST_READ_ADDR0_WAIT;

                end


                ST_READ_ADDR0_WAIT: begin

                    if (byte_done)
                        state <= ST_READ_DATA;

                end


                ST_READ_DATA: begin

                    launch_byte(8'h00);

                    state <= ST_READ_DATA_WAIT;

                end


                ST_READ_DATA_WAIT: begin

                    if (byte_done) begin

                        readback_data <= byte_rx;
                        flash_cs_n    <= 1'b1;

                        state <= ST_EVALUATE;

                    end
                end


                // ============================================================
                // FINAL PASS / FAIL
                // ============================================================

                ST_EVALUATE: begin

                    busy     <= 1'b0;
                    complete <= 1'b1;

                    if (
                        (readback_data == latched_data) &&
                        !blocked &&
                        !timeout_error &&
                        (
                            already_programmed ||
                            (
                                target_erased &&
                                wel_set_seen &&
                                wel_cleared
                            )
                        )
                    ) begin

                        pass <= 1'b1;
                        fail <= 1'b0;

                    end else begin

                        pass <= 1'b0;
                        fail <= 1'b1;

                    end

                    state <= ST_DONE;

                end


                // ============================================================
                // HOLD RESULT UNTIL RESET
                // ============================================================

                ST_DONE: begin

                    flash_cs_n <= 1'b1;
                    busy       <= 1'b0;
                    complete   <= 1'b1;

                end


                default: begin

                    state <= ST_WAIT_EOS;

                end

            endcase
        end
    end

endmodule
