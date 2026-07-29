`timescale 1ns / 1ps

// ============================================================
// REGISTERED WORD PCM ROM
// ============================================================
// Complete words are stored as unsigned 8-bit PCM at 12.5 kHz.
//
// XPM is used to explicitly infer registered block RAM. READ_LATENCY_A = 2
// enables the memory output register, while MEMORY_OPTIMIZATION = "false"
// avoids the updatemem compatibility warning.
//
// MEMORY_OPTIMIZATION is deliberately false. This removes the
// Memdata 28-231 warning and permits updatemem-compatible ROM
// organization, although ordinary synthesis remains supported.
//
// retro_word_pcm.mem must be added to Vivado as a Memory
// Initialization File.
// ============================================================
module retro_word_sample_rom (
    input  wire         clk,
    input  wire [17:0]  address,
    output wire [7:0]   sample
);

    // ECC is disabled, so these status outputs are intentionally unused.
    wire dbiterr_unused;
    wire sbiterr_unused;
    
    // Xilinx Parameterized Macro: single-port read-only memory.
    xpm_memory_sprom #(
        .ADDR_WIDTH_A        (18),
        .AUTO_SLEEP_TIME     (0),
        .CASCADE_HEIGHT      (0),
        .ECC_MODE            ("no_ecc"),
        .MEMORY_INIT_FILE    ("retro_word_pcm.mem"),
        .MEMORY_INIT_PARAM   (""),
        .MEMORY_OPTIMIZATION ("false"),
        .MEMORY_PRIMITIVE    ("block"),
        .MEMORY_SIZE         (1310720), // 160 KiB x 8 bits
        .MESSAGE_CONTROL     (0),
        .READ_DATA_WIDTH_A   (8),
        .READ_LATENCY_A      (2),       // BRAM array read + output register
        .READ_RESET_VALUE_A  ("0"),
        .RST_MODE_A          ("SYNC"),
        .SIM_ASSERT_CHK      (0),
        .USE_MEM_INIT        (1),
        .WAKEUP_TIME         ("disable_sleep")
    ) word_rom_xpm (
        .dbiterra       (dbiterr_unused),
        .douta          (sample),
        .sbiterra       (sbiterr_unused),
        .addra          (address),
        .clka           (clk),
        .ena            (1'b1),
        .injectdbiterra (1'b0),
        .injectsbiterra (1'b0),
        .regcea         (1'b1),
        .rsta           (1'b0),
        .sleep          (1'b0)
    );

endmodule
