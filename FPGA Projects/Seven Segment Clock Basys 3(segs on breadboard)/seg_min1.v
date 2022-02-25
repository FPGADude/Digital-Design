`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module seg_min1(
    input [5:0] minutes,
    output reg [3:0] min1
    );
    
    always @(minutes) begin
        case(minutes)
            0   :   min1 = 0;
            1   :   min1 = 0;
            2   :   min1 = 0;
            3   :   min1 = 0;
            4   :   min1 = 0;
            5   :   min1 = 0;
            6   :   min1 = 0;
            7   :   min1 = 0;
            8   :   min1 = 0;
            9   :   min1 = 0;
            10  :   min1 = 1;
            11  :   min1 = 1;
            12  :   min1 = 1;
            13  :   min1 = 1;
            14  :   min1 = 1;
            15  :   min1 = 1;
            16  :   min1 = 1;
            17  :   min1 = 1;
            18  :   min1 = 1;
            19  :   min1 = 1;
            20  :   min1 = 2;
            21  :   min1 = 2;
            22  :   min1 = 2;
            23  :   min1 = 2;
            24  :   min1 = 2;
            25  :   min1 = 2;
            26  :   min1 = 2;
            27  :   min1 = 2;
            28  :   min1 = 2;
            29  :   min1 = 2;
            30  :   min1 = 3;
            31  :   min1 = 3;
            32  :   min1 = 3;
            33  :   min1 = 3;
            34  :   min1 = 3;
            35  :   min1 = 3;
            36  :   min1 = 3;
            37  :   min1 = 3;
            38  :   min1 = 3;
            39  :   min1 = 3;
            40  :   min1 = 4;
            41  :   min1 = 4;
            42  :   min1 = 4;
            43  :   min1 = 4;
            44  :   min1 = 4;
            45  :   min1 = 4;
            46  :   min1 = 4;
            47  :   min1 = 4;
            48  :   min1 = 4;
            49  :   min1 = 4;
            50  :   min1 = 5;
            51  :   min1 = 5;
            52  :   min1 = 5;
            53  :   min1 = 5;
            54  :   min1 = 5;
            55  :   min1 = 5;
            56  :   min1 = 5;
            57  :   min1 = 5;
            58  :   min1 = 5;
            59  :   min1 = 5;
        endcase
    end  
endmodule


