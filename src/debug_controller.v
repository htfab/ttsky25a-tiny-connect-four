module debug_controller #(parameter ROWS=8, parameter COLS=8) (
    clk,
    rst_n,
    e_debug,
    board_in,
    current_col,
    winner,
    uio_in,
    uio_out,
    uio_oe
);

    input clk;
    input rst_n;
    input e_debug;
    input [ROWS*COLS*2-1:0] board_in;
    input [2:0] current_col;
    input [1:0] winner;
    input [7:0] uio_in;

    output reg [7:0] uio_out;
    output reg [7:0] uio_oe;

    localparam CMD_READ_BOARD = 1;
    localparam CMD_READ_CURRENT_COL = 2;
    localparam CMD_READ_WINNER = 3;

    wire [1:0] debug_cmd = uio_in[1:0];
    wire [5:0] data_in = uio_in[7:2];

    reg data_out_en;
    reg [7:0] data_out;

    wire [2:0] read_row;
    wire [2:0] read_col;
    wire [1:0] read_data;

    assign uio_out = data_out;
    assign uio_oe  = {{data_out_en ? 6'b111111 : 6'b000000}, 2'b00};

    assign read_row = data_in[5:3];
    assign read_col = data_in[2:0];
  
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
                        data_out <= {6'b0, read_data};
                        data_out_en <= 1'b1;
                    end
                    CMD_READ_CURRENT_COL:
                    begin
                        data_out <= {5'b0, current_col};
                        data_out_en <= 1'b1;
                    end
                    CMD_READ_WINNER:
                    begin
                        data_out <= {6'b0, winner};
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

    board_reader #(.ROWS(ROWS), .COLS(COLS)) board_reader_debug_inst (
        .board_in(board_in),
        .row(read_row),
        .col(read_col),
        .data_out(read_data)
    );

endmodule