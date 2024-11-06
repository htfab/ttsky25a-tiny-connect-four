module connect_four_top (
    input wire clk_25MHz,
    input wire rst_n,
    input wire move_right,
    input wire move_left,
    input wire drop_piece,
    output logic vga_hsync,    // Horizontal sync
    output logic vga_vsync,    // Vertical sync
    output logic [1:0] vga_r,  // 2-bit Red channel
    output logic [1:0] vga_g,  // 2-bit Green channel
    output logic [1:0] vga_b   // 2-bit Blue channel
);

    // VGA timing parameters (same as in top module)
	localparam H_ACTIVE = 640;
    localparam H_FRONT_PORCH = 16;
    localparam H_SYNC = 96;
    localparam H_BACK_PORCH = 48;
    localparam H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH;

    localparam V_ACTIVE = 480;
    localparam V_FRONT_PORCH = 10;
    localparam V_SYNC = 2;
    localparam V_BACK_PORCH = 33;
    localparam V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH;

    // Parameters for the game
    localparam ROWS = 8;
    localparam COLS = 8;
    localparam CELL_SIZE = 10'd32; // Each cell is 50x50 pixels
    localparam BOARD_TOP_LEFT_X = 10'd192;
    localparam BOARD_TOP_LEFT_Y = 10'd112;
    localparam CURSOR_OFFSET = 10'd16;
    localparam EMPTY = 2'b00;
    localparam PLAYER1_COLOR = 2'b01;
    localparam PLAYER2_COLOR = 2'b10;

    // New parameters for circle drawing
    localparam CIRCLE_RADIUS = 10'd14; // Radius of the circle pieces
    localparam CIRCLE_RADIUS_SQUARED = CIRCLE_RADIUS * CIRCLE_RADIUS;

    // VGA Colors
    // Background color - Green
    localparam EMPTY_COLOR_R = 2'b01;
    localparam EMPTY_COLOR_G = 2'b11;
    localparam EMPTY_COLOR_B = 2'b01;
    // Board color - Blue
    localparam BOARD_COLOR_R = 2'b00;
    localparam BOARD_COLOR_G = 2'b00;
    localparam BOARD_COLOR_B = 2'b11;
    // Player 1 color - Yellow
    localparam PLAYER1_COLOR_R = 2'b11;
    localparam PLAYER1_COLOR_G = 2'b11;
    localparam PLAYER1_COLOR_B = 2'b00;
    // Player 2 color - Red
    localparam PLAYER2_COLOR_R = 2'b11;
    localparam PLAYER2_COLOR_G = 2'b00;
    localparam PLAYER2_COLOR_B = 2'b00;

    // Game state
    // 0: empty, 1: player 1, 2: player 2
    logic [1:0] board [0:ROWS-1][0:COLS-1];
    logic [2:0] current_col;
    // 01: player 1, 10: player 2
    logic [1:0] current_player;
    // 0: game not over, 1: game over
    logic game_over;
    // 0: no winner, 1: player 1, 2: player 2
    logic [1:0] winner;

    // VGA signals
    logic [9:0] h_count;
    logic [9:0] v_count;

    logic draw_board;
    logic draw_cursor;
    logic vga_active;
    logic [9:0] col_idx_n;
    logic [9:0] row_idx_n;
    logic [2:0] col_idx;
    logic [2:0] row_idx;
    logic [1:0] piece_color;
    logic player_1_turn;

    assign draw_board = (h_count >= BOARD_TOP_LEFT_X & h_count < BOARD_TOP_LEFT_X + COLS * CELL_SIZE & v_count >= BOARD_TOP_LEFT_Y & v_count < BOARD_TOP_LEFT_Y + ROWS * CELL_SIZE);

    assign draw_cursor = (h_count >= BOARD_TOP_LEFT_X &
                          h_count < BOARD_TOP_LEFT_X + COLS * CELL_SIZE &
                          v_count >= BOARD_TOP_LEFT_Y - CURSOR_OFFSET - CELL_SIZE &
                          v_count < BOARD_TOP_LEFT_Y - CURSOR_OFFSET &
                          current_col == col_idx);

    assign vga_active = (h_count < H_ACTIVE & v_count < V_ACTIVE);
    assign col_idx_n = ((h_count - BOARD_TOP_LEFT_X) >> 10'd5);
    assign row_idx_n = ((v_count - BOARD_TOP_LEFT_Y) >> 10'd5);
    assign col_idx = col_idx_n[2:0];
    assign row_idx = 3'h7 - row_idx_n[2:0];
    assign piece_color = board[row_idx][col_idx];
    assign player_1_turn = (current_player == PLAYER1_COLOR);


    // VGA controller instance
    vga_controller vga_ctrl (
        .pixel_clk(clk_25MHz),
        .rst_n(rst_n),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .x_count(h_count),
        .y_count(v_count)
    );


    // Game Instance
    connect_four game (
        .clk(clk_25MHz),
        .rst_n(rst_n),
        .move_right(move_right),
        .move_left(move_left),
        .drop_piece(drop_piece),
        .boardout(board),
        .current_col(current_col),
        .current_player(current_player),
        .game_over(game_over),
        .winner(winner)
    );


    // Declare wires for calculated values
    wire [9:0] cell_center_x, cell_center_y, cursor_center_x, cursor_center_y;
    wire [19:0] dx_cell, dy_cell, distance_squared_cell;
    wire [19:0] dx_cursor, dy_cursor, distance_squared_cursor;
    wire cell_in_circle, cursor_in_circle, draw_circle_cursor;

    // Calculate center positions
    assign cell_center_x = BOARD_TOP_LEFT_X + col_idx * CELL_SIZE + CELL_SIZE/2;
    assign cell_center_y = BOARD_TOP_LEFT_Y + row_idx_n * CELL_SIZE + CELL_SIZE/2;
    assign cursor_center_x = BOARD_TOP_LEFT_X + current_col * CELL_SIZE + CELL_SIZE/2;
    assign cursor_center_y = BOARD_TOP_LEFT_Y - CURSOR_OFFSET - CELL_SIZE/2;

    // Calculate distances and check if inside circle
    assign dx_cell = h_count - cell_center_x;
    assign dy_cell = v_count - cell_center_y;
    assign distance_squared_cell = dx_cell * dx_cell + dy_cell * dy_cell;
    assign cell_in_circle = (distance_squared_cell <= CIRCLE_RADIUS_SQUARED);

    assign dx_cursor = h_count - cursor_center_x;
    assign dy_cursor = v_count - cursor_center_y;
    assign distance_squared_cursor = dx_cursor * dx_cursor + dy_cursor * dy_cursor;
    assign cursor_in_circle = (distance_squared_cursor <= CIRCLE_RADIUS_SQUARED);
    assign draw_circle_cursor = (draw_cursor & cursor_in_circle & ~game_over);

    // VGA output
    always_comb
    begin
        // No color when not active
        vga_r = 2'b00;
        vga_g = 2'b00;
        vga_b = 2'b00;

        if (vga_active) begin
            vga_r = EMPTY_COLOR_R;
            vga_g = EMPTY_COLOR_G;
            vga_b = EMPTY_COLOR_B;

            if (draw_board)
            begin
                if (cell_in_circle)
                begin
                    if (piece_color == PLAYER1_COLOR)
                    begin
                        vga_r = PLAYER1_COLOR_R;
                        vga_g = PLAYER1_COLOR_G;
                        vga_b = PLAYER1_COLOR_B;
                    end
                    else if (piece_color == PLAYER2_COLOR)
                    begin
                        vga_r = PLAYER2_COLOR_R;
                        vga_g = PLAYER2_COLOR_G;
                        vga_b = PLAYER2_COLOR_B;
                    end
                end
                else
                begin
                    // If the current pixel is not inside the circle, it will use the background color
                    vga_r = BOARD_COLOR_R;
                    vga_g = BOARD_COLOR_G;
                    vga_b = BOARD_COLOR_B;
                end
            end
            else if (draw_circle_cursor)
            begin
                if (player_1_turn)
                begin
                    vga_r = PLAYER1_COLOR_R;
                    vga_g = PLAYER1_COLOR_G;
                    vga_b = PLAYER1_COLOR_B;
                end
                else
                begin
                    vga_r = PLAYER2_COLOR_R;
                    vga_g = PLAYER2_COLOR_G;
                    vga_b = PLAYER2_COLOR_B;
                end
            end
            // The else case for the background is not needed as it's set by default
        end
    end

endmodule