module connect_four (
	clk,
	rst_n,
	move_right,
	move_left,
	drop_piece,
	winner,
	port_current_col,
	port_current_player,
	board_out
);

	parameter ROWS = 8;
	parameter COLS = 8;
	parameter COL_BITS = 3;
	parameter ROW_BITS = 3;
	parameter LAST_COL = 3'd7;

	// Inputs
	input clk;
	input rst_n;
	input move_right;
	input move_left;
	input drop_piece;

	// Outputs
	output wire [1:0] winner;
	output wire [2:0] port_current_col;
	output wire [1:0] port_current_player;
	output wire [ROWS*COLS*2-1:0] board_out;

	// Player IDs
	localparam EMPTY = 2'b00;
	localparam PLAYER1 = 2'b01;
	localparam PLAYER2 = 2'b10;

	// Main game states
	localparam ST_IDLE = 2'b00;
	localparam ST_ADDING_PIECE = 2'b01;
	localparam ST_CHECKING_VICTORY = 2'b10;
	localparam ST_WIN = 2'b11;

	// Game state variables
	reg [1:0] current_player;
	reg  [COL_BITS-1:0] current_col;
	reg  [ROW_BITS:0] column_counters [COLS - 1:0];
	wire [ROW_BITS-1:0] current_row;
	wire [ROW_BITS:0] row_to_drop;
	wire [ROWS*COLS*2-1:0] board;
	wire [2:0] next_col_right;
	wire [2:0] next_col_left;
	wire [1:0] next_player;
	wire drop_allowed;
	wire game_over;

	// Counter for sequential synchronous reset of column counter
	reg  [COL_BITS:0] rst_column_counter;

	// Synchronizers for input buttons
	reg [2:0] drop_piece_sync;
	reg [2:0] move_right_sync;
	reg [2:0] move_left_sync;
	wire rising_drop_piece;
	wire rising_move_right;
	wire rising_move_left;
	wire move_to_right;
	wire move_to_left;

	// State machines
	reg [1:0] current_state;

	// Board memory interface
	reg write_to_board;

	// Victory checker interface
	wire [2:0] row_to_get;
	wire [2:0] col_to_get;
	reg  start_checking;
	wire done_checking;

	// Check which row to drop the piece in
    assign row_to_drop = column_counters[current_col];
	assign drop_allowed = row_to_drop[ROW_BITS] == 1'b0;
	assign current_row = row_to_drop[ROW_BITS-1:0];

	// Assign outputs
	assign game_over = (current_state == ST_WIN);
	assign port_current_col = current_col;
	assign port_current_player = current_player;

	// Next column and player
	assign next_col_right = (current_col == LAST_COL ? 3'b000 : current_col + 3'b001);
	assign next_col_left = (current_col == 0 ? LAST_COL : current_col - 3'b001);
	assign next_player = (current_player == PLAYER1 ? PLAYER2 : PLAYER1);

	// Input button synchronizers
	assign rising_drop_piece = drop_piece_sync[2] & ~drop_piece_sync[1];
	assign rising_move_right = move_right_sync[2] & ~move_right_sync[1];
	assign rising_move_left  = move_left_sync[2] & ~move_left_sync[1];
	assign move_to_right     = rising_move_right & ~rising_move_left;
	assign move_to_left      = rising_move_left & ~rising_move_right;

	assign board_out = board;

	// Counter for sequential synchronous reset of column counter
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
			rst_column_counter <= {COL_BITS+1{1'b0}};
		else
		begin
			if (rst_column_counter[COL_BITS] == 1'b0)
				rst_column_counter <= rst_column_counter + {{COL_BITS{1'b0}}, 1'b1};
		end
	end

	// Synchronizers to detect rising edge of input from user
	always @(posedge clk or negedge rst_n)
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
			move_left_sync[2:0]  <= {move_left_sync[1:0], move_left};
		end
	end

	// State Machine to control the game
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		begin
			current_state <= ST_IDLE;
			current_player <= PLAYER1;
			start_checking <= 1'b0;
			write_to_board <= 1'b0;
		end
		else
		    if (rst_column_counter[COL_BITS] == 1'b0)
            	column_counters[rst_column_counter[2:0]] <= {ROW_BITS+1{1'b0}};
			else
			case (current_state)
				ST_IDLE:
					if (rising_drop_piece & drop_allowed)
					begin
						// Write pulse to board
						write_to_board <= 1'b1;
						column_counters[current_col] <= column_counters[current_col] + 1;
						current_state <= ST_ADDING_PIECE;
					end
				ST_ADDING_PIECE:
				begin
					write_to_board <= 1'b0;
					current_player <= next_player;
					start_checking <= 1'b1;
					current_state <= ST_CHECKING_VICTORY;
				end
				ST_CHECKING_VICTORY:
				begin
					start_checking <= 1'b0;
					if (done_checking)
					begin
						if (winner != EMPTY)
							current_state <= ST_WIN;
						else
							current_state <= ST_IDLE;
					end
					else
						current_state <= ST_CHECKING_VICTORY;
				end
				ST_WIN:
					current_state <= ST_WIN;
			endcase
	end

	// Column to drop the piece
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
			current_col <= 3'b000;
		else if (current_state == ST_IDLE)
		begin
			if (move_to_right)
				current_col <= next_col_right;
			else if (move_to_left)
				current_col <= next_col_left;
		end
	end

	// Component to check for victory in all directions
	victory_checker victory_checker_inst (
		.clk(clk),
		.rst_n(rst_n),
		.start(start_checking),
		.move_row(current_row),
		.move_col(current_col),
		.board_in(board),
		.done_checking(done_checking),
		.winner(winner)
	);

	// Component to read and write to board memory
	board_rw board_rw_inst (
		.clk(clk),
		.rst_n(rst_n),
		.enable(1'b1),
		.row(current_row),
		.col(current_col),
		.data_in(current_player),
		.write(write_to_board),
		.board_out(board)
	);

endmodule
