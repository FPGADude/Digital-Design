`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - FPGA Flash From the Ground Up
// Part 4 Flash Sprite Loader
//
// Reads a 32x32 RGB332 sprite from the Macronix MX25L3273E configuration
// flash and streams the 1024 received bytes into FPGA block RAM.
//
// Flash layout used by Part 4:
//
//   FPGA configuration image : begins at 0x000000
//   Sprite data              : begins at 0x3F0000
//
// SPI transaction:
//
//   CS# LOW
//   MOSI: 03 3F 00 00
//         |  \_______/
//         |     |
//         |   24-bit starting address
//         |
//         +-- 03h = normal READ command
//
//   MISO: 1024 sequential sprite bytes
//   CS# HIGH
//
// The loader also calculates a 16-bit additive checksum while receiving the
// sprite. PASS asserts only when all 1024 bytes have been received and the
// final checksum matches EXPECTED_CHECKSUM.
// ============================================================================

module flash_sprite_loader (
    input  wire       clk,
    input  wire       btnC,

    output wire       qspi_cs_n,
    output wire       qspi_mosi,
    input  wire       qspi_miso,

    output reg        sprite_we,
    output reg  [9:0] sprite_waddr,
    output reg  [7:0] sprite_wdata,

    output reg        done,
    output reg        pass
);

    // ========================================================================
    // FSM STATES
    // ========================================================================

    localparam [3:0] S_WAIT_EOS     = 4'd0;
    localparam [3:0] S_WAIT_1MS     = 4'd1;
    localparam [3:0] S_RST_ASSERT   = 4'd2;
    localparam [3:0] S_SEND_FF      = 4'd3;
    localparam [3:0] S_RST_FINISH   = 4'd4;
    localparam [3:0] S_RST_PAUSE    = 4'd5;
    localparam [3:0] S_READ_ASSERT  = 4'd6;
    localparam [3:0] S_SEND_HEADER  = 4'd7;
    localparam [3:0] S_READ_DATA    = 4'd8;
    localparam [3:0] S_FINISH       = 4'd9;
    localparam [3:0] S_DONE         = 4'd10;


    // ========================================================================
    // FLASH READ CONSTANTS
    // ========================================================================

    // 03h = normal READ command
    // 3F0000h = starting flash address of spaceship.bin
    localparam [31:0] READ_HEADER = 32'h03_3F_00_00;

    // IMPORTANT:
    // This value must match the checksum reported by png_to_rgb332_bin.py
    // for the exact sprite.bin file placed into flash.
    localparam [15:0] EXPECTED_CHECKSUM = 16'hCAFA;


    // ========================================================================
    // SPI OUTPUT REGISTERS
    // ========================================================================

    reg [3:0] state = S_WAIT_EOS;

    reg spi_sclk = 1'b0;
    reg cs_n     = 1'b1;
    reg mosi     = 1'b0;

    assign qspi_cs_n = cs_n;
    assign qspi_mosi = mosi;

    wire miso_internal;
    assign miso_internal = qspi_miso;


    // ========================================================================
    // STARTUPE2
    //
    // The MX25L3273E is also the Basys 3 configuration flash. Its SCLK line
    // is connected to the FPGA's dedicated CCLK pin, which cannot be driven
    // as a normal user I/O.
    //
    // STARTUPE2 gives our user logic access to CCLK through USRCCLKO.
    // EOS tells us when FPGA configuration/startup has completed.
    // ========================================================================

    wire eos;

    STARTUPE2 #(
        .PROG_USR      ("FALSE"),
        .SIM_CCLK_FREQ (0.0)
    )
    startup_inst (
        .CFGCLK     (),
        .CFGMCLK    (),
        .EOS        (eos),
        .PREQ       (),

        .CLK        (1'b0),
        .GSR        (1'b0),
        .GTS        (1'b0),
        .KEYCLEARB  (1'b1),
        .PACK       (1'b0),

        .USRCCLKO   (spi_sclk),
        .USRCCLKTS  (1'b0),

        .USRDONEO   (1'b1),
        .USRDONETS  (1'b1)
    );


    // ========================================================================
    // STARTUP / SPI CLOCK TIMING
    // ========================================================================

    // 100 MHz clock -> 100,000 clocks ~= 1 ms.
    reg [16:0] startup_count = 17'd0;

    // 100 clocks at 100 MHz ~= 1 us pause with CS# high.
    reg [6:0] pause_count = 7'd0;

    // Toggle SPI SCLK every 50 system clocks:
    //
    //   100 MHz / (50 * 2) = 1 MHz SPI clock
    reg [5:0] spi_div_count = 6'd0;

    wire spi_tick;
    assign spi_tick = (spi_div_count == 6'd49);


    // ========================================================================
    // TRANSMIT REGISTERS
    // ========================================================================

    // FFh escape command sent after FPGA startup.
    reg [3:0] ff_bit_count = 4'd0;

    // READ_HEADER is shifted MSB-first onto MOSI.
    reg [31:0] tx_shift     = 32'h00000000;
    reg [5:0]  tx_bit_count = 6'd0;
    reg        tx_complete  = 1'b0;


    // ========================================================================
    // RECEIVE REGISTERS
    // ========================================================================

    // Builds one received byte from eight MISO samples.
    reg [7:0] rx_byte_shift = 8'h00;
    reg [3:0] rx_bit_count  = 4'd0;

    // Counts sprite bytes 0 through 1023.
    reg [9:0] byte_count = 10'd0;

    reg rx_complete = 1'b0;

    // 16-bit additive checksum of all received bytes.
    reg [15:0] checksum = 16'h0000;


    // ========================================================================
    // MAIN CONTROLLER
    //
    // SPI Mode 0 behavior used here:
    //   - SCLK idles LOW
    //   - Flash samples MOSI on rising edges
    //   - FPGA samples MISO on rising edges
    //   - Output data changes around falling edges
    // ========================================================================

    always @(posedge clk) begin

        // sprite_we is a one-system-clock pulse whenever one full sprite byte
        // has been received and should be written into BRAM.
        sprite_we <= 1'b0;

        if (btnC) begin

            // ----------------------------------------------------------------
            // Synchronous restart
            // ----------------------------------------------------------------

            state         <= S_WAIT_EOS;

            startup_count <= 17'd0;
            pause_count   <= 7'd0;
            spi_div_count <= 6'd0;

            spi_sclk      <= 1'b0;
            cs_n          <= 1'b1;
            mosi          <= 1'b0;

            ff_bit_count  <= 4'd0;

            tx_shift      <= 32'h00000000;
            tx_bit_count  <= 6'd0;
            tx_complete   <= 1'b0;

            rx_byte_shift <= 8'h00;
            rx_bit_count  <= 4'd0;
            byte_count    <= 10'd0;
            rx_complete   <= 1'b0;

            checksum      <= 16'h0000;

            sprite_waddr  <= 10'd0;
            sprite_wdata  <= 8'h00;

            done          <= 1'b0;
            pass          <= 1'b0;

        end
        else begin

            case (state)

                // ============================================================
                // WAIT FOR FPGA STARTUP TO COMPLETE
                // ============================================================

                S_WAIT_EOS: begin

                    cs_n     <= 1'b1;
                    spi_sclk <= 1'b0;
                    mosi     <= 1'b0;

                    done     <= 1'b0;
                    pass     <= 1'b0;

                    if (eos) begin
                        startup_count <= 17'd0;
                        state         <= S_WAIT_1MS;
                    end

                end


                // ============================================================
                // WAIT AN EXTRA ~1 ms AFTER EOS
                // ============================================================

                S_WAIT_1MS: begin

                    cs_n     <= 1'b1;
                    spi_sclk <= 1'b0;
                    mosi     <= 1'b0;

                    if (startup_count == 17'd99999) begin
                        startup_count <= 17'd0;
                        state         <= S_RST_ASSERT;
                    end
                    else begin
                        startup_count <= startup_count + 1'b1;
                    end

                end


                // ============================================================
                // BEGIN FFh ESCAPE TRANSACTION
                //
                // Part 3 showed that the configuration process can leave the
                // flash in an enhanced/read state. Sending FFh with its own
                // CS# transaction returns it to a known serial-read state.
                // ============================================================

                S_RST_ASSERT: begin

                    cs_n          <= 1'b0;
                    spi_sclk      <= 1'b0;
                    spi_div_count <= 6'd0;

                    ff_bit_count  <= 4'd0;

                    // FFh is all ones, so MOSI remains HIGH for all 8 bits.
                    mosi          <= 1'b1;

                    state         <= S_SEND_FF;

                end


                // ============================================================
                // SEND FFh
                // ============================================================

                S_SEND_FF: begin

                    if (spi_tick) begin

                        spi_div_count <= 6'd0;

                        if (spi_sclk == 1'b0) begin

                            // Rising SPI edge.
                            spi_sclk <= 1'b1;

                            if (ff_bit_count == 4'd7) begin
                                ff_bit_count <= 4'd0;
                            end
                            else begin
                                ff_bit_count <= ff_bit_count + 1'b1;
                            end

                        end
                        else begin

                            // Falling SPI edge.
                            spi_sclk <= 1'b0;

                            if (ff_bit_count == 4'd0) begin
                                state <= S_RST_FINISH;
                            end
                            else begin
                                mosi <= 1'b1;
                            end

                        end

                    end
                    else begin
                        spi_div_count <= spi_div_count + 1'b1;
                    end

                end


                // ============================================================
                // END FFh TRANSACTION
                // ============================================================

                S_RST_FINISH: begin

                    spi_sclk   <= 1'b0;
                    cs_n       <= 1'b1;
                    mosi       <= 1'b0;

                    pause_count <= 7'd0;

                    state      <= S_RST_PAUSE;

                end


                // ============================================================
                // KEEP CS# HIGH FOR ~1 us
                // ============================================================

                S_RST_PAUSE: begin

                    cs_n     <= 1'b1;
                    spi_sclk <= 1'b0;
                    mosi     <= 1'b0;

                    if (pause_count == 7'd99) begin
                        pause_count <= 7'd0;
                        state       <= S_READ_ASSERT;
                    end
                    else begin
                        pause_count <= pause_count + 1'b1;
                    end

                end


                // ============================================================
                // BEGIN SPRITE READ TRANSACTION
                //
                // Load:
                //
                //   03 3F 00 00
                //
                // into the 32-bit transmit shift register.
                // ============================================================

                S_READ_ASSERT: begin

                    cs_n          <= 1'b0;
                    spi_sclk      <= 1'b0;
                    spi_div_count <= 6'd0;

                    tx_shift      <= READ_HEADER;
                    tx_bit_count  <= 6'd0;
                    tx_complete   <= 1'b0;

                    rx_byte_shift <= 8'h00;
                    rx_bit_count  <= 4'd0;
                    byte_count    <= 10'd0;
                    rx_complete   <= 1'b0;

                    checksum      <= 16'h0000;

                    done          <= 1'b0;
                    pass          <= 1'b0;

                    // Present the first (MSB) header bit before the first
                    // rising SPI edge.
                    mosi          <= READ_HEADER[31];

                    state         <= S_SEND_HEADER;

                end


                // ============================================================
                // SEND READ COMMAND + 24-BIT ADDRESS
                // ============================================================

                S_SEND_HEADER: begin

                    if (spi_tick) begin

                        spi_div_count <= 6'd0;

                        if (spi_sclk == 1'b0) begin

                            // Rising edge: flash samples current MOSI bit.
                            spi_sclk <= 1'b1;

                            if (tx_bit_count == 6'd31) begin
                                tx_complete <= 1'b1;
                            end
                            else begin
                                tx_bit_count <= tx_bit_count + 1'b1;
                            end

                        end
                        else begin

                            // Falling edge: prepare the next MOSI bit.
                            spi_sclk <= 1'b0;

                            if (tx_complete) begin

                                // Header is complete. Keep CS# LOW and begin
                                // receiving sequential bytes immediately.
                                tx_complete   <= 1'b0;

                                mosi          <= 1'b0;

                                rx_bit_count  <= 4'd0;
                                byte_count    <= 10'd0;
                                rx_byte_shift <= 8'h00;

                                state         <= S_READ_DATA;

                            end
                            else begin

                                tx_shift <= {tx_shift[30:0], 1'b0};
                                mosi     <= tx_shift[30];

                            end

                        end

                    end
                    else begin
                        spi_div_count <= spi_div_count + 1'b1;
                    end

                end


                // ============================================================
                // READ 1024 SEQUENTIAL SPRITE BYTES
                // ============================================================

                S_READ_DATA: begin

                    if (spi_tick) begin

                        spi_div_count <= 6'd0;

                        if (spi_sclk == 1'b0) begin

                            // ------------------------------------------------
                            // Rising SPI edge: sample one MISO bit.
                            // ------------------------------------------------

                            spi_sclk <= 1'b1;

                            rx_byte_shift <= {
                                rx_byte_shift[6:0],
                                miso_internal
                            };

                            if (rx_bit_count == 4'd7) begin

                                // The eighth sampled bit completes one byte.
                                //
                                // Write the completed byte to BRAM.
                                sprite_we    <= 1'b1;
                                sprite_waddr <= byte_count;
                                sprite_wdata <= {
                                    rx_byte_shift[6:0],
                                    miso_internal
                                };

                                // Add the same completed byte to the checksum.
                                checksum <= checksum + {
                                    rx_byte_shift[6:0],
                                    miso_internal
                                };

                                rx_bit_count  <= 4'd0;
                                rx_byte_shift <= 8'h00;

                                if (byte_count == 10'd1023) begin

                                    // All 1024 bytes have now been sampled.
                                    rx_complete <= 1'b1;

                                end
                                else begin

                                    byte_count <= byte_count + 1'b1;

                                end

                            end
                            else begin

                                rx_bit_count <= rx_bit_count + 1'b1;

                            end

                        end
                        else begin

                            // ------------------------------------------------
                            // Falling SPI edge.
                            //
                            // After the final byte has been received, finish
                            // the transaction and raise CS# in the next state.
                            // ------------------------------------------------

                            spi_sclk <= 1'b0;

                            if (rx_complete) begin
                                state <= S_FINISH;
                            end

                        end

                    end
                    else begin
                        spi_div_count <= spi_div_count + 1'b1;
                    end

                end


                // ============================================================
                // FINISH READ AND VERIFY CHECKSUM
                // ============================================================

                S_FINISH: begin

                    spi_sclk <= 1'b0;
                    cs_n     <= 1'b1;
                    mosi     <= 1'b0;

                    done     <= 1'b1;

                    if (checksum == EXPECTED_CHECKSUM) begin
                        pass <= 1'b1;
                    end
                    else begin
                        pass <= 1'b0;
                    end

                    state <= S_DONE;

                end


                // ============================================================
                // HOLD FINAL STATUS
                // ============================================================

                S_DONE: begin

                    cs_n     <= 1'b1;
                    spi_sclk <= 1'b0;
                    mosi     <= 1'b0;

                    done     <= 1'b1;

                end


                // ============================================================
                // SAFETY DEFAULT
                // ============================================================

                default: begin

                    state       <= S_WAIT_EOS;

                    cs_n        <= 1'b1;
                    spi_sclk    <= 1'b0;
                    mosi        <= 1'b0;

                    rx_complete <= 1'b0;

                end

            endcase

        end

    end

endmodule
