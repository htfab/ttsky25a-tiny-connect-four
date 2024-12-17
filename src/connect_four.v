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
	winning_out,
	buzzer_out
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
	output wire buzzer_out;

	// Player IDs
	localparam EMPTY = 2'b00;
	localparam PLAYER1 = 2'b01;
	localparam PLAYER2 = 2'b10;

	// Main game states
	localparam ST_IDLE = 2'b00;
	localparam ST_ADDING_PIECE = 2'b01;
	localparam ST_CHECKING_VICTORY = 2'b10;
	localparam ST_WIN = 2'b11;

	// Game sound types
	localparam SOUND_TYPE_START = 2'b00;
  localparam SOUND_TYPE_DROP = 2'b01;
  localparam SOUND_TYPE_ERROR = 2'b10;
  localparam SOUND_TYPE_VICTORY = 2'b11;

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

	// Game sounds
	reg [1:0] game_sound_type;
	reg start_game_sound;

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

	// Read from board memory
	assign mem_r_row = current_state == ST_CHECKING_VICTORY ? victory_checker_r_row : top_row_read;
	assign mem_r_col = current_state == ST_CHECKING_VICTORY ? victory_checker_r_col : top_col_read;


	// State Machine to control the game
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		begin
			current_state <= ST_IDLE;
			current_player <= PLAYER1;
			start_checking <= 1'b0;
			write_to_board <= 1'b0;
			start_game_sound <= 1'b1;
			game_sound_type <= SOUND_TYPE_START;

			column_counters[0] <= 4'b0000;
			column_counters[1] <= 4'b0000;
			column_counters[2] <= 4'b0000;
			column_counters[3] <= 4'b0000;
			column_counters[4] <= 4'b0000;
			column_counters[5] <= 4'b0000;
			column_counters[6] <= 4'b0000;
			column_counters[7] <= 4'b0000;
		end
		else
			case (current_state)
				ST_IDLE:
				begin
					if (!drop_piece)
					begin
						if (drop_allowed)
						begin
							// Write pulse to board
							write_to_board <= 1'b1;
							current_state <= ST_ADDING_PIECE;
						end
						else
						begin
							start_game_sound <= 1'b1;
							game_sound_type <= SOUND_TYPE_ERROR;
						end
					end
					else
						start_game_sound <= 1'b0;
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
						begin
							start_game_sound <= 1'b1;
							game_sound_type <= SOUND_TYPE_VICTORY;
							current_state <= ST_WIN;
						end
						else
						begin
							start_game_sound <= 1'b1;
							game_sound_type <= SOUND_TYPE_DROP;
							current_state <= ST_IDLE;
						end
					end
					else
					begin
						current_state <= ST_CHECKING_VICTORY;
						start_game_sound <= 1'b0;
					end
				end
				ST_WIN:
				begin
					current_state <= ST_WIN;
					start_game_sound <= 1'b0;
				end
			endcase
	end

	// Column to drop the piece
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
			current_col <= 3'b000;
		else if (current_state == ST_IDLE)
		begin
			if (!move_right)
				current_col <= next_col_right;
			else if (!move_left)
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
		.w_drop_row(current_row),
		.w_drop_col(current_col),
		.data_in(current_player),
		.write(write_to_board),
		.winning_row(winning_row),
		.winning_col(winning_col),
		.w_winning_pieces(w_winning_pieces),
		.r_row(mem_r_row),
		.r_col(mem_r_col),
		.winner(winner),
		.data_out(mem_data_out),
		.winning_out(winning_out)
	);

	game_sounds game_sounds_inst (
		.clk(clk),
		.rst_n(rst_n),
		.start(start_game_sound),
		.sound_type(game_sound_type),
		.buzzer(buzzer_out)
	);

endmodule
