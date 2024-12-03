module connect_four (
	clk,
	rst_n,
	move_right,
	move_left,
	drop_piece,
	row_read,
	col_read,
	data_out,
	game_over,
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
	input [ROW_BITS-1:0] row_read;
	input [COL_BITS-1:0] col_read;

	// Outputs
	output reg  [1:0] data_out;
	output wire  game_over;
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
	wire [ROW_BITS:0] row_to_drop;
	reg [ROW_BITS-1:0] current_row;
	reg  [COL_BITS-1:0] current_col;
	wire [1:0] winner;
	wire [2:0] next_col_right;
	wire [2:0] next_col_left;
	wire [1:0] next_player;
	wire drop_allowed;

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
	wire [2:0] mem_row;
	wire [2:0] mem_col;
	wire [1:0] mem_data;
	reg write_to_board;

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

	// Victory checker interface
	wire [2:0] row_to_get;
	wire [2:0] col_to_get;
	reg  start_checking;
	wire done_checking;

	// These signals are used as index inputs to read the board memory
	assign mem_row = (current_state == ST_ADDING_PIECE ? current_row   :
	                  current_state == ST_CHECKING_VICTORY? row_to_get :
					  row_read);

	// If we are adding a piece, we want to read the row that the piece will be dropped to
	// mem_col is the column to drop the piece
	// row_to_drop is the row that the piece will be dropped to
	assign mem_col = (current_state == ST_ADDING_PIECE ? current_col   :
	                  current_state == ST_CHECKING_VICTORY? col_to_get :
					  col_read);

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

	// Output board memory data
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
			data_out <= 2'b00;
		else
			data_out <= mem_data;
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
			case (current_state)
				ST_IDLE:
					if (rising_drop_piece)
					begin
						// Write pulse to board
						write_to_board <= 1'b1;
						current_state <= ST_ADDING_PIECE;
					end
				ST_ADDING_PIECE:
				begin
					write_to_board <= 1'b0;
					if (drop_allowed)
					begin
						current_state <= ST_CHECKING_VICTORY;
						current_player <= next_player;
						start_checking <= 1'b1;
					end
					else
						current_state <= ST_IDLE;
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

	// Current row to drop the piece
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
			current_row <= 3'b000;

		// If we are adding a piece, we want to read the row that the piece will be dropped to
		// in order to be able to check victory for that index
		else if (current_state == ST_ADDING_PIECE)
		begin
			current_row <= row_to_drop[ROW_BITS-1:0];
		end
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
		.data_in(mem_data),
		.row_read(row_to_get),
		.col_read(col_to_get),
		.done_checking(done_checking),
		.winner(winner)
	);

	// Component to read and write to board memory
	board_rw board_rw_inst (
		.clk(clk),
		.rst_n(rst_n),
		.enable(1'b1),
		.row(mem_row),
		.col(mem_col),
		.data_in(current_player),
		.write(write_to_board),
		.drop_allowed(drop_allowed),
		.row_to_drop(row_to_drop),
		.data_out(mem_data),
		.board_out(board_out)
	);

endmodule
