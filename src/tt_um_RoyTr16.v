`default_nettype none
module tt_um_RoyTr16 (
	ui_in,
	uo_out,
	uio_in,
	uio_out,
	uio_oe,
	ena,
	clk,
	rst_n
);
	input wire [7:0] ui_in;
	output wire [7:0] uo_out;
	input wire [7:0] uio_in;
	output wire [7:0] uio_out;
	output wire [7:0] uio_oe;
	input wire ena;
	input wire clk;
	input wire rst_n;
	assign uio_out = 0;
	assign uio_oe = 0;
	wire _unused = &{ena, ui_in[7:3], 1'b0};
	wire hsync;
	wire vsync;
	wire [1:0] red;
	wire [1:0] green;
	wire [1:0] blue;
	wire move_right;
	wire move_left;
	wire drop_piece;
	assign uo_out[0] = red[1];
	assign uo_out[1] = green[1];
	assign uo_out[2] = blue[1];
	assign uo_out[3] = vsync;
	assign uo_out[4] = red[0];
	assign uo_out[5] = green[0];
	assign uo_out[6] = blue[0];
	assign uo_out[7] = hsync;
	assign drop_piece = ui_in[0];
	assign move_right = ui_in[1];
	assign move_left = ui_in[2];
	connect_four_top game_inst(
		.clk_25MHz(clk),
		.rst_n(rst_n),
		.move_right(move_right),
		.move_left(move_left),
		.drop_piece(drop_piece),
		.vga_hsync(hsync),
		.vga_vsync(vsync),
		.vga_r(red),
		.vga_g(green),
		.vga_b(blue)
	);
endmodule
