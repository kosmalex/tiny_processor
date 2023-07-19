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
  0x0  : "add"  ,
  0x1  : "sub"  ,
  0x2  : "sll"  ,
  0x3  : "bnez" ,
  0x4  : "srl"  ,
  0x5  : "mul"  ,
  0x6  : "nand" ,
  0x7  : "xor"  ,
  0x8  : "addi" ,
  0x9  : "li"   ,
  0x10 : "slli" ,
  
  0xd :"rst",
  0xe :"la" ,
  0xf :"sa" 
}

def print_regs(_range:range, dut):
  for j in _range:
    reg = "[rs {}]: {}".format(j, dut.tt_um_tiny_processor.dmem[j].value)
    dut._log.info(reg)


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
    for i in range(100):
      dut._log.info(f"------------ cc {i} ------------")
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
      dut._log.info("[Inst: {}, rs: {}, imm: {}]".format(insts[int(dut.tt_um_tiny_processor.opcode.value)], dut.tt_um_tiny_processor.rs.value, dut.tt_um_tiny_processor.imm.value, dut.tt_um_tiny_processor.sext_imm.value))
      dut._log.info("[acc]: {}".format(dut.tt_um_tiny_processor.acc.value))

      print_regs(range(2), dut)

      await ClockCycles(dut.clk, 1)

    print_regs(range(15), dut)