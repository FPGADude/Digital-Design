package route66_pkg;

    localparam logic [7:0] TARGET_VALUE = 8'd66;
    localparam int NUM_QUESTIONS = 8;

    typedef enum logic [0:0] {
        OP_ADD = 1'b0,
        OP_SUB = 1'b1
    } op_t;

    typedef struct packed {
        op_t        op;
        logic [7:0] operand;
    } question_t;

    typedef enum logic [2:0] {
        ST_IDLE          = 3'd0,
        ST_SHOW_QUESTION = 3'd1,
        ST_PLAYING       = 3'd2,
        ST_CHECK         = 3'd3,
        ST_NEXT          = 3'd4,
        ST_GAME_OVER     = 3'd5
    } game_state_t;

endpackage
