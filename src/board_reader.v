module board_reader #(parameter ROWS=8, parameter COLS=8) (
    board_in,
    row,
    col,
    data_out
);

    input [ROWS*COLS*2-1:0] board_in;
    input [2:0] row;
    input [2:0] col;
    output wire [1:0] data_out;

    assign data_out = board_in[(row*COLS+col)*2+1 +: 2];
    
endmodule

