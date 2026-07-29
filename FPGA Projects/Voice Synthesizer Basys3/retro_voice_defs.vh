`ifndef RETRO_VOICE_DEFS_VH
`define RETRO_VOICE_DEFS_VH

// ============================================================================
// SHARED RETRO VOICE IDENTIFIERS
// ============================================================================
// This header is included by the phrase ROM, voice controller, word player,
// and demonstration top module. Centralizing numeric IDs keeps the design
// readable and prevents phrase/word values from drifting between modules.
//
// Current widths:
//   phrase ID = 4 bits, allowing 16 predefined phrases
//   word ID   = 6 bits, allowing 64 dictionary entries
// ============================================================================

// ============================================================================
// PHRASE IDENTIFIERS
// ============================================================================
// A phrase ID selects one sentence in retro_phrase_rom.v. The top-level game
// requests speech by presenting one of these IDs and pulsing start.
// ============================================================================
`define PHRASE_RADAR_ACTIVE       4'd0
`define PHRASE_PLAYER_ONE_READY   4'd1
`define PHRASE_WARNING            4'd2
`define PHRASE_ENEMY_APPROACHING  4'd3
`define PHRASE_FIRE               4'd4
`define PHRASE_SECTOR_CLEAR       4'd5
`define PHRASE_GAME_OVER          4'd6
`define PHRASE_HIGH_SCORE         4'd7

// ============================================================================
// COMPLETE-WORD DICTIONARY IDENTIFIERS
// ============================================================================
// WORD_END is a terminator and has no audible sample. Every phrase eventually
// returns WORD_END so retro_voice_core knows the sentence is complete.
//
// IDs 1 through 15 map to complete 8-bit PCM word samples stored in
// retro_word_pcm.mem and addressed by retro_word_sample_table.v.
// ============================================================================
`define WORD_END          6'd0
`define WORD_RADAR        6'd1
`define WORD_ACTIVE       6'd2
`define WORD_PLAYER       6'd3
`define WORD_ONE          6'd4
`define WORD_READY        6'd5
`define WORD_WARNING      6'd6
`define WORD_ENEMY        6'd7
`define WORD_APPROACHING  6'd8
`define WORD_FIRE         6'd9
`define WORD_SECTOR       6'd10
`define WORD_CLEAR        6'd11
`define WORD_GAME         6'd12
`define WORD_OVER         6'd13
`define WORD_HIGH         6'd14
`define WORD_SCORE        6'd15

// ============================================================================
// LEGACY PHONEME IDENTIFIERS
//
// This first version uses a deliberately small, practical
// phoneme set. Additional sounds can be added later without
// changing the top-level interface.
//
// ============================================================================
`define PH_END     6'd0
`define PH_PAUSE   6'd1
`define PH_R       6'd2
`define PH_AE      6'd3
`define PH_D       6'd4
`define PH_ER      6'd5
`define PH_AA      6'd6
`define PH_K       6'd7
`define PH_T       6'd8
`define PH_IH      6'd9
`define PH_V       6'd10
`define PH_P       6'd11
`define PH_L       6'd12
`define PH_EY      6'd13
`define PH_W       6'd14
`define PH_AH      6'd15
`define PH_N       6'd16
`define PH_IY      6'd17
`define PH_G       6'd18
`define PH_M       6'd19
`define PH_Y       6'd20
`define PH_F       6'd21
`define PH_S       6'd22
`define PH_EH      6'd23
`define PH_CH      6'd24
`define PH_OW      6'd25
`define PH_HH      6'd26
`define PH_Z       6'd27
`define PH_KL      6'd28
`define PH_B       6'd29
`define PH_OY      6'd30
`define PH_UW      6'd31

`endif
