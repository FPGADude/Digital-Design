`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - Flash From the Ground Up
// Sector Erase Controller
//
// Purpose
// -------
// Perform one deliberately constrained 4-KB Sector Erase on the reserved
// development sector at 0x3FF000, then poll the Status Register until the
// self-timed erase operation completes.
//
// Sequence
// --------
// 1. Wait for STARTUPE2 EOS.
// 2. Generate the proven 8 harmless CCLK warm-up cycles with CS# HIGH.
// 3. WREN (06h).
// 4. RDSR (05h) and prove WEL (bit 1) = 1.
// 5. Sector Erase: 20h + 3Fh + F0h + 00h.
// 6. Raise CS# -- this commits/starts the erase operation.
// 7. Repeatedly issue RDSR (05h):
//      - prove WIP (bit 0) becomes 1
//      - continue polling while WIP = 1
//      - stop when WIP = 0
// 8. Prove WEL (bit 1) is 0 after completion.
// 9. PASS.
//
// ============================================================================

module flash_sector_erase #(
    parameter integer CLK_HZ         = 100_000_000,
    parameter integer START_DELAY_US = 1000,
    parameter integer WARMUP_CYCLES  = 8,
    parameter integer MAX_POLLS      = 60000
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        startup_eos,

    input  wire        byte_done,
    input  wire [7:0]  byte_rx,

    output reg         byte_start,
    output reg [7:0]   byte_tx,
    output reg         flash_cs_n,

    output reg         warmup_active,
    output reg         warmup_sck,

    output reg [7:0]   status_after_wren,
    output reg [7:0]   first_busy_status,
    output reg [7:0]   final_status,
    output reg [15:0]  poll_count,

    output reg         wel_set_verified,
    output reg         erase_issued,
    output reg         wip_seen,
    output reg         wel_clear_verified,

    output reg         complete,
    output reg         busy,
    output reg         pass,
    output reg         fail
);

    // ------------------------------------------------------------------------
    // MX25L3273E commands used in this experiment.
    // ------------------------------------------------------------------------
    localparam [7:0] CMD_RDSR = 8'h05;
    localparam [7:0] CMD_WREN = 8'h06;
    localparam [7:0] CMD_SE   = 8'h20;

    // ------------------------------------------------------------------------
    // HARD-WIRED safety boundary.
    //
    // 0x3FF000 is the aligned base address of the final 4-KB sector:
    //     0x3FF000 - 0x3FFFFF
    //
    // There is intentionally no runtime erase-address input.
    // ------------------------------------------------------------------------
    localparam [23:0] ERASE_ADDRESS = 24'h3FF000;

    localparam integer START_DELAY_CLKS =
        (CLK_HZ / 1_000_000) * START_DELAY_US;


    // ------------------------------------------------------------------------
    // State machine encoding.
    // ------------------------------------------------------------------------
    localparam [5:0]
        ST_WAIT_EOS            = 6'd0,
        ST_START_DELAY         = 6'd1,
        ST_WARMUP              = 6'd2,

        ST_WREN                = 6'd3,
        ST_WREN_WAIT           = 6'd4,

        ST_RDSR_WREN_CMD       = 6'd5,
        ST_RDSR_WREN_CMD_WAIT  = 6'd6,
        ST_RDSR_WREN_DATA      = 6'd7,
        ST_RDSR_WREN_DATA_WAIT = 6'd8,
        ST_CHECK_WEL           = 6'd9,

        ST_SE_CMD              = 6'd10,
        ST_SE_CMD_WAIT         = 6'd11,
        ST_SE_A23_A16          = 6'd12,
        ST_SE_A23_A16_WAIT     = 6'd13,
        ST_SE_A15_A8           = 6'd14,
        ST_SE_A15_A8_WAIT      = 6'd15,
        ST_SE_A7_A0            = 6'd16,
        ST_SE_A7_A0_WAIT       = 6'd17,

        ST_POLL_CMD            = 6'd18,
        ST_POLL_CMD_WAIT       = 6'd19,
        ST_POLL_DATA           = 6'd20,
        ST_POLL_DATA_WAIT      = 6'd21,
        ST_CHECK_STATUS        = 6'd22,

        ST_DONE                = 6'd23;

    reg [5:0] state;

    integer delay_count;
    integer warmup_half_count;
    integer warmup_edge_count;

    reg [7:0] polled_status;


    // ------------------------------------------------------------------------
    // Helper task: launch one transaction through the proven byte engine.
    // byte_start is cleared by default every clock, making it a one-cycle
    // pulse whenever this task is called.
    // ------------------------------------------------------------------------
    task launch_byte;
        input [7:0] value;
        begin
            byte_tx    <= value;
            byte_start <= 1'b1;
        end
    endtask


    always @(posedge clk) begin

        if (reset) begin

            state                <= ST_WAIT_EOS;

            byte_start           <= 1'b0;
            byte_tx              <= 8'h00;
            flash_cs_n           <= 1'b1;

            warmup_active        <= 1'b0;
            warmup_sck           <= 1'b0;

            status_after_wren    <= 8'h00;
            first_busy_status    <= 8'h00;
            final_status         <= 8'h00;
            poll_count           <= 16'h0000;
            polled_status        <= 8'h00;

            wel_set_verified     <= 1'b0;
            erase_issued         <= 1'b0;
            wip_seen             <= 1'b0;
            wel_clear_verified   <= 1'b0;

            complete             <= 1'b0;
            busy                 <= 1'b0;
            pass                 <= 1'b0;
            fail                 <= 1'b0;

            delay_count          <= 0;
            warmup_half_count    <= 0;
            warmup_edge_count    <= 0;

        end else begin

            // byte_start is always a one-clock pulse.
            byte_start <= 1'b0;

            case (state)

                // ============================================================
                // Startup / proven CCLK warm-up
                // ============================================================

                ST_WAIT_EOS: begin

                    flash_cs_n         <= 1'b1;
                    warmup_active      <= 1'b0;
                    warmup_sck         <= 1'b0;

                    status_after_wren  <= 8'h00;
                    first_busy_status  <= 8'h00;
                    final_status       <= 8'h00;
                    poll_count         <= 16'h0000;
                    polled_status      <= 8'h00;

                    wel_set_verified   <= 1'b0;
                    erase_issued       <= 1'b0;
                    wip_seen           <= 1'b0;
                    wel_clear_verified <= 1'b0;

                    complete           <= 1'b0;
                    busy               <= 1'b0;
                    pass               <= 1'b0;
                    fail               <= 1'b0;

                    if (startup_eos) begin
                        delay_count <= 0;
                        state       <= ST_START_DELAY;
                    end
                end


                ST_START_DELAY: begin

                    flash_cs_n <= 1'b1;

                    if (delay_count >= START_DELAY_CLKS - 1) begin
                        warmup_active     <= 1'b1;
                        warmup_sck        <= 1'b0;
                        warmup_half_count <= 0;
                        warmup_edge_count <= 0;
                        busy              <= 1'b1;
                        state             <= ST_WARMUP;
                    end else begin
                        delay_count <= delay_count + 1;
                    end
                end


                ST_WARMUP: begin

                    // CS# remains HIGH, so these clocks cannot form a flash
                    // command. This preserves our proven STARTUPE2 behavior.
                    flash_cs_n <= 1'b1;

                    if (warmup_half_count >= 49) begin
                        warmup_half_count <= 0;
                        warmup_sck        <= ~warmup_sck;

                        if (warmup_sck == 1'b0) begin
                            if (warmup_edge_count >= WARMUP_CYCLES - 1) begin
                                warmup_active <= 1'b0;
                                warmup_sck    <= 1'b0;
                                state         <= ST_WREN;
                            end else begin
                                warmup_edge_count <= warmup_edge_count + 1;
                            end
                        end
                    end else begin
                        warmup_half_count <= warmup_half_count + 1;
                    end
                end


                // ============================================================
                // WREN: 06h
                // ============================================================

                ST_WREN: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_WREN);
                    state <= ST_WREN_WAIT;
                end


                ST_WREN_WAIT: begin
                    if (byte_done) begin
                        // WREN takes effect when CS# returns HIGH.
                        flash_cs_n <= 1'b1;
                        state      <= ST_RDSR_WREN_CMD;
                    end
                end


                // ============================================================
                // RDSR: prove WEL = 1 before erase is permitted
                // ============================================================

                ST_RDSR_WREN_CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_RDSR);
                    state <= ST_RDSR_WREN_CMD_WAIT;
                end


                ST_RDSR_WREN_CMD_WAIT: begin
                    if (byte_done)
                        state <= ST_RDSR_WREN_DATA;
                end


                ST_RDSR_WREN_DATA: begin
                    launch_byte(8'h00);
                    state <= ST_RDSR_WREN_DATA_WAIT;
                end


                ST_RDSR_WREN_DATA_WAIT: begin
                    if (byte_done) begin
                        status_after_wren <= byte_rx;
                        flash_cs_n        <= 1'b1;
                        state             <= ST_CHECK_WEL;
                    end
                end


                ST_CHECK_WEL: begin

                    if (status_after_wren[1]) begin
                        wel_set_verified <= 1'b1;
                        state            <= ST_SE_CMD;
                    end else begin
                        // Critical interlock: without WEL=1, we NEVER issue 20h.
                        fail  <= 1'b1;
                        state <= ST_DONE;
                    end
                end


                // ============================================================
                // Sector Erase: 20h + hard-wired 0x3FF000
                //
                // CS# stays LOW through command and all three address bytes.
                // Raising CS# after the final byte commits the command and
                // begins the flash's self-timed erase operation.
                // ============================================================

                ST_SE_CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_SE);
                    state <= ST_SE_CMD_WAIT;
                end


                ST_SE_CMD_WAIT: begin
                    if (byte_done)
                        state <= ST_SE_A23_A16;
                end


                ST_SE_A23_A16: begin
                    launch_byte(ERASE_ADDRESS[23:16]);
                    state <= ST_SE_A23_A16_WAIT;
                end


                ST_SE_A23_A16_WAIT: begin
                    if (byte_done)
                        state <= ST_SE_A15_A8;
                end


                ST_SE_A15_A8: begin
                    launch_byte(ERASE_ADDRESS[15:8]);
                    state <= ST_SE_A15_A8_WAIT;
                end


                ST_SE_A15_A8_WAIT: begin
                    if (byte_done)
                        state <= ST_SE_A7_A0;
                end


                ST_SE_A7_A0: begin
                    launch_byte(ERASE_ADDRESS[7:0]);
                    state <= ST_SE_A7_A0_WAIT;
                end


                ST_SE_A7_A0_WAIT: begin
                    if (byte_done) begin
                        // This rising edge of CS# commits the Sector Erase.
                        flash_cs_n <= 1'b1;
                        erase_issued <= 1'b1;
                        state <= ST_POLL_CMD;
                    end
                end


                // ============================================================
                // Poll RDSR until WIP clears
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
                        polled_status <= byte_rx;
                        flash_cs_n    <= 1'b1;

                        if (poll_count != 16'hFFFF)
                            poll_count <= poll_count + 1'b1;

                        state <= ST_CHECK_STATUS;
                    end
                end


                ST_CHECK_STATUS: begin

                    if (polled_status[0]) begin

                        // WIP = 1: erase is actively in progress.
                        if (!wip_seen)
                            first_busy_status <= polled_status;

                        wip_seen <= 1'b1;

                        if (poll_count >= MAX_POLLS) begin
                            // Erase has taken far longer than expected.
                            fail  <= 1'b1;
                            state <= ST_DONE;
                        end else begin
                            state <= ST_POLL_CMD;
                        end

                    end else begin

                        // WIP = 0: self-timed erase has completed.
                        final_status <= polled_status;

                        // A valid experiment must actually have observed WIP=1.
                        // WEL must also have automatically returned to 0.
                        if (wip_seen && !polled_status[1]) begin
                            wel_clear_verified <= 1'b1;
                            pass               <= 1'b1;
                        end else begin
                            fail <= 1'b1;
                        end

                        state <= ST_DONE;
                    end
                end


                // ============================================================
                // Finished
                // ============================================================

                ST_DONE: begin
                    flash_cs_n <= 1'b1;
                    busy       <= 1'b0;
                    complete   <= 1'b1;
                    state      <= ST_DONE;
                end


                default: begin
                    flash_cs_n <= 1'b1;
                    busy       <= 1'b0;
                    fail       <= 1'b1;
                    complete   <= 1'b1;
                    state      <= ST_DONE;
                end

            endcase
        end
    end

endmodule
