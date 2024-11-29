module results_directions (
  current_row,
  current_col,
  current_player,
  board_vec,
  result_down,
  result_row_1,
  result_row_2,
  result_row_3,
  result_row_4,
  result_diag_right_up_1,
  result_diag_right_up_2,
  result_diag_right_up_3,
  result_diag_right_up_4,
  result_diag_left_down_1,
  result_diag_left_down_2,
  result_diag_left_down_3,
  result_diag_left_down_4
);

	parameter ROWS = 8;
	parameter COLS = 8;
	parameter COL_BITS = 3;
	parameter ROW_BITS = 3;

	input [ROW_BITS-1:0] current_row;
	input [COL_BITS-1:0] current_col;
	input [1:0] current_player;
	input [(ROWS*COLS*2)-1:0] board_vec;

  output result_down;
	output result_row_1;
	output result_row_2;
	output result_row_3;
	output result_row_4;
	output result_diag_right_up_1;
	output result_diag_right_up_2;
	output result_diag_right_up_3;
	output result_diag_right_up_4;
	output result_diag_left_down_1;
	output result_diag_left_down_2;
	output result_diag_left_down_3;
	output result_diag_left_down_4;

	genvar iter1, iter2;

	wire [1:0] board_array [0:ROWS-1][0:COLS-1];

	// Convert the 1D vector back to a 2D array
	generate
		for (iter1 = 0; iter1 < ROWS; iter1 = iter1 + 1)
		begin : row_loop
			for (iter2 = 0; iter2 < COLS; iter2 = iter2 + 1)
			begin : col_loop
				assign board_array[iter1][iter2] = board_vec[((iter1*COLS + iter2)*2) +: 2];
			end
		end
	endgenerate
	

	wire [2:0] col_minus_3 = current_col - 3;
	wire [2:0] col_minus_2 = current_col - 2;
	wire [2:0] col_minus_1 = current_col - 1;
	wire [2:0] col_plus_1  = current_col + 1;
	wire [2:0] col_plus_2  = current_col + 2;
	wire [2:0] col_plus_3  = current_col + 3;

	wire [2:0] row_minus_3 = current_row - 3;
	wire [2:0] row_minus_2 = current_row - 2;
	wire [2:0] row_minus_1 = current_row - 1;
	wire [2:0] row_plus_1  = current_row + 1;
	wire [2:0] row_plus_2  = current_row + 2;
	wire [2:0] row_plus_3  = current_row + 3;

	wire [1:0] pos = board_array[current_row][current_col];

	wire [1:0] pos_left_1 = board_array[current_row][col_minus_1];
	wire [1:0] pos_left_2 = board_array[current_row][col_minus_2];
	wire [1:0] pos_left_3 = board_array[current_row][col_minus_3];
	wire [1:0] pos_right_1 = board_array[current_row][col_plus_1];
	wire [1:0] pos_right_2 = board_array[current_row][col_plus_2];
	wire [1:0] pos_right_3 = board_array[current_row][col_plus_3];

	wire [1:0] pos_down_3 = board_array[row_minus_3][current_col];
	wire [1:0] pos_down_2 = board_array[row_minus_2][current_col];
	wire [1:0] pos_down_1 = board_array[row_minus_1][current_col];

	wire [1:0] pos_diag_right_up_1 = board_array[row_plus_1][col_plus_1];
	wire [1:0] pos_diag_right_up_2 = board_array[row_plus_2][col_plus_2];
	wire [1:0] pos_diag_right_up_3 = board_array[row_plus_3][col_plus_3];

	wire [1:0] pos_diag_right_down_1 = board_array[row_minus_1][col_plus_1];
	wire [1:0] pos_diag_right_down_2 = board_array[row_minus_2][col_plus_2];
	wire [1:0] pos_diag_right_down_3 = board_array[row_minus_3][col_plus_3];

	wire [1:0] pos_diag_left_up_1 = board_array[row_plus_1][col_minus_1];
	wire [1:0] pos_diag_left_up_2 = board_array[row_plus_2][col_minus_2];
	wire [1:0] pos_diag_left_up_3 = board_array[row_plus_3][col_minus_3];

	wire [1:0] pos_diag_left_down_1 = board_array[row_minus_1][col_minus_1];
	wire [1:0] pos_diag_left_down_2 = board_array[row_minus_2][col_minus_2];
	wire [1:0] pos_diag_left_down_3 = board_array[row_minus_3][col_minus_3];


	assign result_down  = (pos == current_player) &
						  (pos_down_1 == current_player) &
						  (pos_down_2 == current_player) &
  	                      (pos_down_3 == current_player);

	assign result_row_1 = (pos_left_3 == current_player) &
						  (pos_left_2 == current_player) &
						  (pos_left_1 == current_player) &
						  (pos == current_player);

	assign result_row_2 = (pos_left_2 == current_player) &
						  (pos_left_1 == current_player) &
						  (pos == current_player) &
						  (pos_right_1 == current_player);

	assign result_row_3 = (pos_left_1 == current_player) &
						  (pos == current_player) &
						  (pos_right_1 == current_player) &
						  (pos_right_2 == current_player);

	assign result_row_4 = (pos == current_player) &
						  (pos_right_1 == current_player) &
						  (pos_right_2 == current_player) &
						  (pos_right_3 == current_player);

	assign result_diag_right_up_1 = (pos_diag_left_up_3 == current_player) &
									(pos_diag_left_up_2 == current_player) &
									(pos_diag_left_up_1 == current_player) &
									(pos == current_player);

	assign result_diag_right_up_2 = (pos_diag_left_up_2 == current_player) &
									(pos_diag_left_up_1 == current_player) &
									(pos == current_player) &
									(pos_diag_right_down_1 == current_player);

	assign result_diag_right_up_3 = (pos_diag_left_up_1 == current_player) &
									(pos == current_player) &
									(pos_diag_right_down_1 == current_player) &
									(pos_diag_right_down_2 == current_player);

	assign result_diag_right_up_4 = (pos == current_player) &
									(pos_diag_right_down_1 == current_player) &
									(pos_diag_right_down_2 == current_player) &
									(pos_diag_right_down_3 == current_player);

	assign result_diag_left_down_1 = (pos == current_player) &
									 (pos_diag_left_down_1 == current_player) &
									 (pos_diag_left_down_2 == current_player) &
									 (pos_diag_left_down_3 == current_player);

	assign result_diag_left_down_2 = (pos_diag_right_up_1 == current_player) &
									 (pos == current_player) &
									 (pos_diag_left_down_1 == current_player) &
									 (pos_diag_left_down_2 == current_player);

	assign result_diag_left_down_3 = (pos_diag_right_up_2 == current_player) &
									 (pos_diag_right_up_1 == current_player) &
									 (pos == current_player) &
									 (pos_diag_left_down_1 == current_player);

	assign result_diag_left_down_4 = (pos_diag_right_up_3 == current_player) &
									 (pos_diag_right_up_2 == current_player) &
									 (pos_diag_right_up_1 == current_player) &
									 (pos == current_player);

endmodule