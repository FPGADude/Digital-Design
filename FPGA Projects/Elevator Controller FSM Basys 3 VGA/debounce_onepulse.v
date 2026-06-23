// ================================================================
// debounce_onepulse.v
// ================================================================
// Creator : David J. Marion
// Date    : 6.20.2026
// Project : Basys 3 FPGA Elevator Controller
// Purpose : Debounces one mechanical pushbutton and produces a 
//           single-clock pulse.
//
// Notes   : Used on the five Basys 3 pushbuttons so one press 
//           creates one request event.
//
// Board   : Digilent Basys 3, 100 MHz system clock
// Language: Verilog HDL
// ================================================================

module debounce_onepulse(
    input  wire clk,
    input  wire reset,
    input  wire btn_in,
    output reg  pulse
);

    // Number of 100 MHz clock cycles the input must remain changed
    // before it is accepted as the new stable value.
    // 2,000,000 cycles / 100 MHz = 20 ms.
    parameter DEBOUNCE_COUNT = 2000000;

    // Two flip-flops synchronize the asynchronous button input to clk.
    reg btn_sync_0, btn_sync_1;

    // btn_stable is the debounced button level.
    // btn_prev is used to detect the 0-to-1 rising edge.
    reg btn_stable;
    reg btn_prev;

    // Counter used while waiting for the input to stay stable.
    reg [21:0] count;

    // Synchronizer stage. This protects the design from metastability
    // caused by the pushbutton changing outside the clock edge.
    always @(posedge clk) begin
        if (reset) begin
            btn_sync_0 <= 0;
            btn_sync_1 <= 0;
        end else begin
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;
        end
    end

    // Debounce filter. If the synchronized button differs from the
    // accepted stable value, wait DEBOUNCE_COUNT cycles before accepting it.
    always @(posedge clk) begin
        if (reset) begin
            count <= 0;
            btn_stable <= 0;
        end else begin
            if (btn_sync_1 != btn_stable) begin
                if (count == DEBOUNCE_COUNT-1) begin
                    btn_stable <= btn_sync_1;
                    count <= 0;
                end else begin
                    count <= count + 1;
                end
            end else begin
                count <= 0;
            end
        end
    end

    // One-pulse generator. pulse is high for exactly one clock cycle
    // when the debounced button transitions from not-pressed to pressed.
    always @(posedge clk) begin
        if (reset) begin
            btn_prev <= 0;
            pulse <= 0;
        end else begin
            btn_prev <= btn_stable;
            pulse <= btn_stable & ~btn_prev;
        end
    end

endmodule