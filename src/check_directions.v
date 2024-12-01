module check_directions (
  current_row,
  current_col,
	check_down,
  check_row_1,
  check_row_2,
  check_row_3,
  check_row_4,
  check_diag_right_up_1,
  check_diag_right_up_2,
  check_diag_right_up_3,
  check_diag_right_up_4,
  check_diag_left_down_1,
  check_diag_left_down_2,
  check_diag_left_down_3,
  check_diag_left_down_4
);

  input [2:0] current_row;
  input [2:0] current_col;

  // Check if there are enough slots in the direction to check
	output wire check_down;
  output wire check_row_1;
  output wire check_row_2;
  output wire check_row_3;
  output wire check_row_4;
  output wire check_diag_right_up_1;
  output wire check_diag_right_up_2;
  output wire check_diag_right_up_3;
  output wire check_diag_right_up_4;
  output wire check_diag_left_down_1;
  output wire check_diag_left_down_2;
  output wire check_diag_left_down_3;
  output wire check_diag_left_down_4;

  // Base the checks on the current row and column
  assign check_down             =  current_row >= 3                                                                ;
	assign check_row_1            =  current_col >= 3                                                                ;
	assign check_row_2            = (current_col >= 2) & (current_col <= 6)                                          ;
	assign check_row_3            = (current_col >= 1) & (current_col <= 5)                                          ;
	assign check_row_4            =  current_col <= 4                                                                ;
	assign check_diag_right_up_1  = (current_col >= 3) & (current_row >= 3)                                          ;
	assign check_diag_right_up_2  = (current_col >= 2) & (current_col <= 6) & (current_row >= 2) & (current_row <= 6);
	assign check_diag_right_up_3  = (current_col >= 1) & (current_col <= 5) & (current_row >= 1) & (current_row <= 5);
	assign check_diag_right_up_4  = (current_col <= 4) & (current_row <= 4)                                          ;
	assign check_diag_left_down_1 = (current_col >= 3) & (current_row <= 4)                                          ;
	assign check_diag_left_down_2 = (current_col >= 2) & (current_col <= 6) & (current_row >= 1) & (current_row <= 5);
	assign check_diag_left_down_3 = (current_col >= 1) & (current_col <= 5) & (current_row >= 2) & (current_row <= 6);
	assign check_diag_left_down_4 = (current_col <= 4) & (current_row >= 3)                                          ;

endmodule