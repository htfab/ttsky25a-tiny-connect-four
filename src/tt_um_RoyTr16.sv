/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_RoyTr16 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in [7:3], 1'b0};

  // VGA output wires
  wire       hsync, vsync;
  wire [1:0] red, green, blue;

  // Buttons
  wire move_right, move_left, drop_piece;

  assign uo_out [0] = red   [1];
  assign uo_out [1] = green [1];
  assign uo_out [2] = blue  [1];
  assign uo_out [3] = vsync;
  assign uo_out [4] = red   [0];
  assign uo_out [5] = green [0];
  assign uo_out [6] = blue  [0];
  assign uo_out [7] = hsync;

  assign ui_in [0] = drop_piece;
  assign ui_in [1] = move_right;
  assign ui_in [2] = move_left;

  connect_four_top game_inst (
    .clk_25MHz   (clk),
    .rst_n       (rst_n),
    .move_right  (move_right),
    .move_left   (move_left),
    .drop_piece  (drop_piece),
    .vga_hsync   (hsync),  // Horizontal sync
    .vga_vsync   (vsync),  // Vertical sync
    .vga_r       (red),    // 4-bit Red channel
    .vga_g       (greed),  // 4-bit Green channel
    .vga_b       (blue)    // 4-bit Blue channel
);

endmodule
