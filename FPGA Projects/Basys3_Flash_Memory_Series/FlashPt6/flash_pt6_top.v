`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - Flash From the Ground Up
// Part 6 - Integrated Sector Erase & Verify Demo
//
// This top-level intentionally REUSES the three hardware-proven controllers:
//
//   1. flash_page_seed
//      - inspects 0x3FF000-0x3FF0FF
//      - programs A5/5A test data only when the page is erased
//      - verifies all 256 programmed bytes
//
//   2. flash_sector_erase
//      - WREN (06h)
//      - verifies WEL = 1
//      - Sector Erase (20h) at the HARD-WIRED address 0x3FF000
//      - polls RDSR (05h) until WIP clears
//      - verifies WEL = 0 afterward
//
//   3. flash_sector_verify
//      - reads exactly 4096 bytes from 0x3FF000-0x3FFFFF
//      - PASS only when every byte equals 8'hFF
//
// The controllers do not run concurrently. A tiny stage sequencer holds the
// inactive controllers in reset and multiplexes the active controller onto the
// one proven SPI byte engine and STARTUPE2 CCLK path.
//
// ============================================================================

module flash_pt6_top (
    input  wire        clk,
    input  wire        btnR,
    input  wire [7:0]  sw,

    output wire        qspi_cs_n,
    output wire        qspi_mosi,
    input  wire        qspi_miso,

    output wire [15:0] led,

    output wire [6:0]  seg,
    output wire [3:0]  an
);

    // ========================================================================
    // Overall demo stages
    // ========================================================================

    localparam [1:0]
        STAGE_SEED   = 2'd0,
        STAGE_ERASE  = 2'd1,
        STAGE_VERIFY = 2'd2,
        STAGE_DONE   = 2'd3;

    reg [1:0] stage = STAGE_SEED;
    reg       overall_fail = 1'b0;

    // Latched stage results remain visible after each subcontroller is reset.
    reg seed_ok   = 1'b0;
    reg erase_ok  = 1'b0;
    reg verify_ok = 1'b0;

    reg        erase_wel_latched        = 1'b0;
    reg        erase_issued_latched     = 1'b0;
    reg        erase_wip_latched        = 1'b0;
    reg [8:0]  seed_verify_latched      = 9'd0;
    reg [15:0] erase_poll_latched       = 16'd0;
    reg [7:0]  erase_final_latched      = 8'h00;
    reg [12:0] verify_checked_latched   = 13'd0;
    reg [12:0] verify_ff_latched        = 13'd0;
    reg [12:0] verify_mismatch_latched  = 13'd0;


    // ========================================================================
    // STARTUPE2 / shared SPI byte engine
    // ========================================================================

    wire startup_eos;

    wire       engine_sck;
    wire       engine_mosi;
    wire [7:0] engine_rx;
    wire       engine_done;
    wire       engine_start;
    wire [7:0] engine_tx;

    wire active_warmup;
    wire active_warmup_sck;
    wire user_cclk;

    assign user_cclk = active_warmup ? active_warmup_sck : engine_sck;


    startup_cclk u_startup (
        .user_cclk (user_cclk),
        .eos       (startup_eos)
    );


    spi_byte_engine #(
        .HALF_PERIOD_CLKS (50)
    ) u_spi (
        .clk      (clk),
        .reset    (btnR),
        .start    (engine_start),
        .tx_byte  (engine_tx),
        .miso     (qspi_miso),
        .sck      (engine_sck),
        .mosi     (engine_mosi),
        .rx_byte  (engine_rx),
        .busy     (),
        .done     (engine_done)
    );

    assign qspi_mosi = engine_mosi;


    // ========================================================================
    // Stage 1 - Seed one known 256-byte page
    // ========================================================================

    wire seed_reset = btnR || (stage != STAGE_SEED);

    wire       seed_byte_start;
    wire [7:0] seed_byte_tx;
    wire       seed_cs_n;
    wire       seed_warmup_active;
    wire       seed_warmup_sck;

    wire [8:0]  seed_verify_count;
    wire [8:0]  seed_mismatch_count;
    wire [15:0] seed_poll_count;
    wire [7:0]  seed_status_after_wren;
    wire [7:0]  seed_final_status;

    wire seed_page_was_erased;
    wire seed_already_seeded;
    wire seed_wel_set_seen;
    wire seed_wip_seen;
    wire seed_wel_cleared;
    wire seed_blocked;
    wire seed_timeout_error;
    wire seed_complete;
    wire seed_busy;
    wire seed_pass;
    wire seed_fail;


    flash_page_seed #(
        .CLK_HZ          (100_000_000),
        .START_DELAY_US  (1000),
        .WARMUP_CYCLES   (8),
        .MAX_POLLS       (4096),
        .PAGE_BASE       (24'h3FF000)
    ) u_seed (
        .clk               (clk),
        .reset             (seed_reset),
        .startup_eos       (startup_eos),

        .byte_done         (engine_done),
        .byte_rx           (engine_rx),
        .byte_start        (seed_byte_start),
        .byte_tx           (seed_byte_tx),
        .flash_cs_n        (seed_cs_n),

        .warmup_active     (seed_warmup_active),
        .warmup_sck        (seed_warmup_sck),

        .verify_count      (seed_verify_count),
        .mismatch_count    (seed_mismatch_count),
        .poll_count_out    (seed_poll_count),
        .status_after_wren (seed_status_after_wren),
        .final_status      (seed_final_status),

        .page_was_erased   (seed_page_was_erased),
        .already_seeded    (seed_already_seeded),
        .wel_set_seen      (seed_wel_set_seen),
        .wip_seen          (seed_wip_seen),
        .wel_cleared       (seed_wel_cleared),
        .blocked           (seed_blocked),
        .timeout_error     (seed_timeout_error),

        .complete          (seed_complete),
        .busy              (seed_busy),
        .pass              (seed_pass),
        .fail              (seed_fail)
    );


    // ========================================================================
    // Stage 2 - Erase the hard-wired final 4-KB sector
    // ========================================================================

    wire erase_reset = btnR || (stage != STAGE_ERASE);

    wire       erase_byte_start;
    wire [7:0] erase_byte_tx;
    wire       erase_cs_n;
    wire       erase_warmup_active;
    wire       erase_warmup_sck;

    wire [7:0]  erase_status_after_wren;
    wire [7:0]  erase_first_busy_status;
    wire [7:0]  erase_final_status;
    wire [15:0] erase_poll_count;

    wire erase_wel_set_verified;
    wire erase_issued;
    wire erase_wip_seen;
    wire erase_wel_clear_verified;
    wire erase_complete;
    wire erase_busy;
    wire erase_pass;
    wire erase_fail;


    flash_sector_erase #(
        .CLK_HZ          (100_000_000),
        .START_DELAY_US  (1000),
        .WARMUP_CYCLES   (8),
        .MAX_POLLS       (60000)
    ) u_erase (
        .clk                (clk),
        .reset              (erase_reset),
        .startup_eos        (startup_eos),

        .byte_done          (engine_done),
        .byte_rx            (engine_rx),
        .byte_start         (erase_byte_start),
        .byte_tx            (erase_byte_tx),
        .flash_cs_n         (erase_cs_n),

        .warmup_active      (erase_warmup_active),
        .warmup_sck         (erase_warmup_sck),

        .status_after_wren  (erase_status_after_wren),
        .first_busy_status  (erase_first_busy_status),
        .final_status       (erase_final_status),
        .poll_count         (erase_poll_count),

        .wel_set_verified   (erase_wel_set_verified),
        .erase_issued       (erase_issued),
        .wip_seen           (erase_wip_seen),
        .wel_clear_verified (erase_wel_clear_verified),

        .complete           (erase_complete),
        .busy               (erase_busy),
        .pass               (erase_pass),
        .fail               (erase_fail)
    );


    // ========================================================================
    // Stage 3 - Independently verify all 4096 bytes are FF
    // ========================================================================

    wire verify_reset = btnR || (stage != STAGE_VERIFY);

    wire       verify_byte_start;
    wire [7:0] verify_byte_tx;
    wire       verify_cs_n;
    wire       verify_warmup_active;
    wire       verify_warmup_sck;

    wire [12:0] verify_bytes_checked;
    wire [12:0] verify_ff_count;
    wire [12:0] verify_mismatch_count;
    wire [23:0] verify_first_bad_address;
    wire [7:0]  verify_first_bad_data;
    wire        verify_first_bad_valid;

    wire verify_complete;
    wire verify_busy;
    wire verify_pass;
    wire verify_fail;


    flash_sector_verify #(
        .CLK_HZ          (100_000_000),
        .START_DELAY_US  (1000),
        .WARMUP_CYCLES   (8)
    ) u_verify (
        .clk               (clk),
        .reset             (verify_reset),
        .startup_eos       (startup_eos),

        .byte_done         (engine_done),
        .byte_rx           (engine_rx),
        .byte_start        (verify_byte_start),
        .byte_tx           (verify_byte_tx),
        .flash_cs_n        (verify_cs_n),

        .warmup_active     (verify_warmup_active),
        .warmup_sck        (verify_warmup_sck),

        .bytes_checked     (verify_bytes_checked),
        .ff_count          (verify_ff_count),
        .mismatch_count    (verify_mismatch_count),
        .first_bad_address (verify_first_bad_address),
        .first_bad_data    (verify_first_bad_data),
        .first_bad_valid   (verify_first_bad_valid),

        .complete          (verify_complete),
        .busy              (verify_busy),
        .pass              (verify_pass),
        .fail              (verify_fail)
    );


    // ========================================================================
    // Active-controller multiplexer
    //
    // Only the controller for the current stage can drive the shared byte
    // engine, flash CS#, or warm-up CCLK source.
    // ========================================================================

    assign engine_start = (stage == STAGE_SEED)   ? seed_byte_start   :
                          (stage == STAGE_ERASE)  ? erase_byte_start  :
                          (stage == STAGE_VERIFY) ? verify_byte_start :
                                                   1'b0;

    assign engine_tx = (stage == STAGE_SEED)   ? seed_byte_tx   :
                       (stage == STAGE_ERASE)  ? erase_byte_tx  :
                       (stage == STAGE_VERIFY) ? verify_byte_tx :
                                                8'h00;

    assign qspi_cs_n = (stage == STAGE_SEED)   ? seed_cs_n   :
                       (stage == STAGE_ERASE)  ? erase_cs_n  :
                       (stage == STAGE_VERIFY) ? verify_cs_n :
                                                1'b1;

    assign active_warmup = (stage == STAGE_SEED)   ? seed_warmup_active   :
                           (stage == STAGE_ERASE)  ? erase_warmup_active  :
                           (stage == STAGE_VERIFY) ? verify_warmup_active :
                                                    1'b0;

    assign active_warmup_sck = (stage == STAGE_SEED)   ? seed_warmup_sck   :
                               (stage == STAGE_ERASE)  ? erase_warmup_sck  :
                               (stage == STAGE_VERIFY) ? verify_warmup_sck :
                                                        1'b0;


    // ========================================================================
    // Overall stage sequencer
    // ========================================================================

    always @(posedge clk) begin

        if (btnR) begin
            stage        <= STAGE_SEED;
            overall_fail <= 1'b0;

            seed_ok                  <= 1'b0;
            erase_ok                 <= 1'b0;
            verify_ok                <= 1'b0;
            erase_wel_latched        <= 1'b0;
            erase_issued_latched     <= 1'b0;
            erase_wip_latched        <= 1'b0;
            seed_verify_latched      <= 9'd0;
            erase_poll_latched       <= 16'd0;
            erase_final_latched      <= 8'h00;
            verify_checked_latched   <= 13'd0;
            verify_ff_latched        <= 13'd0;
            verify_mismatch_latched  <= 13'd0;

        end else begin

            case (stage)

                STAGE_SEED: begin
                    if (seed_fail) begin
                        overall_fail <= 1'b1;
                        stage        <= STAGE_DONE;
                    end else if (seed_complete && seed_pass) begin
                        seed_ok             <= 1'b1;
                        seed_verify_latched <= seed_verify_count;
                        stage               <= STAGE_ERASE;
                    end
                end


                STAGE_ERASE: begin
                    if (erase_fail) begin
                        overall_fail <= 1'b1;
                        stage        <= STAGE_DONE;
                    end else if (erase_complete && erase_pass) begin
                        erase_ok             <= 1'b1;
                        erase_wel_latched    <= erase_wel_set_verified;
                        erase_issued_latched <= erase_issued;
                        erase_wip_latched    <= erase_wip_seen;
                        erase_poll_latched   <= erase_poll_count;
                        erase_final_latched  <= erase_final_status;
                        stage                <= STAGE_VERIFY;
                    end
                end


                STAGE_VERIFY: begin
                    if (verify_fail) begin
                        overall_fail <= 1'b1;
                        stage        <= STAGE_DONE;
                    end else if (verify_complete && verify_pass) begin
                        verify_ok               <= 1'b1;
                        verify_checked_latched  <= verify_bytes_checked;
                        verify_ff_latched       <= verify_ff_count;
                        verify_mismatch_latched <= verify_mismatch_count;
                        stage                   <= STAGE_DONE;
                    end
                end


                default: begin
                    // Hold final PASS/FAIL result until BTNR is pressed.
                    stage <= STAGE_DONE;
                end

            endcase
        end
    end


    // ========================================================================
    // Seven-segment diagnostics
    // ========================================================================

    reg [15:0] display_value;

    always @(*) begin
        case (sw[1:0])

            // Final number of bytes independently checked.
            // Expected final result: 1000 hex = 4096 decimal.
            2'b00:
                display_value = {3'b000, verify_checked_latched};

            // Seed-page verification count.
            // Expected final result: 0100 hex = 256 decimal.
            2'b01:
                display_value = {7'b0000000, seed_verify_latched};

            // Number of RDSR polls during Sector Erase.
            2'b10:
                display_value = erase_poll_latched;

            // Final Status Register after erase.
            // On this board we expect QE to remain set while WIP/WEL are 0,
            // so the observed value has been 0040.
            default:
                display_value = {8'h00, erase_final_latched};

        endcase
    end


    sector_inspect_display u_display (
        .clk           (clk),
        .display_value (display_value),
        .seg           (seg),
        .an            (an)
    );


    // ========================================================================
    // LED status
    //
    // LED9  - seed stage completed successfully
    // LED10 - erase WEL=1 prerequisite verified
    // LED11 - 20h Sector Erase command issued
    // LED12 - WIP=1 actually observed
    // LED13 - full 4096-byte FF verification succeeded
    // LED14 - OVERALL PASS
    // LED15 - OVERALL FAIL
    // ========================================================================

    wire overall_pass = (stage == STAGE_DONE) &&
                        !overall_fail &&
                        seed_ok &&
                        erase_ok &&
                        verify_ok;

    assign led[8:0] = 9'b0;

    assign led[9]  = seed_ok;
    assign led[10] = erase_wel_latched;
    assign led[11] = erase_issued_latched;
    assign led[12] = erase_wip_latched;
    assign led[13] = verify_ok &&
                     (verify_checked_latched  == 13'd4096) &&
                     (verify_ff_latched       == 13'd4096) &&
                     (verify_mismatch_latched == 13'd0);
    assign led[14] = overall_pass;
    assign led[15] = overall_fail;

endmodule




