`timescale 1ns / 1ps
`include "retro_voice_defs.vh"

// ============================================================
// RETRO PHRASE ROM
// ============================================================
// Converts a phrase ID and word position into a complete-word dictionary ID.
//
// The controller starts at word_index = 0 and increments the index only after
// the current word finishes playing. Each phrase must terminate with WORD_END.
//
// This module stores sentence structure only; it contains no PCM audio data.
// To add a phrase, add a phrase ID in retro_voice_defs.vh and define the
// corresponding ordered word list in the case statement below.
// ============================================================
module retro_phrase_rom (
    input  wire [3:0] phrase_id,
    input  wire [3:0] word_index,
    output reg  [5:0] word_id
);

    always @* begin
        // Safe default: unknown phrases and out-of-range indices terminate.
        word_id = `WORD_END;
    
        case (phrase_id)
    
            // "RADAR ACTIVE"
            `PHRASE_RADAR_ACTIVE: begin
                case (word_index)
                    4'd0: word_id = `WORD_RADAR;
                    4'd1: word_id = `WORD_ACTIVE;
                    // Undefined phrase IDs behave like an empty sentence.
            default: word_id = `WORD_END;
                endcase
            end
    
            // "PLAYER ONE READY"
            `PHRASE_PLAYER_ONE_READY: begin
                case (word_index)
                    4'd0: word_id = `WORD_PLAYER;
                    4'd1: word_id = `WORD_ONE;
                    4'd2: word_id = `WORD_READY;
                    // Undefined phrase IDs behave like an empty sentence.
            default: word_id = `WORD_END;
                endcase
            end
    
            // "WARNING"
            `PHRASE_WARNING: begin
                case (word_index)
                    4'd0: word_id = `WORD_WARNING;
                    // Undefined phrase IDs behave like an empty sentence.
            default: word_id = `WORD_END;
                endcase
            end
    
            // "ENEMY APPROACHING"
            `PHRASE_ENEMY_APPROACHING: begin
                case (word_index)
                    4'd0: word_id = `WORD_ENEMY;
                    4'd1: word_id = `WORD_APPROACHING;
                    // Undefined phrase IDs behave like an empty sentence.
            default: word_id = `WORD_END;
                endcase
            end
    
            // "FIRE"
            `PHRASE_FIRE: begin
                case (word_index)
                    4'd0: word_id = `WORD_FIRE;
                    // Undefined phrase IDs behave like an empty sentence.
            default: word_id = `WORD_END;
                endcase
            end
    
            // "SECTOR CLEAR"
            `PHRASE_SECTOR_CLEAR: begin
                case (word_index)
                    4'd0: word_id = `WORD_SECTOR;
                    4'd1: word_id = `WORD_CLEAR;
                    // Undefined phrase IDs behave like an empty sentence.
            default: word_id = `WORD_END;
                endcase
            end
    
            // "GAME OVER"
            `PHRASE_GAME_OVER: begin
                case (word_index)
                    4'd0: word_id = `WORD_GAME;
                    4'd1: word_id = `WORD_OVER;
                    // Undefined phrase IDs behave like an empty sentence.
            default: word_id = `WORD_END;
                endcase
            end
    
            // "HIGH SCORE"
            `PHRASE_HIGH_SCORE: begin
                case (word_index)
                    4'd0: word_id = `WORD_HIGH;
                    4'd1: word_id = `WORD_SCORE;
                    // Undefined phrase IDs behave like an empty sentence.
            default: word_id = `WORD_END;
                endcase
            end
    
            // Undefined phrase IDs behave like an empty sentence.
            default: word_id = `WORD_END;
        endcase
    end

endmodule
