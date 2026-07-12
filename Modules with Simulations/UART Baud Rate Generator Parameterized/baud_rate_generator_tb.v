`timescale 1ns / 1ps

module baud_rate_generator_tb;
    localparam integer CLOCK_FREQ_HZ = 100_000_000;
    localparam integer BAUD_RATE1    = 9600;
    localparam integer BAUD_RATE2    = 19200;
    localparam integer BAUD_RATE3    = 38400;
    localparam integer BAUD_RATE4    = 57600;
    reg  clk;
    reg  reset;
    wire baud_tick_9600, baud_tick_19200, baud_tick_38400,
         baud_tick_57600, baud_tick_115200;
    
    baud_rate_generator #(.CLOCK_FREQ_HZ(CLOCK_FREQ_HZ), .BAUD_RATE(BAUD_RATE1)
    ) dut1 (.clk(clk), .reset(reset), .baud_tick(baud_tick_9600));
    
    baud_rate_generator #(.CLOCK_FREQ_HZ(CLOCK_FREQ_HZ), .BAUD_RATE(BAUD_RATE2)
    ) dut2 (.clk(clk), .reset(reset), .baud_tick(baud_tick_19200));
    
    baud_rate_generator #(.CLOCK_FREQ_HZ(CLOCK_FREQ_HZ), .BAUD_RATE(BAUD_RATE3)
    ) dut3 (.clk(clk), .reset(reset), .baud_tick(baud_tick_38400));
    
    baud_rate_generator #(.CLOCK_FREQ_HZ(CLOCK_FREQ_HZ), .BAUD_RATE(BAUD_RATE4)
    ) dut4 (.clk(clk), .reset(reset), .baud_tick(baud_tick_57600));
    
    baud_rate_generator // Using default parameters
      dut5 (.clk(clk), .reset(reset), .baud_tick(baud_tick_115200));
    
    // 100 MHz clock: 10 ns period.
    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        #100;   // Hold reset for ten full clock periods.
        #2 reset = 1'b0;    // Deassert reset away from a rising clock edge.
        
        // Run for 1 millisecond.
        // This allows all five baud rates to produce multiple visible ticks.
        #1_000_000;

        $finish;
    end

endmodule


