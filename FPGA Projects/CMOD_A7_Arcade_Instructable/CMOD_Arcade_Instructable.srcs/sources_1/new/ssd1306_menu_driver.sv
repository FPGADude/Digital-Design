`timescale 1ns / 1ps

module ssd1306_menu_driver #(
    parameter int CLK_HZ = 12_000_000,
    parameter int I2C_HZ = 100_000,
    parameter logic [7:0] OLED_ADDR_WR = 8'h78,
    parameter int FRAME_WAIT_CLKS = 600_000
)(
    input  logic clk,
    input  logic reset,

    input  logic [1:0] menu_index,
    input  logic selected_mode,

    output logic oled_scl,
    inout  wire  oled_sda,

    output logic frame_tick
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
                            0:  line_char = "F";
                            1:  line_char = "P";
                            2:  line_char = "G";
                            3:  line_char = "A";
                            4:  line_char = " ";
                            5:  line_char = "A";
                            6:  line_char = "R";
                            7:  line_char = "C";
                            8:  line_char = "A";
                            9:  line_char = "D";
                            10: line_char = "E";
                            default: line_char = " ";
                        endcase
                    end

                    2: begin
                        case (pos)
                            0: line_char = (menu_index == 2'd0) ? ">" : " ";
                            2: line_char = "S";
                            3: line_char = "N";
                            4: line_char = "A";
                            5: line_char = "K";
                            6: line_char = "E";
                            default: line_char = " ";
                        endcase
                    end

                    3: begin
                        case (pos)
                            0: line_char = (menu_index == 2'd1) ? ">" : " ";
                            2: line_char = "P";
                            3: line_char = "O";
                            4: line_char = "N";
                            5: line_char = "G";
                            default: line_char = " ";
                        endcase
                    end

                    4: begin
                        case (pos)
                            0: line_char = (menu_index == 2'd2) ? ">" : " ";
                            2: line_char = "B";
                            3: line_char = "R";
                            4: line_char = "E";
                            5: line_char = "A";
                            6: line_char = "K";
                            7: line_char = "O";
                            8: line_char = "U";
                            9: line_char = "T";
                            default: line_char = " ";
                        endcase
                    end

                    5: begin
                        case (pos)
                            0: line_char = (menu_index == 2'd3) ? ">" : " ";
                            2: line_char = "I";
                            3: line_char = "N";
                            4: line_char = "V";
                            5: line_char = "A";
                            6: line_char = "D";
                            7: line_char = "E";
                            8: line_char = "R";
                            9: line_char = "S";
                            default: line_char = " ";
                        endcase
                    end

                    7: begin
                        case (pos)
                            0: line_char = "A";
                            1: line_char = "=";
                            2: line_char = "S";
                            3: line_char = "T";
                            4: line_char = "A";
                            5: line_char = "R";
                            6: line_char = "T";
                            default: line_char = " ";
                        endcase
                    end

                    default: line_char = " ";
                endcase
            end else begin
                case (line)
                    1: begin
                        case (pos)
                            0: line_char = "S";
                            1: line_char = "E";
                            2: line_char = "L";
                            3: line_char = "E";
                            4: line_char = "C";
                            5: line_char = "T";
                            6: line_char = "E";
                            7: line_char = "D";
                            default: line_char = " ";
                        endcase
                    end

                    3: begin
                        case (menu_index)
                            2'd0: begin
                                case (pos)
                                    0: line_char = "S";
                                    1: line_char = "N";
                                    2: line_char = "A";
                                    3: line_char = "K";
                                    4: line_char = "E";
                                    default: line_char = " ";
                                endcase
                            end

                            2'd1: begin
                                case (pos)
                                    0: line_char = "P";
                                    1: line_char = "O";
                                    2: line_char = "N";
                                    3: line_char = "G";
                                    default: line_char = " ";
                                endcase
                            end

                            2'd2: begin
                                case (pos)
                                    0: line_char = "B";
                                    1: line_char = "R";
                                    2: line_char = "E";
                                    3: line_char = "A";
                                    4: line_char = "K";
                                    5: line_char = "O";
                                    6: line_char = "U";
                                    7: line_char = "T";
                                    default: line_char = " ";
                                endcase
                            end

                            default: begin
                                case (pos)
                                    0: line_char = "I";
                                    1: line_char = "N";
                                    2: line_char = "V";
                                    3: line_char = "A";
                                    4: line_char = "D";
                                    5: line_char = "E";
                                    6: line_char = "R";
                                    7: line_char = "S";
                                    default: line_char = " ";
                                endcase
                            end
                        endcase
                    end

                    6: begin
                        case (pos)
                            0:  line_char = "S";
                            1:  line_char = "E";
                            2:  line_char = "L";
                            3:  line_char = "E";
                            4:  line_char = "C";
                            5:  line_char = "T";
                            6:  line_char = "=";
                            7:  line_char = "B";
                            8:  line_char = "A";
                            9:  line_char = "C";
                            10: line_char = "K";
                            default: line_char = " ";
                        endcase
                    end

                    default: line_char = " ";
                endcase
            end
        end
    endfunction

    logic [7:0] char_code;
    logic [2:0] font_row;
    logic [4:0] font_bits;

    font5x7_rom font (
        .char_code(char_code),
        .row(font_row),
        .bits(font_bits)
    );

    function automatic logic pixel_border(input logic [6:0] x, input logic [5:0] y);
        begin
            pixel_border = (x == 0 || x == 127 || y == 0 || y == 63);
        end
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

            if (char_x < 5 && char_y < 7) begin
                unique case (c)
                    "A": case(char_y) 0:bits_local=5'b01110;1:bits_local=5'b10001;2:bits_local=5'b10001;3:bits_local=5'b11111;4:bits_local=5'b10001;5:bits_local=5'b10001;6:bits_local=5'b10001;default:bits_local=0; endcase
                    "B": case(char_y) 0:bits_local=5'b11110;1:bits_local=5'b10001;2:bits_local=5'b10001;3:bits_local=5'b11110;4:bits_local=5'b10001;5:bits_local=5'b10001;6:bits_local=5'b11110;default:bits_local=0; endcase
                    "C": case(char_y) 0:bits_local=5'b01110;1:bits_local=5'b10001;2:bits_local=5'b10000;3:bits_local=5'b10000;4:bits_local=5'b10000;5:bits_local=5'b10001;6:bits_local=5'b01110;default:bits_local=0; endcase
                    "D": case(char_y) 0:bits_local=5'b11110;1:bits_local=5'b10001;2:bits_local=5'b10001;3:bits_local=5'b10001;4:bits_local=5'b10001;5:bits_local=5'b10001;6:bits_local=5'b11110;default:bits_local=0; endcase
                    "E": case(char_y) 0:bits_local=5'b11111;1:bits_local=5'b10000;2:bits_local=5'b10000;3:bits_local=5'b11110;4:bits_local=5'b10000;5:bits_local=5'b10000;6:bits_local=5'b11111;default:bits_local=0; endcase
                    "F": case(char_y) 0:bits_local=5'b11111;1:bits_local=5'b10000;2:bits_local=5'b10000;3:bits_local=5'b11110;4:bits_local=5'b10000;5:bits_local=5'b10000;6:bits_local=5'b10000;default:bits_local=0; endcase
                    "G": case(char_y) 0:bits_local=5'b01110;1:bits_local=5'b10001;2:bits_local=5'b10000;3:bits_local=5'b10111;4:bits_local=5'b10001;5:bits_local=5'b10001;6:bits_local=5'b01110;default:bits_local=0; endcase
                    "I": case(char_y) 0:bits_local=5'b11111;1:bits_local=5'b00100;2:bits_local=5'b00100;3:bits_local=5'b00100;4:bits_local=5'b00100;5:bits_local=5'b00100;6:bits_local=5'b11111;default:bits_local=0; endcase
                    "K": case(char_y) 0:bits_local=5'b10001;1:bits_local=5'b10010;2:bits_local=5'b10100;3:bits_local=5'b11000;4:bits_local=5'b10100;5:bits_local=5'b10010;6:bits_local=5'b10001;default:bits_local=0; endcase
                    "L": case(char_y) 0:bits_local=5'b10000;1:bits_local=5'b10000;2:bits_local=5'b10000;3:bits_local=5'b10000;4:bits_local=5'b10000;5:bits_local=5'b10000;6:bits_local=5'b11111;default:bits_local=0; endcase
                    "N": case(char_y) 0:bits_local=5'b10001;1:bits_local=5'b11001;2:bits_local=5'b10101;3:bits_local=5'b10011;4:bits_local=5'b10001;5:bits_local=5'b10001;6:bits_local=5'b10001;default:bits_local=0; endcase
                    "O": case(char_y) 0:bits_local=5'b01110;1:bits_local=5'b10001;2:bits_local=5'b10001;3:bits_local=5'b10001;4:bits_local=5'b10001;5:bits_local=5'b10001;6:bits_local=5'b01110;default:bits_local=0; endcase
                    "P": case(char_y) 0:bits_local=5'b11110;1:bits_local=5'b10001;2:bits_local=5'b10001;3:bits_local=5'b11110;4:bits_local=5'b10000;5:bits_local=5'b10000;6:bits_local=5'b10000;default:bits_local=0; endcase
                    "R": case(char_y) 0:bits_local=5'b11110;1:bits_local=5'b10001;2:bits_local=5'b10001;3:bits_local=5'b11110;4:bits_local=5'b10100;5:bits_local=5'b10010;6:bits_local=5'b10001;default:bits_local=0; endcase
                    "S": case(char_y) 0:bits_local=5'b01111;1:bits_local=5'b10000;2:bits_local=5'b10000;3:bits_local=5'b01110;4:bits_local=5'b00001;5:bits_local=5'b00001;6:bits_local=5'b11110;default:bits_local=0; endcase
                    "T": case(char_y) 0:bits_local=5'b11111;1:bits_local=5'b00100;2:bits_local=5'b00100;3:bits_local=5'b00100;4:bits_local=5'b00100;5:bits_local=5'b00100;6:bits_local=5'b00100;default:bits_local=0; endcase
                    "U": case(char_y) 0:bits_local=5'b10001;1:bits_local=5'b10001;2:bits_local=5'b10001;3:bits_local=5'b10001;4:bits_local=5'b10001;5:bits_local=5'b10001;6:bits_local=5'b01110;default:bits_local=0; endcase
                    "V": case(char_y) 0:bits_local=5'b10001;1:bits_local=5'b10001;2:bits_local=5'b10001;3:bits_local=5'b10001;4:bits_local=5'b10001;5:bits_local=5'b01010;6:bits_local=5'b00100;default:bits_local=0; endcase
                    ">": case(char_y) 0:bits_local=5'b10000;1:bits_local=5'b01000;2:bits_local=5'b00100;3:bits_local=5'b00010;4:bits_local=5'b00100;5:bits_local=5'b01000;6:bits_local=5'b10000;default:bits_local=0; endcase
                    "=": case(char_y) 0:bits_local=5'b00000;1:bits_local=5'b11111;2:bits_local=5'b00000;3:bits_local=5'b11111;4:bits_local=5'b00000;5:bits_local=5'b00000;6:bits_local=5'b00000;default:bits_local=0; endcase
                    default: bits_local = 5'b00000;
                endcase

                pixel_text = bits_local[4-char_x];
            end
        end
    endfunction

    function automatic logic pixel_on(input logic [6:0] x, input logic [5:0] y);
        begin
            pixel_on = pixel_border(x,y) | pixel_text(x,y);
        end
    endfunction

    function automatic logic [7:0] framebuffer_byte(input logic [2:0] p, input logic [6:0] c);
        logic [7:0] b;
        int bit_i;
        logic [5:0] y;
        begin
            b = 8'h00;
            for (bit_i = 0; bit_i < 8; bit_i = bit_i + 1) begin
                y = {p, 3'b000} + bit_i[5:0];
                b[bit_i] = pixel_on(c, y);
            end
            framebuffer_byte = b;
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

