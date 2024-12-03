# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from cocotb.types import LogicArray, Range

GL_TEST = os.environ.get('GATES', None) == 'yes'

DEBUG = 0b10000000
DROP_PIECE =       0b00000110 | DEBUG
MOVE_RIGHT =       0b00000101 | DEBUG
MOVE_LEFT  =       0b00000011 | DEBUG
NOT_PUSHED =       0b00000111 | DEBUG

CMD_READ_BOARD = 1
CMD_READ_CURRENT_COL = 2
CMD_READ_WINNER = 3

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
        self._dut.ui_in.value  # Enable debug mode

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
        self._dut.uio_in.value = (((data & 0x3F) << 6) | (cmd & 0x3)) & 0xFF
        await ClockCycles(self._dut.clk, 1)  # Wait for the next clock cycle
        self._dut.uio_in.value = 0
        await FallingEdge(self._dut.clk)     # Wait for output data to become valid

        data = self._dut.uio_out.value
        if cmd == CMD_READ_CURRENT_COL:
            return (int(data) >> 5) & 0x7
        elif cmd == CMD_READ_WINNER or cmd == CMD_READ_BOARD:
            return (int(data) >> 6) & 0x3
    
    async def read_current_col(self):
        return await self.debug_cmd(CMD_READ_CURRENT_COL, 0)
    
    async def read_winner(self):
        return await self.debug_cmd(CMD_READ_WINNER, 0)
    
    async def read_board(self):
        board = []
        for row in range(8):
            col_lst = []
            for col in range(8):
                idx_data = ((row * 8) & 0x7) << 3 | (col & 0x7)
                value = await self.debug_cmd(CMD_READ_BOARD, idx_data)
                col_lst.append(value)
            board.append(col_lst)
        return board

    async def make_move(self, column, exepcted_winner=0):
        """Make a move in the game"""
        current_col = await self.read_current_col()
        while current_col != column:
            if (current_col < column):
                # Move right
                await self.move_right()
            else:
                # Move left
                await self.move_left()
            current_col = await self.debug_cmd(CMD_READ_CURRENT_COL, 0)

        # Drop the piece
        await self.drop_piece()
        # Wait for the piece to drop
        await ClockCycles(self._dut.clk, 100)
        if exepcted_winner != 0:
            winner = await self.read_winner()
            assert winner == exepcted_winner

    def print_board(self):
        """Print the board"""
        board = self.read_board()
        self._dut._log.info("Board State:")
        for row in range(0,8):
            row_str = ""
            for col in range(0,8):
                piece_color = board[row][col]
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

    board = await game.read_board()
    for row in range(8):
        for col in range(8):
            assert board[row][col] == 0


@cocotb.test()
async def test_move_right_and_wrap_around(dut):
    """Test moving the piece right and wrapping around"""
    game = GameDriver(dut)
    await game.reset()

    for i in range(0, 8):
        current_col = await game.read_current_col()
        assert current_col == i
        await game.move_right()
        await ClockCycles(dut.clk, 10)

@cocotb.test()
async def test_move_left_and_wrap_around(dut):
    """Test moving the piece left and wrapping around"""
    game = GameDriver(dut)
    await game.reset()

    current_col = await game.read_current_col()
    assert current_col == 0
    await game.move_left()
    await ClockCycles(dut.clk, 10)

    for i in range(7, -1, -1):
        current_col = await game.read_current_col()
        assert current_col == i
        await game.move_left()
        await ClockCycles(dut.clk, 10)


@cocotb.test()
async def test_vertical_win(dut):
    """Test a vertical win of player 1"""
    game = GameDriver(dut)
    await game.reset()

    await game.make_move(0)
    await game.make_move(1)
    await game.make_move(0)
    await game.make_move(1)
    await game.make_move(0)
    await game.make_move(1)
    await game.make_move(0, exepcted_winner=1)

    game.print_board()


@cocotb.test()
async def test_double_diagonal_win(dut):
    """Test a double diagonal win of player 1"""
    game = GameDriver(dut)
    await game.reset()

    await game.make_move(0)
    await game.make_move(1)
    await game.make_move(1)
    await game.make_move(3)
    await game.make_move(4)
    await game.make_move(1)
    await game.make_move(3)
    await game.make_move(3)
    await game.make_move(3)
    await game.make_move(2)
    await game.make_move(1)
    await game.make_move(2)
    await game.make_move(2, exepcted_winner=1)

    game.print_board()


@cocotb.test()
async def test_horizontal_win(dut):
    """Test a horizontal win of player 2"""
    game = GameDriver(dut)
    await game.reset()

    await game.make_move(0)
    await game.make_move(1)
    await game.make_move(1)
    await game.make_move(2)
    await game.make_move(2)
    await game.make_move(3)
    await game.make_move(3)
    await game.make_move(4, exepcted_winner=2)

    game.print_board()