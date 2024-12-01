module direction_checker (
    clk,
    rst_n,
    start,
    row,
    col,
    direction,
    data_in,
    row_read,
    col_read,
    winner
);

    input clk;
    input rst_n;
    input start;
    input [2:0] row;
    input [2:0] col;
    input [3:0] direction;
    input [1:0] data_in;

    output reg [2:0] row_read;
    output reg [2:0] col_read;
    output reg [1:0] winner;

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

    localparam ST_IDLE = 3'b000;
    localparam ST_READING_PIECE_1 = 3'b001;
    localparam ST_READING_PIECE_2 = 3'b010;
    localparam ST_READING_PIECE_3 = 3'b011;
    localparam ST_READING_PIECE_4 = 3'b100;
    localparam ST_COMPARE = 3'b101;

    reg [2:0] current_state;

    reg [1:0] piece1;
    reg [1:0] piece2;
    reg [1:0] piece3;
    reg [1:0] piece4;

    wire [2:0] row_piece_1 = row;
    wire [2:0] col_piece_1 = col;

    wire [2:0] row_piece_2, row_piece_3, row_piece_4;
    wire [2:0] col_piece_2, col_piece_3, col_piece_4;

    // Define offsets for each direction
    reg [2:0] row_offset [0:2];
    reg [2:0] col_offset [0:2];


    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            current_state <= ST_IDLE;
            row_read <= 3'b000;
            col_read <= 3'b000;
        end
        else
        begin
            case (current_state)
                ST_IDLE:
                begin
                    winner <= 2'b00;
                    piece1 <= 2'b00;
                    piece2 <= 2'b00;
                    piece3 <= 2'b00;
                    piece4 <= 2'b00;
                    if (start)
                    begin
                        row_read <= row_piece_1;
                        col_read <= col_piece_1;
                        current_state <= ST_READING_PIECE_1;
                    end
                end
                ST_READING_PIECE_1:
                begin
                        piece1 <= data_in;
                        row_read <= row_piece_2;
                        col_read <= col_piece_2;
                        current_state <= ST_READING_PIECE_2;
                end
                ST_READING_PIECE_2:
                begin
                        piece2 <= data_in;
                        row_read <= row_piece_3;
                        col_read <= col_piece_3;
                        current_state <= ST_READING_PIECE_3;
                end
                ST_READING_PIECE_3:
                begin
                        piece3 <= data_in;
                        row_read <= row_piece_4;
                        col_read <= col_piece_4;
                        current_state <= ST_READING_PIECE_4;
                end
                ST_READING_PIECE_4:
                begin
                        piece4 <= data_in;
                        current_state <= ST_COMPARE;
                end
                ST_COMPARE:
                begin
                    if (piece1 == piece2 & piece2 == piece3 & piece3 == piece4)
                        winner <= piece1;
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
                row_offset[0] = -3'd1;
                row_offset[1] = -3'd2;
                row_offset[2] = -3'd3;
                col_offset[0] = 3'd0;
                col_offset[1] = 3'd0;
                col_offset[2] = 3'd0;
            end
            ROW_1:
            begin
                row_offset[0] = 3'd0;
                row_offset[1] = 3'd0;
                row_offset[2] = 3'd0;
                col_offset[0] = -3'd3;
                col_offset[1] = -3'd2;
                col_offset[2] = -3'd1;
            end
            ROW_2:
            begin
                row_offset[0] = 3'd0;
                row_offset[1] = 3'd0;
                row_offset[2] = 3'd0;
                col_offset[0] = -3'd2;
                col_offset[1] = -3'd1;
                col_offset[2] = 3'd1;
            end
            ROW_3:
            begin
                row_offset[0] = 3'd0;
                row_offset[1] = 3'd0;
                row_offset[2] = 3'd0;
                col_offset[0] = -3'd1;
                col_offset[1] = 3'd1;
                col_offset[2] = 3'd2;
            end
            ROW_4:
            begin
                row_offset[0] = 3'd0;
                row_offset[1] = 3'd0;
                row_offset[2] = 3'd0;
                col_offset[0] = 3'd1;
                col_offset[1] = 3'd2;
                col_offset[2] = 3'd3;
            end
            DIAG_RIGHT_UP_1:
            begin
                row_offset[0] = -3'd3;
                row_offset[1] = -3'd2;
                row_offset[2] = -3'd1;
                col_offset[0] = -3'd3;
                col_offset[1] = -3'd2;
                col_offset[2] = -3'd1;
            end
            DIAG_RIGHT_UP_2:
            begin
                row_offset[0] = -3'd2;
                row_offset[1] = -3'd1;
                row_offset[2] = 3'd1;
                col_offset[0] = -3'd2;
                col_offset[1] = -3'd1;
                col_offset[2] = 3'd1;
            end
            DIAG_RIGHT_UP_3:
            begin
                row_offset[0] = -3'd1;
                row_offset[1] = 3'd1;
                row_offset[2] = 3'd2;
                col_offset[0] = -3'd1;
                col_offset[1] = 3'd1;
                col_offset[2] = 3'd2;
            end
            DIAG_RIGHT_UP_4:
            begin
                row_offset[0] = 3'd1;
                row_offset[1] = 3'd2;
                row_offset[2] = 3'd3;
                col_offset[0] = 3'd1;
                col_offset[1] = 3'd2;
                col_offset[2] = 3'd3;
            end
            DIAG_LEFT_DOWN_1:
            begin
                row_offset[0] = -3'd3;
                row_offset[1] = -3'd2;
                row_offset[2] = -3'd1;
                col_offset[0] = 3'd3;
                col_offset[1] = 3'd2;
                col_offset[2] = 3'd1;
            end
            DIAG_LEFT_DOWN_2:
            begin
                row_offset[0] = -3'd2;
                row_offset[1] = -3'd1;
                row_offset[2] = 3'd1;
                col_offset[0] = 3'd2;
                col_offset[1] = 3'd1;
                col_offset[2] = -3'd1;
            end
            DIAG_LEFT_DOWN_3:
            begin
                row_offset[0] = -3'd1;
                row_offset[1] = 3'd1;
                row_offset[2] = 3'd2;
                col_offset[0] = 3'd1;
                col_offset[1] = -3'd1;
                col_offset[2] = -3'd2;
            end
            DIAG_LEFT_DOWN_4:
            begin
                row_offset[0] = 3'd1;
                row_offset[1] = 3'd2;
                row_offset[2] = 3'd3;
                col_offset[0] = -3'd1;
                col_offset[1] = -3'd2;
                col_offset[2] = -3'd3;
            end
            default:
            begin
                row_offset[0] = 3'd0;
                row_offset[1] = 3'd0;
                row_offset[2] = 3'd0;
                col_offset[0] = 3'd0;
                col_offset[1] = 3'd0;
                col_offset[2] = 3'd0;
            end
        endcase
    end

    // Assign coordinates using offsets
    assign row_piece_2 = row + row_offset[0];
    assign row_piece_3 = row + row_offset[1];
    assign row_piece_4 = row + row_offset[2];
    assign col_piece_2 = col + col_offset[0];
    assign col_piece_3 = col + col_offset[1];
    assign col_piece_4 = col + col_offset[2];


endmodule