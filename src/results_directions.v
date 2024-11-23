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

  	assign result_down  = (board_array[current_row][current_col]   == current_player) &
											  (board_array[current_row-1][current_col] == current_player) &
											  (board_array[current_row-2][current_col] == current_player) &
											  (board_array[current_row-3][current_col] == current_player);

	assign result_row_1 = (board_array[current_row][current_col]   == current_player) &
												(board_array[current_row][current_col-1] == current_player) &
												(board_array[current_row][current_col-2] == current_player) &
												(board_array[current_row][current_col-3] == current_player);

	assign result_row_2 = (board_array[current_row][current_col+1] == current_player) &
												(board_array[current_row][current_col]   == current_player) &
												(board_array[current_row][current_col-1] == current_player) &
												(board_array[current_row][current_col-2] == current_player);

	assign result_row_3 = (board_array[current_row][current_col+2] == current_player) &
												(board_array[current_row][current_col+1] == current_player) &
												(board_array[current_row][current_col]   == current_player) &
												(board_array[current_row][current_col-1] == current_player);

	assign result_row_4 = (board_array[current_row][current_col+3] == current_player) &
												(board_array[current_row][current_col+2] == current_player) &
												(board_array[current_row][current_col+1] == current_player) &
												(board_array[current_row][current_col]   == current_player);

	assign result_diag_right_up_1 = (board_array[current_row][current_col]     == current_player) &
																	(board_array[current_row-1][current_col-1] == current_player) &
																	(board_array[current_row-2][current_col-2] == current_player) &
																	(board_array[current_row-3][current_col-3] == current_player);

	assign result_diag_right_up_2 = (board_array[current_row+1][current_col+1] == current_player) &
																	(board_array[current_row][current_col]     == current_player) &
																	(board_array[current_row-1][current_col-1] == current_player) &
																	(board_array[current_row-2][current_col-2] == current_player);

	assign result_diag_right_up_3 = (board_array[current_row+2][current_col+2] == current_player) &
																	(board_array[current_row+1][current_col+1] == current_player) &
																	(board_array[current_row][current_col]     == current_player) &
																	(board_array[current_row-1][current_col-1] == current_player);

	assign result_diag_right_up_4 = (board_array[current_row+3][current_col+3] == current_player) &
																	(board_array[current_row+2][current_col+2] == current_player) &
																	(board_array[current_row+1][current_col+1] == current_player) &
																	(board_array[current_row][current_col]     == current_player);

	assign result_diag_left_down_1 = (board_array[current_row][current_col]     == current_player) &
																	 (board_array[current_row+1][current_col-1] == current_player) &
																	 (board_array[current_row+2][current_col-2] == current_player) &
																   (board_array[current_row+3][current_col-3] == current_player);

	assign result_diag_left_down_2 = (board_array[current_row-1][current_col+1] == current_player) &
																	 (board_array[current_row][current_col]     == current_player) &
																	 (board_array[current_row+1][current_col-1] == current_player) &
																	 (board_array[current_row+2][current_col-2] == current_player);

	assign result_diag_left_down_3 = (board_array[current_row-2][current_col+2] == current_player) &
																	 (board_array[current_row-1][current_col+1] == current_player) &
																	 (board_array[current_row][current_col]     == current_player) &
																	 (board_array[current_row+1][current_col-1] == current_player);

	assign result_diag_left_down_4 = (board_array[current_row-3][current_col+3] == current_player) &
																	 (board_array[current_row-2][current_col+2] == current_player) &
																	 (board_array[current_row-1][current_col+1] == current_player) &
																	 (board_array[current_row][current_col]     == current_player);

endmodule