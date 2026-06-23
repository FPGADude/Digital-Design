// ================================================================
// request_manager.v
// ================================================================
// Creator : David J. Marion
// Date    : 6.20.2026
// Project : Basys 3 FPGA Elevator Controller
// Purpose : Stores pending elevator floor requests until the
//           elevator serves them.
//
// Notes   : requests[0]=floor 1, requests[1]=floor 2, 
//           requests[2]=floor 3, requests[3]=floor 4.
//
// Board   : Digilent Basys 3, 100 MHz system clock
// Language: Verilog HDL
// ================================================================

module request_manager(
    input  wire       clk,
    input  wire       reset,
    input  wire [3:0] request_pulse,        // bit0=floor1, bit1=floor2, bit2=floor3, bit3=floor4
    input  wire [1:0] curr_floor,           // 0=floor1, 1=floor2, 2=floor3, 3=floor4
    input  wire       clear_current_request,
    output reg  [3:0] requests
);

    // One-hot mask for the current floor. When the elevator opens
    // at this floor, the matching request bit is cleared.
    reg [3:0] clear_mask;

    // Convert the binary current-floor number into a one-hot mask.
    // curr_floor uses 0-3 internally, while the display shows 1-4.
    always @(*) begin
        case (curr_floor)
            2'd0: clear_mask = 4'b0001;
            2'd1: clear_mask = 4'b0010;
            2'd2: clear_mask = 4'b0100;
            2'd3: clear_mask = 4'b1000;
            default: clear_mask = 4'b0000;
        endcase
    end

    // Latch new requests and clear the current floor when served.
    // New button pulses are ORed into the request register so multiple
    // pending floors can be stored at the same time.
    always @(posedge clk) begin
        if (reset) begin
            requests <= 4'b0000;
        end else begin
            // Store any new floor requests.
            requests <= requests | request_pulse;

            // If the controller says the current floor was served,
            // clear that bit after also considering any new request pulse.
            if (clear_current_request)
                requests <= (requests | request_pulse) & ~clear_mask;
        end
    end

endmodule