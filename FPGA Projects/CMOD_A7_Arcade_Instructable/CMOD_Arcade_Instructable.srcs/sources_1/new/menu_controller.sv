`timescale 1ns / 1ps

module menu_controller (
    input  logic clk,
    input  logic reset,

    input  logic up_pulse,
    input  logic down_pulse,
    input  logic select_pulse,
    input  logic back_pulse,

    output logic [1:0] menu_index,
    output logic selected_mode
);

    always_ff @(posedge clk) begin
        if (reset) begin
            menu_index <= 2'd0;
            selected_mode <= 1'b0;
        end else begin
            if (selected_mode) begin
                if (back_pulse)
                    selected_mode <= 1'b0;
            end else begin
                if (up_pulse) begin
                    if (menu_index == 2'd0)
                        menu_index <= 2'd3;
                    else
                        menu_index <= menu_index - 1'b1;
                end else if (down_pulse) begin
                    if (menu_index == 2'd3)
                        menu_index <= 2'd0;
                    else
                        menu_index <= menu_index + 1'b1;
                end else if (select_pulse) begin
                    selected_mode <= 1'b1;
                end
            end
        end
    end

endmodule



