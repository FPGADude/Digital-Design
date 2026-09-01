`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - Part 5 Final Demo with Seven-Segment Display
//
// Controls
// --------
// SW[7:0] : byte to program into flash
// BTNR    : reset / rerun
//
// Flash address
// -------------
// 0x3FF200
//
// Seven-segment display
// ---------------------
//
// Before completion:
//
//                     5 A - -
//
// After successfully programming and reading back 0x5A:
//
//                     5 A 5 A
//
// Left two digits  = byte selected with SW[7:0]
// Right two digits = actual byte read back from flash
//
// LEDs
// ----
// LED10 = target byte was erased before first programming
// LED11 = WEL = 1 verified before Page Program
// LED12 = WIP = 1 observed during programming
// LED13 = WEL returned to 0 after programming
// LED14 = PASS
// LED15 = FAIL / unsafe target / timeout
//
// LED[9:0] are unused in this final recording-oriented build.
//
// Recommended first recording test:
//     SW[7:0] = 8'h5A
//
// Expected display:
//     5A5A
//
// Expected first-run status LEDs:
//     LED10, LED11, LED12, LED13, LED14
//
// Safe BTNR rerun:
//     Display remains 5A5A.
//     Only LED14 is expected because no new Page Program occurs.
// ============================================================================

module basys3_flash_part5_demo_7seg_top (
    input  wire        clk,
    input  wire        btnR,
    input  wire [7:0]  sw,

    output wire        qspi_cs_n,
    output wire        qspi_mosi,
    input  wire        qspi_miso,

    output wire [15:0] led,

    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        dp
);

    // ------------------------------------------------------------------------
    // STARTUPE2 / CCLK signals
    // ------------------------------------------------------------------------

    wire startup_eos;

    wire warmup_active;
    wire warmup_sck;
    wire user_cclk;


    // ------------------------------------------------------------------------
    // SPI byte engine signals
    // ------------------------------------------------------------------------

    wire       engine_sck;
    wire       engine_mosi;
    wire [7:0] engine_rx;
    wire       engine_busy;
    wire       engine_done;

    wire       engine_start;
    wire [7:0] engine_tx;


    // ------------------------------------------------------------------------
    // Flash controller status/debug signals
    // ------------------------------------------------------------------------

    wire [7:0] latched_data;
    wire [7:0] readback_data;

    wire [7:0] status_before;
    wire [7:0] status_after_wren;
    wire [7:0] final_status;

    wire target_erased;
    wire already_programmed;
    wire wel_set_seen;
    wire wip_seen;
    wire wel_cleared;

    wire blocked;
    wire timeout_error;

    wire complete;
    wire busy;
    wire pass;
    wire fail;


    // ------------------------------------------------------------------------
    // Route the appropriate clock source to the configuration flash CCLK.
    // ------------------------------------------------------------------------

    assign user_cclk =
        warmup_active ? warmup_sck : engine_sck;


    // ------------------------------------------------------------------------
    // STARTUPE2 wrapper
    // ------------------------------------------------------------------------

    startup_cclk u_startup (
        .user_cclk (user_cclk),
        .eos       (startup_eos)
    );


    // ------------------------------------------------------------------------
    // SPI Mode-0 byte engine
    // ------------------------------------------------------------------------

    spi_mode0_byte_engine #(
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

        .busy     (engine_busy),
        .done     (engine_done)
    );


    // ------------------------------------------------------------------------
    // Hardware-tested Part 5 flash demo controller.
    //
    // The controller itself is unchanged from the previous verified demo.
    // Only the board-facing display has been improved for recording.
    // ------------------------------------------------------------------------

    mx25l3273e_part5_demo #(
        .CLK_HZ          (100_000_000),
        .START_DELAY_US  (1000),
        .WARMUP_CYCLES   (8),
        .MAX_POLLS       (2048),
        .TEST_ADDR       (24'h3FF200)
    ) u_flash_demo (
        .clk                (clk),
        .reset              (btnR),

        .startup_eos        (startup_eos),

        .user_data          (sw),

        .byte_done          (engine_done),
        .byte_rx            (engine_rx),
        .byte_start         (engine_start),
        .byte_tx            (engine_tx),

        .flash_cs_n         (qspi_cs_n),

        .warmup_active      (warmup_active),
        .warmup_sck         (warmup_sck),

        .latched_data       (latched_data),
        .readback_data      (readback_data),

        .status_before      (status_before),
        .status_after_wren  (status_after_wren),
        .final_status       (final_status),

        .target_erased      (target_erased),
        .already_programmed (already_programmed),
        .wel_set_seen       (wel_set_seen),
        .wip_seen           (wip_seen),
        .wel_cleared        (wel_cleared),

        .blocked            (blocked),
        .timeout_error      (timeout_error),

        .complete           (complete),
        .busy               (busy),
        .pass               (pass),
        .fail               (fail)
    );


    // MOSI comes directly from the byte engine.
    assign qspi_mosi = engine_mosi;


    // ------------------------------------------------------------------------
    // Seven-segment display
    //
    // The left pair shows what we intended to program.
    // The right pair shows what was actually read from flash.
    // ------------------------------------------------------------------------

    sevenseg_hex_compare u_display (
        .clk             (clk),
        .programmed_byte (latched_data),
        .readback_byte   (readback_data),
        .complete        (complete),

        .seg             (seg),
        .an              (an),
        .dp              (dp)
    );


    // ------------------------------------------------------------------------
    // Recording-friendly LED status display
    // ------------------------------------------------------------------------

    assign led[9:0] = 10'b0;

    assign led[10] = target_erased;
    assign led[11] = wel_set_seen;
    assign led[12] = wip_seen;
    assign led[13] = wel_cleared;

    assign led[14] = pass;

    assign led[15] =
        fail |
        blocked |
        timeout_error;

endmodule
