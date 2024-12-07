import os

ROWS = 8
COLS = 8


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


class Board:
    grid = []  # list of COLS columns, each with size of ROWS
    turn_of = 1
    winner = 0

    def __init__(self, grid=None):
        if grid is None:
            self.grid = [[0 for _ in range(ROWS)] for _ in range(COLS)]
        else:
            self.grid = grid
        self.turn_of = 1
        self.winner = 0

    def add_piece(self, col: int, team: int):
        for row in range(0, ROWS):
            if self.grid[row][col] == 0:
                self.grid[row][col] = team
                return row
        return -1
    
    def read(self, x, y):
        return self.grid[y][x]

    def check_victory(self, turn_of):
        """Checks if someone won the game"""
        # check horizontal
        for y in range(ROWS):
            streak = 1
            for x in range(COLS - 1):
                if self.read(x,y) == self.read(x+1, y) and self.read(x, y) != 0:
                    streak += 1
                else:
                    streak = 1
                if streak >= 4:
                    self.winner = turn_of
                    return True

        # check vertical
        for x in range(COLS):
            streak = 1
            for y in range(ROWS - 1):
                if self.read(x,y) == self.read(x, y+1) and self.read(x,y) != 0:
                    streak += 1
                else:
                    streak = 1
                if streak >= 4:
                    self.winner = turn_of
                    return True

        # check diagonal (bottom-left to top-right)
        for x in range(COLS - 3):
            for y in range(ROWS - 3):
                if (self.read(x,y) != 0 and
                    self.read(x,y) == self.read(x+1, y+1) ==
                    self.read(x+2, y+2) == self.read(x+3, y+3)):

                    self.winner = turn_of
                    return True
                    

        # check diagonal (top-left to bottom-right)
        for x in range(COLS - 3):
            for y in range(3, ROWS):
                if (self.read(x, y) != 0 and
                    self.read(x, y) == self.read(x+1, y-1) ==
                    self.read(x+2, y-2) == self.read(x+3, y-3)):
                    
                    self.winner = turn_of
                    return True

        return False

    def __str__(self):
        ROW_SEPARATOR = "-" * (COLS * 4 + 3) + "\n"
        rows = self.grid
        reversed_rows = list(reversed(rows))

        row_strs = []
        for row in reversed_rows:
            row_str = "|"
            for val in row:
                if val == 0:
                    val = " "
                elif val == 1:
                    val = f"{bcolors.WARNING}*{bcolors.ENDC}"
                else:
                    val = f"{bcolors.FAIL}*{bcolors.ENDC}"
                row_str += f"| {val} "
            row_str += "||\n"
            row_strs.append(row_str)

        res = ""
        for st in row_strs:
            res += ROW_SEPARATOR
            res += st

        res += ROW_SEPARATOR

        return res

    def make_move(self, col: int):
        row = self.add_piece(col, self.turn_of)
        if row == -1:
            return False
        
        victory = self.check_victory(self.turn_of)
        self.turn_of = 1 if self.turn_of == 2 else 2
        return victory
        