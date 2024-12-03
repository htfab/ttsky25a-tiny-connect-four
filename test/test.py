# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from cocotb.types import LogicArray, Range

GL_TEST = os.environ.get('GATES', None) == 'yes'

DROP_PIECE = 0b00000110
MOVE_RIGHT = 0b00000101
MOVE_LEFT  = 0b00000011
NOT_PUSHED = 0b00000111

class GameDriver:
    def __init__(self, dut):
        clock = Clock(dut.clk, 40, units="ns")
        cocotb.start_soon(clock.start())
        self._dut = dut
        self._clock = clock

    async def reset(self):
        """Reset the game"""
        self._dut._log.info("Reset")
        self._dut.ena.value = 1
        self._dut.ui_in.value = NOT_PUSHED
        self._dut.uio_in.value = 0
        self._dut.rst_n.value = 0
        await ClockCycles(self._dut.clk, 10)
        self._dut.rst_n.value = 1

        # Wait for five clock cycles then stop the reset
        await ClockCycles(self._dut.clk, 5)
        self._dut.rst_n.value = 1

        # The reset sequence should take 64 clock cycles
        await ClockCycles(self._dut.clk, 64)

    async def move_right(self):
        """Move the piece right"""
        self._dut.ui_in.value = MOVE_RIGHT
        await ClockCycles(self._dut.clk, 3)
        self._dut.ui_in.value = NOT_PUSHED
        await ClockCycles(self._dut.clk, 1)

    async def move_left(self):
        """Move the piece left"""
        self._dut.ui_in.value = MOVE_LEFT
        await ClockCycles(self._dut.clk, 3)
        self._dut.ui_in.value = NOT_PUSHED
        await ClockCycles(self._dut.clk, 1)

    async def drop_piece(self):
        """Drop the piece"""
        self._dut.ui_in.value = DROP_PIECE
        await ClockCycles(self._dut.clk, 3)
        self._dut.ui_in.value = NOT_PUSHED
        await ClockCycles(self._dut.clk, 1)

    async def debug_cmd(self, cmd: int, data: int):
        self._dut.uio_in.value = ((data & 0xF) << 4) | (cmd & 0xF)
        await ClockCycles(self._dut.clk, 1)  # Wait for the next clock cycle
        self._dut.uio_in.value = 0
        await FallingEdge(self._dut.clk)     # Wait for output data to become valid
        return (self._dut.uio_out.value >> 4) & 0xF

    async def make_move(self, column):
        """Make a move in the game"""
        current_col = self._dut.user_project.game_inst.current_col
        while current_col.value != column:
            int_current_col = int(current_col.value)
            if (int_current_col < column):
                # Move right
                await self.move_right()
            else:
                # Move left
                await self.move_left()
                
        # Drop the piece
        row = self._dut.user_project.game_inst.game.current_row.value
        await self.drop_piece()
        # Wait for the piece to drop
        await ClockCycles(self._dut.clk, 100)

    def print_board(self):
        """Print the board"""
        self._dut._log.info("Board State:")
        board = self._dut.user_project.game_inst.game.board_rw_inst.board
        for row in range(0,8):
            row_str = ""
            for col in range(0,8):
                start_index = ((8 * row + (7-col)) * 2 + 1)
                end_index = start_index - 1
                msb = board.value[start_index]
                lsb = board.value[end_index]
                piece_color = msb << 1 | lsb
                row_str += "X" if piece_color == 1 else "O" if piece_color == 2 else "."
            self._dut._log.info(row_str)


@cocotb.test()
async def test_reset(dut):
    """Test the board is empty after reset"""
    game = GameDriver(dut)
    await game.reset()

    if not GL_TEST:
        top_board = dut.user_project.game_inst.game.board_rw_inst.board
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

    if not GL_TEST:
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

    if not GL_TEST:
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

    if not GL_TEST:
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

    if not GL_TEST:
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

    if not GL_TEST:
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

    if not GL_TEST:
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