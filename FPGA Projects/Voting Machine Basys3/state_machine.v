`timescale 1ns / 1ps

module state_machine(
    input clk_1Hz,
    input btn1,
    input btn2,
    input btn3,
    input btn_ov_cv,
    input reset,
    input [15:0] sw,
    output reg [1:0] the_winner,    
    output enable_leds,         // to enable flashing LEDs
    output [3:0] vote_count,    // 4 bits allows for 15 votes, votes = 2^(number of bits) - 1
    output [1:0] the_state
    );
    
    reg [1:0] vc_ctr = 0;                   // Voting Closed Counter Register
    reg [3:0] candidate1_votes, candidate2_votes, candidate3_votes, total_votes;
    
    // **************************************************************************************
    // The following reg is the code to enable opening/closing of voting by administrator ***
    
                    reg [15:0] admin_code = 16'b1000_0001_1000_0001;
                    
    // It is represented on the Basys 3 by the 16 switches **********************************
    // **************************************************************************************
    
    // State Parameters
    parameter IDLE          = 2'b00;
    parameter VOTING_OPEN   = 2'b01;
    parameter VOTING_CLOSED = 2'b10;
    parameter DISPLAY_WIN   = 2'b11;
    
    reg [1:0] state_reg;                    // State Register
    
    // Next State Logic
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            state_reg <= IDLE;
        else
            case(state_reg)
                IDLE            :   if(btn_ov_cv)
                                        if(sw == admin_code)
                                            state_reg <= VOTING_OPEN;
                                
                VOTING_OPEN     :   if(btn_ov_cv)
                                        if(sw == admin_code)
                                            state_reg <= VOTING_CLOSED;
                
                VOTING_CLOSED   :   if(vc_ctr == 2'b11)
                                        state_reg <= DISPLAY_WIN;
                
                DISPLAY_WIN     :   if(btn_ov_cv)
                                        state_reg <= IDLE;
            endcase
    end
    
    // Total Votes Register Logic
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            total_votes <= 0;
        else
            if(btn1 | btn2 | btn3)
                if(state_reg == VOTING_OPEN)
                    total_votes <= total_votes + 1;
    end
    
    // Candidate1 Votes Register Logic
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            candidate1_votes <= 0;
        else
            if(btn1)
                if(state_reg == VOTING_OPEN)
                    candidate1_votes <= candidate1_votes + 1;
    end
    
    // Candidate2 Votes Register Logic
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            candidate2_votes <= 0;
        else
            if(btn2)
                if(state_reg == VOTING_OPEN)
                    candidate2_votes <= candidate2_votes + 1;
    end
    
    // Candidate3 Votes Register Logic
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            candidate3_votes <= 0;
        else
            if(btn3)
                if(state_reg == VOTING_OPEN)
                    candidate3_votes <= candidate3_votes + 1;
    end
    
    // Voting Closed Counter Register Logic
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            vc_ctr <= 0;
        else
            if(state_reg == VOTING_CLOSED)
                vc_ctr <= vc_ctr + 1;
    end
    
    // Winner Register Control Logic
    always @(posedge clk_1Hz or posedge reset) begin
        if(reset)
            the_winner <= 0;
        else
            if(candidate1_votes > candidate2_votes && candidate1_votes > candidate3_votes)
                the_winner <= 2'b01;
            else if(candidate2_votes > candidate1_votes && candidate2_votes > candidate3_votes)
                the_winner <= 2'b10;
            else if(candidate3_votes > candidate1_votes && candidate3_votes > candidate2_votes)
                the_winner <= 2'b11;
            else
                the_winner <= 2'b00;    // no winner, a tie, need a revote
    
    end
    
    // Assigning outputs
    assign vote_count = total_votes;
    assign enable_leds = (state_reg == VOTING_OPEN) ? 1 : 0;
    assign the_state = state_reg;
    
endmodule
