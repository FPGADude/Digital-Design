// ============================================================================
// coin_input.v
// ----------------------------------------------------------------------------
// Converts the four Basys 3 slide switches used as coin selectors into a coin
// value in cents.  The design requires exactly one coin switch to be ON when
// BTN-U is pressed.
//
//   sw[0] = nickel  =   5 cents
//   sw[1] = dime    =  10 cents
//   sw[2] = quarter =  25 cents
//   sw[3] = dollar  = 100 cents
//
// If no switch or more than one switch is ON, coin_valid is deasserted.  The
// FSM uses that condition to flash the selected coin field on the VGA display.
// ============================================================================
`timescale 1ns / 1ps

module coin_input(
    input  wire [3:0] sw,
    output reg  [8:0] coin_value_cents,
    output reg        coin_valid
);

    // Coin selection for the Basys 3 switches.
    // Turn on exactly one switch, then press BTN-U to insert that coin.
    // sw[0] = nickel  =  5 cents
    // sw[1] = dime    = 10 cents
    // sw[2] = quarter = 25 cents
    // sw[3] = dollar  = 100 cents
    always @(*) begin
        coin_value_cents = 9'd0;
        coin_valid       = 1'b0;

        case (sw)
            4'b0001: begin coin_value_cents = 9'd5;   coin_valid = 1'b1; end
            4'b0010: begin coin_value_cents = 9'd10;  coin_valid = 1'b1; end
            4'b0100: begin coin_value_cents = 9'd25;  coin_valid = 1'b1; end
            4'b1000: begin coin_value_cents = 9'd100; coin_valid = 1'b1; end
            default: begin coin_value_cents = 9'd0;   coin_valid = 1'b0; end
        endcase
    end
endmodule
