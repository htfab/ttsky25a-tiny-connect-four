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
)

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

    reg [3:0] current_state;

    reg [1:0] piece1;
    reg [1:0] piece2;
    reg [1:0] piece3;
    reg [1:0] piece4;

    wire [2:0] row_piece_1 = row;
    wire [2:0] col_piece_1 = col;

    wire [2:0] row_piece_2;
    wire [2:0] row_piece_3;
    wire [2:0] row_piece_4;

    wire [2:0] col_piece_2;
    wire [2:0] col_piece_3;
    wire [2:0] col_piece_4;

    wire [2:0] row_up_1 = row + 1;
    wire [2:0] row_up_2 = row + 2;
    wire [2:0] row_up_3 = row + 3;
    wire [2:0] row_down_1 = row - 1;
    wire [2:0] row_down_2 = row - 2;
    wire [2:0] row_down_3 = row - 3;

    wire [2:0] col_left_1 = col - 1;
    wire [2:0] col_left_2 = col - 2;
    wire [2:0] col_left_3 = col - 3;
    wire [2:0] col_right_1 = col + 1;
    wire [2:0] col_right_2 = col + 2;
    wire [2:0] col_right_3 = col + 3;

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            current_state <= ST_IDLE;
            row_read <= 3'b000;
            col_read <= 3'b000;
        else
        begin
            case (current_state)
                ST_IDLE:
                begin
                    winner <= 2'b00;
                    piece1 = 2'b00;
                    piece2 = 2'b00;
                    piece3 = 2'b00;
                    piece4 = 2'b00;
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
                    row_piece_2 = row_down_1;
                    col_piece_2 = col;

                    row_piece_3 = row_down_2;
                    col_piece_3 = col;

                    row_piece_4 = row_down_3;
                    col_piece_4 = col;
                end
            ROW_1:
                begin
                    row_piece_2 = row;
                    col_piece_2 = col_left_3;

                    row_piece_3 = row;
                    col_piece_3 = col_left_2;

                    row_piece_4 = row;
                    col_piece_4 = col_left_1;
                end

            ROW_2:
                begin
                    row_piece_2 = row;
                    col_piece_2 = col_left_2;

                    row_piece_3 = row;
                    col_piece_3 = col_left_1;

                    row_piece_4 = row;
                    col_piece_4 = col_right_1;
                end

            ROW_3:
                begin
                    row_piece_2 = row;
                    col_piece_2 = col_left_1;

                    row_piece_3 = row;
                    col_piece_3 = col_right_1;

                    row_piece_4 = row;
                    col_piece_4 = col_right_2;
                end

            ROW_4:
                begin
                    row_piece_2 = row;
                    col_piece_2 = col_right_1;

                    row_piece_3 = row;
                    col_piece_3 = col_right_2;

                    row_piece_4 = row;
                    col_piece_4 = col_right_3;
                end

            DIAG_RIGHT_UP_1:
                begin
                    row_piece_2 = row_left_3;
                    col_piece_2 = col_down_3;

                    row_piece_3 = row_left_2;
                    col_piece_3 = col_down_2;

                    row_piece_4 = row_left_1;
                    col_piece_4 = col_down_1;
                end

            DIAG_RIGHT_UP_2:
                begin
                    row_piece_2 = row_left_2;
                    col_piece_2 = col_down_2;

                    row_piece_3 = row_left_1;
                    col_piece_3 = col_down_1;

                    row_piece_4 = row_right_1;
                    col_piece_4 = col_up_1;
                end

            DIAG_RIGHT_UP_3:
                begin
                    row_piece_2 = row_left_1;
                    col_piece_2 = col_down_1;

                    row_piece_3 = row_right_1;
                    col_piece_3 = col_up_1;

                    row_piece_4 = row_right_2;
                    col_piece_4 = col_up_2;
                end

            DIAG_RIGHT_UP_4:
                begin
                    row_piece_2 = row_right_1;
                    col_piece_2 = col_up_1;

                    row_piece_3 = row_right_2;
                    col_piece_3 = col_up_2;

                    row_piece_4 = row_right_3;
                    col_piece_4 = col_up_3;
                end

            DIAG_LEFT_DOWN_1:
                begin
                    row_piece_2 = row_left_3;
                    col_piece_2 = col_up_3;

                    row_piece_3 = row_left_2;
                    col_piece_3 = col_up_2;

                    row_piece_4 = row_left_1;
                    col_piece_4 = col_up_1;
                end
            
            DIAG_LEFT_DOWN_2:
                begin
                    row_piece_2 = row_left_2;
                    col_piece_2 = col_up_2;

                    row_piece_3 = row_left_1;
                    col_piece_3 = col_up_1;

                    row_piece_4 = row_right_1;
                    col_piece_4 = col_down_1;
                end

            DIAG_LEFT_DOWN_3:
                begin
                    row_piece_2 = row_left_1;
                    col_piece_2 = col_up_1;

                    row_piece_3 = row_right_1;
                    col_piece_3 = col_down_1;

                    row_piece_4 = row_right_2;
                    col_piece_4 = col_down_2;
                end

            DIAG_LEFT_DOWN_4:
                begin
                    row_piece_2 = row_right_1;
                    col_piece_2 = col_down_1;

                    row_piece_3 = row_right_2;
                    col_piece_3 = col_down_2;

                    row_piece_4 = row_right_3;
                    col_piece_4 = col_down_3;
                end

            default:
                begin
                    row_piece_2 = row;
                    col_piece_2 = col;

                    row_piece_3 = row;
                    col_piece_3 = col;

                    row_piece_4 = row;
                    col_piece_4 = col;
                end
                
        endcase
    end


endmodule