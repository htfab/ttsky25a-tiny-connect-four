module direction_checker (
    clk,
    rst_n,
    start,
    row,
    col,
    direction,
    data_in,
    read_row,
    read_col,
    finished_checking,
    winner,
    winning_row,
    winning_col,
    w_winning_pieces
);

    input clk;
    input rst_n;
    input start;
    input [2:0] row;
    input [2:0] col;
    input [3:0] direction;
    input [1:0] data_in;

    output reg finished_checking;
    output reg [1:0] winner;
    output reg [2:0] winning_row;
    output reg [2:0] winning_col;
    output reg w_winning_pieces;

    // Direction parameters
    localparam DOWN = 4'b0001;
	localparam ROW_1 = 4'b0010;
	localparam ROW_2 = 4'b0011;
	localparam ROW_3 = 4'b0100;
	localparam ROW_4 = 4'b0101;
	localparam DIAG_RIGHT_UP_1 = 4'b0110;
	localparam DIAG_RIGHT_UP_2 = 4'b0111;
	localparam DIAG_RIGHT_UP_3 = 4'b1000;
	localparam DIAG_RIGHT_UP_4 = 4'b1001;
	localparam DIAG_LEFT_DOWN_1 = 4'b1010;
	localparam DIAG_LEFT_DOWN_2 = 4'b1011;
	localparam DIAG_LEFT_DOWN_3 = 4'b1100;
	localparam DIAG_LEFT_DOWN_4 = 4'b1101;

    // State machine parameters
    localparam ST_IDLE = 4'b0000;
    localparam ST_READING_PIECE_1 = 4'b0001;
    localparam ST_READING_PIECE_2 = 4'b0010;
    localparam ST_READING_PIECE_3 = 4'b0011;
    localparam ST_READING_PIECE_4 = 4'b0100;
    localparam ST_COMPARE = 4'b0101;
    localparam ST_WRITING_WINNING_PIECE_1 = 4'b0110;
    localparam ST_WRITING_WINNING_PIECE_2 = 4'b0111;
    localparam ST_WRITING_WINNING_PIECE_3 = 4'b1000;
    localparam ST_WRITING_WINNING_PIECE_4 = 4'b1001;

    // These are the row and column coordinates of the pieces to be checked
    output reg  [2:0] read_row;
    output reg  [2:0] read_col;

    reg [3:0] current_state;

    // These are the pieces to be checked
    // They are read sequentially from the board memory
    reg [1:0] piece1;
    reg [1:0] piece2;
    reg [1:0] piece3;
    reg [1:0] piece4;

    // Piece 1 is always the piece which was just dropped
    wire [2:0] row_piece_1 = row;
    wire [2:0] col_piece_1 = col;

    // The other pieces are determined by the direction
    wire [2:0] row_piece_2, row_piece_3, row_piece_4;
    wire [2:0] col_piece_2, col_piece_3, col_piece_4;

    // Define offsets for each direction
    reg [2:0] row_offset_2, row_offset_3, row_offset_4;
    reg [2:0] col_offset_2, col_offset_3, col_offset_4;

    // Determine if pieces are winning combination
    wire winning_combination;

    // Assign coordinates using offsets
    assign row_piece_2 = row + row_offset_2;
    assign row_piece_3 = row + row_offset_3;
    assign row_piece_4 = row + row_offset_4;
    assign col_piece_2 = col + col_offset_2;
    assign col_piece_3 = col + col_offset_3;
    assign col_piece_4 = col + col_offset_4;

    assign winning_combination = (piece1 == piece2 & piece2 == piece3 & piece3 == piece4);

    // State machine for sequential reading of pieces
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            current_state <= ST_IDLE;
            read_row <= 3'b000;
            read_col <= 3'b000;
            finished_checking <= 1'b0;
            w_winning_pieces <= 1'b0;
            winning_row <= 3'b000;
            winning_col <= 3'b000;
        end
        else
        begin
            case (current_state)
                ST_IDLE:
                begin
                    w_winning_pieces <= 1'b0;
                    winning_row <= 3'b000;
                    winning_col <= 3'b000;
                    finished_checking <= 1'b0;
                    winner <= 2'b00;
                    piece1 <= 2'b00;
                    piece2 <= 2'b00;
                    piece3 <= 2'b00;
                    piece4 <= 2'b00;
                    if (start)
                    begin
                        read_row <= row_piece_1;
                        read_col <= col_piece_1;
                        current_state <= ST_READING_PIECE_1;
                    end
                end
                ST_READING_PIECE_1:
                begin
                        piece1 <= data_in;
                        read_row <= row_piece_2;
                        read_col <= col_piece_2;
                        current_state <= ST_READING_PIECE_2;
                end
                ST_READING_PIECE_2:
                begin
                        piece2 <= data_in;
                        read_row <= row_piece_3;
                        read_col <= col_piece_3;
                        current_state <= ST_READING_PIECE_3;
                end
                ST_READING_PIECE_3:
                begin
                        piece3 <= data_in;
                        read_row <= row_piece_4;
                        read_col <= col_piece_4;
                        current_state <= ST_READING_PIECE_4;
                end
                ST_READING_PIECE_4:
                begin
                        piece4 <= data_in;
                        current_state <= ST_COMPARE;
                end
                ST_COMPARE:
                begin
                    if (winning_combination)
                    begin
                        winner <= piece1;
                        winning_row <= row_piece_1;
                        winning_col <= col_piece_1;
                        w_winning_pieces <= 1'b1;
                        current_state <= ST_WRITING_WINNING_PIECE_1;
                    end
                    else
                    begin
                        finished_checking <= 1'b1;
                        current_state <= ST_IDLE;
                    end
                end
                ST_WRITING_WINNING_PIECE_1:
                begin
                    winning_row <= row_piece_2;
                    winning_col <= col_piece_2;
                    current_state <= ST_WRITING_WINNING_PIECE_2;
                end
                ST_WRITING_WINNING_PIECE_2:
                begin
                    winning_row <= row_piece_3;
                    winning_col <= col_piece_3;
                    current_state <= ST_WRITING_WINNING_PIECE_3;
                end
                ST_WRITING_WINNING_PIECE_3:
                begin
                    winning_row <= row_piece_4;
                    winning_col <= col_piece_4;
                    current_state <= ST_WRITING_WINNING_PIECE_4;
                end
                ST_WRITING_WINNING_PIECE_4:
                begin
                    finished_checking <= 1'b1;
                    w_winning_pieces <= 1'b0;
                    current_state <= ST_IDLE;
                end
                default:
                    current_state <= ST_IDLE;
            endcase
        end
    end

    always @(*) begin
        case (direction)
            DOWN:
            begin
                row_offset_2 = -3'd1;
                row_offset_3 = -3'd2;
                row_offset_4 = -3'd3;
                col_offset_2 = 3'd0;
                col_offset_3 = 3'd0;
                col_offset_4 = 3'd0;
            end
            ROW_1:
            begin
                row_offset_2 = 3'd0;
                row_offset_3 = 3'd0;
                row_offset_4 = 3'd0;
                col_offset_2 = -3'd3;
                col_offset_3 = -3'd2;
                col_offset_4 = -3'd1;
            end
            ROW_2:
            begin
                row_offset_2 = 3'd0;
                row_offset_3 = 3'd0;
                row_offset_4 = 3'd0;
                col_offset_2 = -3'd2;
                col_offset_3 = -3'd1;
                col_offset_4 = 3'd1;
            end
            ROW_3:
            begin
                row_offset_2 = 3'd0;
                row_offset_3 = 3'd0;
                row_offset_4 = 3'd0;
                col_offset_2 = -3'd1;
                col_offset_3 = 3'd1;
                col_offset_4 = 3'd2;
            end
            ROW_4:
            begin
                row_offset_2 = 3'd0;
                row_offset_3 = 3'd0;
                row_offset_4 = 3'd0;
                col_offset_2 = 3'd1;
                col_offset_3 = 3'd2;
                col_offset_4 = 3'd3;
            end
            DIAG_RIGHT_UP_1:
            begin
                row_offset_2 = -3'd3;
                row_offset_3 = -3'd2;
                row_offset_4 = -3'd1;
                col_offset_2 = -3'd3;
                col_offset_3 = -3'd2;
                col_offset_4 = -3'd1;
            end
            DIAG_RIGHT_UP_2:
            begin
                row_offset_2 = -3'd2;
                row_offset_3 = -3'd1;
                row_offset_4 = 3'd1;
                col_offset_2 = -3'd2;
                col_offset_3 = -3'd1;
                col_offset_4 = 3'd1;
            end
            DIAG_RIGHT_UP_3:
            begin
                row_offset_2 = -3'd1;
                row_offset_3 = 3'd1;
                row_offset_4 = 3'd2;
                col_offset_2 = -3'd1;
                col_offset_3 = 3'd1;
                col_offset_4 = 3'd2;
            end
            DIAG_RIGHT_UP_4:
            begin
                row_offset_2 = 3'd1;
                row_offset_3 = 3'd2;
                row_offset_4 = 3'd3;
                col_offset_2 = 3'd1;
                col_offset_3 = 3'd2;
                col_offset_4 = 3'd3;
            end
            DIAG_LEFT_DOWN_1:
            begin
                row_offset_2 = 3'd3;
                row_offset_3 = 3'd2;
                row_offset_4 = 3'd1;
                col_offset_2 = -3'd3;
                col_offset_3 = -3'd2;
                col_offset_4 = -3'd1;
            end
            DIAG_LEFT_DOWN_2:
            begin
                row_offset_2 = 3'd2;
                row_offset_3 = 3'd1;
                row_offset_4 = -3'd1;
                col_offset_2 = -3'd2;
                col_offset_3 = -3'd1;
                col_offset_4 = 3'd1;
            end
            DIAG_LEFT_DOWN_3:
            begin
                row_offset_2 = 3'd1;
                row_offset_3 = -3'd1;
                row_offset_4 = -3'd2;
                col_offset_2 = -3'd1;
                col_offset_3 = 3'd1;
                col_offset_4 = 3'd2;
            end
            DIAG_LEFT_DOWN_4:
            begin
                row_offset_2 = -3'd1;
                row_offset_3 = -3'd2;
                row_offset_4 = -3'd3;
                col_offset_2 = 3'd1;
                col_offset_3 = 3'd2;
                col_offset_4 = 3'd3;
            end
            default:
            begin
                row_offset_2 = 3'd0;
                row_offset_3 = 3'd0;
                row_offset_4 = 3'd0;
                col_offset_2 = 3'd0;
                col_offset_3 = 3'd0;
                col_offset_4 = 3'd0;
            end
        endcase
    end


endmodule