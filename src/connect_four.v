module connect_four (
	clk,
	rst_n,
	move_right,
	move_left,
	drop_piece,
	port_board_out,
	port_current_col,
	port_current_player,
	port_game_over,
	port_winner
);
	reg _sv2v_0;
	parameter ROWS = 8;
	parameter COLS = 8;
	parameter COL_BITS = 3;
	parameter ROW_BITS = 3;
	parameter LAST_COL = 3'd7;
	parameter LAST_ROW = 3'd7;
	input clk;
	input rst_n;
	input move_right;
	input move_left;
	input drop_piece;
	output wire [((ROWS * COLS) * 2) - 1:0] port_board_out;
	output wire [2:0] port_current_col;
	output wire [1:0] port_current_player;
	output wire port_game_over;
	output wire [1:0] port_winner;
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
	localparam FLASH_COUNTER_MAX = 26'd50000000;
	reg [((ROWS * COLS) * 2) - 1:0] board_out;
	reg [2:0] current_col;
	reg [1:0] current_player;
	reg game_over;
	reg [1:0] winner;
	reg [1:0] board [0:ROWS - 1][0:COLS - 1];
	reg [2:0] drop_piece_sync;
	wire rising_drop_piece;
	reg [2:0] move_right_sync;
	wire rising_move_right;
	reg [2:0] move_left_sync;
	wire rising_move_left;
	wire move_to_right;
	wire move_to_left;
	wire [2:0] next_col_right;
	wire [2:0] next_col_left;
	wire [1:0] next_player;
	reg [ROW_BITS:0] column_counters [COLS - 1:0];
	wire [ROW_BITS:0] row_to_drop;
	wire [ROW_BITS - 1:0] current_row;
	wire attempted_drop;
	wire drop_allowed;
	reg [1:0] current_state;
	wire check_down;
	wire check_row_1;
	wire check_row_2;
	wire check_row_3;
	wire check_row_4;
	wire check_diag_right_up_1;
	wire check_diag_right_up_2;
	wire check_diag_right_up_3;
	wire check_diag_right_up_4;
	wire check_diag_left_down_1;
	wire check_diag_left_down_2;
	wire check_diag_left_down_3;
	wire check_diag_left_down_4;
	wire result_down;
	wire result_row_1;
	wire result_row_2;
	wire result_row_3;
	wire result_row_4;
	wire result_diag_right_up_1;
	wire result_diag_right_up_2;
	wire result_diag_right_up_3;
	wire result_diag_right_up_4;
	wire result_diag_left_down_1;
	wire result_diag_left_down_2;
	wire result_diag_left_down_3;
	wire result_diag_left_down_4;
	wire piece_can_win;
	wire winning_down;
	wire winning_row_1;
	wire winning_row_2;
	wire winning_row_3;
	wire winning_row_4;
	wire winning_diag_right_up_1;
	wire winning_diag_right_up_2;
	wire winning_diag_right_up_3;
	wire winning_diag_right_up_4;
	wire winning_diag_left_down_1;
	wire winning_diag_left_down_2;
	wire winning_diag_left_down_3;
	wire winning_diag_left_down_4;
	reg [25:0] flash_counter;
	wire toggle_flash;
	reg show_winning_pieces;
	wire hide_winning_pieces;
	wire found_winning_pieces;
	reg winning_pieces [0:ROWS - 1][0:COLS - 1];
	reg [3:0] check_state;
	wire [3:0] check_state_next_final;
	assign port_board_out = board_out;
	assign port_current_col = current_col;
	assign port_current_player = current_player;
	assign port_game_over = game_over;
	assign port_winner = winner;
	assign rising_drop_piece = drop_piece_sync[2] & ~drop_piece_sync[1];
	assign rising_move_right = move_right_sync[2] & ~move_right_sync[1];
	assign rising_move_left = move_left_sync[2] & ~move_left_sync[1];
	assign move_to_right = rising_move_right & ~rising_move_left;
	assign move_to_left = rising_move_left & ~rising_move_right;
	assign next_col_right = (current_col == LAST_COL ? 3'b000 : current_col + 3'b001);
	assign next_col_left = (current_col == 0 ? LAST_COL : current_col - 3'b001);
	assign next_player = (current_player == PLAYER1 ? PLAYER2 : PLAYER1);
	assign row_to_drop = column_counters[current_col];
	assign current_row = row_to_drop[ROW_BITS - 1:0];
	assign attempted_drop = current_state == ST_ADDING_PIECE;
	assign drop_allowed = row_to_drop < ROWS;
	assign check_state_next_final = (game_over ? ST_VICTORY : ST_CHECKING_DONE);
	assign check_down = current_row >= 3;
	assign check_row_1 = current_col >= 3;
	assign check_row_2 = (current_col >= 2) & (current_col <= 6);
	assign check_row_3 = (current_col >= 1) & (current_col <= 5);
	assign check_row_4 = current_col <= 4;
	assign check_diag_right_up_1 = (current_col >= 3) & (current_row >= 3);
	assign check_diag_right_up_2 = (((current_col >= 2) & (current_col <= 6)) & (current_row >= 2)) & (current_row <= 6);
	assign check_diag_right_up_3 = (((current_col >= 1) & (current_col <= 5)) & (current_row >= 1)) & (current_row <= 5);
	assign check_diag_right_up_4 = (current_col <= 4) & (current_row <= 4);
	assign check_diag_left_down_1 = (current_col >= 3) & (current_row <= 4);
	assign check_diag_left_down_2 = (((current_col >= 2) & (current_col <= 6)) & (current_row >= 1)) & (current_row <= 5);
	assign check_diag_left_down_3 = (((current_col >= 1) & (current_col <= 5)) & (current_row >= 2)) & (current_row <= 6);
	assign check_diag_left_down_4 = (current_col <= 4) & (current_row >= 3);
	assign result_down = ((((board[current_row][current_col] == current_player) & (board[current_row - 1][current_col] == current_player)) & (board[current_row - 2][current_col] == current_player)) & (board[current_row - 3][current_col] == current_player)) & check_down;
	assign result_row_1 = ((((board[current_row][current_col] == current_player) & (board[current_row][current_col - 1] == current_player)) & (board[current_row][current_col - 2] == current_player)) & (board[current_row][current_col - 3] == current_player)) & check_row_1;
	assign result_row_2 = ((((board[current_row][current_col + 1] == current_player) & (board[current_row][current_col] == current_player)) & (board[current_row][current_col - 1] == current_player)) & (board[current_row][current_col - 2] == current_player)) & check_row_2;
	assign result_row_3 = ((((board[current_row][current_col + 2] == current_player) & (board[current_row][current_col + 1] == current_player)) & (board[current_row][current_col] == current_player)) & (board[current_row][current_col - 1] == current_player)) & check_row_3;
	assign result_row_4 = ((((board[current_row][current_col + 3] == current_player) & (board[current_row][current_col + 2] == current_player)) & (board[current_row][current_col + 1] == current_player)) & (board[current_row][current_col] == current_player)) & check_row_4;
	assign result_diag_right_up_1 = ((((board[current_row][current_col] == current_player) & (board[current_row - 1][current_col - 1] == current_player)) & (board[current_row - 2][current_col - 2] == current_player)) & (board[current_row - 3][current_col - 3] == current_player)) & check_diag_right_up_1;
	assign result_diag_right_up_2 = ((((board[current_row + 1][current_col + 1] == current_player) & (board[current_row][current_col] == current_player)) & (board[current_row - 1][current_col - 1] == current_player)) & (board[current_row - 2][current_col - 2] == current_player)) & check_diag_right_up_2;
	assign result_diag_right_up_3 = ((((board[current_row + 2][current_col + 2] == current_player) & (board[current_row + 1][current_col + 1] == current_player)) & (board[current_row][current_col] == current_player)) & (board[current_row - 1][current_col - 1] == current_player)) & check_diag_right_up_3;
	assign result_diag_right_up_4 = ((((board[current_row + 3][current_col + 3] == current_player) & (board[current_row + 2][current_col + 2] == current_player)) & (board[current_row + 1][current_col + 1] == current_player)) & (board[current_row][current_col] == current_player)) & check_diag_right_up_4;
	assign result_diag_left_down_1 = ((((board[current_row][current_col] == current_player) & (board[current_row + 1][current_col - 1] == current_player)) & (board[current_row + 2][current_col - 2] == current_player)) & (board[current_row + 3][current_col - 3] == current_player)) & check_diag_left_down_1;
	assign result_diag_left_down_2 = ((((board[current_row - 1][current_col + 1] == current_player) & (board[current_row][current_col] == current_player)) & (board[current_row + 1][current_col - 1] == current_player)) & (board[current_row + 2][current_col - 2] == current_player)) & check_diag_left_down_2;
	assign result_diag_left_down_3 = ((((board[current_row - 2][current_col + 2] == current_player) & (board[current_row - 1][current_col + 1] == current_player)) & (board[current_row][current_col] == current_player)) & (board[current_row + 1][current_col - 1] == current_player)) & check_diag_left_down_3;
	assign result_diag_left_down_4 = ((((board[current_row - 3][current_col + 3] == current_player) & (board[current_row - 2][current_col + 2] == current_player)) & (board[current_row - 1][current_col + 1] == current_player)) & (board[current_row][current_col] == current_player)) & check_diag_left_down_4;
	assign winning_down = result_down & check_down;
	assign winning_row_1 = result_row_1 & check_row_1;
	assign winning_row_2 = result_row_2 & check_row_2;
	assign winning_row_3 = result_row_3 & check_row_3;
	assign winning_row_4 = result_row_4 & check_row_4;
	assign winning_diag_right_up_1 = result_diag_right_up_1 & check_diag_right_up_1;
	assign winning_diag_right_up_2 = result_diag_right_up_2 & check_diag_right_up_2;
	assign winning_diag_right_up_3 = result_diag_right_up_3 & check_diag_right_up_3;
	assign winning_diag_right_up_4 = result_diag_right_up_4 & check_diag_right_up_4;
	assign winning_diag_left_down_1 = result_diag_left_down_1 & check_diag_left_down_1;
	assign winning_diag_left_down_2 = result_diag_left_down_2 & check_diag_left_down_2;
	assign winning_diag_left_down_3 = result_diag_left_down_3 & check_diag_left_down_3;
	assign winning_diag_left_down_4 = result_diag_left_down_4 & check_diag_left_down_4;
	assign hide_winning_pieces = game_over & ~show_winning_pieces;
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			drop_piece_sync <= 3'b111;
			move_right_sync <= 3'b111;
			move_left_sync <= 3'b111;
		end
		else begin
			drop_piece_sync[2:0] <= {drop_piece_sync[1:0], drop_piece};
			move_right_sync[2:0] <= {move_right_sync[1:0], move_right};
			move_left_sync[2:0] <= {move_left_sync[1:0], move_left};
		end
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			current_state <= ST_IDLE;
		else
			case (current_state)
				ST_IDLE:
					if (rising_drop_piece)
						current_state <= ST_ADDING_PIECE;
				ST_ADDING_PIECE:
					if (drop_allowed)
						current_state <= ST_CHECKING_VICTORY;
					else
						current_state <= ST_IDLE;
				ST_CHECKING_VICTORY:
					if (check_state == ST_VICTORY)
						current_state <= ST_WIN;
					else if (check_state == ST_CHECKING_DONE)
						current_state <= ST_IDLE;
					else
						current_state <= ST_CHECKING_VICTORY;
				ST_WIN: current_state <= ST_WIN;
			endcase
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			current_col <= 3'b000;
		else if (current_state == ST_IDLE) begin
			if (move_to_right)
				current_col <= next_col_right;
			else if (move_to_left)
				current_col <= next_col_left;
		end
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			game_over <= 1'b0;
			winner <= 2'b00;
			check_state <= ST_NOT_CHECKING;
			current_player <= 2'b01;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < ROWS; i = i + 1)
					column_counters[i] <= 4'b0000;
			end
			begin : sv2v_autoblock_2
				reg signed [31:0] i;
				for (i = 0; i < ROWS; i = i + 1)
					begin : sv2v_autoblock_3
						reg signed [31:0] j;
						for (j = 0; j < COLS; j = j + 1)
							begin
								board[i][j] <= 2'b00;
								winning_pieces[i][j] <= 1'b0;
							end
					end
			end
		end
		else if (current_state == ST_ADDING_PIECE) begin
			if (attempted_drop) begin
				if (drop_allowed)
					board[current_row][current_col] <= current_player;
			end
		end
		else if (current_state == ST_CHECKING_VICTORY)
			case (check_state)
				ST_NOT_CHECKING: check_state <= ST_CHECKING_DOWN;
				ST_CHECKING_DOWN: begin
					check_state <= ST_CHECKING_ROW_1;
					if (winning_down) begin
						game_over <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row - 1][current_col] <= 1'b1;
						winning_pieces[current_row - 2][current_col] <= 1'b1;
						winning_pieces[current_row - 3][current_col] <= 1'b1;
					end
				end
				ST_CHECKING_ROW_1: begin
					check_state <= ST_CHECKING_ROW_2;
					if (winning_row_1) begin
						game_over <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row][current_col - 1] <= 1'b1;
						winning_pieces[current_row][current_col - 2] <= 1'b1;
						winning_pieces[current_row][current_col - 3] <= 1'b1;
					end
				end
				ST_CHECKING_ROW_2: begin
					check_state <= ST_CHECKING_ROW_3;
					if (winning_row_2) begin
						game_over <= 1'b1;
						winning_pieces[current_row][current_col + 1] <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row][current_col - 1] <= 1'b1;
						winning_pieces[current_row][current_col - 2] <= 1'b1;
					end
				end
				ST_CHECKING_ROW_3: begin
					check_state <= ST_CHECKING_ROW_4;
					if (winning_row_3) begin
						game_over <= 1'b1;
						winning_pieces[current_row][current_col + 2] <= 1'b1;
						winning_pieces[current_row][current_col + 1] <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row][current_col - 1] <= 1'b1;
					end
				end
				ST_CHECKING_ROW_4: begin
					check_state <= ST_CHECKING_DIAG_RIGHT_UP_1;
					if (winning_row_4) begin
						game_over <= 1'b1;
						winning_pieces[current_row][current_col + 3] <= 1'b1;
						winning_pieces[current_row][current_col + 2] <= 1'b1;
						winning_pieces[current_row][current_col + 1] <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
					end
				end
				ST_CHECKING_DIAG_RIGHT_UP_1: begin
					check_state <= ST_CHECKING_DIAG_RIGHT_UP_2;
					if (winning_diag_right_up_1) begin
						game_over <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row - 1][current_col - 1] <= 1'b1;
						winning_pieces[current_row - 2][current_col - 2] <= 1'b1;
						winning_pieces[current_row - 3][current_col - 3] <= 1'b1;
					end
				end
				ST_CHECKING_DIAG_RIGHT_UP_2: begin
					check_state <= ST_CHECKING_DIAG_RIGHT_UP_3;
					if (winning_diag_right_up_2) begin
						game_over <= 1'b1;
						winning_pieces[current_row + 1][current_col + 1] <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row - 1][current_col - 1] <= 1'b1;
						winning_pieces[current_row - 2][current_col - 2] <= 1'b1;
					end
				end
				ST_CHECKING_DIAG_RIGHT_UP_3: begin
					check_state <= ST_CHECKING_DIAG_RIGHT_UP_4;
					if (winning_diag_right_up_3) begin
						game_over <= 1'b1;
						winning_pieces[current_row + 2][current_col + 2] <= 1'b1;
						winning_pieces[current_row + 1][current_col + 1] <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row - 1][current_col - 1] <= 1'b1;
					end
				end
				ST_CHECKING_DIAG_RIGHT_UP_4: begin
					check_state <= ST_CHECKING_DIAG_LEFT_DOWN_1;
					if (winning_diag_right_up_4) begin
						game_over <= 1'b1;
						winning_pieces[current_row + 3][current_col + 3] <= 1'b1;
						winning_pieces[current_row + 2][current_col + 2] <= 1'b1;
						winning_pieces[current_row + 1][current_col + 1] <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
					end
				end
				ST_CHECKING_DIAG_LEFT_DOWN_1: begin
					check_state <= ST_CHECKING_DIAG_LEFT_DOWN_2;
					if (winning_diag_left_down_1) begin
						game_over <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row + 1][current_col - 1] <= 1'b1;
						winning_pieces[current_row + 2][current_col - 2] <= 1'b1;
						winning_pieces[current_row + 3][current_col - 3] <= 1'b1;
					end
				end
				ST_CHECKING_DIAG_LEFT_DOWN_2: begin
					check_state <= ST_CHECKING_DIAG_LEFT_DOWN_3;
					if (winning_diag_left_down_2) begin
						game_over <= 1'b1;
						winning_pieces[current_row - 1][current_col + 1] <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row + 1][current_col - 1] <= 1'b1;
						winning_pieces[current_row + 2][current_col - 2] <= 1'b1;
					end
				end
				ST_CHECKING_DIAG_LEFT_DOWN_3: begin
					check_state <= ST_CHECKING_DIAG_LEFT_DOWN_4;
					if (winning_diag_left_down_3) begin
						game_over <= 1'b1;
						winning_pieces[current_row - 2][current_col + 2] <= 1'b1;
						winning_pieces[current_row - 1][current_col + 1] <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
						winning_pieces[current_row + 1][current_col - 1] <= 1'b1;
					end
				end
				ST_CHECKING_DIAG_LEFT_DOWN_4: begin
					check_state <= check_state_next_final;
					if (winning_diag_left_down_4) begin
						game_over <= 1'b1;
						winning_pieces[current_row - 3][current_col + 3] <= 1'b1;
						winning_pieces[current_row - 2][current_col + 2] <= 1'b1;
						winning_pieces[current_row - 1][current_col + 1] <= 1'b1;
						winning_pieces[current_row][current_col] <= 1'b1;
					end
				end
				ST_VICTORY: begin
					winner <= current_player;
					check_state <= ST_CHECKING_DONE;
				end
				ST_CHECKING_DONE: begin
					check_state <= ST_NOT_CHECKING;
					column_counters[current_col] <= column_counters[current_col] + 3'b001;
					current_player <= next_player;
				end
				default: check_state <= ST_NOT_CHECKING;
			endcase
	always @(posedge clk or negedge rst_n)
		if (~rst_n) begin
			flash_counter <= 26'd0;
			show_winning_pieces <= 1'b1;
		end
		else if (game_over) begin
			if (flash_counter == FLASH_COUNTER_MAX) begin
				flash_counter <= 26'd0;
				show_winning_pieces <= ~show_winning_pieces;
			end
			else
				flash_counter <= flash_counter + 26'd1;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_4
			reg signed [31:0] row;
			for (row = 0; row < ROWS; row = row + 1)
				begin : sv2v_autoblock_5
					reg signed [31:0] col;
					for (col = 0; col < COLS; col = col + 1)
						begin
							board_out[((((ROWS - 1) - row) * COLS) + ((COLS - 1) - col)) * 2+:2] = board[row][col];
							if (winning_pieces[row][col])
								board_out[((((ROWS - 1) - row) * COLS) + ((COLS - 1) - col)) * 2+:2] = (show_winning_pieces ? board[row][col] : EMPTY);
						end
				end
		end
	end
	initial _sv2v_0 = 0;
endmodule
