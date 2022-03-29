`timescale 1ns / 1ps

// Used on Basys 3 

module pixel_gen(
    input clk,              // 100MHz
    input reset,            // btnC
    input up,               // btnU
    input down,             // btnD
    input left,             // btnL
    input right,            // btnR
    input [9:0] x,          // from vga controller
    input [9:0] y,          // from vga controller
    input video_on,         // from vga controller
    input p_tick,           // 25MHz from vga controller
    output reg [11:0] rgb   // to DAC, to vga connector
    );
    
    // 60Hz refresh tick
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0; // start of vsync(vertical retrace)
    
    // ********************************************************************************
    
    // maximum x, y values in display area
    parameter X_MAX = 639;
    parameter Y_MAX = 479;
    
    // FROG
    // square rom boundaries
    parameter FROG_SIZE = 28;
    parameter X_START = 320;                // starting x position - left rom edge centered horizontally
    parameter Y_START = 422;                // starting y position - centered in lower yellow area vertically
    
    // frog gameboard boundaries
    parameter X_LEFT = 32;                  // against left green wall
    parameter X_RIGHT = 608;                // against right green wall
    parameter Y_TOP = 68;                   // against top home/wall areas 
    parameter Y_BOTTOM = 452;               // against bottom green wall
    // frog boundary signals
    wire [9:0] x_frog_l, x_frog_r;          // frog horizontal boundary signals
    wire [9:0] y_frog_t, y_frog_b;          // frog vertical boundary signals  
    reg [9:0] y_frog_reg = Y_START;         // frog starting position X
    reg [9:0] x_frog_reg = X_START;         // frog starting position Y
    reg [9:0] y_frog_next, x_frog_next;     // signals for register buffer 
    parameter FROG_VELOCITY = 4;            // frog velocity  
    

    // Register Control
    always @(posedge clk or posedge reset)
        if(reset) begin
            x_frog_reg <= X_START;
            y_frog_reg <= Y_START;
        end
        else begin
            x_frog_reg <= x_frog_next;
            y_frog_reg <= y_frog_next;
        end
   
   
    // Frog Control
    always @* begin
        y_frog_next = y_frog_reg;       // no move
        x_frog_next = x_frog_reg;       // no move
        if(refresh_tick)                
            if(up & (y_frog_t > FROG_VELOCITY) & (y_frog_t > (Y_TOP + FROG_VELOCITY)))
                y_frog_next = y_frog_reg - FROG_VELOCITY;  // move up
            else if(down & (y_frog_b < (Y_MAX - FROG_VELOCITY)) & (y_frog_b < (Y_BOTTOM - FROG_VELOCITY)))
                y_frog_next = y_frog_reg + FROG_VELOCITY;  // move down
            else if(left & (x_frog_l > FROG_VELOCITY) & (x_frog_l > (X_LEFT + FROG_VELOCITY - 1)))
                x_frog_next = x_frog_reg - FROG_VELOCITY;   // move left
            else if(right & (x_frog_r < (X_MAX - FROG_VELOCITY)) & (x_frog_r < (X_RIGHT - FROG_VELOCITY)))
                x_frog_next = x_frog_reg + FROG_VELOCITY;   // move right
    end     
    
    
    // row and column wires for each rom
    wire [4:0] row1, col1;      // frog up
    wire [4:0] row2, col2;      // frog down
    wire [4:0] row3, col3;      // frog left
    wire [4:0] row4, col4;      // frog right

    
    // give value to rows and columns for roms
    // for frog roms
    assign col1 = x - x_frog_l;     // to obtain the column value, subtract rom left x position from x
    assign row1 = y - y_frog_t;     // to obtain the row value, subtract rom top y position from y
    assign col2 = x - x_frog_l;   
    assign row2 = y - y_frog_t;
    assign col3 = x - x_frog_l;   
    assign row3 = y - y_frog_t;
    assign col4 = x - x_frog_l;   
    assign row4 = y - y_frog_t;

    
    // Instantiate roms
    // frog direction roms
    frog_up_rom rom1(.clk(clk), .row(row1), .col(col1), .color_data(rom_data1));
    frog_down_rom rom2(.clk(clk), .row(row2), .col(col2), .color_data(rom_data2));
    frog_left_rom rom3(.clk(clk), .row(row3), .col(col3), .color_data(rom_data3));
    frog_right_rom rom4(.clk(clk), .row(row4), .col(col4), .color_data(rom_data4));
    
    
    // **** ROM BOUNDARIES / STATUS SIGNALS ****
    // frog rom data square boundaries
    assign x_frog_l = x_frog_reg;
    assign y_frog_t = y_frog_reg;
    assign x_frog_r = x_frog_l + FROG_SIZE - 1;
    assign y_frog_b = y_frog_t + FROG_SIZE - 1;
    
    // rom object status signal
    wire frog_on;
                    
    // pixel within rom square boundaries
    assign frog_on = (x_frog_l <= x) && (x <= x_frog_r) &&
                     (y_frog_t <= y) && (y <= y_frog_b);                              
   
                             
    // RGB color values for game board
    parameter GREEN  = 12'h0F0;
    parameter BLUE   = 12'h00F;
    parameter YELLOW = 12'hFF0; 
    parameter BLACK  = 12'h000;
    
    
    // Pixel Location Status Signals
    wire bottom_green_on, top_black_on, left_green_on, right_green_on;
    wire upper_green__on, upper_yellow_on, lower_yellow_on;
    wire home1_on, home2_on, home3_on, home4_on, home5_on;      // all homes blue
    wire wall1_on, wall2_on, wall3_on, wall4_on;                // all walls green
    wire street_on, water_on;
    
 
    // drivers for status signals based on boundary pixel locations
    assign bottom_green_on  = ((x >= 0)   && (x < 640)   &&  (y >= 452) && (y < 480));
    assign top_black_on = ((x >= 0)  && (x < 640)  &&  (y >= 0) && (y < 32));
    assign left_green_on   = ((x >= 0) && (x < 32)  &&  (y >= 32) && (y < 452));
    assign right_green_on  = ((x >= 608) && (x < 640)  &&  (y >= 32) && (y < 452));
    assign upper_green_on = ((x >= 32) && (x < 608)  &&  (y >= 32) && (y < 36));
    assign upper_yellow_on    = ((x >= 32) && (x < 608)  &&  (y >= 228) && (y < 260));
    assign lower_yellow_on   = ((x >= 32) && (x < 608)  &&  (y >= 420) && (y < 452));
    assign home1_on = ((x >= 32)   && (x < 96)   &&  (y >= 36) && (y < 68));
    assign wall1_on  = ((x >= 96) && (x < 160)  && (y >= 36) && (y < 68));
    assign home2_on = ((x >= 160) && (x < 224)  &&  (y >= 36) && (y < 68));
    assign wall2_on  = ((x >= 224) && (x < 288)  && (y >= 36) && (y < 68));
    assign home3_on = ((x >= 288) && (x < 352)  &&   (y >= 36) && (y < 68));
    assign wall3_on  = ((x >= 352) && (x < 416)  && (y >= 36) && (y < 68));
    assign home4_on = ((x >= 416) && (x < 480)  &&  (y >= 36) && (y < 68));
    assign wall4_on  = ((x >= 480) && (x < 544)  && (y >= 36) && (y < 68));
    assign home5_on = ((x >= 544) && (x < 608)  &&  (y >= 36) && (y < 68));    
    assign street_on = ((x >= 32) && (x < 608)  && (y >= 260) && (y < 420));
    assign water_on = ((x >= 32) && (x < 608)  &&  (y >= 68) && (y < 228));
    
    
     
    // **** MULTIPLEX FROG ROMS ****
    wire [11:0] frog_rom;
    wire [11:0] rom_data1, rom_data2, rom_data3, rom_data4;
    
    reg [1:0] frog_select;
    
    always @(posedge clk or posedge reset)
        if(reset)
            frog_select = 2'b00;
        else if(refresh_tick)
            if(up)
                frog_select = 2'b00;
            else if(down)
                frog_select = 2'b01;
            else if(left)
                frog_select = 2'b10;
            else if(right)
                frog_select = 2'b11;
                 
    assign frog_rom = (frog_select == 2'b00) ? rom_data1 :
                      (frog_select == 2'b01) ? rom_data2 :
                      (frog_select == 2'b10) ? rom_data3 :
                                               rom_data4 ;  
    
    
    
    // Set RGB output value based on status signals
    always @*
        if(~video_on)
            rgb = 12'h000;
        
        else     
                 // frog 
			     if(frog_on && lower_yellow_on)      // frog on lower yellow
			     	if(&frog_rom)  // check for white bitmap background value 12'hFFF
			     		rgb = YELLOW;
			     	else
			     		rgb = frog_rom;
			     
			     
			     else if(frog_on && upper_yellow_on) // frog on upper yellow
			     	if(&frog_rom)  // check for white bitmap background value 12'hFFF
			     		rgb = YELLOW;
			     	else
			     		rgb = frog_rom;
			     
			     
			     else if(frog_on && street_on)       // frog on street
			     	if(&frog_rom)  // check for white bitmap background value 12'hFFF
			     		rgb = BLACK;
			     	else
			     		rgb = frog_rom;
			     
			     
			     else if(frog_on && water_on)        // frog on water
			     	if(&frog_rom)  // check for white bitmap background value 12'hFFF
			     		rgb = BLUE;
			     	else
			     		rgb = frog_rom;
		
		         
		         // game board backgrounds
		         else if(left_green_on)
                     rgb = GREEN;
                     
                     
                 else if(right_green_on)
                     rgb = GREEN;
		               
		               
                 else if(bottom_green_on)
                     rgb = GREEN;
                     
                     
                 else if(top_black_on)
                     rgb = BLACK;
                     
                     
                 else if(upper_green_on)
                     rgb = GREEN;
                     
                     
                 else if(upper_yellow_on)
                     rgb = YELLOW;
                     
                     
                 else if(lower_yellow_on)
                     rgb = YELLOW;
                     
                     
                 else if(home1_on)
                     rgb = BLUE;
                     
                     
                 else if(home2_on)
                     rgb = BLUE;
                     
                     
                 else if(home3_on)
                     rgb = BLUE;
                     
                     
                 else if(home4_on)
                     rgb = BLUE;
                     
                     
                 else if(home5_on)
                     rgb = BLUE;
                     
                     
                 else if(wall1_on)
                     rgb = GREEN;
                     
                     
                 else if(wall2_on)
                     rgb = GREEN;
                     
                     
                 else if(wall3_on)
                     rgb = GREEN;
                     
                     
                 else if(wall4_on)
                     rgb = GREEN;
                     
                     
                 else if(street_on)
                     rgb = BLACK;
                     
                     
                 else if(water_on)
                     rgb = BLUE;
    
    
endmodule
