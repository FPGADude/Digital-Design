// ============================================================================
// vending_fsm.v
// ----------------------------------------------------------------------------
// Main finite state machine for the VGA vending machine.
//
// Responsibilities:
//   * Track selected product
//   * Track current credit in cents
//   * Compare credit against selected product price
//   * Calculate change
//   * Reduce inventory after a successful purchase
//   * Generate status states for the VGA renderer
//   * Handle sold-out, invalid coin, and cancel/refund cases
//
// This module intentionally keeps the state-machine decision making separate
// from the VGA renderer.  The renderer only displays the current state and data.
// ============================================================================
`timescale 1ns / 1ps

module vending_fsm(
    input  wire       clk,
    input  wire       reset,
    input  wire       tick_60hz,

    input  wire       select_chips,
    input  wire       select_soda,
    input  wire       select_candy,
    input  wire       insert_coin,
    input  wire       cancel,
    input  wire [8:0] coin_value_cents,
    input  wire       coin_valid,

    output reg  [2:0] state,
    output reg  [1:0] selected_product,
    output reg  [8:0] credit_cents,
    output reg  [8:0] price_cents,
    output reg  [8:0] change_cents,
    output reg        vend_pulse,
    output reg        invalid_coin_flash,
    output reg  [3:0] chips_count,
    output reg  [3:0] soda_count,
    output reg  [3:0] candy_count
);

    // State encoding.
    // ST_SELECT waits for a product button.
    // ST_INSERT accumulates credit until enough money is inserted or cancel is pressed.
    // ST_DISPENSE gives the renderer time to animate the falling product.
    // ST_CHANGE displays calculated change.
    // ST_THANKS finishes the transaction.
    // ST_SOLDOUT is shown when a selected product has no inventory left.
    // ST_REFUND is used when the user cancels before buying.
    localparam ST_SELECT   = 3'd0;
    localparam ST_INSERT   = 3'd1;
    localparam ST_DISPENSE = 3'd2;
    localparam ST_CHANGE   = 3'd3;
    localparam ST_THANKS   = 3'd4;
    localparam ST_SOLDOUT  = 3'd5;
    localparam ST_REFUND   = 3'd6;

    localparam PROD_CHIPS = 2'd0;
    localparam PROD_SODA  = 2'd1;
    localparam PROD_CANDY = 2'd2;

    localparam CHIPS_PRICE = 9'd125;
    localparam SODA_PRICE  = 9'd150;
    localparam CANDY_PRICE = 9'd75;

    reg [7:0] state_timer;
    reg [7:0] flash_timer;

    // Return the price for the selected product.
    // Prices are represented in cents so all money math stays integer-only.
    function [8:0] product_price;
        input [1:0] product;
        begin
            case (product)
                PROD_CHIPS: product_price = CHIPS_PRICE;
                PROD_SODA : product_price = SODA_PRICE;
                PROD_CANDY: product_price = CANDY_PRICE;
                default   : product_price = 9'd0;
            endcase
        end
    endfunction

    // Check the inventory count for the selected product.
    // This function is called when the user chooses CHIPS, SODA, or CANDY.
    function product_in_stock;
        input [1:0] product;
        begin
            case (product)
                PROD_CHIPS: product_in_stock = (chips_count != 4'd0);
                PROD_SODA : product_in_stock = (soda_count  != 4'd0);
                PROD_CANDY: product_in_stock = (candy_count != 4'd0);
                default   : product_in_stock = 1'b0;
            endcase
        end
    endfunction

    // Shared product-selection task.
    // This avoids repeating the same setup code for btnL, btnC, and btnR.
    // It also immediately moves to SOLDOUT if the chosen product count is zero.
    task select_product;
        input [1:0] product;
        begin
            selected_product <= product;
            price_cents      <= product_price(product);
            credit_cents     <= 9'd0;
            change_cents     <= 9'd0;
            state_timer      <= 8'd0;

            if (product_in_stock(product))
                state <= ST_INSERT;
            else
                state <= ST_SOLDOUT;
        end
    endtask

    // Decrement inventory after a successful vend.
    // The guard prevents accidental underflow if this task were ever called when empty.
    task reduce_inventory;
        input [1:0] product;
        begin
            case (product)
                PROD_CHIPS: if (chips_count != 4'd0) chips_count <= chips_count - 1'b1;
                PROD_SODA : if (soda_count  != 4'd0) soda_count  <= soda_count  - 1'b1;
                PROD_CANDY: if (candy_count != 4'd0) candy_count <= candy_count - 1'b1;
            endcase
        end
    endtask

    always @(posedge clk) begin
        if (reset) begin
            state              <= ST_SELECT;
            selected_product   <= PROD_CHIPS;
            credit_cents       <= 9'd0;
            price_cents        <= CHIPS_PRICE;
            change_cents       <= 9'd0;
            vend_pulse         <= 1'b0;
            invalid_coin_flash <= 1'b0;
            state_timer        <= 8'd0;
            flash_timer        <= 8'd0;
            chips_count        <= 4'd5;
            soda_count         <= 4'd5;
            candy_count        <= 4'd5;
        end else begin
            // vend_pulse is a one-clock event. It is cleared every cycle and
            // asserted only on the transaction cycle that starts dispensing.
            vend_pulse <= 1'b0;

            if (tick_60hz) begin
                if (state_timer != 8'hFF)
                    state_timer <= state_timer + 1'b1;

                if (flash_timer != 8'd0) begin
                    flash_timer <= flash_timer - 1'b1;
                    invalid_coin_flash <= 1'b1;
                end else begin
                    invalid_coin_flash <= 1'b0;
                end
            end

            case (state)
                // ---------------------------------------------------------
                // Wait for the user to select a product.
                // Credit/change are cleared here so the machine is ready for
                // the next transaction.
                // ---------------------------------------------------------
                ST_SELECT: begin
                    credit_cents <= 9'd0;
                    change_cents <= 9'd0;

                    if (select_chips)
                        select_product(PROD_CHIPS);
                    else if (select_soda)
                        select_product(PROD_SODA);
                    else if (select_candy)
                        select_product(PROD_CANDY);
                end

                // ---------------------------------------------------------
                // Product has been selected. Now accept coins or cancel.
                // If credit reaches/exceeds price, calculate change, reduce
                // inventory, and move to the dispense animation state.
                // ---------------------------------------------------------
                ST_INSERT: begin
                    if (cancel) begin
                        change_cents <= credit_cents;
                        state_timer  <= 8'd0;
                        state        <= ST_REFUND;
                    end else if (insert_coin) begin
                        if (coin_valid) begin
                            if ((credit_cents + coin_value_cents) >= price_cents) begin
                                credit_cents <= credit_cents + coin_value_cents;
                                change_cents <= (credit_cents + coin_value_cents) - price_cents;
                                state_timer  <= 8'd0;
                                state        <= ST_DISPENSE;
                                vend_pulse   <= 1'b1;
                                reduce_inventory(selected_product);
                            end else begin
                                credit_cents <= credit_cents + coin_value_cents;
                            end
                        end else begin
                            flash_timer <= 8'd45;
                        end
                    end
                end

                // Hold this state long enough for the renderer to animate the
                // product falling into the collection tray.
                ST_DISPENSE: begin
                    if (tick_60hz && state_timer >= 8'd90) begin
                        state_timer <= 8'd0;
                        state       <= ST_CHANGE;
                    end
                end

                // Briefly display the calculated change after dispensing.
                ST_CHANGE: begin
                    if (tick_60hz && state_timer >= 8'd60) begin
                        state_timer <= 8'd0;
                        state       <= ST_THANKS;
                    end
                end

                // End-of-sale message, then return to idle selection.
                ST_THANKS: begin
                    if (tick_60hz && state_timer >= 8'd90)
                        state <= ST_SELECT;
                end

                // Product was selected while inventory was zero.
                ST_SOLDOUT: begin
                    if (tick_60hz && state_timer >= 8'd90)
                        state <= ST_SELECT;
                end

                // User canceled before completing a purchase. The current
                // credit is shown as change/refund for a short time.
                ST_REFUND: begin
                    if (tick_60hz && state_timer >= 8'd90)
                        state <= ST_SELECT;
                end

                default: state <= ST_SELECT;
            endcase
        end
    end
endmodule
