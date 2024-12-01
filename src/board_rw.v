module board_rw (
    clk,
    rst_n,
    enable,
    row,
    col,
    data_in,
    write,
    drop_allowed,
    current_row,
    data_out
);

    localparam ROWS = 8;
    localparam COLS = 8;
    localparam COL_BITS = 3;
    localparam ROW_BITS = 3;

    input clk;
    input rst_n;
    input enable;
    input [2:0] row;
    input [2:0] col;
    input [1:0] data_in;
    input write;
    output drop_allowed;
    output [2:0] current_row;
    output [1:0] data_out;

    reg [127:0] board;

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
    assign current_row = row_to_drop[ROW_BITS - 1:0];
	assign drop_allowed = row_to_drop < ROWS;

    assign data_out = enable ? board[(8*row + col)*2+:2] : 2'b00;

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
    always @(posedge clk)
    begin
        if (rst_column_counter[COL_BITS] == 1'b0)
            column_counters[rst_column_counter[2:0]] <= {ROW_BITS+1{1'b0}};
        if (!rst_board_done)
            board[(8*rst_row_counter + rst_col_counter)*2 +: 2] <= 2'b00;
        else
        if (enable & write & drop_allowed)
        begin
            board[(8*column_counters[col] + col)*2 +: 2] <= data_in;
            column_counters[col] <= column_counters[col] + 1;
        end
    end

endmodule