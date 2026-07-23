`timescale 1ns / 1ps
//==============================================================================
// Module:      tmp2_packet_tx
// Project:     FPGA Wi-Fi Temperature Monitor
//
// Description:
//   Converts each valid 16-bit TMP2 reading into the four-byte binary packet
//   sent to the ESP32:
//
//       Byte 0: 0x55                      synchronization byte
//       Byte 1: raw_temperature[15:8]     sensor MSB
//       Byte 2: raw_temperature[7:0]      sensor LSB
//       Byte 3: 0x55 XOR MSB XOR LSB      checksum
//
// Interface:
//   The module presents one byte at a time to uart_tx. uart_valid is pulsed for
//   one clock when a byte is ready. The uart_busy handshake guarantees that the
//   next byte is not issued until the transmitter accepts and finishes the
//   current byte.
//
// Notes:
//   At 115200 baud, the complete four-byte packet is transmitted in less than
//   one millisecond, far faster than the one-second sensor sample interval.
//==============================================================================

module tmp2_packet_tx(
    input  wire        clk,
    input  wire        reset,

    input  wire [15:0] raw_temperature,
    input  wire        new_temperature,

    output reg  [7:0]  uart_data,
    output reg         uart_valid,
    input  wire        uart_busy
);

    localparam [7:0] SYNC_BYTE = 8'h55;

    // Index of the packet byte currently being sent.
    reg [1:0] byte_index;

    // Latched packet bytes. Latching protects the packet from any later change
    // to raw_temperature while transmission is underway.
    reg [7:0] packet_byte [0:3];

    reg packet_active;
    reg waiting_for_uart_busy;

    always @(posedge clk) begin
        if (reset) begin
            uart_data             <= 8'h00;
            uart_valid            <= 1'b0;
            byte_index            <= 2'd0;
            packet_active         <= 1'b0;
            waiting_for_uart_busy <= 1'b0;
        end
        else begin
            // Default inactive; asserted for one clock when launching a byte.
            uart_valid <= 1'b0;

            //------------------------------------------------------------------
            // Capture a new reading and build the complete packet.
            //------------------------------------------------------------------
            if (new_temperature && !packet_active) begin
                packet_byte[0] <= SYNC_BYTE;
                packet_byte[1] <= raw_temperature[15:8];
                packet_byte[2] <= raw_temperature[7:0];
                packet_byte[3] <= SYNC_BYTE
                                ^ raw_temperature[15:8]
                                ^ raw_temperature[7:0];

                byte_index            <= 2'd0;
                packet_active         <= 1'b1;
                waiting_for_uart_busy <= 1'b0;
            end

            //------------------------------------------------------------------
            // Send the four bytes sequentially through the UART transmitter.
            //------------------------------------------------------------------
            else if (packet_active) begin
                // After uart_valid is asserted, wait for uart_busy to confirm
                // that the transmitter accepted the byte.
                if (waiting_for_uart_busy) begin
                    if (uart_busy)
                        waiting_for_uart_busy <= 1'b0;
                end

                // Launch a byte only when the UART transmitter is idle.
                else if (!uart_busy) begin
                    uart_data             <= packet_byte[byte_index];
                    uart_valid            <= 1'b1;
                    waiting_for_uart_busy <= 1'b1;

                    if (byte_index == 2'd3) begin
                        packet_active <= 1'b0;
                        byte_index    <= 2'd0;
                    end
                    else begin
                        byte_index <= byte_index + 1'b1;
                    end
                end
            end
        end
    end

endmodule
