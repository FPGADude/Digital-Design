`timescale 1ns / 1ps

// ============================================================================
// FPGA Discovery - QSPI Flash Showcase
// Final Top-Level RTL
//
// Demonstrates the Basys 3 onboard SPI flash as persistent storage for:
//
//   * FPGA configuration
//   * 8x16 character font
//   * Three 32x32 RGB332 sprites
//   * 22.05 kHz, unsigned 8-bit mono PCM audio
//
// Startup sequence:
//
//   1. The Artix-7 configures itself from the onboard flash.
//   2. STARTUPE2 asserts EOS (End Of Startup).
//   3. The design reads the font and sprite region with command 0x03.
//   4. Font and sprite bytes are copied into FPGA block RAM.
//   5. The VGA renderer then operates entirely from block RAM.
//   6. Flash ownership transfers to the audio streamer.
//   7. Audio is streamed into a FIFO and converted to PWM for the Pmod AMP2.
//
// Flash asset map:
//
//   0x200000 - 0x3C1B7F : Audio, 1,842,048 bytes
//   0x3E0000 - 0x3E0FFF : Font, 4096 bytes
//   0x3E1000 - 0x3E13FF : Sprite 1, 1024 bytes
//   0x3E2000 - 0x3E23FF : Sprite 2, 1024 bytes
//   0x3E3000 - 0x3E33FF : Sprite 3, 1024 bytes
//
// btnC resets the user logic. The FPGA configuration itself remains in flash.
// ============================================================================

module qspi_showcase_top (
    // 100 MHz Basys 3 system clock and center-button reset.
    input  wire       clk,
    input  wire       btnC,

    // Onboard SPI flash signals. CCLK/SCK is driven internally through
    // STARTUPE2, so only CS#, MOSI, and MISO appear as top-level ports.
    output wire       qspi_cs_n,
    output wire       qspi_mosi,
    input  wire       qspi_miso,

    // 12-bit Basys 3 VGA output: four bits each for red, green, and blue.
    output reg  [3:0] vgaRed,
    output reg  [3:0] vgaGreen,
    output reg  [3:0] vgaBlue,
    output wire       Hsync,
    output wire       Vsync,

    // Pmod AMP2 control/audio outputs.
    output wire       amp_pwm,
    output wire       amp_gain,
    output wire       amp_shutdown,

    // Hardware status indicators.
    output wire       led_done,
    output wire       led_pass,
    output wire       led_audio,
    output wire       led_underrun
);
wire eos;
    wire spi_sck, spi_mosi;
    wire [7:0] spi_rx;
    wire spi_done;

    // The single physical SPI byte engine is shared sequentially:
    // 1) visual loader owns it until load_complete
    // 2) audio streamer owns it forever after that.
    wire vis_byte_start, aud_byte_start;
    wire [7:0] vis_byte_tx, aud_byte_tx;
    wire vis_cs_n, aud_cs_n;
    wire vis_warmup_active, vis_warmup_sck;
    wire aud_warmup_active, aud_warmup_sck;

    wire [7:0] flash_data;
    wire [13:0] flash_index;
    wire flash_valid, load_busy, load_complete;

    wire audio_owner = load_complete;
    wire selected_start = audio_owner ? aud_byte_start : vis_byte_start;
    wire [7:0] selected_tx = audio_owner ? aud_byte_tx : vis_byte_tx;
    wire selected_cs_n = audio_owner ? aud_cs_n : vis_cs_n;
    wire selected_warmup_active = audio_owner ? aud_warmup_active : vis_warmup_active;
    wire selected_warmup_sck = audio_owner ? aud_warmup_sck : vis_warmup_sck;
    wire user_cclk = selected_warmup_active ? selected_warmup_sck : spi_sck;

    startup_cclk u_startup(.user_cclk(user_cclk), .eos(eos));

    spi_byte_engine #(.HALF_PERIOD_CLKS(50)) u_spi(
    .clk(clk), .reset(btnC), .start(selected_start), .tx_byte(selected_tx),
    .miso(qspi_miso), .sck(spi_sck), .mosi(spi_mosi), .rx_byte(spi_rx),
    .busy(), .done(spi_done)
    );

    assign qspi_mosi = spi_mosi;
    assign qspi_cs_n = selected_cs_n;

    // ------------------------ boot-time visual asset load ---------------------
    // 0x3400 bytes = through the final byte of sprite3.
    flash_reader #(
    .START_ADDRESS(24'h3E0000),
    .BYTE_COUNT(13312)
    ) u_reader(
    .clk(clk), .reset(btnC), .startup_eos(eos),
    .byte_done(spi_done), .byte_rx(spi_rx),
    .byte_start(vis_byte_start), .byte_tx(vis_byte_tx),
    .flash_cs_n(vis_cs_n),
    .warmup_active(vis_warmup_active), .warmup_sck(vis_warmup_sck),
    .data_out(flash_data), .data_index(flash_index),
    .data_valid(flash_valid), .busy(load_busy), .complete(load_complete)
    );

    // ---------------------------- write routing -------------------------------
    wire font_we = flash_valid && (flash_index < 14'h1000);
    wire s1_we   = flash_valid && (flash_index >= 14'h1000) && (flash_index < 14'h1400);
    wire s2_we   = flash_valid && (flash_index >= 14'h2000) && (flash_index < 14'h2400);
    wire s3_we   = flash_valid && (flash_index >= 14'h3000) && (flash_index < 14'h3400);

    wire [11:0] font_waddr = flash_index[11:0];
    wire [9:0] s1_waddr = flash_index - 14'h1000;
    wire [9:0] s2_waddr = flash_index - 14'h2000;
    wire [9:0] s3_waddr = flash_index - 14'h3000;

    // ------------------------------- BRAMs ------------------------------------
    wire [11:0] font_raddr;
    wire [7:0] font_rdata;
    font_bram u_font(
    .clk(clk), .we(font_we), .waddr(font_waddr), .wdata(flash_data),
    .raddr(font_raddr), .rdata(font_rdata)
    );

    wire [9:0] s1_raddr, s2_raddr, s3_raddr;
    wire [7:0] s1_rdata, s2_rdata, s3_rdata;

    sprite_bram u_sprite1(
    .clk(clk), .we(s1_we), .waddr(s1_waddr), .wdata(flash_data),
    .raddr(s1_raddr), .rdata(s1_rdata)
    );
    sprite_bram u_sprite2(
    .clk(clk), .we(s2_we), .waddr(s2_waddr), .wdata(flash_data),
    .raddr(s2_raddr), .rdata(s2_rdata)
    );
    sprite_bram u_sprite3(
    .clk(clk), .we(s3_we), .waddr(s3_waddr), .wdata(flash_data),
    .raddr(s3_raddr), .rdata(s3_rdata)
    );

    // --------------------------- load verification ----------------------------
    reg [14:0] byte_count_seen;
    reg spot_fail;

    always @(posedge clk) begin
    if (btnC) begin
   byte_count_seen <= 0;
   spot_fail <= 0;

    end
    else if (flash_valid) begin
   byte_count_seen <= byte_count_seen + 1'b1;

   case(flash_index)
    // Known font bytes provide a lightweight integrity check.
    14'h0000: if (flash_data != 8'h00) spot_fail <= 1;
    14'h0410: if (flash_data != 8'h18) spot_fail <= 1;
    14'h0412: if (flash_data != 8'h3C) spot_fail <= 1;
    14'h0414: if (flash_data != 8'h66) spot_fail <= 1;
    14'h041C: if (flash_data != 8'h66) spot_fail <= 1;
    14'h0FFF: if (flash_data != 8'h00) spot_fail <= 1;

    // Known sprite bytes provide lightweight integrity checks.
    // sprite1 offset 110 = 92
    14'h106E: if (flash_data != 8'h92) spot_fail <= 1;
    // sprite2 offset 21 = 92
    14'h2015: if (flash_data != 8'h92) spot_fail <= 1;
    // sprite3 offset 177 = B6
    14'h30B1: if (flash_data != 8'hB6) spot_fail <= 1;

    default: ;
   endcase

    end

    end

    wire assets_pass = load_complete &&
                    (byte_count_seen == 15'd13312) &&
                    !spot_fail;

    assign led_done = load_complete;
    assign led_pass = assets_pass;

    // ------------------------------ audio -------------------------------------
    // Audio starts only after font/sprites have been copied into BRAM.
    // This guarantees that VGA rendering no longer needs the flash.
    wire audio_reset = btnC || !load_complete;
    wire fifo_push, fifo_empty, fifo_full;
    wire [7:0] fifo_push_data, fifo_front;
    wire [10:0] fifo_count;
    wire audio_streaming;
    wire sample_tick;
    reg playback_started;
    reg [7:0] current_sample;
    reg underrun_latched;

    flash_audio_streamer #(
    .AUDIO_BASE(24'h200000),
    .AUDIO_LENGTH(24'h1C1B80),
    .FIFO_HIGH_WATER(1000)
    ) u_audio_stream(
    .clk(clk), .reset(audio_reset), .startup_eos(eos),
    .byte_done(spi_done), .byte_rx(spi_rx),
    .byte_start(aud_byte_start), .byte_tx(aud_byte_tx),
    .flash_cs_n(aud_cs_n),
    .warmup_active(aud_warmup_active), .warmup_sck(aud_warmup_sck),
    .fifo_count(fifo_count),
    .fifo_push(fifo_push), .fifo_data(fifo_push_data),
    .streaming(audio_streaming)
    );

    wire fifo_pop = sample_tick && playback_started && !fifo_empty;

    audio_fifo #(.ADDR_WIDTH(10)) u_audio_fifo(
    .clk(clk), .reset(audio_reset),
    .push(fifo_push), .push_data(fifo_push_data),
    .pop(fifo_pop), .front_data(fifo_front),
    .empty(fifo_empty), .full(fifo_full), .count(fifo_count)
    );

    sample_tick_22050 u_sample_tick(
    .clk(clk), .reset(audio_reset), .tick(sample_tick)
    );

    always @(posedge clk) begin
    if (audio_reset) begin
   playback_started <= 1'b0;
   current_sample <= 8'h80;
   underrun_latched <= 1'b0;

        end else begin
   if (!playback_started && fifo_count >= 11'd512)
    playback_started <= 1'b1;

   if (sample_tick && playback_started) begin
    if (!fifo_empty)
     current_sample <= fifo_front;
    else begin
     current_sample <= 8'h80;
     underrun_latched <= 1'b1;

    end

    end

    end

    end

    audio_pwm u_audio_pwm(
    .clk(clk), .reset(audio_reset),
    .sample(current_sample), .pwm_out(amp_pwm)
    );

    // GAIN=0 selects the AMP2 higher-gain setting (12 dB).
    assign amp_gain = 1'b0;
    assign amp_shutdown = 1'b1;
    assign led_audio = playback_started && audio_streaming;
    assign led_underrun = underrun_latched;

    // ------------------------------- VGA --------------------------------------
    wire pixel_tick;
    wire [9:0] pixel_x, pixel_y;
    wire video_active;

    vga_640x480 u_vga(
    .clk(clk), .pixel_tick(pixel_tick),
    .pixel_x(pixel_x), .pixel_y(pixel_y),
    .video_active(video_active), .hsync(Hsync), .vsync(Vsync)
    );

    // ------------------------------- text -------------------------------------
    wire text_on;
    wire [11:0] text_rgb;

    text_renderer u_text(
    .font_ready(assets_pass),
    .pixel_x(pixel_x), .pixel_y(pixel_y),
    .font_data(font_rdata), .font_addr(font_raddr),
    .text_on(text_on), .text_rgb(text_rgb)
    );

    // ------------------------------ sprites -----------------------------------
    wire s1_on, s2_on, s3_on;
    wire [11:0] s1_rgb, s2_rgb, s3_rgb;

    // Sprite 1: left position. A 32x32 source image is displayed at 4x scale.
    sprite_renderer_32x32 u_render_s1(
    .pixel_x(pixel_x), .pixel_y(pixel_y),
    .origin_x(10'd70), .origin_y(10'd145),
    .enable(assets_pass), .sprite_data(s1_rdata),
    .sprite_addr(s1_raddr), .sprite_on(s1_on), .sprite_rgb(s1_rgb)
    );

    // Sprite 3: center position.
    sprite_renderer_32x32 u_render_s3(
    .pixel_x(pixel_x), .pixel_y(pixel_y),
    .origin_x(10'd256), .origin_y(10'd145),
    .enable(assets_pass), .sprite_data(s3_rdata),
    .sprite_addr(s3_raddr), .sprite_on(s3_on), .sprite_rgb(s3_rgb)
    );

    // Sprite 2: right position.
    sprite_renderer_32x32 u_render_s2(
    .pixel_x(pixel_x), .pixel_y(pixel_y),
    .origin_x(10'd442), .origin_y(10'd145),
    .enable(assets_pass), .sprite_data(s2_rdata),
    .sprite_addr(s2_raddr), .sprite_on(s2_on), .sprite_rgb(s2_rgb)
    );

    // --------------------------- background scene -----------------------------
    reg [11:0] base_rgb;

    always @(*) begin
    base_rgb = 12'h000;

    if (video_active) begin
   base_rgb = 12'h247;

   if (pixel_x>=40 && pixel_x<600 && pixel_y>=35 && pixel_y<95)
    base_rgb = 12'hEEE;

   if (pixel_x>=70 && pixel_x<570 && pixel_y>=320 && pixel_y<420)
    base_rgb = 12'h125;

   if (pixel_x>=90 && pixel_x<550 && pixel_y>=375 && pixel_y<400) begin
    if (!load_complete)
     base_rgb = 12'hF80;
    else if (assets_pass)
     base_rgb = 12'h1D4;
    else
     base_rgb = 12'hE11;

    end

    end

    end

    // Priority: text, then sprites, then background.
    always @(*) begin
    if (!video_active) begin
   vgaRed=0;
   vgaGreen=0;
   vgaBlue=0;

    end
    else if (text_on) begin
   vgaRed=text_rgb[11:8];
   vgaGreen=text_rgb[7:4];
   vgaBlue=text_rgb[3:0];

    end
    else if (s1_on) begin
   vgaRed=s1_rgb[11:8];
   vgaGreen=s1_rgb[7:4];
   vgaBlue=s1_rgb[3:0];

    end
    else if (s3_on) begin
   vgaRed=s3_rgb[11:8];
   vgaGreen=s3_rgb[7:4];
   vgaBlue=s3_rgb[3:0];

    end
    else if (s2_on) begin
   vgaRed=s2_rgb[11:8];
   vgaGreen=s2_rgb[7:4];
   vgaBlue=s2_rgb[3:0];

    end
    else begin
   vgaRed=base_rgb[11:8];
   vgaGreen=base_rgb[7:4];
   vgaBlue=base_rgb[3:0];

    end

    end

endmodule
