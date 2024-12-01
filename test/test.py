# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.types import LogicArray, Range

DROP_PIECE = 0b00000110
MOVE_RIGHT = 0b00000101
MOVE_LEFT  = 0b00000011
NOT_PUSHED = 0b00000111

async def push_button(dut, button, cycles):
    """Helper function to push a button for a number of cycles"""
    dut.ui_in.value = button
    await ClockCycles(dut.clk, cycles)
    dut.ui_in.value = NOT_PUSHED

async def move_right(dut):
    """Helper function to move right"""
    await push_button(dut, MOVE_RIGHT, 3)
    await ClockCycles(dut.clk, 1)

async def move_left(dut):
    """Helper function to move left"""
    await push_button(dut, MOVE_LEFT, 3)
    await ClockCycles(dut.clk, 1)

async def drop_piece(dut):
    """Helper function to drop a piece"""
    await push_button(dut, DROP_PIECE, 3)
    await ClockCycles(dut.clk, 1)


async def make_move(dut, column):
    """Helper function to make a move in the game"""
    current_col = dut.user_project.game_inst.current_col
    while current_col.value != column:
        dut._log.info(f"Current column: {current_col}")
        int_current_col = int(current_col.value)
        if (int_current_col < column):
            # Move right
            await move_right(dut)
        else:
            # Move left
            await move_left(dut)
            
    # Drop the piece
    row = dut.user_project.game_inst.game.current_row.value
    dut._log.info(f"Dropping piece in column {column}. row {int(row)}")
    await drop_piece(dut)
    # Wait for the piece to drop
    await ClockCycles(dut.clk, 100)

def print_board(dut):
    """Helper function to print the board"""
    dut._log.info("Board State:")
    board = dut.user_project.game_inst.game.board_rw_inst.board
    for row in range(0,8):
        row_str = ""
        for col in range(0,8):
            start_index = 127 - ((8 * row + (7-col)) * 2)
            end_index = start_index - 1
            piece_color = LogicArray(board.value[start_index:end_index], Range(start_index, "downto", end_index))
            row_str += "X" if piece_color == 1 else "O" if piece_color == 2 else "."
        dut._log.info(row_str)


@cocotb.test(skip=True)
async def test_reset(dut):
    """Test the board is empty after reset"""
    dut._log.info("Start")

    # Set the clock to 25MHz (40 ns period)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = NOT_PUSHED
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Wait for five clock cycles then stop the reset
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # The reset sequence should take 64 clock cycles
    await ClockCycles(dut.clk, 64)


    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    top_board = dut.user_project.game_inst.board
    assert top_board.value == 0


@cocotb.test()
async def test_move_right(dut):
    """Test moving the piece right"""
    dut._log.info("Start")

    # Set the clock to 25MHz (40 ns period)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = NOT_PUSHED
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Wait for five clock cycles then stop the reset
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # The reset sequence should take 64 clock cycles
    await ClockCycles(dut.clk, 64)

    # Move right
    await push_button(dut, MOVE_RIGHT, 5)

    # Check the output
    current_col = dut.user_project.game_inst.current_col
    assert current_col.value == 1


@cocotb.test()
async def test_move_right_and_wrap_around(dut):
    """Test moving the piece right and wrapping around"""
    dut._log.info("Start")

    # Set the clock to 25MHz (40 ns period)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = NOT_PUSHED
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Wait for five clock cycles then stop the reset
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # The reset sequence should take 64 clock cycles
    await ClockCycles(dut.clk, 64)

    # Move right
    current_col = dut.user_project.game_inst.current_col

    for i in range(0, 7):
        await push_button(dut, MOVE_RIGHT, 3)
        await ClockCycles(dut.clk, 1)
        assert current_col.value == i+1

    # Move right and wrap around
    await push_button(dut, MOVE_RIGHT, 3)
    await ClockCycles(dut.clk, 1)
    assert current_col.value == 0


@cocotb.test()
async def test_move_left_and_wrap_around(dut):
    """Test moving the piece left and wrapping around"""
    dut._log.info("Start")

    # Set the clock to 25MHz (40 ns period)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = NOT_PUSHED
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Wait for five clock cycles then stop the reset
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # The reset sequence should take 64 clock cycles
    await ClockCycles(dut.clk, 64)

    # Move left
    current_col = dut.user_project.game_inst.current_col

    assert current_col.value == 0

    for i in range(0, 8):
        await push_button(dut, MOVE_LEFT, 3)
        await ClockCycles(dut.clk, 1)
        assert current_col.value == 7-i


@cocotb.test()
async def test_vertical_win(dut):
    """Test a vertical win of player 1"""
    dut._log.info("Start")

    # Set the clock to 25MHz (40 ns period)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = NOT_PUSHED
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Wait for five clock cycles then stop the reset
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # The reset sequence should take 64 clock cycles
    await ClockCycles(dut.clk, 64)

    game = dut.user_project.game_inst.game
    winner = game.winner
    game_over = game.game_over

    # Play the game
    await make_move(dut, 0)
    assert winner.value == 0
    await make_move(dut, 1)
    assert winner.value == 0
    await make_move(dut, 0)
    assert winner.value == 0
    await make_move(dut, 1)
    assert winner.value == 0
    await make_move(dut, 0)
    assert winner.value == 0
    await make_move(dut, 1)
    assert winner.value == 0
    await make_move(dut, 0) # Player 1 wins

    print_board(dut)

    # Check the output
    assert winner.value == 1
    assert game_over.value == 1


@cocotb.test()
async def test_double_diagonal_win(dut):
    dut._log.info("Start")

    # Set the clock to 25MHz (40 ns period)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = NOT_PUSHED
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Wait for five clock cycles then stop the reset
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # The reset sequence should take 64 clock cycles
    await ClockCycles(dut.clk, 64)

    # Play the game
    await make_move(dut, 0)
    await make_move(dut, 1)
    await make_move(dut, 1)
    await make_move(dut, 3)
    await make_move(dut, 4)
    await make_move(dut, 1)
    await make_move(dut, 3)
    await make_move(dut, 3)
    await make_move(dut, 3)
    await make_move(dut, 2)
    await make_move(dut, 1)
    await make_move(dut, 2)
    await make_move(dut, 2) # Player 1 wins

    print_board(dut)

    # Check the output
    game = dut.user_project.game_inst.game
    winner = game.winner
    game_over = game.game_over

    assert winner.value == 1
    assert game_over.value == 1


@cocotb.test()
async def test_horizontal_win(dut):
    """Test a horizontal win of player 2"""
    dut._log.info("Start")

    # Set the clock to 25MHz (40 ns period)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = NOT_PUSHED
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Wait for five clock cycles then stop the reset
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # The reset sequence should take 64 clock cycles
    await ClockCycles(dut.clk, 64)

    game = dut.user_project.game_inst.game
    winner = game.winner
    game_over = game.game_over

    # Play the game
    await make_move(dut, 0)

    assert winner.value == 0
    assert game_over.value == 0

    await make_move(dut, 1)
    await make_move(dut, 1)
    await make_move(dut, 2)
    await make_move(dut, 2)

    assert winner.value == 0
    assert game_over.value == 0

    await make_move(dut, 3)
    await make_move(dut, 3)
    
    assert winner.value == 0
    assert game_over.value == 0

    await make_move(dut, 4)

    print_board(dut)

    # Check the output
    assert winner.value == 2
    assert game_over.value == 1