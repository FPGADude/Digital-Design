`timescale 1ns / 1ps

// ============================================================================
// QSPI Flash Audio Streamer
//
// Streams raw unsigned 8-bit PCM samples from the onboard flash.
//
// Flash transaction:
//   CS# LOW
//   0x03
//   24-bit AUDIO_BASE address
//   sequential data bytes...
//
// The flash can be paused between bytes because SCK simply remains idle. When
// the FIFO reaches FIFO_HIGH_WATER, this controller stops requesting bytes
// until playback creates room. CS# remains low during that pause.
//
// After AUDIO_LENGTH bytes, CS# is released and a new READ begins at AUDIO_BASE,
// causing the music track to loop continuously.
// ============================================================================
module flash_audio_streamer #(
    parameter [23:0]  AUDIO_BASE      = 24'h200000,
    parameter [23:0]  AUDIO_LENGTH    = 24'h1C1B80,
    parameter integer FIFO_HIGH_WATER = 1000
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

    input  wire [10:0] fifo_count,
    output reg         fifo_push,
    output reg  [7:0]  fifo_data,

    output reg         streaming
);

    // One millisecond at the Basys 3 100 MHz system clock.
    localparam integer START_DELAY_CLKS = 100_000;

    localparam [7:0] CMD_READ = 8'h03;

    localparam [4:0]
        S_EOS     = 5'd0,
        S_DELAY   = 5'd1,
        S_WARM    = 5'd2,
        S_CMD     = 5'd3,
        S_CMDW    = 5'd4,
        S_A2      = 5'd5,
        S_A2W     = 5'd6,
        S_A1      = 5'd7,
        S_A1W     = 5'd8,
        S_A0      = 5'd9,
        S_A0W     = 5'd10,
        S_DATA    = 5'd11,
        S_DATAW   = 5'd12,
        S_RESTART = 5'd13;

    reg [4:0]  state;
    reg [16:0] delay_count;
    reg [6:0]  warm_half_count;
    reg [5:0]  warm_edge_count;
    reg [23:0] bytes_sent;

    // Request one byte transaction from spi_byte_engine.
    task launch_byte;
        input [7:0] value;
        begin
            byte_tx    <= value;
            byte_start <= 1'b1;
        end
    endtask

    always @(posedge clk) begin
        if (reset) begin
            state             <= S_EOS;
            delay_count       <= 17'd0;
            warm_half_count   <= 7'd0;
            warm_edge_count   <= 6'd0;
            byte_start        <= 1'b0;
            byte_tx           <= 8'h00;
            flash_cs_n        <= 1'b1;
            warmup_active     <= 1'b0;
            warmup_sck        <= 1'b0;
            fifo_push         <= 1'b0;
            fifo_data         <= 8'h80;
            bytes_sent        <= 24'd0;
            streaming         <= 1'b0;
        end else begin
            // Pulse outputs default low.
            byte_start <= 1'b0;
            fifo_push  <= 1'b0;

            case (state)
                S_EOS: begin
                    flash_cs_n <= 1'b1;
                    streaming  <= 1'b0;

                    if (startup_eos) begin
                        delay_count <= 17'd0;
                        state       <= S_DELAY;
                    end
                end

                S_DELAY: begin
                    if (delay_count >= START_DELAY_CLKS - 1) begin
                        delay_count     <= 17'd0;
                        warm_half_count <= 7'd0;
                        warm_edge_count <= 6'd0;
                        warmup_active   <= 1'b1;
                        warmup_sck      <= 1'b0;
                        state           <= S_WARM;
                    end else begin
                        delay_count <= delay_count + 1'b1;
                    end
                end

                S_WARM: begin
                    flash_cs_n <= 1'b1;

                    if (warm_half_count >= 7'd49) begin
                        warm_half_count <= 7'd0;
                        warmup_sck      <= ~warmup_sck;

                        // Sixteen half-edges = eight complete warm-up clocks.
                        if (warm_edge_count >= 6'd15) begin
                            warmup_sck    <= 1'b0;
                            warmup_active <= 1'b0;
                            bytes_sent    <= 24'd0;
                            state         <= S_CMD;
                        end else begin
                            warm_edge_count <= warm_edge_count + 1'b1;
                        end
                    end else begin
                        warm_half_count <= warm_half_count + 1'b1;
                    end
                end

                S_CMD: begin
                    flash_cs_n <= 1'b0;
                    launch_byte(CMD_READ);
                    state <= S_CMDW;
                end

                S_CMDW: if (byte_done) state <= S_A2;

                S_A2: begin
                    launch_byte(AUDIO_BASE[23:16]);
                    state <= S_A2W;
                end

                S_A2W: if (byte_done) state <= S_A1;

                S_A1: begin
                    launch_byte(AUDIO_BASE[15:8]);
                    state <= S_A1W;
                end

                S_A1W: if (byte_done) state <= S_A0;

                S_A0: begin
                    launch_byte(AUDIO_BASE[7:0]);
                    state <= S_A0W;
                end

                S_A0W: begin
                    if (byte_done) begin
                        streaming <= 1'b1;
                        state     <= S_DATA;
                    end
                end

                S_DATA: begin
                    // Request another byte only when the FIFO has room below
                    // the selected high-water mark.
                    if (fifo_count < FIFO_HIGH_WATER) begin
                        launch_byte(8'h00);
                        state <= S_DATAW;
                    end
                end

                S_DATAW: begin
                    if (byte_done) begin
                        fifo_data <= byte_rx;
                        fifo_push <= 1'b1;

                        if (bytes_sent == AUDIO_LENGTH - 1) begin
                            flash_cs_n <= 1'b1;
                            bytes_sent <= 24'd0;
                            streaming  <= 1'b0;
                            state      <= S_RESTART;
                        end else begin
                            bytes_sent <= bytes_sent + 1'b1;
                            state      <= S_DATA;
                        end
                    end
                end

                S_RESTART: begin
                    // Give the flash one FPGA clock with CS# high before the
                    // next 0x03 command starts the song again.
                    state <= S_CMD;
                end

                default: begin
                    flash_cs_n <= 1'b1;
                    streaming  <= 1'b0;
                    state      <= S_EOS;
                end
            endcase
        end
    end

endmodule
