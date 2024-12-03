module debug_controller #(parameter ROWS=8, parameter COLS=8) (
    clk,
    rst_n,
    e_debug,
    board_in
);

    input clk;
    input rst_n;
    input e_debug;
    input [ROWS*COLS*2-1:0] board_in;


endmodule