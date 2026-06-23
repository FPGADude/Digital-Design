// ================================================================
// elevator_renderer.v
// ================================================================
// Creator : David J. Marion
// Date    : 6.20.2026
// Project : Basys 3 FPGA Elevator Controller
// Purpose : Draws the VGA elevator shaft, moving car, door 
//           animation, requests, and status panel.
//
// Notes   : Pure combinational pixel renderer. Input pixel_x/pixel_y 
//           selects one RGB color for the current pixel.
//
// Board   : Digilent Basys 3, 100 MHz system clock
// Language: Verilog HDL
// ================================================================

module elevator_renderer(
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire       video_on,
    input  wire [2:0] state,
    input  wire [1:0] curr_floor,
    input  wire       dir_up,
    input  wire [3:0] requests,
    input  wire       moving,
    input  wire       door_open,
    input  wire       door_opening,
    input  wire       door_closing,
    input  wire [9:0] car_y,
    input  wire [5:0] door_pos,
    input  wire       estop_active,
    output reg  [11:0] rgb
);

    // 12-bit RGB color constants. Basys 3 VGA uses 4 bits each for red, green, blue.
    localparam BLACK  = 12'h000;
    localparam WHITE  = 12'hFFF;
    localparam GRAY   = 12'h777;
    localparam DGRAY  = 12'h333;
    localparam LGRAY  = 12'hAAA;
    localparam RED    = 12'hF00;
    localparam GREEN  = 12'h0F0;
    localparam YELLOW = 12'hFF0;
    localparam BLUE   = 12'h04F;
    localparam CYAN   = 12'h0FF;
    localparam ORANGE = 12'hFA0;

    // State encodings copied from elevator_controller for display logic.
    localparam S_IDLE       = 3'd0;
    localparam S_MOVE_UP    = 3'd1;
    localparam S_MOVE_DOWN  = 3'd2;
    localparam S_OPEN_DOOR  = 3'd3;
    localparam S_WAIT       = 3'd4;
    localparam S_CLOSE_DOOR = 3'd5;

    // Main geometry of the elevator shaft and car on a 640x480 screen.
    localparam SHAFT_L = 200;
    localparam SHAFT_R = 440;
    localparam SHAFT_T = 40;
    localparam SHAFT_B = 460;
    localparam CAR_X   = 260;
    localparam CAR_W   = 120;
    localparam CAR_H   = 70;

    // Door geometry is relative to the car top-left corner. door_pos from
    // the controller controls how far the left/right door halves slide apart.
    localparam DOOR_TOP  = 12;
    localparam DOOR_BOT  = 62;
    localparam DOOR_L    = 16;
    localparam DOOR_R    = 104;
    localparam DOOR_MID  = 60;

    // Basic shape tests for the shaft, floor lines, car body, and doors.
    // Each wire becomes true when the current pixel belongs to that object.
    wire shaft_area = rect(pixel_x,pixel_y,SHAFT_L,SHAFT_T,SHAFT_R,SHAFT_B);
    wire wall = shaft_area && ((pixel_x < SHAFT_L+10) || (pixel_x > SHAFT_R-10));
    wire floor_line = shaft_area &&
        ((pixel_y >= 79  && pixel_y <= 82)  ||
         (pixel_y >= 179 && pixel_y <= 182) ||
         (pixel_y >= 279 && pixel_y <= 282) ||
         (pixel_y >= 379 && pixel_y <= 382));

    wire car_body = rect(pixel_x,pixel_y,CAR_X,car_y,CAR_X+CAR_W,car_y+CAR_H);
    wire car_border = car_body &&
        (pixel_x < CAR_X+4 || pixel_x > CAR_X+CAR_W-4 ||
         pixel_y < car_y+4 || pixel_y > car_y+CAR_H-4);

    // Simple door animation: the elevator interior is drawn first, then two
    // rectangles slide away from the middle as door_pos increases.
    wire interior = rect(pixel_x,pixel_y,CAR_X+DOOR_L,car_y+DOOR_TOP,CAR_X+DOOR_R,car_y+DOOR_BOT);
    wire left_door = rect(pixel_x,pixel_y,
                          CAR_X+DOOR_L,
                          car_y+DOOR_TOP,
                          CAR_X+DOOR_MID-door_pos,
                          car_y+DOOR_BOT);
    wire right_door = rect(pixel_x,pixel_y,
                           CAR_X+DOOR_MID+door_pos,
                           car_y+DOOR_TOP,
                           CAR_X+DOOR_R,
                           car_y+DOOR_BOT);

    // Slightly highlight the current floor band behind the elevator car.
    wire curr_floor_band =
        ((curr_floor == 2'd3) && pixel_y >= 45  && pixel_y <= 115) ||
        ((curr_floor == 2'd2) && pixel_y >= 145 && pixel_y <= 215) ||
        ((curr_floor == 2'd1) && pixel_y >= 245 && pixel_y <= 315) ||
        ((curr_floor == 2'd0) && pixel_y >= 345 && pixel_y <= 415);

    // Green request lamps beside the shaft show pending floor calls.
    wire req4_lamp = requests[3] && rect(pixel_x,pixel_y,448,70,458,90);
    wire req3_lamp = requests[2] && rect(pixel_x,pixel_y,448,170,458,190);
    wire req2_lamp = requests[1] && rect(pixel_x,pixel_y,448,270,458,290);
    wire req1_lamp = requests[0] && rect(pixel_x,pixel_y,448,370,458,390);

    // Right-side panels for status, request list, and legend.
    wire status_box  = rect(pixel_x,pixel_y,470,55,630,205);
    wire request_box = rect(pixel_x,pixel_y,470,225,630,365);
    wire legend_box  = rect(pixel_x,pixel_y,470,390,630,455);

    // Text objects for labels and panel contents. These use the small
    // built-in 5x7 font functions below.
    wire floor4_txt = text_floor_label(pixel_x,pixel_y,25, 68,2'd3);
    wire floor3_txt = text_floor_label(pixel_x,pixel_y,25,168,2'd2);
    wire floor2_txt = text_floor_label(pixel_x,pixel_y,25,268,2'd1);
    wire floor1_txt = text_floor_label(pixel_x,pixel_y,25,368,2'd0);

    wire status_title = text_word(pixel_x,pixel_y,490,70,4'd0,curr_floor,1'b0,1'b0);
    wire status_floor = text_word(pixel_x,pixel_y,490,105,4'd1,curr_floor,1'b0,1'b0);
    wire status_dir   = text_word(pixel_x,pixel_y,490,130,4'd2,curr_floor,dir_up,moving);
    wire status_door  = text_word(pixel_x,pixel_y,490,155,4'd3,curr_floor,1'b0,1'b0);
    wire status_estop = estop_active && text_word(pixel_x,pixel_y,490,180,4'd4,curr_floor,1'b0,1'b0);

    wire req_title = text_word(pixel_x,pixel_y,490,240,4'd5,curr_floor,1'b0,1'b0);
    wire req4_txt  = text_request(pixel_x,pixel_y,500,270,2'd3,requests[3]);
    wire req3_txt  = text_request(pixel_x,pixel_y,500,293,2'd2,requests[2]);
    wire req2_txt  = text_request(pixel_x,pixel_y,500,316,2'd1,requests[1]);
    wire req1_txt  = text_request(pixel_x,pixel_y,500,339,2'd0,requests[0]);

    wire legend_title = text_word(pixel_x,pixel_y,495,405,4'd6,curr_floor,1'b0,1'b0);
    wire legend_req   = text_word(pixel_x,pixel_y,492,430,4'd7,curr_floor,1'b0,1'b0);

    // Simple direction arrow drawn on the elevator car while moving.
    wire up_arrow = moving && dir_up && rect(pixel_x,pixel_y,CAR_X+108,car_y+22,CAR_X+114,car_y+42);
    wire up_tip   = moving && dir_up &&
                    (pixel_y >= car_y+14 && pixel_y <= car_y+22 &&
                     pixel_x >= CAR_X+105+(pixel_y-(car_y+14))/2 &&
                     pixel_x <= CAR_X+117-(pixel_y-(car_y+14))/2);
    wire dn_arrow = moving && !dir_up && rect(pixel_x,pixel_y,CAR_X+108,car_y+22,CAR_X+114,car_y+42);
    wire dn_tip   = moving && !dir_up &&
                    (pixel_y >= car_y+42 && pixel_y <= car_y+50 &&
                     pixel_x >= CAR_X+105+((car_y+50)-pixel_y)/2 &&
                     pixel_x <= CAR_X+117-((car_y+50)-pixel_y)/2);

    // Pixel priority encoder. Objects listed earlier have priority over
    // objects below them, so text and arrows appear on top of panels/car.
    always @(*) begin
        if (!video_on)
            rgb = BLACK;
        else if (floor4_txt || floor3_txt || floor2_txt || floor1_txt)
            rgb = WHITE;
        else if (status_title || req_title || legend_title)
            rgb = YELLOW;
        else if (status_estop)
            rgb = RED;
        else if (status_floor || status_dir || status_door || req4_txt || req3_txt || req2_txt || req1_txt || legend_req)
            rgb = WHITE;
        else if (estop_active && rect(pixel_x,pixel_y,180,15,460,32))
            rgb = RED;
        else if (estop_active && text_word(pixel_x,pixel_y,205,18,4'd8,curr_floor,1'b0,1'b0))
            rgb = WHITE;
        else if (up_arrow || up_tip)
            rgb = GREEN;
        else if (dn_arrow || dn_tip)
            rgb = RED;
        else if (req1_lamp || req2_lamp || req3_lamp || req4_lamp)
            rgb = GREEN;
        else if (car_border)
            rgb = WHITE;
        else if (left_door || right_door)
            rgb = DGRAY;
        else if (interior)
            rgb = 12'h9CF;
        else if (car_body)
            rgb = LGRAY;
        else if (wall)
            rgb = DGRAY;
        else if (floor_line)
            rgb = BLACK;
        else if (shaft_area && curr_floor_band)
            rgb = 12'h888;
        else if (shaft_area)
            rgb = GRAY;
        else if (status_box || request_box || legend_box)
            rgb = 12'h111;
        else if (pixel_x < 170 || pixel_x >= 460)
            rgb = BLACK;
        else
            rgb = 12'h001;
    end

    // Rectangle helper. Returns 1 when (x,y) is inside the inclusive box.
    function rect;
        input [9:0] x, y, x1, y1, x2, y2;
        begin
            rect = (x >= x1 && x <= x2 && y >= y1 && y <= y2);
        end
    endfunction

    // Draw one scaled 5x7 character. Each font pixel is expanded to about
    // 2x2 screen pixels for easier visibility on VGA.
    function char_at;
        input [9:0] x, y, x0, y0;
        input [7:0] ch;
        reg [9:0] dx, dy;
        reg [2:0] col, row;
        reg [4:0] bits;
        begin
            char_at = 1'b0;
            if (x >= x0 && x < x0 + 10 && y >= y0 && y < y0 + 14) begin
                dx = x - x0;
                dy = y - y0;
                col = dx[3:1];
                row = dy[3:1];
                bits = font_bits(ch,row);
                if (col < 5)
                    char_at = bits[4-col];
            end
        end
    endfunction

    // Tiny 5x7 font ROM implemented as a Verilog function. Only the
    // characters needed by this project are included.
    function [4:0] font_bits;
        input [7:0] ch;
        input [2:0] row;
        begin
            case (ch)
                "0": case(row) 0:font_bits=5'b11111;1:font_bits=5'b10001;2:font_bits=5'b10011;3:font_bits=5'b10101;4:font_bits=5'b11001;5:font_bits=5'b10001;6:font_bits=5'b11111;default:font_bits=0; endcase
                "1": case(row) 0:font_bits=5'b00100;1:font_bits=5'b01100;2:font_bits=5'b00100;3:font_bits=5'b00100;4:font_bits=5'b00100;5:font_bits=5'b00100;6:font_bits=5'b01110;default:font_bits=0; endcase
                "2": case(row) 0:font_bits=5'b11110;1:font_bits=5'b00001;2:font_bits=5'b00001;3:font_bits=5'b11110;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b11111;default:font_bits=0; endcase
                "3": case(row) 0:font_bits=5'b11110;1:font_bits=5'b00001;2:font_bits=5'b00001;3:font_bits=5'b01110;4:font_bits=5'b00001;5:font_bits=5'b00001;6:font_bits=5'b11110;default:font_bits=0; endcase
                "4": case(row) 0:font_bits=5'b10010;1:font_bits=5'b10010;2:font_bits=5'b10010;3:font_bits=5'b11111;4:font_bits=5'b00010;5:font_bits=5'b00010;6:font_bits=5'b00010;default:font_bits=0; endcase
                "A": case(row) 0:font_bits=5'b01110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b11111;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b10001;default:font_bits=0; endcase
                "C": case(row) 0:font_bits=5'b01111;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b10000;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b01111;default:font_bits=0; endcase
                "D": case(row) 0:font_bits=5'b11110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b10001;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b11110;default:font_bits=0; endcase
                "E": case(row) 0:font_bits=5'b11111;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b11110;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b11111;default:font_bits=0; endcase
                "F": case(row) 0:font_bits=5'b11111;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b11110;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b10000;default:font_bits=0; endcase
                "G": case(row) 0:font_bits=5'b01111;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b10111;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b01111;default:font_bits=0; endcase
                "I": case(row) 0:font_bits=5'b11111;1:font_bits=5'b00100;2:font_bits=5'b00100;3:font_bits=5'b00100;4:font_bits=5'b00100;5:font_bits=5'b00100;6:font_bits=5'b11111;default:font_bits=0; endcase
                "L": case(row) 0:font_bits=5'b10000;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b10000;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b11111;default:font_bits=0; endcase
                "M": case(row) 0:font_bits=5'b10001;1:font_bits=5'b11011;2:font_bits=5'b10101;3:font_bits=5'b10101;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b10001;default:font_bits=0; endcase
                "N": case(row) 0:font_bits=5'b10001;1:font_bits=5'b11001;2:font_bits=5'b10101;3:font_bits=5'b10011;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b10001;default:font_bits=0; endcase
                "O": case(row) 0:font_bits=5'b01110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b10001;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b01110;default:font_bits=0; endcase
                "P": case(row) 0:font_bits=5'b11110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b11110;4:font_bits=5'b10000;5:font_bits=5'b10000;6:font_bits=5'b10000;default:font_bits=0; endcase
                "Q": case(row) 0:font_bits=5'b01110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b10001;4:font_bits=5'b10101;5:font_bits=5'b10010;6:font_bits=5'b01101;default:font_bits=0; endcase
                "R": case(row) 0:font_bits=5'b11110;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b11110;4:font_bits=5'b10100;5:font_bits=5'b10010;6:font_bits=5'b10001;default:font_bits=0; endcase
                "S": case(row) 0:font_bits=5'b01111;1:font_bits=5'b10000;2:font_bits=5'b10000;3:font_bits=5'b01110;4:font_bits=5'b00001;5:font_bits=5'b00001;6:font_bits=5'b11110;default:font_bits=0; endcase
                "T": case(row) 0:font_bits=5'b11111;1:font_bits=5'b00100;2:font_bits=5'b00100;3:font_bits=5'b00100;4:font_bits=5'b00100;5:font_bits=5'b00100;6:font_bits=5'b00100;default:font_bits=0; endcase
                "U": case(row) 0:font_bits=5'b10001;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b10001;4:font_bits=5'b10001;5:font_bits=5'b10001;6:font_bits=5'b01110;default:font_bits=0; endcase
                "V": case(row) 0:font_bits=5'b10001;1:font_bits=5'b10001;2:font_bits=5'b10001;3:font_bits=5'b10001;4:font_bits=5'b10001;5:font_bits=5'b01010;6:font_bits=5'b00100;default:font_bits=0; endcase
                "Y": case(row) 0:font_bits=5'b10001;1:font_bits=5'b10001;2:font_bits=5'b01010;3:font_bits=5'b00100;4:font_bits=5'b00100;5:font_bits=5'b00100;6:font_bits=5'b00100;default:font_bits=0; endcase
                "*": case(row) 0:font_bits=5'b00100;1:font_bits=5'b10101;2:font_bits=5'b01110;3:font_bits=5'b11111;4:font_bits=5'b01110;5:font_bits=5'b10101;6:font_bits=5'b00100;default:font_bits=0; endcase
                ":": case(row) 0:font_bits=5'b00000;1:font_bits=5'b00100;2:font_bits=5'b00100;3:font_bits=5'b00000;4:font_bits=5'b00100;5:font_bits=5'b00100;6:font_bits=5'b00000;default:font_bits=0; endcase
                "-": case(row) 0:font_bits=5'b00000;1:font_bits=5'b00000;2:font_bits=5'b00000;3:font_bits=5'b11111;4:font_bits=5'b00000;5:font_bits=5'b00000;6:font_bits=5'b00000;default:font_bits=0; endcase
                " ": font_bits=5'b00000;
                default: font_bits=5'b00000;
            endcase
        end
    endfunction

    // Convert internal floor code 0-3 into ASCII characters "1"-"4".
    function [7:0] floor_digit_char;
        input [1:0] floor;
        begin
            case (floor)
                2'd0: floor_digit_char = "1";
                2'd1: floor_digit_char = "2";
                2'd2: floor_digit_char = "3";
                2'd3: floor_digit_char = "4";
                default: floor_digit_char = "1";
            endcase
        end
    endfunction

    // Render a label like "FLOOR 1" at a fixed location.
    function text_floor_label;
        input [9:0] x, y, x0, y0;
        input [1:0] floor;
        reg [3:0] idx;
        reg [7:0] ch;
        begin
            text_floor_label = 1'b0;
            if (x >= x0 && x < x0 + 84 && y >= y0 && y < y0 + 14) begin
                idx = (x - x0) / 12;
                case (idx)
                    0: ch="F"; 1: ch="L"; 2: ch="O"; 3: ch="O"; 4: ch="R"; 5: ch=" "; 6: ch=floor_digit_char(floor);
                    default: ch=" ";
                endcase
                text_floor_label = char_at(x,y,x0+idx*12,y0,ch);
            end
        end
    endfunction

    // General-purpose text renderer for the status words used on the
    // right-side panel. The id input selects which phrase to draw.
    function text_word;
        input [9:0] x, y, x0, y0;
        input [3:0] id;
        input [1:0] floor;
        input dir;
        input is_moving;
        reg [3:0] idx;
        reg [7:0] ch;
        begin
            text_word = 1'b0;
            if (x >= x0 && x < x0 + 156 && y >= y0 && y < y0 + 14) begin
                idx = (x - x0) / 12;
                ch = " ";
                case (id)
                    // STATUS
                    4'd0: case(idx) 0:ch="S";1:ch="T";2:ch="A";3:ch="T";4:ch="U";5:ch="S"; default:ch=" "; endcase
                    // FLOOR: n
                    4'd1: case(idx) 0:ch="F";1:ch="L";2:ch="O";3:ch="O";4:ch="R";5:ch=":";6:ch=" ";7:ch=floor_digit_char(floor); default:ch=" "; endcase
                    // DIR: UP / DN / IDLE
                    4'd2: case(idx)
                        0:ch="D";1:ch="I";2:ch="R";3:ch=":";4:ch=" ";
                        5:ch=(is_moving ? (dir ? "U" : "D") : "I");
                        6:ch=(is_moving ? (dir ? "P" : "N") : "D");
                        7:ch=(is_moving ? " " : "L");
                        8:ch=(is_moving ? " " : "E");
                        default:ch=" ";
                    endcase
                    // DOOR: OPEN/CLOSED
                    4'd3: case(idx)
                        0:ch="D";1:ch="O";2:ch="O";3:ch="R";4:ch=":";5:ch=" ";
                        6:ch=(door_open || door_opening ? "O" : "C");
                        7:ch=(door_open || door_opening ? "P" : "L");
                        8:ch=(door_open || door_opening ? "E" : "O");
                        9:ch=(door_open || door_opening ? "N" : "S");
                        10:ch=(door_open || door_opening ? " " : "E");
                        11:ch=(door_open || door_opening ? " " : "D");
                        default:ch=" ";
                    endcase
                    // ESTOP ON
                    4'd4: case(idx) 0:ch="E";1:ch="S";2:ch="T";3:ch="O";4:ch="P";5:ch=" ";6:ch="O";7:ch="N"; default:ch=" "; endcase
                    // REQUESTS
                    4'd5: case(idx) 0:ch="R";1:ch="E";2:ch="Q";3:ch="U";4:ch="E";5:ch="S";6:ch="T";7:ch="S"; default:ch=" "; endcase
                    // LEGEND
                    4'd6: case(idx) 0:ch="L";1:ch="E";2:ch="G";3:ch="E";4:ch="N";5:ch="D"; default:ch=" "; endcase
                    // * REQUEST
                    4'd7: case(idx) 0:ch="*";1:ch=" ";2:ch="R";3:ch="E";4:ch="Q";5:ch="U";6:ch="E";7:ch="S";8:ch="T"; default:ch=" "; endcase
                    // EMERGENCY STOP
                    4'd8: case(idx) 0:ch="E";1:ch="M";2:ch="E";3:ch="R";4:ch="G";5:ch="E";6:ch="N";7:ch="C";8:ch="Y";9:ch=" ";10:ch="S";11:ch="T";12:ch="O";13:ch="P"; default:ch=" "; endcase
                    default: ch=" ";
                endcase
                text_word = char_at(x,y,x0+idx*12,y0,ch);
            end
        end
    endfunction

    // Render one request-list row such as "F3 - *" or "F3 - -".
    function text_request;
        input [9:0] x, y, x0, y0;
        input [1:0] floor;
        input req;
        reg [3:0] idx;
        reg [7:0] ch;
        begin
            text_request = 1'b0;
            if (x >= x0 && x < x0 + 96 && y >= y0 && y < y0 + 14) begin
                idx = (x - x0) / 12;
                case(idx)
                    0:ch="F";1:ch=floor_digit_char(floor);2:ch=" ";3:ch="-";4:ch=" ";5:ch=(req ? "*" : "-");
                    default:ch=" ";
                endcase
                text_request = char_at(x,y,x0+idx*12,y0,ch);
            end
        end
    endfunction

endmodule



