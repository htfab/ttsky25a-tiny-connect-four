module debug_controller (
    clk,
    rst_n,
    e_debug,
    piece_data,
    current_col,
    winner,
    d_r_row,
    d_r_col,
    read_board,
    uio_in,
    uio_out,
    uio_oe
);

    input clk;
    input rst_n;
    input e_debug;
    input [1:0] piece_data;
    input [2:0] current_col;
    input [1:0] winner;
    input [7:0] uio_in;

    output wire [2:0] d_r_row;
    output wire [2:0] d_r_col;
    output wire read_board;
    output wire [7:0] uio_out;
    output wire [7:0] uio_oe;

    localparam CMD_READ_BOARD = 1;
    localparam CMD_READ_CURRENT_COL = 2;
    localparam CMD_READ_WINNER = 3;

    wire [1:0] debug_cmd = uio_in[1:0];
    wire [5:0] data_in = uio_in[7:2];

    reg data_out_en;
    reg [7:0] data_out;

    assign uio_out = data_out;
    assign uio_oe  = data_out_en ? 8'b11111100 : 8'b00000000;

    assign d_r_row = data_in[5:3];
    assign d_r_col = data_in[2:0];
    assign read_board = (debug_cmd == CMD_READ_BOARD);
  
    always @(posedge clk or negedge rst_n) 
    begin
        if (~rst_n) 
        begin
            data_out_en <= 1'b0;
            data_out <= 8'b0;
        end else 
        begin
            if (e_debug) 
            begin
                case (debug_cmd)
                    CMD_READ_BOARD: 
                    begin
                        data_out <= {piece_data, 6'b0};
                        data_out_en <= 1'b1;
                    end
                    CMD_READ_CURRENT_COL:
                    begin
                        data_out <= {current_col, 5'b0};
                        data_out_en <= 1'b1;
                    end
                    CMD_READ_WINNER:
                    begin
                        data_out <= {winner, 6'b0};
                        data_out_en <= 1'b1;
                    end
                    default: 
                    begin
                        data_out_en <= 1'b0;
                        data_out <= 8'b0;
                    end
                endcase
            end 
        end
    end


endmodule