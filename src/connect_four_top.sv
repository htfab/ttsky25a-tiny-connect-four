module connect_four_top (
    input wire clk_50MHz,      // TODO: Change to 25MHz
    input wire rst_n,
    input wire move_right,
    input wire move_left,
    input wire drop_piece,
    output logic vga_hsync,    // Horizontal sync
    output logic vga_vsync,    // Vertical sync
    output logic [3:0] vga_r,  // 4-bit Red channel
    output logic [3:0] vga_g,  // 4-bit Green channel
    output logic [3:0] vga_b   // 4-bit Blue channel
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

    // Game state
    // 0: empty, 1: player 1, 2: player 2
    logic [1:0] board [ROWS-1:0][COLS-1:0];
    logic [2:0] current_col;
    // 01: player 1, 10: player 2
    logic [1:0] current_player;
    // 0: game not over, 1: game over
    logic game_over;
    // 0: no winner, 1: player 1, 2: player 2
    logic [1:0] winner;

    // VGA signals
    logic pixel_clk;
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

    // Generate 25MHz pixel clock
    // TODO: Remove this when using 25MHz clock
    pll pll_inst (
        .inclk0(clk_50MHz),
        .c0(pixel_clk)
    );

    // VGA controller instance
    vga_controller vga_ctrl (
        .pixel_clk(pixel_clk),
        .rst_n(rst_n),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .x_count(h_count),
        .y_count(v_count)
    );


    // Game Instance
    connect_four game (
        .clk(clk_50MHz),
        .rst_n(rst_n),
        .move_right(move_right),
        .move_left(move_left),
        .drop_piece(drop_piece),
        .board_out(board),
        .current_col(current_col),
        .current_player(current_player),
        .game_over(game_over),
        .winner(winner)
    );


    // VGA output
    always_comb begin
        vga_r = 4'h0;
        vga_g = 4'h0;
        vga_b = 4'h0;
        if (vga_active)
        begin
            // Draw the board
            if (draw_board)
            begin
                if (piece_color == PLAYER1_COLOR)
                begin
                    vga_r = 4'hf;
                    vga_g = 4'hf;
                    vga_b = 4'h0;
                end
                else if (piece_color == PLAYER2_COLOR)
                begin
                    vga_r = 4'hf;
                    vga_g = 4'h0;
                    vga_b = 4'h0;
                end
                else
                begin
                    vga_r = 4'h0;
                    vga_g = 4'h0;
                    vga_b = 4'hf;
                end
            end
            else
            if (draw_cursor)
            begin
                if (player_1_turn)
                begin
                    vga_r = 4'hf;
                    vga_g = 4'hf;
                    vga_b = 4'h0;
                end
                else
                begin
                    vga_r = 4'hf;
                    vga_g = 4'h0;
                    vga_b = 4'h0;
                end
            end
            else
            begin
                vga_r = 4'h8;
                vga_g = 4'hf;
                vga_b = 4'h8;
            end
        end
    end

endmodule