module board_rw (
    clk,
    rst_n,
    enable,
    row,
    col,
    data_in,
    write
    drop_allowed,
    data_out,
)
    localparam ROWS = 8;
    localparam COLS = 8;
    localparam COL_BITS = 3;

    input clk;
    input rst_n;
    input enable;
    input [2:0] row;
    input [2:0] col;
    input [1:0] data_in;
    input write;
    output drop_allowed;
    output [1:0] data_out;

    reg [1:0] board [0:ROWS - 1][0:COLS - 1];

    reg  [6:0] rst_board_counter;
    reg  [COL_BITS:0] rst_column_counter;
	wire [2:0] rst_col_counter;
	wire [2:0] rst_row_counter;
    wire rst_board_done;

    // Keep track of the number of pieces in each column
	reg  [ROW_BITS:0] column_counters [COLS - 1:0];
	wire [ROW_BITS:0] row_to_drop;

    assign rst_col_counter = rst_board_counter[2:0];
	assign rst_row_counter = rst_board_counter[5:3];
	assign rst_board_done = rst_board_counter[6];

    assign row_to_drop = column_counters[col];
	assign drop_allowed = row_to_drop < ROWS;

    assign data_out = enable ? board[row][col] : 2'b00;

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

	// Counter for sequential synchronous reset of board counter
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
			rst_board_counter <= 7'd0;
		else
		begin
			if (rst_board_counter[6] == 1'b0)
				rst_board_counter <= rst_board_counter + 7'd1;
		end
	end

    // Sequential write to board
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            if (rst_column_counter[COL_BITS] == 1'b0)
				column_counters[rst_column_counter[2:0]] <= {ROW_BITS+1{1'b0}};
			if (!rst_board_done)
			begin
				board[rst_row_counter][rst_col_counter] <= 2'b00;
				winning_pieces[rst_row_counter][rst_col_counter] <= 1'b0;
			end
        end
        else
        begin
            if (enable & write & drop_allowed)
            begin
                board[row][col] <= data_in;
            end
        end
    end

endmodule