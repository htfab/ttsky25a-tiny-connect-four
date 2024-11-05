module connect_four
#(
    parameter ROWS = 8,
    parameter COLS = 8,
    parameter COL_BITS = 3,
    parameter ROW_BITS = 3,
    parameter LAST_COL = 3'd7,
    parameter LAST_ROW = 3'd7
)
(
    input wire clk,
    input wire rst_n,
    input wire move_right,
    input wire move_left,
    input wire drop_piece,
    output reg [1:0] board_out [ROWS-1:0][COLS-1:0],
    output reg [2:0] current_col,
    output reg [1:0] current_player,
    output reg game_over,
    output reg [1:0] winner
);

    localparam EMPTY = 2'b00;
    localparam PLAYER1 = 2'b01;
    localparam PLAYER2 = 2'b10;

    localparam ST_IDLE = 2'b00;
    localparam ST_ADDING_PIECE = 2'b01;
    localparam ST_CHECKING_VICTORY = 2'b10;
    localparam ST_WIN = 2'b11;

    localparam ST_NOT_CHECKING = 4'b0000;
    localparam ST_CHECKING_DOWN = 4'b0001;
    localparam ST_CHECKING_ROW_1 = 4'b0010;
    localparam ST_CHECKING_ROW_2 = 4'b0011;
    localparam ST_CHECKING_ROW_3 = 4'b0100;
    localparam ST_CHECKING_ROW_4 = 4'b0101;
    localparam ST_CHECKING_DIAG_RIGHT_UP_1 = 4'b0110;
    localparam ST_CHECKING_DIAG_RIGHT_UP_2 = 4'b0111;
    localparam ST_CHECKING_DIAG_RIGHT_UP_3 = 4'b1000;
    localparam ST_CHECKING_DIAG_RIGHT_UP_4 = 4'b1001;
    localparam ST_CHECKING_DIAG_LEFT_DOWN_1 = 4'b1010;
    localparam ST_CHECKING_DIAG_LEFT_DOWN_2 = 4'b1011;
    localparam ST_CHECKING_DIAG_LEFT_DOWN_3 = 4'b1100;
    localparam ST_CHECKING_DIAG_LEFT_DOWN_4 = 4'b1101;
    localparam ST_CHECKING_DONE = 4'b1110;
    localparam ST_VICTORY = 4'b1111;

    reg [1:0] board [ROWS-1:0][COLS-1:0];

    logic [2:0] drop_piece_sync;
    logic rising_drop_piece;
    logic [2:0] move_right_sync;
    logic rising_move_right;
    logic [2:0] move_left_sync;
    logic rising_move_left;

    logic move_to_right;
    logic move_to_left;
    logic [2:0] next_col_right;
    logic [2:0] next_col_left;

    logic [1:0] next_player;
    logic [ROW_BITS:0] column_counters [COLS-1:0];
    logic [ROW_BITS:0] row_to_drop;
    logic [ROW_BITS-1:0] current_row;
    logic attempted_drop;
    logic drop_allowed;
    logic [1:0] current_state;

    logic check_down;
    logic check_row_1;
    logic check_row_2;
    logic check_row_3;
    logic check_row_4;
    logic check_diag_right_up_1;
    logic check_diag_right_up_2;
    logic check_diag_right_up_3;
    logic check_diag_right_up_4;
    logic check_diag_left_down_1;
    logic check_diag_left_down_2;
    logic check_diag_left_down_3;
    logic check_diag_left_down_4;

    logic result_down;
    logic result_row_1;
    logic result_row_2;
    logic result_row_3;
    logic result_row_4;
    logic result_diag_right_up_1;
    logic result_diag_right_up_2;
    logic result_diag_right_up_3;
    logic result_diag_right_up_4;
    logic result_diag_left_down_1;
    logic result_diag_left_down_2;
    logic result_diag_left_down_3;
    logic result_diag_left_down_4;

    logic [3:0] check_state;

    logic [3:0] next_down;
    logic [3:0] next_row_1;
    logic [3:0] next_row_2;
    logic [3:0] next_row_3;
    logic [3:0] next_row_4;
    logic [3:0] next_diag_right_up_1;
    logic [3:0] next_diag_right_up_2;
    logic [3:0] next_diag_right_up_3;
    logic [3:0] next_diag_right_up_4;
    logic [3:0] next_diag_left_down_1;
    logic [3:0] next_diag_left_down_2;
    logic [3:0] next_diag_left_down_3;
    logic [3:0] next_diag_left_down_4;


    assign rising_drop_piece = drop_piece_sync[2] & ~drop_piece_sync[1]; // Active low
    assign rising_move_right = move_right_sync[2] & ~move_right_sync[1];
    assign rising_move_left  = move_left_sync[2]  & ~move_left_sync[1] ;

    assign move_to_right = rising_move_right & ~rising_move_left;
    assign move_to_left = rising_move_left & ~rising_move_right;
    assign next_col_right = (current_col == LAST_COL) ? 3'b000 : current_col + 3'b001;
    assign next_col_left = (current_col == 0) ? LAST_COL : current_col - 3'b001;

    assign next_player = (current_player == PLAYER1) ? PLAYER2 : PLAYER1;
    assign row_to_drop = column_counters[current_col];
    assign current_row = row_to_drop[ROW_BITS-1:0];
    assign attempted_drop = (current_state == ST_ADDING_PIECE);
    assign drop_allowed = (row_to_drop < ROWS);

    assign check_down = (current_row >= 3);
    assign check_row_1 = (current_col >= 3);
    assign check_row_2 = (current_col >= 2) & (current_col <= 6);
    assign check_row_3 = (current_col >= 1) & (current_col <= 5);
    assign check_row_4 = (current_col <= 4);
    assign check_diag_right_up_1 = (current_col >= 3) & (current_row >= 3);
    assign check_diag_right_up_2 = (current_col >= 2) & (current_col <= 6) & (current_row >= 2) & (current_row <= 6);
    assign check_diag_right_up_3 = (current_col >= 1) & (current_col <= 5) & (current_row >= 1) & (current_row <= 5);
    assign check_diag_right_up_4 = (current_col <= 4) & (current_row <= 4);
    assign check_diag_left_down_1 = (current_col >= 3) & (current_row <= 4);
    assign check_diag_left_down_2 = (current_col >= 2) & (current_col <= 6) & (current_row >= 1) & (current_row <= 5);
    assign check_diag_left_down_3 = (current_col >= 1) & (current_col <= 5) & (current_row >= 2) & (current_row <= 6);
    assign check_diag_left_down_4 = (current_col <= 4) & (current_row >= 3);

    assign result_down = (board[current_row][current_col]   == current_player) &
                         (board[current_row-1][current_col] == current_player) &
                         (board[current_row-2][current_col] == current_player) &
                         (board[current_row-3][current_col] == current_player) &
                         check_down;

    assign result_row_1 = (board[current_row][current_col]   == current_player) &
                          (board[current_row][current_col-1] == current_player) &
                          (board[current_row][current_col-2] == current_player) &
                          (board[current_row][current_col-3] == current_player) &
                          check_row_1;

    assign result_row_2 = (board[current_row][current_col+1] == current_player) &
                          (board[current_row][current_col]   == current_player) &
                          (board[current_row][current_col-1] == current_player) &
                          (board[current_row][current_col-2] == current_player) &
                          check_row_2;

    assign result_row_3 = (board[current_row][current_col+2] == current_player) &
                          (board[current_row][current_col+1] == current_player) &
                          (board[current_row][current_col]   == current_player) &
                          (board[current_row][current_col-1] == current_player) &
                          check_row_3;

    assign result_row_4 = (board[current_row][current_col+3] == current_player) &
                          (board[current_row][current_col+2] == current_player) &
                          (board[current_row][current_col+1] == current_player) &
                          (board[current_row][current_col]   == current_player) &
                          check_row_4;

    assign result_diag_right_up_1 = (board[current_row][current_col]     == current_player) &
                                    (board[current_row-1][current_col-1] == current_player) &
                                    (board[current_row-2][current_col-2] == current_player) &
                                    (board[current_row-3][current_col-3] == current_player) &
                                    check_diag_right_up_1;

    assign result_diag_right_up_2 = (board[current_row+1][current_col+1] == current_player) &
                                    (board[current_row][current_col]     == current_player) &
                                    (board[current_row-1][current_col-1] == current_player) &
                                    (board[current_row-2][current_col-2] == current_player) &
                                    check_diag_right_up_2;

    assign result_diag_right_up_3 = (board[current_row+2][current_col+2] == current_player) &
                                    (board[current_row+1][current_col+1] == current_player) &
                                    (board[current_row][current_col]     == current_player) &
                                    (board[current_row-1][current_col-1] == current_player) &
                                    check_diag_right_up_3;

    assign result_diag_right_up_4 = (board[current_row+3][current_col+3] == current_player) &
                                    (board[current_row+2][current_col+2] == current_player) &
                                    (board[current_row+1][current_col+1] == current_player) &
                                    (board[current_row][current_col]     == current_player) &
                                    check_diag_right_up_4;

    assign result_diag_left_down_1 = (board[current_row][current_col]     == current_player) &
                                     (board[current_row+1][current_col-1] == current_player) &
                                     (board[current_row+2][current_col-2] == current_player) &
                                     (board[current_row+3][current_col-3] == current_player) &
                                     check_diag_left_down_1;

    assign result_diag_left_down_2 = (board[current_row-1][current_col+1] == current_player) &
                                     (board[current_row][current_col]     == current_player) &
                                     (board[current_row+1][current_col-1] == current_player) &
                                     (board[current_row+2][current_col-2] == current_player) &
                                     check_diag_left_down_2;

    assign result_diag_left_down_3 = (board[current_row-2][current_col+2] == current_player) &
                                     (board[current_row-1][current_col+1] == current_player) &
                                     (board[current_row][current_col]     == current_player) &
                                     (board[current_row+1][current_col-1] == current_player) &
                                     check_diag_left_down_3;

    assign result_diag_left_down_4 = (board[current_row-3][current_col+3] == current_player) &
                                     (board[current_row-2][current_col+2] == current_player) &
                                     (board[current_row-1][current_col+1] == current_player) &
                                     (board[current_row][current_col]     == current_player) &
                                     check_diag_left_down_4;


    assign next_down = result_down? ST_VICTORY : ST_CHECKING_ROW_1;
    assign next_row_1 = result_row_1? ST_VICTORY : ST_CHECKING_ROW_2;
    assign next_row_2 = result_row_2? ST_VICTORY : ST_CHECKING_ROW_3;
    assign next_row_3 = result_row_3? ST_VICTORY : ST_CHECKING_ROW_4;
    assign next_row_4 = result_row_4? ST_VICTORY : ST_CHECKING_DIAG_RIGHT_UP_1;
    assign next_diag_right_up_1 = result_diag_right_up_1? ST_VICTORY : ST_CHECKING_DIAG_RIGHT_UP_2;
    assign next_diag_right_up_2 = result_diag_right_up_2? ST_VICTORY : ST_CHECKING_DIAG_RIGHT_UP_3;
    assign next_diag_right_up_3 = result_diag_right_up_3? ST_VICTORY : ST_CHECKING_DIAG_RIGHT_UP_4;
    assign next_diag_right_up_4 = result_diag_right_up_4? ST_VICTORY : ST_CHECKING_DIAG_LEFT_DOWN_1;
    assign next_diag_left_down_1 = result_diag_left_down_1? ST_VICTORY : ST_CHECKING_DIAG_LEFT_DOWN_2;
    assign next_diag_left_down_2 = result_diag_left_down_2? ST_VICTORY : ST_CHECKING_DIAG_LEFT_DOWN_3;
    assign next_diag_left_down_3 = result_diag_left_down_3? ST_VICTORY : ST_CHECKING_DIAG_LEFT_DOWN_4;
    assign next_diag_left_down_4 = result_diag_left_down_4? ST_VICTORY : ST_CHECKING_DONE;


    // Synchronizers to detect rising edge of input from user
    always_ff @(posedge clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
        drop_piece_sync <= 3'b111;
        move_right_sync <= 3'b111;
        move_left_sync  <= 3'b111;
      end
      else
      begin
        drop_piece_sync[2:0] <= {drop_piece_sync[1:0], drop_piece};
        move_right_sync[2:0] <= {move_right_sync[1:0], move_right};
        move_left_sync[2:0]  <= {move_left_sync[1:0] , move_left };
      end
    end

    // State Machine to control the game
    always_ff @(posedge clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
        current_state <= ST_IDLE;
      end
      else
      begin
        case (current_state)
          ST_IDLE:
          begin
            if (rising_drop_piece)
            begin
              current_state <= ST_ADDING_PIECE;
            end
          end
          ST_ADDING_PIECE:
          begin
            if (drop_allowed)
            begin
              current_state <= ST_CHECKING_VICTORY;
            end
            else
            begin
              current_state <= ST_IDLE;
            end
          end
          ST_CHECKING_VICTORY:
          begin
            if (check_state == ST_VICTORY)
            begin
              current_state <= ST_WIN;
            end
            else if (check_state == ST_CHECKING_DONE)
            begin
              current_state <= ST_IDLE;
            end
            else
            begin
              current_state <= ST_CHECKING_VICTORY;
            end
          end
          ST_WIN:
          begin
            current_state <= ST_WIN;
          end
        endcase
      end
    end

    // Column to drop the piece
    always_ff @(posedge clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
        current_col <= 3'b000;
      end
      else
      if (current_state == ST_IDLE)
      begin
          if (move_to_right)
          begin
            current_col <= next_col_right;
          end
          else if (move_to_left)
          begin
            current_col <= next_col_left;
          end
      end
    end

    // Drop the piece
    always_ff @(posedge clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
        // Initialize the board (TODO: Make this more efficient)
        for (int i = 0; i < ROWS; i++)
        begin
          for (int j = 0; j < COLS; j++)
          begin
              board[i][j] <= 2'b00;
          end
        end
      end
      else
      begin
        if (attempted_drop)
        begin
          if (drop_allowed)
          begin
            board[current_row][current_col] <= current_player;
          end
        end
      end
    end

    // Output the board state
    always_comb
	  begin
        for (int row = 0; row < ROWS; row++)
		    begin
            for (int col = 0; col < COLS; col++)
            begin
                board_out[row][col] = board[row][col];
            end
        end
    end

    // Check for victory
    // Based on the drop location, check for a win in the relevant directions
    // Every clock take 4 squares and check if they are the same player
    // Don't perform the check in a direction if it's not possible to win in that direction
    // For example: If the piece is in the first row, don't check up
    // If the piece is in the last column, don't check right
    always_ff @(posedge clk or negedge rst_n)
    begin
      if (!rst_n)
      begin
        game_over <= 1'b0;
        winner <= 2'b00;
        check_state <= ST_NOT_CHECKING;
        current_player <= 2'b01;
        for (int i = 0; i < ROWS; i++)
        begin
          column_counters[i] <= 4'b0000;
        end
      end
      else
      if (current_state == ST_CHECKING_VICTORY)
      begin
        case (check_state)
          ST_NOT_CHECKING:
          begin
            check_state <= ST_CHECKING_DOWN;
          end
          ST_CHECKING_DOWN:
          begin
            if (check_down)
              check_state <= next_down;
            else
              check_state <= ST_CHECKING_ROW_1;
          end
          ST_CHECKING_ROW_1:
          begin
            if (check_row_1)
              check_state <= next_row_1;
            else
              check_state <= ST_CHECKING_ROW_2;
          end
          ST_CHECKING_ROW_2:
          begin
            if (check_row_2)
              check_state <= next_row_2;
            else
              check_state <= ST_CHECKING_ROW_3;
          end
          ST_CHECKING_ROW_3:
          begin
            if (check_row_3)
              check_state <= next_row_3;
            else
              check_state <= ST_CHECKING_ROW_4;
          end
          ST_CHECKING_ROW_4:
          begin
            if (check_row_4)
              check_state <= next_row_4;
            else
              check_state <= ST_CHECKING_DIAG_RIGHT_UP_1;
          end
          ST_CHECKING_DIAG_RIGHT_UP_1:
          begin
            if (check_diag_right_up_1)
              check_state <= next_diag_right_up_1;
            else
              check_state <= ST_CHECKING_DIAG_RIGHT_UP_2;
          end
          ST_CHECKING_DIAG_RIGHT_UP_2:
          begin
            if (check_diag_right_up_2)
              check_state <= next_diag_right_up_2;
            else
              check_state <= ST_CHECKING_DIAG_RIGHT_UP_3;
          end
          ST_CHECKING_DIAG_RIGHT_UP_3:
          begin
            if (check_diag_right_up_3)
              check_state <= next_diag_right_up_3;
            else
              check_state <= ST_CHECKING_DIAG_RIGHT_UP_4;
          end
          ST_CHECKING_DIAG_RIGHT_UP_4:
          begin
            if (check_diag_right_up_4)
              check_state <= next_diag_right_up_4;
            else
              check_state <= ST_CHECKING_DIAG_LEFT_DOWN_1;
          end
          ST_CHECKING_DIAG_LEFT_DOWN_1:
          begin
            if (check_diag_left_down_1)
              check_state <= next_diag_left_down_1;
            else
              check_state <= ST_CHECKING_DIAG_LEFT_DOWN_2;
          end
          ST_CHECKING_DIAG_LEFT_DOWN_2:
          begin
            if (check_diag_left_down_2)
              check_state <= next_diag_left_down_2;
            else
              check_state <= ST_CHECKING_DIAG_LEFT_DOWN_3;
          end
          ST_CHECKING_DIAG_LEFT_DOWN_3:
          begin
            if (check_diag_left_down_3)
              check_state <= next_diag_left_down_3;
            else
              check_state <= ST_CHECKING_DIAG_LEFT_DOWN_4;
          end
          ST_CHECKING_DIAG_LEFT_DOWN_4:
          begin
            if (check_diag_left_down_4)
              check_state <= next_diag_left_down_4;
            else
              check_state <= ST_CHECKING_DONE;
          end
          ST_VICTORY:
          begin
            game_over <= 1'b1;
            winner <= current_player;
            check_state <= ST_CHECKING_DONE;
          end
          ST_CHECKING_DONE:
          begin
            check_state <= ST_NOT_CHECKING;
            column_counters[current_col] <= column_counters[current_col] + 3'b001;
            current_player <= next_player;
          end
          default:
          begin
            check_state <= ST_NOT_CHECKING;
          end
        endcase
      end
    end


endmodule