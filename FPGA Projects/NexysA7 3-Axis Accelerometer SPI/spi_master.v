`timescale 1ns / 1ps
// Created by David J. Marion
// Date: 7.21.2022
// For Nexys A7 Accelerometer reading

module spi_master(
    input iclk,                 // 4MHz
    input miso,                 // master in
	output sclk,				// 1MHz
    output reg mosi = 1'b0,     // master out
    output reg csn = 1'b1,
    output [7:0] x_data,
    output [7:0] y_data,
    output [7:0] z_data
    );
    
	
	reg clk_counter = 1'b0;
	reg clk_reg = 1'b1;
	
	// Create a 1MHz signal from a 4MHz signal
	// 4 x 10^6 / 1 x 10^6 / 2 = 2
	always @(posedge iclk) begin
		clk_counter <= clk_counter + 1;
		if(clk_counter == 1'b1)
			clk_reg <= ~clk_reg;
	end
	
    reg [7:0] read_instr  = 8'h0B;
    reg [7:0] x_data_addr = 8'h08;
    reg [23:0] temp_data_storage = 24'b0;
    //reg [7:0] y_data_addr = 8'h09;
    //reg [7:0] z_data_addr = 8'h0A;
    reg [7:0] X = 8'h00;
    reg [7:0] Y = 8'h00;
    reg [7:0] Z = 8'h00;
    reg [31:0] counter = 32'b0;         	// state machine counter
    
    // 43 states for state machine
    localparam [5:0] POWER_UP    = 6'h00,
                     SEND_CSL    = 6'h01,
                     SEND_CMD7   = 6'h02,
					 SEND_CMD6   = 6'h03,
					 SEND_CMD5   = 6'h04,
					 SEND_CMD4   = 6'h05,
					 SEND_CMD3   = 6'h06,
					 SEND_CMD2   = 6'h07,
					 SEND_CMD1   = 6'h08,
					 SEND_CMD0   = 6'h09,
                     SEND_ADDR7  = 6'h0A,
					 SEND_ADDR6  = 6'h0B,
					 SEND_ADDR5  = 6'h0C,
					 SEND_ADDR4  = 6'h0D,
					 SEND_ADDR3  = 6'h0E,
					 SEND_ADDR2  = 6'h0F,
					 SEND_ADDR1  = 6'h10,
					 SEND_ADDR0  = 6'h11,
                     REC_X7      = 6'h12,
					 REC_X6      = 6'h13,
					 REC_X5      = 6'h14,
					 REC_X4      = 6'h15,
					 REC_X3      = 6'h16,
					 REC_X2      = 6'h17,
					 REC_X1      = 6'h18,
					 REC_X0      = 6'h19,
                     REC_Y7      = 6'h1A,
					 REC_Y6      = 6'h1B,
					 REC_Y5      = 6'h1C,
					 REC_Y4      = 6'h1D,
					 REC_Y3      = 6'h1E,
					 REC_Y2      = 6'h1F,
					 REC_Y1      = 6'h20,
					 REC_Y0      = 6'h21,
                     REC_Z7      = 6'h22,
					 REC_Z6      = 6'h23,
					 REC_Z5      = 6'h24,
					 REC_Z4      = 6'h25,
					 REC_Z3      = 6'h26,
					 REC_Z2      = 6'h27,
					 REC_Z1      = 6'h28,
					 REC_Z0      = 6'h29,
                     SEND_CSH    = 6'h2A;
                                   
    // State Register              
    reg [5:0] state_reg = POWER_UP;
                                   
    always @(posedge iclk) begin   
        counter <= counter + 1;
        case(state_reg)
            POWER_UP    : begin
                            if(counter == 32'd19999)			// Wait for 5ms
                                state_reg <= SEND_CSL;
			end
			SEND_CSL	: begin						// 20000
							csn <= 1'b0;			// 20001
							if(counter == 32'd20001)
								state_reg <= SEND_CMD7;
			end
            SEND_CMD7    : begin					// 20002
							mosi <= read_instr[7];	// 20003
							if(counter == 32'd20005)
								state_reg <= SEND_CMD6;
            end
			SEND_CMD6    : begin					// 20006
							mosi <= read_instr[6];	// 20007
							if(counter == 32'd20009)
								state_reg <= SEND_CMD5;
            end
			SEND_CMD5    : begin					// 20010
							mosi <= read_instr[5];	// 20011
							if(counter == 32'd20013)
								state_reg <= SEND_CMD4;
            end
			SEND_CMD4    : begin					// 20014
							mosi <= read_instr[4];	// 20015
							if(counter == 32'd20017)
								state_reg <= SEND_CMD3;
            end
			SEND_CMD3    : begin					// 20018
							mosi <= read_instr[3];	// 20019
							if(counter == 32'd20021)
								state_reg <= SEND_CMD2;
            end
			SEND_CMD2    : begin					// 20022
							mosi <= read_instr[2];	// 20023
							if(counter == 32'd20025)
								state_reg <= SEND_CMD1;
            end
			SEND_CMD1    : begin					// 20026
							mosi <= read_instr[1];	// 20027
							if(counter == 32'd20029)
								state_reg <= SEND_CMD0;
            end
			SEND_CMD0    : begin					// 20030
							mosi <= read_instr[0];	// 20031
							if(counter == 32'd20033)
								state_reg <= SEND_ADDR7;
            end
            SEND_ADDR7   : begin					// 20034
							mosi <= x_data_addr[7];	// 20035
							if(counter == 32'd20037)
								state_reg <= SEND_ADDR6;							
            end
			SEND_ADDR6   : begin					// 20038
							mosi <= x_data_addr[6];	// 20039
							if(counter == 32'd20041)
								state_reg <= SEND_ADDR5;
            end
			SEND_ADDR5   : begin					// 20042
							mosi <= x_data_addr[5];	// 20043
							if(counter == 32'd20045)
								state_reg <= SEND_ADDR4;
            end
			SEND_ADDR4   : begin					// 20046
							mosi <= x_data_addr[4];	// 20047
							if(counter == 32'd20049)
								state_reg <= SEND_ADDR3;
            end
			SEND_ADDR3   : begin					// 20050
							mosi <= x_data_addr[3];	// 20051
							if(counter == 32'd20053)
								state_reg <= SEND_ADDR2;
            end
			SEND_ADDR2   : begin					// 20054
							mosi <= x_data_addr[2];	// 20055
							if(counter == 32'd20057)
								state_reg <= SEND_ADDR1;
            end
			SEND_ADDR1   : begin					// 20058
							mosi <= x_data_addr[1];	// 20059
							if(counter == 32'd20061)
								state_reg <= SEND_ADDR0;
            end
			SEND_ADDR0   : begin					// 20062
							mosi <= x_data_addr[0];	// 20063
							if(counter == 32'd20065) begin
								//mosi <= 1'bz;
								state_reg <= REC_X7;
							end
            end
            REC_X7       : begin					// 20066
                            X[7] <= miso;			// 20067
                            if(counter == 32'd20069)
								state_reg <= REC_X6;
            end
			REC_X6       : begin					// 20070
                            X[6] <= miso;			// 20071
                            if(counter == 32'd20073)
								state_reg <= REC_X5;
            end
			REC_X5       : begin					// 20074
                            X[5] <= miso;			// 20075
                            if(counter == 32'd20077)
								state_reg <= REC_X4;
            end
			REC_X4       : begin					// 20078
                            X[4] <= miso;			// 20079
                            if(counter == 32'd20081)
								state_reg <= REC_X3;
            end
			REC_X3       : begin					// 20082
                            X[3] <= miso;			// 20083
                            if(counter == 32'd20085)
								state_reg <= REC_X2;
            end
			REC_X2       : begin					// 20086
                            X[2] <= miso;			// 20087
                            if(counter == 32'd20089)
								state_reg <= REC_X1;
            end
			REC_X1       : begin					// 20090
                            X[1] <= miso;			// 20091
                            if(counter == 32'd20093)
								state_reg <= REC_X0;
            end
			REC_X0       : begin					// 20094
                            X[0] <= miso;			// 20095
                            if(counter == 32'd20097)
								state_reg <= REC_Y7;
            end
            REC_Y7       : begin					// 20098
							Y[7] <= miso;			// 20099
							if(counter == 32'd20101)
								state_reg <= REC_Y6;
            end
			REC_Y6       : begin					// 20102
							Y[6] <= miso;			// 20103
							if(counter == 32'd20105)
								state_reg <= REC_Y5;
            end
			REC_Y5       : begin					// 20106
							Y[5] <= miso;			// 20107
							if(counter == 32'd20109)
								state_reg <= REC_Y4;
            end
			REC_Y4       : begin					// 20110
							Y[4] <= miso;			// 20111
							if(counter == 32'd20113)
								state_reg <= REC_Y3;
            end
			REC_Y3       : begin					// 20114
							Y[3] <= miso;			// 20115
							if(counter == 32'd20117)
								state_reg <= REC_Y2;
            end
			REC_Y2       : begin					// 20118
							Y[2] <= miso;			// 20119
							if(counter == 32'd20121)
								state_reg <= REC_Y1;
            end
			REC_Y1       : begin					// 20122
							Y[1] <= miso;			// 20123
							if(counter == 32'd20125)
								state_reg <= REC_Y0;
            end
			REC_Y0       : begin					// 20126
							Y[0] <= miso;			// 20127
							if(counter == 32'd20129)
								state_reg <= REC_Z7;
            end
            REC_Z7       : begin					// 20130
							Z[7] <= miso;			// 20131
							if(counter == 32'd20133)
								state_reg <= REC_Z6;
            end
			REC_Z6       : begin					// 20134
							Z[6] <= miso;			// 20135
							if(counter == 32'd20137)
								state_reg <= REC_Z5;
            end
			REC_Z5       : begin					// 20138
							Z[5] <= miso;			// 20139
							if(counter == 32'd20141)
								state_reg <= REC_Z4;
            end
			REC_Z4       : begin					// 20142
							Z[4] <= miso;			// 20143
							if(counter == 32'd20145)
								state_reg <= REC_Z3;
            end
			REC_Z3       : begin					// 20146
							Z[3] <= miso;			// 20147
							if(counter == 32'd20149)
								state_reg <= REC_Z2;
            end
			REC_Z2       : begin					// 20150
							Z[2] <= miso;			// 20151
							if(counter == 32'd20153)
								state_reg <= REC_Z1;
            end
			REC_Z1       : begin					// 20154
							Z[1] <= miso;			// 20155
							if(counter == 32'd20157)
								state_reg <= REC_Z0;
            end
			REC_Z0       : begin					// 20158
							Z[0] <= miso;			// 20159
							if(counter == 32'd20161)
								state_reg <= SEND_CSH;
            end
            SEND_CSH    : begin						// 20162
							csn <= 1'b1;			// 20163
							if(counter == 32'd30163) begin	// wait 2.5ms
								counter <= 32'd20000;	// reset to 20000
								state_reg <= SEND_CSL;
							end	
            end
        endcase
    end
    
    // Data Buffer
    always @(posedge sclk)
        if(counter == 32'd20162)		// latch when first entering state SEND_CSH
            temp_data_storage <= { X, Y, Z };
            
    // Output accelerometer data
    assign x_data = temp_data_storage[23:16];
    assign y_data = temp_data_storage[15:8];
    assign z_data = temp_data_storage[7:0];
	
	assign sclk = clk_reg;
    
endmodule
