`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////// 
// Authored by David J Marion aka FPGA Dude
// Created on 4/29/2022
// Playing Star Wars "Imperial March" on speaker driven by the Basys 3 FPGA.
/////////////////////////////////////////////////////////////////////////////// 

module song_top(
    input clk_100MHz,       // from Basys 3
    input play,             // btnD
    output speaker          // PMOD JB[0]
    );
    
    // Play button debounce
    reg x, y, z;
    
    always @(posedge clk_100MHz) begin
        x <= play;
        y <= x;
        z <= y;
    end
    assign w_play = z;
    
    // Signals for each tone
    wire a, cH, eH, fH, f, gS;
    
    // Instantiate tone modules
    a_440Hz   t_a (.clk_100MHz(clk_100MHz), .o_440Hz(a));
    cH_523Hz  t_cH(.clk_100MHz(clk_100MHz), .o_523Hz(cH));
    eH_659Hz  t_eH(.clk_100MHz(clk_100MHz), .o_659Hz(eH));
    fH_698Hz  t_fH(.clk_100MHz(clk_100MHz), .o_698Hz(fH));
    f_349Hz   t_f (.clk_100MHz(clk_100MHz), .o_349Hz(f));
    gS_415Hz  t_gS(.clk_100MHz(clk_100MHz), .o_415Hz(gS));
    
    // Song Note Delays
    parameter CLK_FREQ = 100_000_000;                   // 100MHz
    parameter integer D_500ms = 0.50000000 * CLK_FREQ;  // 500ms
    parameter integer D_350ms = 0.35000000 * CLK_FREQ;  // 350ms
    parameter integer D_150ms = 0.15000000 * CLK_FREQ;  // 150ms
    parameter integer D_650ms = 0.65000000 * CLK_FREQ;  // 650ms
    // Note Break Delay
    parameter integer D_break = 0.10000000 * CLK_FREQ;  // 100ms
    
    // Registers for Delays
    reg [25:0] count = 26'b0;
    reg counter_clear = 1'b0;
    reg flag_500ms = 1'b0;
    reg flag_350ms = 1'b0;
    reg flag_150ms = 1'b0;
    reg flag_650ms = 1'b0; 
    reg flag_break = 1'b0;
    
    // State Machine Register
    reg [31:0] state = "idle";
    
    always @(posedge clk_100MHz) begin
        // reaction to counter_clear signal
        if(counter_clear) begin
            count <= 26'b0;
            counter_clear <= 1'b0;
            flag_500ms <= 1'b0;
            flag_350ms <= 1'b0;
            flag_150ms <= 1'b0;
            flag_650ms <= 1'b0;
            flag_break <= 1'b0;
        end
        
        // set flags based on count
        if(!counter_clear) begin
            count <= count + 1;
            if(count == D_break) begin
                flag_break <= 1'b1;
            end
            if(count == D_150ms) begin
                flag_150ms <= 1'b1;
            end
            if(count == D_350ms) begin
                flag_350ms <= 1'b1;
            end
            if(count == D_500ms) begin
                flag_500ms <= 1'b1;
            end
            if(count == D_650ms) begin
                flag_650ms <= 1'b1;
            end
        end
       
        // State Machine
        case(state)
            "idle" : begin
                counter_clear <= 1'b1;
                if(w_play) begin
                    state <= "n1";
                end    
            end
            
            "n1" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b1";
                end
            end
            
            "b1" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n2";
                end
            end
        
            "n2" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b2";
                end
            end
        
            "b2" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n3";
                end
            end
        
            "n3" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b3";
                end
            end
        
            "b3" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n4";
                end
            end
        
            "n4" : begin
                if(flag_350ms) begin
                    counter_clear <= 1'b1;
                    state <= "b4";
                end
            end
        
            "b4" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n5";
                end
            end
        
            "n5" : begin
                if(flag_150ms) begin
                    counter_clear <= 1'b1;
                    state <= "b5";
                end
            end
        
            "b5" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n6";
                end
            end
        
            "n6" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b6";
                end
            end
            
            "b6" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n7";
                end
            end
            
            "n7" : begin
                if(flag_350ms) begin
                    counter_clear <= 1'b1;
                    state <= "b7";
                end
            end
            
            "b7" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n8";
                end
            end
            
            "n8" : begin
                if(flag_150ms) begin
                    counter_clear <= 1'b1;
                    state <= "b8";
                end
            end
            
            "b8" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n9";
                end
            end
            
            "n9" : begin
                if(flag_650ms) begin
                    counter_clear <= 1'b1;
                    state <= "bm";
                end
            end
        
            "bm" : begin
                if(flag_650ms) begin
                    counter_clear <= 1'b1;
                    state <= "n10";
                end
            end
            
            "n10" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b10";
                end
            end
            
            "b10" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n11";
                end
            end
            
            "n11" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b11";
                end
            end
            
            "b11" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n12";
                end
            end
            
            "n12" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b12";
                end
            end
            
            "b12" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n13";
                end
            end
            
            "n13" : begin
                if(flag_350ms) begin
                    counter_clear <= 1'b1;
                    state <= "b13";
                end
            end
        
            "b13" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n14";
                end
            end
        
            "n14" : begin
                if(flag_150ms) begin
                    counter_clear <= 1'b1;
                    state <= "b14";
                end
            end
            
            "b14" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n15";
                end
            end
            
            "n15" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b15";
                end
            end
            
            "b15" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n16";
                end
            end
            
            "n16" : begin
                if(flag_350ms) begin
                    counter_clear <= 1'b1;
                    state <= "b16";
                end
            end
            
            "b16" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n17";
                end
            end
            
            "n17" : begin
                if(flag_150ms) begin
                    counter_clear <= 1'b1;
                    state <= "b17";
                end
            end
            
            "b17" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n18";
                end
            end
            
            "n18" : begin
                if(flag_650ms) begin
                    counter_clear <= 1'b1;
                    state <= "idle";
                end
            end  
        endcase                
    end
    
    // Output to speaker
    assign speaker = (state=="n1" || state=="n2" || state=="n3" || state=="n6" || state=="n9" || state=="n18") ? a :    // a
                     (state=="n4" || state=="n7" || state=="n16") ? f :                                                 // f
                     (state=="n5" || state=="n8" || state=="n14" || state=="n17") ? cH :                                // cH
                     (state=="n10" || state=="n11" || state=="n12") ? eH :                                              // eH
                     (state=="n13") ? fH :                                                                              // fH
                     (state=="n15") ? gS : 0;                                                                           // gS
    
    
endmodule
