# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

# Test the board is empty after reset
@cocotb.test()
async def test_reset(dut):
    dut._log.info("Start")

    # Set the clock to 25MHz (40 ns period)
    clock = Clock(dut.clk, 40, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Wait for five clock cycles then stop the reset
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1

    # The reset sequence should take 64 clock cycles
    await ClockCycles(dut.clk, 70)


    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.user_project.game_inst.board.value == 0


