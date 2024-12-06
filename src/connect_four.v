module connect_four (
	clk,
	rst_n,
	move_right,
	move_left,
	drop_piece,
	top_row_read,
	top_col_read,
	winner,
	port_current_col,
	port_current_player,
	top_data_out,
	winning_out
);

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
	input [2:0] top_row_read;
	input [2:0] top_col_read;

	// Outputs
	output wire [1:0] winner;
	output wire [2:0] port_current_col;
	output wire [1:0] port_current_player;
	output wire [1:0] top_data_out;
	output wire winning_out;

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
	wire [2:0] next_col_right;
	wire [2:0] next_col_left;
	wire [1:0] next_player;
	wire drop_allowed;

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
	wire [1:0] mem_data_out;
	wire [2:0] mem_r_row;
	wire [2:0] mem_r_col;

	// Victory checker interface
	reg  start_checking;
	wire done_checking;
	wire [2:0] victory_checker_r_row;
	wire [2:0] victory_checker_r_col;

	// Winning Pieces
	wire [2:0] winning_row;
	wire [2:0] winning_col;
	wire w_winning_pieces;

	// Check which row to drop the piece in
    assign row_to_drop = column_counters[current_col];
	assign drop_allowed = row_to_drop[ROW_BITS] == 1'b0;
	assign current_row = row_to_drop[ROW_BITS-1:0];

	// Assign outputs
	assign port_current_col = current_col;
	assign port_current_player = current_player;
	assign top_data_out = mem_data_out;

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

	// Read from board memory
	assign mem_r_row = current_state == ST_CHECKING_VICTORY ? victory_checker_r_row : top_row_read;
	assign mem_r_col = current_state == ST_CHECKING_VICTORY ? victory_checker_r_col : top_col_read;
	

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
						column_counters[current_col] <= column_counters[current_col] + 1;
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
		.data_in(mem_data_out),
		.read_row(victory_checker_r_row),
		.read_col(victory_checker_r_col),
		.done_checking(done_checking),
		.winner(winner),
		.winning_row(winning_row),
		.winning_col(winning_col),
		.w_winning_pieces(w_winning_pieces)
	);

	// Component to read and write to board memory
	board_rw board_rw_inst (
		.clk(clk),
		.rst_n(rst_n),
		.enable(1'b1),
		.w_row(current_row),
		.w_col(current_col),
		.data_in(current_player),
		.write(write_to_board),
		.winning_row(winning_row),
		.winning_col(winning_col),
		.w_winning_pieces(w_winning_pieces),
		.r_row(mem_r_row),
		.r_col(mem_r_col),
		.data_out(mem_data_out),
		.winning_out(winning_out)
	);

endmodule
