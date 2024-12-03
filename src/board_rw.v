module board_rw (
    clk,
    rst_n,
    enable,
    w_row,
    w_col,
    data_in,
    write,
    r_row,
    r_col,
    data_out
);

    localparam ROWS = 8;
    localparam COLS = 8;

    input clk;
    input rst_n;
    input enable;
    input [2:0] w_row;
    input [2:0] w_col;
    input [1:0] data_in;
    input write;
    input [2:0] r_row;
    input [2:0] r_col;
    output [1:0] data_out;

    // 8x8 board
    reg [ROWS*COLS*2-1:0] board;

    // Counter for sequential synchronous reset of board
    reg  [6:0] rst_board_counter;
    wire rst_board_done;

    // Reset counter for board
	wire [2:0] rst_col_counter;
	wire [2:0] rst_row_counter;

    // Divide the board counter into row and column counters
    assign rst_col_counter = rst_board_counter[2:0];
	assign rst_row_counter = rst_board_counter[5:3];
	assign rst_board_done = rst_board_counter[6];

    // Read from board
    assign data_out = board[(8*r_row + r_col)*2 +: 2];

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
        // Reset board
        if (!rst_board_done)
            board[(8*rst_row_counter + rst_col_counter)*2 +: 2] <= 2'b00;
        else
        // Write to board
        if (enable & write)
        begin
            board[(8*w_row + w_col)*2 +: 2] <= data_in;
        end
    end

endmodule