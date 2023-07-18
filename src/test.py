import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

segments = {
  0 : 0b0111111,
  1 : 0b0000110,
  2 : 0b1011011,
  3 : 0b1001111,
  4 : 0b1100110,
  5 : 0b1101101,
  6 : 0b1111100,
  7 : 0b0000111,
  8 : 0b1111111,
  9 : 0b1100111,
  10: 0b1110111,
  11: 0b1111100,
  12: 0b0111001,
  13: 0b1011110,
  14: 0b1111001,
  15: 0b1110001,
}

insts = {
  0x0: "ADD",
  0x1: "NAND",
  0x3: "BNEZ",
  0x2: "ADDI",
  0x4: "LI",
  0x5: "SLLI",
  0xe: "LA",
  0xf: "SA",
}

@cocotb.test()
async def test_7seg(dut):
    dut._log.info("start")
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut._log.info("reset")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    dut._log.info("check all segments")
    for i in range(120):

      dut._log.info("--- FETCH ---")
      # assert int(dut.tt_um_tiny_processor.pc.value) == i 
      # dut._log.info("[PC {}] -> [SEG {}]".format(dut.tt_um_tiny_processor.pc.value, dut.segments.value))
      dut._log.info("[PC {}] -> [{}]".format(dut.tt_um_tiny_processor.pc.value, dut.tt_um_tiny_processor.inst.value))
      # assert int(dut.segments.value) == segments[int(dut.tt_um_tiny_processor.pc.value)]

      dut._log.info("--- EXEC ---")
      dut._log.info("- comb")
      dut._log.info("[sext_imm: {}]".format(dut.tt_um_tiny_processor.sext_imm.value))
      dut._log.info("[alu_res]: {}".format(dut.tt_um_tiny_processor.alu_res.value))
      dut._log.info("[fwd_alu_res]: {}".format(dut.tt_um_tiny_processor.fwd_alu_res.value))
      dut._log.info("- seq")
      dut._log.info("[Inst: {}, rs: {}, imm: {}]".format(insts[int(dut.tt_um_tiny_processor.ir_opcode.value)], dut.tt_um_tiny_processor.ir_rs.value, dut.tt_um_tiny_processor.ir_imm.value, dut.tt_um_tiny_processor.sext_imm.value))
      dut._log.info("[acc]: {}".format(dut.tt_um_tiny_processor.acc.value))
      for j in range(2):
        reg = "[rs {}]: ".format(j)
        val = ""
        val += "{}".format(dut.tt_um_tiny_processor.dmem[j].value)
        dut._log.info(reg + val)
      await ClockCycles(dut.clk, 1)

    for j in range(15):
      reg = "[rs {}]: ".format(j)
      val = ""
      val += "{}".format(dut.tt_um_tiny_processor.dmem[j].value)
      dut._log.info(reg + val)
