`ifndef ROUTE66_VOICE_DEFS_VH
`define ROUTE66_VOICE_DEFS_VH

// Route 66 phrase identifiers (4-bit phrase bus)
`define PHRASE_ROUTE_66       4'd0
`define PHRASE_BEGIN          4'd1
`define PHRASE_ADDITION       4'd2
`define PHRASE_SUBTRACTION    4'd3
`define PHRASE_CORRECT        4'd4
`define PHRASE_INCORRECT      4'd5
`define PHRASE_TEN_SECONDS    4'd6
`define PHRASE_TIME_EXPIRED   4'd7
`define PHRASE_GAME_OVER      4'd8

// Complete-word dictionary identifiers (6-bit word bus)
`define WORD_END          6'd0
`define WORD_ROUTE        6'd1
`define WORD_SIXTY        6'd2
`define WORD_SIX          6'd3
`define WORD_BEGIN        6'd4
`define WORD_ADDITION     6'd5
`define WORD_SUBTRACTION  6'd6
`define WORD_CORRECT      6'd7
`define WORD_INCORRECT    6'd8
`define WORD_TEN          6'd9
`define WORD_SECONDS      6'd10
`define WORD_TIME         6'd11
`define WORD_EXPIRED      6'd12
`define WORD_GAME         6'd13
`define WORD_OVER         6'd14

`endif
