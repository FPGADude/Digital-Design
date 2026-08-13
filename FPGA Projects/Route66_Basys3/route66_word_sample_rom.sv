`timescale 1ns / 1ps
module route66_word_sample_rom (
    input  logic        clk,
    input  logic [17:0] address,
    output logic [7:0]  sample
);
    wire [7:0] sample_wire;
    wire dbiterr_unused, sbiterr_unused;

    // 109,211 used bytes. Allocate 112 KiB (917,504 bits) in block ROM.
    xpm_memory_sprom #(
        .ADDR_WIDTH_A        (18),
        .AUTO_SLEEP_TIME     (0),
        .CASCADE_HEIGHT      (0),
        .ECC_MODE            ("no_ecc"),
        .MEMORY_INIT_FILE    ("route66_word_pcm.mem"),
        .MEMORY_INIT_PARAM   (""),
        .MEMORY_OPTIMIZATION ("false"),
        .MEMORY_PRIMITIVE    ("block"),
        .MEMORY_SIZE         (917504),
        .MESSAGE_CONTROL     (0),
        .READ_DATA_WIDTH_A   (8),
        .READ_LATENCY_A      (2),
        .READ_RESET_VALUE_A  ("0"),
        .RST_MODE_A          ("SYNC"),
        .SIM_ASSERT_CHK      (0),
        .USE_MEM_INIT        (1),
        .WAKEUP_TIME         ("disable_sleep")
    ) u_rom (
        .dbiterra       (dbiterr_unused),
        .douta          (sample_wire),
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

    assign sample = sample_wire;
endmodule
