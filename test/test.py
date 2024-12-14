# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import os
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from cocotb.regression import TestFactory

from connect_four_sim import Board

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
        """Send a debug command to the game"""
        uio_in = ((data & 0x3F) << 2) | (cmd & 0x3)
        self._dut.uio_in.value = uio_in
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
    
    async def read_piece(self, row, col):
        idx = (row << 3) | col
        return await self.debug_cmd(CMD_READ_BOARD, idx)
    
    async def read_board(self) -> list:
        """Read the board state"""
        board = []
        for row in range(8):
            board_row = []
            for col in range(8):
                value = await self.read_piece(row, col)
                await ClockCycles(self._dut.clk, 1)
                board_row.append(int(value))
            board.append(board_row)
        return board

    async def make_move(self, column, exepcted_winner=0, check_winner=True):
        """Make a move in the game"""
        current_col = await self.read_current_col()
        move_col_count = 0
        while current_col != column:
            if move_col_count > 8:
                raise Exception(f"Moved more than 8 columns and still not at the target column. Current column: {current_col}, Target column: {column}")
            if (current_col < column):
                # Move right
                await self.move_right()
                move_col_count += 1
            else:
                # Move left
                await self.move_left()
                move_col_count += 1
            current_col = await self.debug_cmd(CMD_READ_CURRENT_COL, 0)

        # Drop the piece
        await self.drop_piece()
        # Wait for the piece to drop
        await ClockCycles(self._dut.clk, 120)

        if check_winner:
            winner = await self.read_winner()
            if exepcted_winner != 0:
                await self.print_board()
                assert winner == exepcted_winner
            else:
                if winner != 0:
                    await self.print_board()
                    raise Exception(f"Unexpected winner: {winner}")


    async def print_board(self):
        """Print the board"""
        board = await self.read_board()
        print(Board(board))


def generate_random_move():
    return random.randint(0, 7)


def compare_boards(dut_board: Board, sim_board: Board, move_list: list = []):
    for row in range(8):
        for col in range(8):
            if (dut_board.grid[row][col] != sim_board.grid[row][col]):
                print("DUT Board:")
                print(dut_board)
                print("Sim Board:")
                print(sim_board)
                if len(move_list) > 0:
                    print("Move List:")
                    print(move_list)
                raise Exception(f"Boards do not match at row: {row}, col: {col}. \
                                  Expected: {sim_board.grid[row][col]}, Actual: {dut_board.grid[row][col]}")


async def simulate_random_game(dut, output=False):
    game = GameDriver(dut)
    await game.reset()

    sim_board = Board()
    move = generate_random_move()
    count = 0
    move_list = []
    while sim_board.winner == 0 and count < 100:
        move_list.append(move)
        sim_board.make_move(move)
        await game.make_move(move, check_winner=False)

        dut_board = Board(await game.read_board())

        compare_boards(dut_board, sim_board, move_list)

        hardware_winner = await game.read_winner()
        if hardware_winner != sim_board.winner:
            print("DUT Board:")
            print(dut_board)
            print("Sim Board:")
            print(sim_board)
            print("Move List:")
            print(move_list)
            raise Exception(f"Winner mismatch. Hardware winner: {hardware_winner}, Software winner: {sim_board.winner}")

        move = generate_random_move()
        count += 1

    if output:
        print(sim_board)
        print(f"Winner: {sim_board.winner}")


async def simulate_game_from_move_list(dut, moves: list):
    """Simulate a game from a list of moves"""
    game = GameDriver(dut)
    await game.reset()

    sim_board = Board()
    for move in moves:
        sim_board.make_move(move)
        await game.make_move(move, check_winner=False)

        dut_board = Board(await game.read_board())

        compare_boards(dut_board, sim_board)

        hardware_winner = await game.read_winner()
        if hardware_winner != sim_board.winner:
            print("DUT Board:")
            print(dut_board)
            print("Sim Board:")
            print(sim_board)
            raise Exception(f"Winner mismatch. Hardware winner: {hardware_winner}, Software winner: {sim_board.winner}")

    print(sim_board)
    print(f"Winner: {sim_board.winner}")


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
        await ClockCycles(dut.clk, 3)

@cocotb.test()
async def test_move_left_and_wrap_around(dut):
    """Test moving the piece left and wrapping around"""
    game = GameDriver(dut)
    await game.reset()

    current_col = await game.read_current_col()
    assert current_col == 0
    await game.move_left()
    await ClockCycles(dut.clk, 3)

    for i in range(7, -1, -1):
        current_col = await game.read_current_col()
        assert current_col == i
        await game.move_left()
        await ClockCycles(dut.clk, 3)


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


@cocotb.test()
async def test_false_detection_diag_warparound(dut):
    """Test a false detection of a diagonal win due to wrap around doesn't count as a win"""
    game = GameDriver(dut)
    await game.reset()

    await game.make_move(0)
    await game.make_move(0)
    await game.make_move(0)
    await game.make_move(1)
    await game.make_move(1)
    await game.make_move(3)
    await game.make_move(2)
    await game.make_move(4)
    for _ in range(0, 8):
        await game.make_move(3)

    # The game should not be won


@cocotb.test()
async def test_board_mismatch_case_1_simplified(dut):
    """Test case 1 where the boards mismatched in a random test and simplify the moves to recreate the issue"""
    game = GameDriver(dut)
    await game.reset()

    moves = [0, 0, 1, 1, 2, 1, 2, 2, 4, 4, 4, 4, 5, 5, 5, 4, 5, 5, 0, 3, 2, 3, 3, 5, 5, 3]
    
    await simulate_game_from_move_list(dut, moves)


@cocotb.test()
async def test_over_25_pieces(dut):
    """Test a game with over 25 moves"""
    game = GameDriver(dut)
    await game.reset()

    for _ in range(0, 3):
        for i in range(0, 8):
            await game.make_move(i)

    for i in range(1, 8):
        await game.make_move(i)

    await game.make_move(1)
    await game.make_move(2)
    await game.make_move(3)
    
    await game.print_board()

    winner = await game.read_winner()
    assert winner == 0


@cocotb.test()
async def test_random_moves(dut):
    """Test random moves"""
    await simulate_random_game(dut, output=True)


@cocotb.test()
async def test_random_game_n_times(dut, n_times=1):
    """Test random games n times"""
    await simulate_random_game(dut)


# tf = TestFactory(test_random_game_n_times)
# tf.add_option("n_times", [_ for _ in range(100)])
# tf.generate_tests()