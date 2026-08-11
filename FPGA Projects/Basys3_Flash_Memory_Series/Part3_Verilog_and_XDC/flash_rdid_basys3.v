`timescale 1ns / 1ps

module flash_rdid_basys3 (
    input  wire       clk,
    input  wire       btnC,

    input  wire [1:0] sw,

    output wire       qspi_cs_n,
    output wire       qspi_mosi,
    input  wire       qspi_miso,

    output wire [7:0] led_data,
    output wire       led_done,
    output wire       led_pass
);

    // ============================================================
    // FSM STATES
    // ============================================================

    localparam STATE_WAIT_EOS       = 4'd0;
    localparam STATE_WAIT_1MS       = 4'd1;

    localparam STATE_RESET_ASSERT   = 4'd2;
    localparam STATE_SEND_FF        = 4'd3;
    localparam STATE_RESET_FINISH   = 4'd4;
    localparam STATE_RESET_PAUSE    = 4'd5;

    localparam STATE_RDID_ASSERT    = 4'd6;
    localparam STATE_SEND_9F        = 4'd7;
    localparam STATE_READ_ID        = 4'd8;
    localparam STATE_FINISH         = 4'd9;
    localparam STATE_DONE           = 4'd10;


    // ============================================================
    // DEBUG SIGNALS
    // ============================================================
    reg [3:0] state = STATE_WAIT_EOS;
    reg spi_sclk = 1'b0;
    reg cs_n = 1'b1;
    reg mosi = 1'b0;
    wire miso_internal;
    reg [23:0] rx_shift = 24'h000000;
    reg [23:0] rdid_result = 24'h000000;
    reg done = 1'b0;
    reg pass = 1'b0;
    
    assign miso_internal = qspi_miso;

    // ============================================================
    // STARTUPE2
    // ============================================================

    wire eos;

    STARTUPE2 #(
        .PROG_USR("FALSE"),
        .SIM_CCLK_FREQ(0.0)
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


    // ============================================================
    // STARTUP DELAY
    // ============================================================

    reg [16:0] startup_count = 17'd0;


    // ============================================================
    // PAUSE BETWEEN FF RESET AND RDID
    // ============================================================

    reg [6:0] pause_count = 7'd0;


    // ============================================================
    // SPI CLOCK TIMING
    // ============================================================

    reg [5:0] spi_div_count = 6'd0;

    wire spi_tick = (spi_div_count == 6'd49);


    // ============================================================
    // SPI REGISTERS / COUNTERS
    // ============================================================

    reg [7:0] tx_shift = 8'h00;

    reg [3:0] tx_bit_count = 4'd0;
    reg [5:0] rx_bit_count = 6'd0;

    reg rx_complete = 1'b0;


    // ============================================================
    // EXTERNAL SPI CONNECTIONS
    // ============================================================

    assign qspi_cs_n = cs_n;
    assign qspi_mosi = mosi;


    // ============================================================
    // STATUS OUTPUTS
    // ============================================================

    assign led_done = done;
    assign led_pass = pass;


    // ============================================================
    // DIAGNOSTIC BYTE DISPLAY
    //
    // Display the final latched result.
    //
    // SW1 SW0
    //
    // 00 -> C2
    // 01 -> 20
    // 10 -> 16
    // 11 -> 00
    // ============================================================

    reg [7:0] selected_byte;

    always @(*) begin

        case (sw)

            2'b00:
                selected_byte = rdid_result[23:16];

            2'b01:
                selected_byte = rdid_result[15:8];

            2'b10:
                selected_byte = rdid_result[7:0];

            default:
                selected_byte = 8'h00;

        endcase

    end

    assign led_data = selected_byte;


    // ============================================================
    // MAIN CONTROLLER
    // ============================================================

    always @(posedge clk) begin

        if (btnC) begin

            state         <= STATE_WAIT_EOS;

            startup_count <= 17'd0;
            pause_count   <= 7'd0;
            spi_div_count <= 6'd0;

            spi_sclk      <= 1'b0;

            cs_n          <= 1'b1;
            mosi          <= 1'b0;

            tx_shift      <= 8'h00;
            rx_shift      <= 24'h000000;
            rdid_result   <= 24'h000000;

            tx_bit_count  <= 4'd0;
            rx_bit_count  <= 6'd0;

            rx_complete   <= 1'b0;

            done          <= 1'b0;
            pass          <= 1'b0;

        end

        else begin

            case (state)

                // =================================================
                // WAIT FOR FPGA STARTUP
                // =================================================

                STATE_WAIT_EOS: begin

                    cs_n        <= 1'b1;
                    spi_sclk    <= 1'b0;
                    mosi        <= 1'b0;

                    done        <= 1'b0;
                    pass        <= 1'b0;

                    rx_complete <= 1'b0;

                    if (eos) begin

                        startup_count <= 17'd0;

                        state <= STATE_WAIT_1MS;

                    end

                end


                // =================================================
                // EXTRA 1 ms STARTUP DELAY
                // =================================================

                STATE_WAIT_1MS: begin

                    cs_n     <= 1'b1;
                    spi_sclk <= 1'b0;
                    mosi     <= 1'b0;

                    if (startup_count == 17'd99999) begin

                        startup_count <= 17'd0;

                        state <= STATE_RESET_ASSERT;

                    end

                    else begin

                        startup_count <= startup_count + 1'b1;

                    end

                end


                // =================================================
                // ASSERT CS FOR PERFORMANCE ENHANCE RESET
                // =================================================

                STATE_RESET_ASSERT: begin

                    cs_n <= 1'b0;

                    spi_sclk      <= 1'b0;
                    spi_div_count <= 6'd0;

                    tx_shift     <= 8'hFF;
                    tx_bit_count <= 4'd0;

                    mosi <= 1'b1;

                    state <= STATE_SEND_FF;

                end


                // =================================================
                // SEND FF
                // =================================================

                STATE_SEND_FF: begin

                    if (spi_tick) begin

                        spi_div_count <= 6'd0;

                        if (spi_sclk == 1'b0) begin

                            spi_sclk <= 1'b1;

                            if (tx_bit_count == 4'd7)
                                tx_bit_count <= 4'd0;
                            else
                                tx_bit_count <= tx_bit_count + 1'b1;

                        end

                        else begin

                            spi_sclk <= 1'b0;

                            if (tx_bit_count == 4'd0) begin

                                state <= STATE_RESET_FINISH;

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


                // =================================================
                // END FF TRANSACTION
                // =================================================

                STATE_RESET_FINISH: begin

                    spi_sclk <= 1'b0;
                    cs_n     <= 1'b1;
                    mosi     <= 1'b0;

                    pause_count <= 7'd0;

                    state <= STATE_RESET_PAUSE;

                end


                // =================================================
                // 1 us PAUSE
                // =================================================

                STATE_RESET_PAUSE: begin

                    cs_n     <= 1'b1;
                    spi_sclk <= 1'b0;
                    mosi     <= 1'b0;

                    if (pause_count == 7'd99) begin

                        pause_count <= 7'd0;

                        state <= STATE_RDID_ASSERT;

                    end

                    else begin

                        pause_count <= pause_count + 1'b1;

                    end

                end


                // =================================================
                // BEGIN RDID TRANSACTION
                // =================================================

                STATE_RDID_ASSERT: begin

                    cs_n <= 1'b0;

                    spi_sclk      <= 1'b0;
                    spi_div_count <= 6'd0;

                    tx_shift     <= 8'h9F;
                    tx_bit_count <= 4'd0;

                    rx_shift     <= 24'h000000;
                    rdid_result  <= 24'h000000;

                    rx_bit_count <= 6'd0;
                    rx_complete  <= 1'b0;

                    mosi <= 1'b1;

                    state <= STATE_SEND_9F;

                end


                // =================================================
                // SEND 9F
                // =================================================

                STATE_SEND_9F: begin

                    if (spi_tick) begin

                        spi_div_count <= 6'd0;

                        if (spi_sclk == 1'b0) begin

                            spi_sclk <= 1'b1;

                            if (tx_bit_count == 4'd7)
                                tx_bit_count <= 4'd0;
                            else
                                tx_bit_count <= tx_bit_count + 1'b1;

                        end

                        else begin

                            spi_sclk <= 1'b0;

                            if (tx_bit_count == 4'd0) begin

                                mosi <= 1'b0;

                                rx_bit_count <= 6'd0;
                                rx_complete  <= 1'b0;

                                state <= STATE_READ_ID;

                            end

                            else begin

                                tx_shift <= {
                                    tx_shift[6:0],
                                    1'b0
                                };

                                mosi <= tx_shift[6];

                            end

                        end

                    end

                    else begin

                        spi_div_count <= spi_div_count + 1'b1;

                    end

                end


                // =================================================
                // READ 24 RDID BITS
                // =================================================

                STATE_READ_ID: begin

                    if (spi_tick) begin

                        spi_div_count <= 6'd0;

                        // Rising edge: sample MISO
                        if (spi_sclk == 1'b0) begin

                            spi_sclk <= 1'b1;

                            if (!rx_complete) begin

                                rx_shift <= {
                                    rx_shift[22:0],
                                    miso_internal
                                };

                                if (rx_bit_count == 6'd23) begin

                                    rx_complete <= 1'b1;

                                end

                                else begin

                                    rx_bit_count <= rx_bit_count + 1'b1;

                                end

                            end

                        end

                        // Falling edge: finish after final bit
                        else begin

                            spi_sclk <= 1'b0;

                            if (rx_complete) begin

                                state <= STATE_FINISH;

                            end

                        end

                    end

                    else begin

                        spi_div_count <= spi_div_count + 1'b1;

                    end

                end


                // =================================================
                // END RDID TRANSACTION
                //
                // This is where we latch the final stable result.
                // =================================================

                STATE_FINISH: begin

                    spi_sclk <= 1'b0;
                    cs_n     <= 1'b1;
                    mosi     <= 1'b0;

                    // Capture final 24-bit identification value.
                    rdid_result <= rx_shift;

                    done <= 1'b1;

                    if (rx_shift == 24'hC22016)
                        pass <= 1'b1;
                    else
                        pass <= 1'b0;

                    state <= STATE_DONE;

                end


                // =================================================
                // HOLD FINAL RESULT
                // =================================================

                STATE_DONE: begin

                    cs_n     <= 1'b1;
                    spi_sclk <= 1'b0;
                    mosi     <= 1'b0;

                    done <= 1'b1;

                    // rdid_result is intentionally left unchanged.

                end


                // =================================================
                // SAFETY DEFAULT
                // =================================================

                default: begin

                    state <= STATE_WAIT_EOS;

                    cs_n        <= 1'b1;
                    spi_sclk    <= 1'b0;
                    mosi        <= 1'b0;

                    rx_complete <= 1'b0;

                end

            endcase

        end

    end 

    // ILA Instantiation
    ila_0 ILA0(
        .clk(    clk         ),     // 100MHz system clock                  
        .probe0(spi_sclk     ),     // 1 bit
        .probe1(cs_n         ),     // 1 bit
        .probe2(mosi         ),     // 1 bit
        .probe3(miso_internal),     // 1 bit
        .probe4(rx_shift     ),     // 24 bits
        .probe5(rdid_result  ),     // 24 bits
        .probe6(state        ),     // 4 bits
        .probe7({done, pass} )      // 2 bits
        );

endmodule
