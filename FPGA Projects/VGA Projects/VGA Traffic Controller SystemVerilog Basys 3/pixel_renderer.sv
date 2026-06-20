`timescale 1ns / 1ps

// -----------------------------------------------------------------------------
// Module: pixel_renderer
// -----------------------------------------------------------------------------
// Purpose:
//   Draws the base VGA scene for the traffic controller demonstration.
//
//   This module is purely combinational. For every pixel coordinate (pix_x, pix_y)
//   it decides what 12-bit RGB color should appear at that location. The scene
//   includes the roads, sidewalks, crosswalks, dashed lane dividers, stop bars,
//   traffic light housings, traffic light bulbs, pedestrian signal housings, and
//   the WALK / DON'T WALK icons.
//
//   The countdown digits are intentionally NOT drawn here. They are drawn by
//   text_renderer.sv so the block diagram stays clean:
//
//       vga_display_controller
//           +-- pixel_renderer : base scene and icons
//           +-- text_renderer  : countdown digits
//
// Notes:
//   - The renderer uses simple rectangle-based drawing primitives so the design
//     stays FPGA-friendly and synthesizes cleanly.
//   - Later drawing operations can overwrite earlier ones. This is intentional:
//     the background is drawn first, then roads, crosswalks, signals, and icons.
//   - No registers are used in this module.
// -----------------------------------------------------------------------------

module pixel_renderer (
    input  logic [9:0] pix_x,
    input  logic [9:0] pix_y,
    input  logic [1:0] main_light,
    input  logic [1:0] cross_light,
    input  logic [1:0] main_ped,
    input  logic [1:0] cross_ped,
    input  logic       blink_on,
    output logic [11:0] rgb
);

    // Encoded traffic light values received from traffic_light_fsm.
    localparam logic [1:0] LIGHT_RED    = 2'd0;
    localparam logic [1:0] LIGHT_YELLOW = 2'd1;
    localparam logic [1:0] LIGHT_GREEN  = 2'd2;

    // Encoded pedestrian signal values received from traffic_light_fsm.
    localparam logic [1:0] PED_DONT_STEADY = 2'd0;
    localparam logic [1:0] PED_WALK        = 2'd1;
    localparam logic [1:0] PED_DONT_BLINK  = 2'd2;

    // 12-bit RGB color constants. Each channel is 4 bits: {red, green, blue}.
    localparam logic [11:0] C_BLACK     = 12'h000;
    localparam logic [11:0] C_WHITE     = 12'hFFF;
    localparam logic [11:0] C_DGRAY     = 12'h222;
    localparam logic [11:0] C_ROAD      = 12'h333;
    localparam logic [11:0] C_ROAD_DARK = 12'h222;
    localparam logic [11:0] C_GRASS     = 12'h173;
    localparam logic [11:0] C_SIDEWALK  = 12'hAAA;
    localparam logic [11:0] C_CURB      = 12'hDDD;
    localparam logic [11:0] C_YELLOWLN  = 12'hDD0;
    localparam logic [11:0] C_RED       = 12'hF00;
    localparam logic [11:0] C_YELLOW    = 12'hFE0;
    localparam logic [11:0] C_GREEN     = 12'h0D2;
    localparam logic [11:0] C_DIM_R     = 12'h300;
    localparam logic [11:0] C_DIM_Y     = 12'h330;
    localparam logic [11:0] C_DIM_G     = 12'h030;
    localparam logic [11:0] C_ORANGE    = 12'hF80;
    localparam logic [11:0] C_POLE      = 12'h777;
    localparam logic [11:0] C_SIGNAL    = 12'hDB0;

    // Basic rectangle test used throughout the renderer.
    // Returns 1 when the current pixel is inside the inclusive rectangle
    // bounded by (x0,y0) and (x1,y1).
    function automatic logic in_rect(input int x0, input int y0, input int x1, input int y1);
        return (pix_x >= x0) && (pix_x <= x1) && (pix_y >= y0) && (pix_y <= y1);
    endfunction

    // Vertical dashed-line primitive.
    // Used for dashed lane dividers that run up and down the screen.
    // The modulo operation creates repeated ON/OFF dash segments.
    function automatic logic dash_v(input int x, input int y0, input int y1);
        logic on_dash;
        begin
            on_dash = (((pix_y - y0) % 32) < 18);
            return (pix_x >= x) && (pix_x <= x + 3) &&
                   (pix_y >= y0) && (pix_y <= y1) && on_dash;
        end
    endfunction

    // Horizontal dashed-line primitive.
    // Used for dashed lane dividers that run left and right across the screen.
    // The modulo operation creates repeated ON/OFF dash segments.
    function automatic logic dash_h(input int x0, input int x1, input int y);
        logic on_dash;
        begin
            on_dash = (((pix_x - x0) % 32) < 18);
            return (pix_x >= x0) && (pix_x <= x1) &&
                   (pix_y >= y) && (pix_y <= y + 3) && on_dash;
        end
    endfunction

    // Draws the striped crosswalks across the north/south road.
    // The caller supplies the upper-left coordinate of the crosswalk block.
    // Individual white rectangles form the zebra-stripe pattern.
    function automatic logic crosswalk_top_bottom(input int x0, input int y0);
        // Stripe pattern for crosswalks that cross the full 220-pixel N/S road width.
        return in_rect(x0 +  8, y0, x0 + 15, y0 + 28) ||
               in_rect(x0 + 24, y0, x0 + 31, y0 + 28) ||
               in_rect(x0 + 40, y0, x0 + 47, y0 + 28) ||
               in_rect(x0 + 56, y0, x0 + 63, y0 + 28) ||
               in_rect(x0 + 72, y0, x0 + 79, y0 + 28) ||
               in_rect(x0 + 88, y0, x0 + 95, y0 + 28) ||
               in_rect(x0 +104, y0, x0 +111, y0 + 28) ||
               in_rect(x0 +120, y0, x0 +127, y0 + 28) ||
               in_rect(x0 +136, y0, x0 +143, y0 + 28) ||
               in_rect(x0 +152, y0, x0 +159, y0 + 28) ||
               in_rect(x0 +168, y0, x0 +175, y0 + 28) ||
               in_rect(x0 +184, y0, x0 +191, y0 + 28) ||
               in_rect(x0 +200, y0, x0 +207, y0 + 28);
    endfunction

    // Draws the striped crosswalks across the east/west road.
    // The caller supplies the upper-left coordinate of the crosswalk block.
    // Individual white rectangles form the zebra-stripe pattern.
    function automatic logic crosswalk_left_right(input int x0, input int y0);
        // Stripe pattern for crosswalks that cross the full 220-pixel E/W road width.
        return in_rect(x0, y0 +  8, x0 + 28, y0 + 15) ||
               in_rect(x0, y0 + 24, x0 + 28, y0 + 31) ||
               in_rect(x0, y0 + 40, x0 + 28, y0 + 47) ||
               in_rect(x0, y0 + 56, x0 + 28, y0 + 63) ||
               in_rect(x0, y0 + 72, x0 + 28, y0 + 79) ||
               in_rect(x0, y0 + 88, x0 + 28, y0 + 95) ||
               in_rect(x0, y0 +104, x0 + 28, y0 +111) ||
               in_rect(x0, y0 +120, x0 + 28, y0 +127) ||
               in_rect(x0, y0 +136, x0 + 28, y0 +143) ||
               in_rect(x0, y0 +152, x0 + 28, y0 +159) ||
               in_rect(x0, y0 +168, x0 + 28, y0 +175) ||
               in_rect(x0, y0 +184, x0 + 28, y0 +191) ||
               in_rect(x0, y0 +200, x0 + 28, y0 +207);
    endfunction

    // Small WALK-person icon.
    // The icon is built from a few simple rectangles representing the head,
    // body, arms, and legs. It is drawn in white when the active pedestrian
    // state is PED_WALK.
    function automatic logic walk_icon_small(input int x0, input int y0);
        logic head, body, larm, rarm, lleg, rleg;
        begin
            head = in_rect(x0 + 11, y0 +  2, x0 + 17, y0 +  8);
            body = in_rect(x0 + 13, y0 + 10, x0 + 16, y0 + 23);
            larm = in_rect(x0 +  7, y0 + 13, x0 + 12, y0 + 16);
            rarm = in_rect(x0 + 17, y0 + 13, x0 + 23, y0 + 16);
            lleg = in_rect(x0 +  8, y0 + 24, x0 + 12, y0 + 34);
            rleg = in_rect(x0 + 17, y0 + 24, x0 + 22, y0 + 34);
            return head || body || larm || rarm || lleg || rleg;
        end
    endfunction

    // Small DON'T WALK hand icon.
    // The icon is built from simple rectangles representing the palm, thumb,
    // and fingers. It is drawn in orange when the pedestrian state requests
    // a steady hand or a blinking hand.
    function automatic logic hand_icon_small(input int x0, input int y0);
        logic palm, thumb, f1, f2, f3, f4;
        begin
            palm  = in_rect(x0 +  8, y0 + 18, x0 + 22, y0 + 30);
            thumb = in_rect(x0 +  3, y0 + 20, x0 +  9, y0 + 24);
            f1    = in_rect(x0 +  8, y0 +  6, x0 + 11, y0 + 19);
            f2    = in_rect(x0 + 12, y0 +  3, x0 + 15, y0 + 19);
            f3    = in_rect(x0 + 16, y0 +  5, x0 + 19, y0 + 19);
            f4    = in_rect(x0 + 20, y0 +  9, x0 + 23, y0 + 20);
            return palm || thumb || f1 || f2 || f3 || f4;
        end
    endfunction

    // Outer pedestrian-signal housing.
    // This creates the yellow casing around the pedestrian signal block.
    function automatic logic ped_box(input int x0, input int y0);
        return in_rect(x0, y0, x0 + 33, y0 + 61);
    endfunction

    // Inner pedestrian-signal face.
    // This draws the dark display area inside the yellow casing.
    function automatic logic ped_inner(input int x0, input int y0);
        return in_rect(x0 + 2, y0 + 2, x0 + 31, y0 + 59);
    endfunction

    // Outer vertical traffic-light housing.
    // This creates the yellow traffic-light casing.
    function automatic logic signal_body_v(input int x0, input int y0);
        return in_rect(x0, y0, x0 + 25, y0 + 65);
    endfunction

    // Inner vertical traffic-light face.
    // This draws the dark area where the red/yellow/green lamps appear.
    function automatic logic signal_inner_v(input int x0, input int y0);
        return in_rect(x0 + 2, y0 + 2, x0 + 23, y0 + 63);
    endfunction

    // Internal visibility controls for the orange DON'T WALK hand.
    // In steady mode the hand is always visible; in blink mode it follows blink_on.
    logic main_hand_visible;
    logic cross_hand_visible;

    // Main combinational renderer.
    // For each pixel, start with the grass background and then layer the scene
    // objects in priority order. Later assignments overwrite earlier colors.
    always_comb begin
        main_hand_visible  = (main_ped == PED_DONT_STEADY) || ((main_ped == PED_DONT_BLINK) && blink_on);
        cross_hand_visible = (cross_ped == PED_DONT_STEADY) || ((cross_ped == PED_DONT_BLINK) && blink_on);

        rgb = C_GRASS;

        // Revised display layout, rev5:
        // - Scale is pulled back from rev4 so sidewalks do NOT run across the lanes.
        // - Roads are still wider than the early version, but not oversized.
        // - No lane arrows.
        // - No yellow lines around dashed white lane dividers.
        // - No extra inner white crosswalk guide lines.
        // - Crosswalk stripes line up with sidewalks and span completely across the lane width.
        //
        // Coordinate plan, 640x480:
        //   N/S road: x = 210..429
        //   E/W road: y = 130..349
        //   N/S lane divider: x = 319, stopped before crosswalks/intersection
        //   E/W lane divider: y = 239, stopped before crosswalks/intersection
        //   Sidewalks sit only in the four corner areas; they do not cross the roads.

        // Main roads.
        if (in_rect(210, 0, 429, 479) || in_rect(0, 130, 639, 349)) rgb = C_ROAD;
        if (in_rect(210, 130, 429, 349)) rgb = C_ROAD_DARK;

        // Sidewalks in corner regions only.  They are widened enough for the pedestrian signs,
        // but still stop at the road edges; sidewalks do NOT run across the streets.
        // Top-left corner sidewalks.
        if (in_rect(150,   0, 209, 129) || in_rect(  0,  70, 209, 129) ||
            // Top-right corner sidewalks.
            in_rect(430,   0, 489, 129) || in_rect(430,  70, 639, 129) ||
            // Bottom-left corner sidewalks.
            in_rect(150, 350, 209, 479) || in_rect(  0, 350, 209, 409) ||
            // Bottom-right corner sidewalks.
            in_rect(430, 350, 489, 479) || in_rect(430, 350, 639, 409))
            rgb = C_SIDEWALK;

        // Stop-line/curb marker lines removed for this revision.
        // A future version can add true white vehicle stop bars behind each crosswalk.

        // Crosswalks spanning all the way across each road.
        // Top/bottom crosswalks cross the full N/S road width.
        // Left/right crosswalks cross the full E/W road height.
        if (crosswalk_top_bottom(210, 100) || crosswalk_top_bottom(210, 350) ||
            crosswalk_left_right(180, 130) || crosswalk_left_right(430, 130))
            rgb = C_WHITE;

        // Vehicle stop bars: thin white lines placed before each crosswalk,
        // only across the approach lane where cars stop.
        // Southbound approach from top: left half of N/S road, just above top crosswalk.
        if (in_rect(214, 94, 314, 97)) rgb = C_WHITE;
        // Northbound approach from bottom: right half of N/S road, just below bottom crosswalk.
        if (in_rect(324, 382, 424, 385)) rgb = C_WHITE;
        // Eastbound approach from left: lower half of E/W road, just left of left crosswalk.
        if (in_rect(174, 244, 177, 344)) rgb = C_WHITE;
        // Westbound approach from right: upper half of E/W road, just right of right crosswalk.
        if (in_rect(462, 134, 465, 234)) rgb = C_WHITE;

        // Dashed white lane dividers only, stopped before crosswalks/intersection.
        if (dash_v(318,   0,  92) || dash_v(318, 388, 479) ||
            dash_h(  0, 172, 238) || dash_h(468, 639, 238))
            rgb = C_WHITE;

        // Traffic signal support poles removed for a cleaner VGA display.

        // Yellow traffic signal housings.
        // Northbound approach: bottom road, right-hand lane, signal ahead of the lane, above top crosswalk.
        if (signal_body_v(360, 30) ||
            // Southbound approach: top road, left-hand lane, signal ahead of the lane, below bottom crosswalk.
            signal_body_v(252, 388) ||
            // Westbound approach: right-to-left lane, moved left of the left crosswalk.
            signal_body_v(118, 168) ||
            // Eastbound approach: left-to-right lane, moved right of the right crosswalk.
            signal_body_v(500, 268))
            rgb = C_SIGNAL;

        // Black inner face of the signal housings.
        if (signal_inner_v(360, 30) || signal_inner_v(252, 388) ||
            signal_inner_v(118, 168) || signal_inner_v(500, 268))
            rgb = C_BLACK;

        // Northbound main signal, facing cars moving up: R/Y/G from top to bottom.
        if (in_rect(368,  38, 377,  49)) rgb = (main_light == LIGHT_RED)    ? C_RED    : C_DIM_R;
        if (in_rect(368,  57, 377,  68)) rgb = (main_light == LIGHT_YELLOW) ? C_YELLOW : C_DIM_Y;
        if (in_rect(368,  76, 377,  87)) rgb = (main_light == LIGHT_GREEN)  ? C_GREEN  : C_DIM_G;

        // Southbound main signal, drawn normal now: R/Y/G from top to bottom.
        if (in_rect(260, 396, 269, 407)) rgb = (main_light == LIGHT_RED)    ? C_RED    : C_DIM_R;
        if (in_rect(260, 415, 269, 426)) rgb = (main_light == LIGHT_YELLOW) ? C_YELLOW : C_DIM_Y;
        if (in_rect(260, 434, 269, 445)) rgb = (main_light == LIGHT_GREEN)  ? C_GREEN  : C_DIM_G;

        // Westbound cross-street signal, centered in the westbound lane and clear of crosswalk.
        if (in_rect(126, 176, 135, 187)) rgb = (cross_light == LIGHT_RED)    ? C_RED    : C_DIM_R;
        if (in_rect(126, 195, 135, 206)) rgb = (cross_light == LIGHT_YELLOW) ? C_YELLOW : C_DIM_Y;
        if (in_rect(126, 214, 135, 225)) rgb = (cross_light == LIGHT_GREEN)  ? C_GREEN  : C_DIM_G;

        // Eastbound cross-street signal, centered in the eastbound lane and clear of crosswalk.
        if (in_rect(508, 276, 517, 287)) rgb = (cross_light == LIGHT_RED)    ? C_RED    : C_DIM_R;
        if (in_rect(508, 295, 517, 306)) rgb = (cross_light == LIGHT_YELLOW) ? C_YELLOW : C_DIM_Y;
        if (in_rect(508, 314, 517, 325)) rgb = (cross_light == LIGHT_GREEN)  ? C_GREEN  : C_DIM_G;

        // Pedestrian signal housings with yellow traffic-signal-style casing.
        // Each corner has two pedestrian signs placed diagonally from one another, not side-by-side:
        //   cross_ped signs belong to top/bottom crosswalks across the N/S road.
        //   main_ped signs belong to left/right crosswalks across the E/W road.
        if (ped_box(176,  52) || ped_box(432,  52) ||     // top N/S-road crosswalk pair
            ped_box(176, 366) || ped_box(432, 366) ||     // bottom N/S-road crosswalk pair
            ped_box(118,  66) || ped_box(118, 350) ||     // left E/W-road crosswalk pair
            ped_box(488,  66) || ped_box(488, 350))       // right E/W-road crosswalk pair
            rgb = C_SIGNAL;

        if (ped_inner(176,  52) || ped_inner(432,  52) ||
            ped_inner(176, 366) || ped_inner(432, 366) ||
            ped_inner(118,  66) || ped_inner(118, 350) ||
            ped_inner(488,  66) || ped_inner(488, 350))
            rgb = C_DGRAY;

        // Main pedestrian signs: crossing the E/W road at the left and right crosswalks.
        if (main_ped == PED_WALK) begin
            if (walk_icon_small(120,  72) || walk_icon_small(120, 356) ||
                walk_icon_small(490,  72) || walk_icon_small(490, 356)) rgb = C_WHITE;
        end
        if (main_hand_visible) begin
            if (hand_icon_small(120,  72) || hand_icon_small(120, 356) ||
                hand_icon_small(490,  72) || hand_icon_small(490, 356)) rgb = C_ORANGE;
        end

        // Cross pedestrian signs: crossing the N/S road at the top and bottom crosswalks.
        if (cross_ped == PED_WALK) begin
            if (walk_icon_small(178,  58) || walk_icon_small(434,  58) ||
                walk_icon_small(178, 372) || walk_icon_small(434, 372)) rgb = C_WHITE;
        end
        if (cross_hand_visible) begin
            if (hand_icon_small(178,  58) || hand_icon_small(434,  58) ||
                hand_icon_small(178, 372) || hand_icon_small(434, 372)) rgb = C_ORANGE;
        end    end

endmodule

