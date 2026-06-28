`timescale 1ns / 1ps

module i2c_3byte_tx_master #(
    parameter int CLK_HZ = 12_000_000,
    parameter int I2C_HZ = 100_000
)(
    input  logic clk,
    input  logic reset,

    input  logic start_tx,
    input  logic [7:0] byte0,
    input  logic [7:0] byte1,
    input  logic [7:0] byte2,

    output logic busy,
    output logic done,

    output logic scl,
    output logic sda_oe
);

    localparam int HALF_CLKS = CLK_HZ / (I2C_HZ * 2);
    localparam int HALF_W = (HALF_CLKS <= 1) ? 1 : $clog2(HALF_CLKS);

    typedef enum logic [4:0] {
        S_IDLE,
        S_START_A,
        S_START_B,
        S_START_C,
        S_LOAD_BYTE,
        S_BIT_SETUP,
        S_BIT_HIGH,
        S_BIT_LOW,
        S_ACK_SETUP,
        S_ACK_HIGH,
        S_ACK_LOW,
        S_STOP_A,
        S_STOP_B,
        S_STOP_C,
        S_DONE
    } state_t;

    state_t state;

    logic [HALF_W-1:0] div_count;
    logic tick;

    logic [7:0] shifter;
    logic [2:0] bit_index;
    logic [1:0] byte_index;

    logic [7:0] b0, b1, b2;

    always_ff @(posedge clk) begin
        if (reset) begin
            div_count <= '0;
            tick <= 1'b0;
        end else begin
            if (busy) begin
                if (div_count == HALF_CLKS-1) begin
                    div_count <= '0;
                    tick <= 1'b1;
                end else begin
                    div_count <= div_count + 1'b1;
                    tick <= 1'b0;
                end
            end else begin
                div_count <= '0;
                tick <= 1'b0;
            end
        end
    end

    function automatic logic [7:0] select_byte(
        input logic [1:0] idx,
        input logic [7:0] x0,
        input logic [7:0] x1,
        input logic [7:0] x2
    );
        begin
            case (idx)
                2'd0: select_byte = x0;
                2'd1: select_byte = x1;
                default: select_byte = x2;
            endcase
        end
    endfunction

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            scl <= 1'b1;
            sda_oe <= 1'b0;
            shifter <= 8'h00;
            bit_index <= 3'd7;
            byte_index <= 2'd0;
            b0 <= 8'h00;
            b1 <= 8'h00;
            b2 <= 8'h00;
        end else begin
            done <= 1'b0;

            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    scl <= 1'b1;
                    sda_oe <= 1'b0;

                    if (start_tx) begin
                        busy <= 1'b1;
                        b0 <= byte0;
                        b1 <= byte1;
                        b2 <= byte2;
                        byte_index <= 2'd0;
                        state <= S_START_A;
                    end
                end

                S_START_A: if (tick) begin
                    scl <= 1'b1;
                    sda_oe <= 1'b0;
                    state <= S_START_B;
                end

                S_START_B: if (tick) begin
                    scl <= 1'b1;
                    sda_oe <= 1'b1;
                    state <= S_START_C;
                end

                S_START_C: if (tick) begin
                    scl <= 1'b0;
                    sda_oe <= 1'b1;
                    state <= S_LOAD_BYTE;
                end

                S_LOAD_BYTE: begin
                    shifter <= select_byte(byte_index, b0, b1, b2);
                    bit_index <= 3'd7;
                    state <= S_BIT_SETUP;
                end

                S_BIT_SETUP: if (tick) begin
                    scl <= 1'b0;
                    sda_oe <= ~shifter[bit_index];
                    state <= S_BIT_HIGH;
                end

                S_BIT_HIGH: if (tick) begin
                    scl <= 1'b1;
                    state <= S_BIT_LOW;
                end

                S_BIT_LOW: if (tick) begin
                    scl <= 1'b0;

                    if (bit_index == 3'd0)
                        state <= S_ACK_SETUP;
                    else begin
                        bit_index <= bit_index - 1'b1;
                        state <= S_BIT_SETUP;
                    end
                end

                S_ACK_SETUP: if (tick) begin
                    scl <= 1'b0;
                    sda_oe <= 1'b0;
                    state <= S_ACK_HIGH;
                end

                S_ACK_HIGH: if (tick) begin
                    scl <= 1'b1;
                    state <= S_ACK_LOW;
                end

                S_ACK_LOW: if (tick) begin
                    scl <= 1'b0;

                    if (byte_index == 2'd2)
                        state <= S_STOP_A;
                    else begin
                        byte_index <= byte_index + 1'b1;
                        state <= S_LOAD_BYTE;
                    end
                end

                S_STOP_A: if (tick) begin
                    scl <= 1'b0;
                    sda_oe <= 1'b1;
                    state <= S_STOP_B;
                end

                S_STOP_B: if (tick) begin
                    scl <= 1'b1;
                    sda_oe <= 1'b1;
                    state <= S_STOP_C;
                end

                S_STOP_C: if (tick) begin
                    scl <= 1'b1;
                    sda_oe <= 1'b0;
                    state <= S_DONE;
                end

                S_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

