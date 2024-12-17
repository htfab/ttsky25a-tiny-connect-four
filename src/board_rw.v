module board_rw (
    clk,
    rst_n,
    enable,
    w_drop_row,
    w_drop_col,
    data_in,
    write,
    winning_row,
    winning_col,
    w_winning_pieces,
    r_row,
    r_col,
    winner,
    data_out,
    winning_out
);

    localparam ROWS = 8;
    localparam COLS = 8;

    input clk;
    input rst_n;
    input enable;
    input [2:0] w_drop_row;
    input [2:0] w_drop_col;
    input [1:0] data_in;
    input write;
    input [2:0] winning_row;
    input [2:0] winning_col;
    input w_winning_pieces;
    input [2:0] r_row;
    input [2:0] r_col;
    input [1:0] winner;
    output [1:0] data_out;
    output winning_out;

    // 8x8 board
    reg [ROWS*COLS*2-1:0] board;

    wire [1:0] r_piece;
    wire write_to_board;
    wire [1:0] w_piece;
    wire [2:0] w_row;
    wire [2:0] w_col;

    // Read from board
    assign r_piece = board[(8*r_row + r_col)*2 +: 2];
    assign write_to_board = enable & (write | w_winning_pieces);
    assign w_piece = w_winning_pieces ? 2'b11 : data_in;
    assign w_row   = w_winning_pieces ? winning_row : w_drop_row;
    assign w_col   = w_winning_pieces ? winning_col : w_drop_col;

    assign data_out    = winner  == 2'b00 ? r_piece :
                         r_piece == 2'b11 ? winner :
                         r_piece;

    assign winning_out = r_piece == 2'b11;

    // Sequential write to board
    always @(posedge clk or negedge rst_n)
    begin
        if (~rst_n)
            board <= 0;
        else
        if (enable)
        // Write to board
        begin
            if (write_to_board)
                board[(8*w_row + w_col)*2 +: 2] <= w_piece;
        end
    end

endmodule
