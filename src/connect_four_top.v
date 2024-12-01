module connect_four_top (
	clk_25MHz,
	rst_n,
	move_right,
	move_left,
	drop_piece,
	vga_hsync,
	vga_vsync,
	vga_r,
	vga_g,
	vga_b
);

	input wire clk_25MHz;
	input wire rst_n;
	input wire move_right;
	input wire move_left;
	input wire drop_piece;
	output wire vga_hsync;
	output wire vga_vsync;
	output reg [1:0] vga_r;
	output reg [1:0] vga_g;
	output reg [1:0] vga_b;

	localparam H_ACTIVE = 640;
	localparam V_ACTIVE = 480;

	localparam ROWS = 8;
	localparam COLS = 8;

	localparam CELL_SIZE = 10'd32;
	localparam BOARD_TOP_LEFT_X = 10'd192;
	localparam BOARD_TOP_LEFT_Y = 10'd112;
	localparam CURSOR_OFFSET = 10'd16;

	localparam PLAYER1_COLOR = 2'b01;
	localparam PLAYER2_COLOR = 2'b10;

	localparam CIRCLE_RADIUS = 10'd14;
	localparam CIRCLE_RADIUS_SQUARED = CIRCLE_RADIUS * CIRCLE_RADIUS;

	localparam EMPTY_COLOR_R = 2'b01;
	localparam EMPTY_COLOR_G = 2'b11;
	localparam EMPTY_COLOR_B = 2'b01;
	localparam BOARD_COLOR_R = 2'b00;
	localparam BOARD_COLOR_G = 2'b00;
	localparam BOARD_COLOR_B = 2'b11;
	localparam PLAYER1_COLOR_R = 2'b11;
	localparam PLAYER1_COLOR_G = 2'b11;
	localparam PLAYER1_COLOR_B = 2'b00;
	localparam PLAYER2_COLOR_R = 2'b11;
	localparam PLAYER2_COLOR_G = 2'b00;
	localparam PLAYER2_COLOR_B = 2'b00;

	wire [2:0] current_col;
	wire [1:0] current_player;
	wire game_over;
	wire [9:0] h_count;
	wire [9:0] v_count;
	wire draw_board;
	wire draw_cursor;
	wire vga_active;
	wire [2:0] col_idx_n;
	wire [2:0] row_idx_n;
	wire [2:0] col_idx;
	wire [2:0] row_idx;
	wire [1:0] piece_color;
	wire player_1_turn;

	wire [9:0] h_count_board_offset;
	wire [9:0] v_count_board_offset;

	assign h_count_board_offset = h_count - BOARD_TOP_LEFT_X;
	assign v_count_board_offset = v_count - BOARD_TOP_LEFT_Y;

	assign draw_board = (((h_count >= BOARD_TOP_LEFT_X) & (h_count < (BOARD_TOP_LEFT_X + (COLS * CELL_SIZE)))) & (v_count >= BOARD_TOP_LEFT_Y)) & (v_count < (BOARD_TOP_LEFT_Y + (ROWS * CELL_SIZE)));
	assign draw_cursor = ((((h_count >= BOARD_TOP_LEFT_X) & (h_count < (BOARD_TOP_LEFT_X + (COLS * CELL_SIZE)))) & (v_count >= ((BOARD_TOP_LEFT_Y - CURSOR_OFFSET) - CELL_SIZE))) & (v_count < (BOARD_TOP_LEFT_Y - CURSOR_OFFSET))) & (current_col == col_idx);
	assign vga_active = (h_count < H_ACTIVE) & (v_count < V_ACTIVE);
	assign col_idx_n = h_count_board_offset[7:5];
	assign row_idx_n = v_count_board_offset[7:5];
	assign col_idx = col_idx_n;
	assign row_idx = 3'd7 - row_idx_n;
	assign player_1_turn = current_player == PLAYER1_COLOR;

	// Generate 25MHz pixel clock
	vga_controller vga_ctrl(
		.pixel_clk(clk_25MHz),
		.rst_n(rst_n),
		.hsync(vga_hsync),
		.vsync(vga_vsync),
		.x_count(h_count),
		.y_count(v_count)
	);

	connect_four game (
		.clk(clk_25MHz),
		.rst_n(rst_n),
		.move_right(move_right),
		.move_left(move_left),
		.drop_piece(drop_piece),
		.row_read(row_idx),
		.col_read(col_idx),
		.data_out(piece_color),
		.port_current_col(current_col),
		.port_current_player(current_player)
	);

	wire [9:0] cell_center_x;
	wire [9:0] cell_center_y;
	wire [9:0] cursor_center_x;
	wire [9:0] cursor_center_y;
	wire [9:0] dx_cell;
	wire [9:0] dy_cell;
	wire [9:0] distance_squared_cell;
	wire [9:0] dx_cursor;
	wire [9:0] dy_cursor;
	wire [9:0] distance_squared_cursor;
	wire cell_in_circle;
	wire cursor_in_circle;
	wire draw_circle_cursor;

	assign cell_center_x = (BOARD_TOP_LEFT_X + (col_idx * CELL_SIZE)) + (CELL_SIZE / 2);
	assign cell_center_y = (BOARD_TOP_LEFT_Y + (row_idx_n * CELL_SIZE)) + (CELL_SIZE / 2);
	assign cursor_center_x = (BOARD_TOP_LEFT_X + (current_col * CELL_SIZE)) + (CELL_SIZE / 2);
	assign cursor_center_y = (BOARD_TOP_LEFT_Y - CURSOR_OFFSET) - (CELL_SIZE / 2);
	assign dx_cell = h_count - cell_center_x;
	assign dy_cell = v_count - cell_center_y;
	assign distance_squared_cell = (dx_cell * dx_cell) + (dy_cell * dy_cell);
	assign cell_in_circle = distance_squared_cell <= CIRCLE_RADIUS_SQUARED;
	assign dx_cursor = h_count - cursor_center_x;
	assign dy_cursor = v_count - cursor_center_y;
	assign distance_squared_cursor = (dx_cursor * dx_cursor) + (dy_cursor * dy_cursor);
	assign cursor_in_circle = distance_squared_cursor <= CIRCLE_RADIUS_SQUARED;
	assign draw_circle_cursor = (draw_cursor & cursor_in_circle) & ~game_over;

	always @(*) 
	begin
		vga_r = 2'b00;
		vga_g = 2'b00;
		vga_b = 2'b00;
		if (vga_active) 
		begin
			vga_r = EMPTY_COLOR_R;
			vga_g = EMPTY_COLOR_G;
			vga_b = EMPTY_COLOR_B;
			if (draw_board) 
			begin
				if (cell_in_circle) 
				begin
					if (piece_color == PLAYER1_COLOR) 
					begin
						vga_r = PLAYER1_COLOR_R;
						vga_g = PLAYER1_COLOR_G;
						vga_b = PLAYER1_COLOR_B;
					end
					else if (piece_color == PLAYER2_COLOR) 
					begin
						vga_r = PLAYER2_COLOR_R;
						vga_g = PLAYER2_COLOR_G;
						vga_b = PLAYER2_COLOR_B;
					end
				end
				else 
				begin
					vga_r = BOARD_COLOR_R;
					vga_g = BOARD_COLOR_G;
					vga_b = BOARD_COLOR_B;
				end
			end
			else if (draw_circle_cursor) 
			begin
				if (player_1_turn) 
				begin
					vga_r = PLAYER1_COLOR_R;
					vga_g = PLAYER1_COLOR_G;
					vga_b = PLAYER1_COLOR_B;
				end
				else 
				begin
					vga_r = PLAYER2_COLOR_R;
					vga_g = PLAYER2_COLOR_G;
					vga_b = PLAYER2_COLOR_B;
				end
			end
		end
	end

endmodule
