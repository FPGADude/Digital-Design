`timescale 1ns / 1ps

// ------------------------------------------------------------
// SSD1306 Arcade Driver - Modular Version
//
// Owns:
//   - SSD1306 init and I2C pixel streaming
//   - Menu text rendering
//   - Game pixel mux
//
// Does NOT own game logic. Games are separate modules with the same
// standard interface and return a single pixel_on signal.
// ------------------------------------------------------------
module ssd1306_arcade_driver #(
    parameter int CLK_HZ = 12_000_000,
    parameter int I2C_HZ = 100_000,
    parameter logic [7:0] OLED_ADDR_WR = 8'h78,
    parameter int FRAME_WAIT_CLKS = 600_000,
    parameter int SNAKE_HZ = 2
)(
    input  logic clk,
    input  logic reset,

    input  logic [1:0] menu_index,
    input  logic selected_mode,

    input  logic btn_up,
    input  logic btn_down,
    input  logic btn_left,
    input  logic btn_right,
    input  logic btn_a,
    input  logic btn_start,

    output logic oled_scl,
    inout  wire  oled_sda,

    output logic frame_tick,
    output logic [3:0] audio_event
);

    logic sda_oe;
    assign oled_sda = sda_oe ? 1'b0 : 1'bz;

    logic tx_start;
    logic [7:0] tx_b0, tx_b1, tx_b2;
    logic tx_busy;
    logic tx_done;

    i2c_3byte_tx_master #(
        .CLK_HZ(CLK_HZ),
        .I2C_HZ(I2C_HZ)
    ) i2c_tx (
        .clk(clk),
        .reset(reset),
        .start_tx(tx_start),
        .byte0(tx_b0),
        .byte1(tx_b1),
        .byte2(tx_b2),
        .busy(tx_busy),
        .done(tx_done),
        .scl(oled_scl),
        .sda_oe(sda_oe)
    );

    typedef enum logic [4:0] {
        S_POWER_WAIT,
        S_INIT_SEND,
        S_INIT_WAIT,
        S_ADDR_CMD_SEND,
        S_ADDR_CMD_WAIT,
        S_DATA_SEND,
        S_DATA_WAIT,
        S_FRAME_WAIT
    } state_t;

    state_t state;

    logic [23:0] wait_count;
    logic [7:0] init_index;
    logic [3:0] addr_cmd_index;
    logic [2:0] page;
    logic [6:0] col;

    localparam int INIT_LEN = 28;
    logic [7:0] init_rom [0:INIT_LEN-1];

    initial begin
        init_rom[0]  = 8'hAE; init_rom[1]  = 8'hD5; init_rom[2]  = 8'h80;
        init_rom[3]  = 8'hA8; init_rom[4]  = 8'h3F; init_rom[5]  = 8'hD3;
        init_rom[6]  = 8'h00; init_rom[7]  = 8'h40; init_rom[8]  = 8'h8D;
        init_rom[9]  = 8'h14; init_rom[10] = 8'h20; init_rom[11] = 8'h00;
        init_rom[12] = 8'hA1; init_rom[13] = 8'hC8; init_rom[14] = 8'hDA;
        init_rom[15] = 8'h12; init_rom[16] = 8'h81; init_rom[17] = 8'hCF;
        init_rom[18] = 8'hD9; init_rom[19] = 8'hF1; init_rom[20] = 8'hDB;
        init_rom[21] = 8'h40; init_rom[22] = 8'hA4; init_rom[23] = 8'hA6;
        init_rom[24] = 8'h2E; init_rom[25] = 8'hAF; init_rom[26] = 8'hE3;
        init_rom[27] = 8'hE3;
    end

    function automatic logic [7:0] addr_cmd_byte(input logic [3:0] idx);
        begin
            case (idx)
                4'd0: addr_cmd_byte = 8'h21;
                4'd1: addr_cmd_byte = 8'h00;
                4'd2: addr_cmd_byte = 8'h7F;
                4'd3: addr_cmd_byte = 8'h22;
                4'd4: addr_cmd_byte = 8'h00;
                4'd5: addr_cmd_byte = 8'h07;
                default: addr_cmd_byte = 8'hE3;
            endcase
        end
    endfunction

    function automatic logic [7:0] line_char(input int line, input int pos);
        begin
            line_char = " ";

            if (!selected_mode) begin
                case (line)
                    0: begin
                        case (pos)
                            0:  line_char = "F"; 1:  line_char = "P"; 2:  line_char = "G";
                            3:  line_char = "A"; 4:  line_char = " "; 5:  line_char = "A";
                            6:  line_char = "R"; 7:  line_char = "C"; 8:  line_char = "A";
                            9:  line_char = "D"; 10: line_char = "E";
                            default: line_char = " ";
                        endcase
                    end
                    2: begin
                        case (pos)
                            0: line_char = (menu_index == 2'd0) ? ">" : " ";
                            2: line_char = "S"; 3: line_char = "N"; 4: line_char = "A";
                            5: line_char = "K"; 6: line_char = "E";
                            default: line_char = " ";
                        endcase
                    end
                    3: begin
                        case (pos)
                            0: line_char = (menu_index == 2'd1) ? ">" : " ";
                            2: line_char = "P"; 3: line_char = "O"; 4: line_char = "N"; 5: line_char = "G";
                            default: line_char = " ";
                        endcase
                    end
                    4: begin
                        case (pos)
                            0: line_char = (menu_index == 2'd2) ? ">" : " ";
                            2: line_char = "B"; 3: line_char = "R"; 4: line_char = "E";
                            5: line_char = "A"; 6: line_char = "K"; 7: line_char = "O";
                            8: line_char = "U"; 9: line_char = "T";
                            default: line_char = " ";
                        endcase
                    end
                    5: begin
                        case (pos)
                            0: line_char = (menu_index == 2'd3) ? ">" : " ";
                            2: line_char = "I"; 3: line_char = "N"; 4: line_char = "V";
                            5: line_char = "A"; 6: line_char = "D"; 7: line_char = "E";
                            8: line_char = "R"; 9: line_char = "S";
                            default: line_char = " ";
                        endcase
                    end
                    7: begin
                        case (pos)
                            0: line_char = "A"; 1: line_char = "="; 2: line_char = "S";
                            3: line_char = "T"; 4: line_char = "A"; 5: line_char = "R";
                            6: line_char = "T";
                            default: line_char = " ";
                        endcase
                    end
                    default: line_char = " ";
                endcase
            end else begin
                // Text screen for games that are not implemented yet.
                case (line)
                    1: begin
                        case (pos)
                            0: line_char = "S"; 1: line_char = "E"; 2: line_char = "L"; 3: line_char = "E";
                            4: line_char = "C"; 5: line_char = "T"; 6: line_char = "E"; 7: line_char = "D";
                            default: line_char = " ";
                        endcase
                    end
                    3: begin
                        case (menu_index)
                            2'd0: begin
                                case (pos)
                                    0: line_char = "S"; 1: line_char = "N"; 2: line_char = "A"; 3: line_char = "K"; 4: line_char = "E";
                                    default: line_char = " ";
                                endcase
                            end
                            2'd1: begin
                                case (pos)
                                    0: line_char = "P"; 1: line_char = "O"; 2: line_char = "N"; 3: line_char = "G";
                                    default: line_char = " ";
                                endcase
                            end
                            2'd2: begin
                                case (pos)
                                    0: line_char = "B"; 1: line_char = "R"; 2: line_char = "E"; 3: line_char = "A";
                                    4: line_char = "K"; 5: line_char = "O"; 6: line_char = "U"; 7: line_char = "T";
                                    default: line_char = " ";
                                endcase
                            end
                            default: begin
                                case (pos)
                                    0: line_char = "I"; 1: line_char = "N"; 2: line_char = "V"; 3: line_char = "A";
                                    4: line_char = "D"; 5: line_char = "E"; 6: line_char = "R"; 7: line_char = "S";
                                    default: line_char = " ";
                                endcase
                            end
                        endcase
                    end
                    6: begin
                        case (pos)
                            0:  line_char = "S"; 1:  line_char = "E"; 2:  line_char = "L";
                            3:  line_char = "E"; 4:  line_char = "C"; 5:  line_char = "T";
                            6:  line_char = "="; 7:  line_char = "B"; 8:  line_char = "A";
                            9:  line_char = "C"; 10: line_char = "K";
                            default: line_char = " ";
                        endcase
                    end
                    default: line_char = " ";
                endcase
            end
        end
    endfunction

    function automatic logic [4:0] font_bits(input logic [7:0] c, input int row);
        begin
            font_bits = 5'b00000;
            unique case (c)
                "A": case(row) 0:font_bits=5'b01110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b11111;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b10001;default:font_bits=0; endcase
                "B": case(row) 0:font_bits=5'b11110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b11110;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b11110;default:font_bits=0; endcase
                "C": case(row) 0:font_bits=5'b01110;1:font_bits=5'b10001;2:font_bits=5'b10000;3:font_bits=5'b10000;4:font_bits=5'b10000;5:font_bits=5'b10001;6:font_bits=5'b01110;default:font_bits=0; endcase
                "D": case(row) 0:font_bits=5'b11110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b10001;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b11110;default:font_bits=0; endcase
                "E": case(row) 0:font_bits=5'b11111;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b11110;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b11111;default:font_bits=0; endcase
                "F": case(row) 0:font_bits=5'b11111;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b11110;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b10000;default:font_bits=0; endcase
                "G": case(row) 0:font_bits=5'b01110;1:font_bits=5'b10001;2:font_bits=5'b10000;3:font_bits=5'b10111;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b01110;default:font_bits=0; endcase
                "I": case(row) 0:font_bits=5'b11111;1:font_bits=5'b00100;2:font_bits=5'b00100;3:font_bits=5'b00100;4:font_bits=5'b00100;5:font_bits=5'b00100;6:font_bits=5'b11111;default:font_bits=0; endcase
                "K": case(row) 0:font_bits=5'b10001;1:font_bits=5'b10010;2:font_bits=5'b10100;3:font_bits=5'b11000;4:font_bits=5'b10100;5:font_bits=5'b10010;6:font_bits=5'b10001;default:font_bits=0; endcase
                "L": case(row) 0:font_bits=5'b10000;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b10000;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b11111;default:font_bits=0; endcase
                "N": case(row) 0:font_bits=5'b10001;1:font_bits=5'b11001;2:font_bits=5'b10101;3:font_bits=5'b10011;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b10001;default:font_bits=0; endcase
                "O": case(row) 0:font_bits=5'b01110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b10001;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b01110;default:font_bits=0; endcase
                "P": case(row) 0:font_bits=5'b11110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b11110;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b10000;default:font_bits=0; endcase
                "R": case(row) 0:font_bits=5'b11110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b11110;4:font_bits=5'b10100;5:font_bits=5'b10010;6:font_bits=5'b10001;default:font_bits=0; endcase
                "S": case(row) 0:font_bits=5'b01111;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b01110;4:font_bits=5'b00001;5:font_bits=5'b00001;6:font_bits=5'b11110;default:font_bits=0; endcase
                "T": case(row) 0:font_bits=5'b11111;1:font_bits=5'b00100;2:font_bits=5'b00100;3:font_bits=5'b00100;4:font_bits=5'b00100;5:font_bits=5'b00100;6:font_bits=5'b00100;default:font_bits=0; endcase
                "U": case(row) 0:font_bits=5'b10001;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b10001;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b01110;default:font_bits=0; endcase
                "V": case(row) 0:font_bits=5'b10001;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b10001;4:font_bits=5'b10001;5:font_bits=5'b01010;6:font_bits=5'b00100;default:font_bits=0; endcase
                ">": case(row) 0:font_bits=5'b10000;1:font_bits=5'b01000;2:font_bits=5'b00100;3:font_bits=5'b00010;4:font_bits=5'b00100;5:font_bits=5'b01000;6:font_bits=5'b10000;default:font_bits=0; endcase
                "=": case(row) 0:font_bits=5'b00000;1:font_bits=5'b11111;2:font_bits=5'b00000;3:font_bits=5'b11111;4:font_bits=5'b00000;5:font_bits=5'b00000;6:font_bits=5'b00000;default:font_bits=0; endcase
                default: font_bits = 5'b00000;
            endcase
        end
    endfunction

    function automatic logic pixel_border(input logic [6:0] x, input logic [5:0] y);
        pixel_border = (x == 7'd0 || x == 7'd127 || y == 6'd0 || y == 6'd63);
    endfunction

    function automatic logic pixel_text(input logic [6:0] x, input logic [5:0] y);
        int text_line;
        int text_col;
        int char_x;
        int char_y;
        logic [7:0] c;
        logic [4:0] bits_local;
        begin
            pixel_text = 1'b0;
            text_line = y / 8;
            text_col  = x / 6;
            char_x    = x % 6;
            char_y    = y % 8;

            c = line_char(text_line, text_col);
            bits_local = font_bits(c, char_y);

            if (char_x < 5 && char_y < 7) begin
                pixel_text = bits_local[4-char_x];
            end
        end
    endfunction

    logic [7:0] snake_byte;
    logic [7:0] pong_byte;
    logic [7:0] breakout_byte;
    logic [7:0] invaders_byte;

    logic [3:0] snake_audio_event;
    logic [3:0] pong_audio_event;
    logic [3:0] breakout_audio_event;
    logic [3:0] invaders_audio_event;

    wire snake_active = selected_mode && (menu_index == 2'd0);
    wire pong_active  = selected_mode && (menu_index == 2'd1);
    wire breakout_active = selected_mode && (menu_index == 2'd2);
    wire invaders_active = selected_mode && (menu_index == 2'd3);

    snake_game #(
        .CLK_HZ(CLK_HZ),
        .SNAKE_HZ(SNAKE_HZ),
        .MAX_LEN(32)
    ) snake_inst (
        .clk(clk),
        .reset(reset),
        .game_active(snake_active),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_a(btn_a),
        .btn_start(btn_start),
        .page(page),
        .col(col),
        .pixel_byte(snake_byte),
        .audio_event(snake_audio_event)
    );

    pong_game #(
        .CLK_HZ(CLK_HZ)
    ) pong_inst (
        .clk(clk),
        .reset(reset),
        .game_active(pong_active),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_a(btn_a),
        .btn_start(btn_start),
        .page(page),
        .col(col),
        .pixel_byte(pong_byte),
        .audio_event(pong_audio_event)
    );

    breakout_game #(
        .CLK_HZ(CLK_HZ)
    ) breakout_inst (
        .clk(clk),
        .reset(reset),
        .game_active(breakout_active),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_a(btn_a),
        .btn_start(btn_start),
        .page(page),
        .col(col),
        .pixel_byte(breakout_byte),
        .audio_event(breakout_audio_event)
    );


    invaders_game #(
        .CLK_HZ(CLK_HZ)
    ) invaders_inst (
        .clk(clk),
        .reset(reset),
        .game_active(invaders_active),
        .btn_up(btn_up),
        .btn_down(btn_down),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_a(btn_a),
        .btn_start(btn_start),
        .page(page),
        .col(col),
        .pixel_byte(invaders_byte),
        .audio_event(invaders_audio_event)
    );


    always_comb begin
        audio_event = 4'd0;
        if (snake_active) begin
            audio_event = snake_audio_event;
        end else if (pong_active) begin
            audio_event = pong_audio_event;
        end else if (breakout_active) begin
            audio_event = breakout_audio_event;
        end else if (invaders_active) begin
            audio_event = invaders_audio_event;
        end
    end

    function automatic logic [7:0] text_framebuffer_byte(input logic [2:0] p, input logic [6:0] c);
        logic [7:0] b;
        int bit_i;
        logic [5:0] y;
        begin
            b = 8'h00;
            for (bit_i = 0; bit_i < 8; bit_i = bit_i + 1) begin
                y = {p, 3'b000} + bit_i[5:0];
                // Menu border removed so text no longer overlaps the frame.
                b[bit_i] = pixel_text(c, y);
            end
            text_framebuffer_byte = b;
        end
    endfunction

    function automatic logic [7:0] framebuffer_byte(input logic [2:0] p, input logic [6:0] c);
        begin
            if (!selected_mode) begin
                framebuffer_byte = text_framebuffer_byte(p, c);
            end else begin
                case (menu_index)
                    2'd0: framebuffer_byte = snake_byte;
                    2'd1: framebuffer_byte = pong_byte;
                    2'd2: framebuffer_byte = breakout_byte;
                    2'd3: framebuffer_byte = invaders_byte;
                    default: framebuffer_byte = text_framebuffer_byte(p, c);
                endcase
            end
        end
    endfunction

    task automatic start_transaction(input logic [7:0] ctrl, input logic [7:0] payload);
        begin
            tx_b0 <= OLED_ADDR_WR;
            tx_b1 <= ctrl;
            tx_b2 <= payload;
            tx_start <= 1'b1;
        end
    endtask

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= S_POWER_WAIT;
            wait_count <= 24'd0;
            init_index <= 8'd0;
            addr_cmd_index <= 4'd0;
            page <= 3'd0;
            col <= 7'd0;
            tx_start <= 1'b0;
            tx_b0 <= 8'h00;
            tx_b1 <= 8'h00;
            tx_b2 <= 8'h00;
            frame_tick <= 1'b0;
        end else begin
            tx_start <= 1'b0;
            frame_tick <= 1'b0;

            case (state)
                S_POWER_WAIT: begin
                    if (wait_count == 24'd1_200_000) begin
                        wait_count <= 24'd0;
                        init_index <= 8'd0;
                        state <= S_INIT_SEND;
                    end else begin
                        wait_count <= wait_count + 1'b1;
                    end
                end

                S_INIT_SEND: begin
                    if (!tx_busy) begin
                        start_transaction(8'h00, init_rom[init_index]);
                        state <= S_INIT_WAIT;
                    end
                end

                S_INIT_WAIT: begin
                    if (tx_done) begin
                        if (init_index == INIT_LEN-1) begin
                            addr_cmd_index <= 4'd0;
                            state <= S_ADDR_CMD_SEND;
                        end else begin
                            init_index <= init_index + 1'b1;
                            state <= S_INIT_SEND;
                        end
                    end
                end

                S_ADDR_CMD_SEND: begin
                    if (!tx_busy) begin
                        start_transaction(8'h00, addr_cmd_byte(addr_cmd_index));
                        state <= S_ADDR_CMD_WAIT;
                    end
                end

                S_ADDR_CMD_WAIT: begin
                    if (tx_done) begin
                        if (addr_cmd_index == 4'd5) begin
                            page <= 3'd0;
                            col <= 7'd0;
                            state <= S_DATA_SEND;
                        end else begin
                            addr_cmd_index <= addr_cmd_index + 1'b1;
                            state <= S_ADDR_CMD_SEND;
                        end
                    end
                end

                S_DATA_SEND: begin
                    if (!tx_busy) begin
                        start_transaction(8'h40, framebuffer_byte(page, col));
                        state <= S_DATA_WAIT;
                    end
                end

                S_DATA_WAIT: begin
                    if (tx_done) begin
                        if (col == 7'd127) begin
                            col <= 7'd0;
                            if (page == 3'd7) begin
                                frame_tick <= 1'b1;
                                wait_count <= 24'd0;
                                state <= S_FRAME_WAIT;
                            end else begin
                                page <= page + 1'b1;
                                state <= S_DATA_SEND;
                            end
                        end else begin
                            col <= col + 1'b1;
                            state <= S_DATA_SEND;
                        end
                    end
                end

                S_FRAME_WAIT: begin
                    if (wait_count == FRAME_WAIT_CLKS-1) begin
                        addr_cmd_index <= 4'd0;
                        state <= S_ADDR_CMD_SEND;
                    end else begin
                        wait_count <= wait_count + 1'b1;
                    end
                end

                default: state <= S_POWER_WAIT;
            endcase
        end
    end

endmodule




