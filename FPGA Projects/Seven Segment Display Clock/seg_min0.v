`timescale 1ns / 1ps

// For 7-segment display clock
// Authored by David J Marion

module seg_min0(
    input [5:0] minutes,
    output reg [3:0] min0
    );
    
    always @(minutes) begin
        case(minutes)
            0   :   min0 = 0;
            1   :   min0 = 1;
            2   :   min0 = 2;
            3   :   min0 = 3;
            4   :   min0 = 4;
            5   :   min0 = 5;
            6   :   min0 = 6;
            7   :   min0 = 7;
            8   :   min0 = 8;
            9   :   min0 = 9;
            10  :   min0 = 0;
            11  :   min0 = 1;
            12  :   min0 = 2;
            13  :   min0 = 3;
            14  :   min0 = 4;
            15  :   min0 = 5;
            16  :   min0 = 6;
            17  :   min0 = 7;
            18  :   min0 = 8;
            19  :   min0 = 9;
            20  :   min0 = 0;
            21  :   min0 = 1;
            22  :   min0 = 2;
            23  :   min0 = 3;
            24  :   min0 = 4;
            25  :   min0 = 5;
            26  :   min0 = 6;
            27  :   min0 = 7;
            28  :   min0 = 8;
            29  :   min0 = 9;
            30  :   min0 = 0;
            31  :   min0 = 1;
            32  :   min0 = 2;
            33  :   min0 = 3;
            34  :   min0 = 4;
            35  :   min0 = 5;
            36  :   min0 = 6;
            37  :   min0 = 7;
            38  :   min0 = 8;
            39  :   min0 = 9;
            40  :   min0 = 0;
            41  :   min0 = 1;
            42  :   min0 = 2;
            43  :   min0 = 3;
            44  :   min0 = 4;
            45  :   min0 = 5;
            46  :   min0 = 6;
            47  :   min0 = 7;
            48  :   min0 = 8;
            49  :   min0 = 9;
            50  :   min0 = 0;
            51  :   min0 = 1;
            52  :   min0 = 2;
            53  :   min0 = 3;
            54  :   min0 = 4;
            55  :   min0 = 5;
            56  :   min0 = 6;
            57  :   min0 = 7;
            58  :   min0 = 8;
            59  :   min0 = 9;
        endcase
    end 
endmodule


