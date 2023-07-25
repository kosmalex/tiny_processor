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
  0x0 : "add"  ,
  0x4 : "sub"  ,
  0x8 : "addi" ,
  
  0x1 : "and"  ,
  0x5 : "nand" ,
  0x9 : "andi" ,
  
  0x2 : "sll"  ,
  0xA : "slli" ,
  0x6 : "srl"  ,
  
  0x3 : "la"  ,
  0xB : "li"  ,
  0x7 : "sa"  ,
  
  0xC : "or"  ,
  0xD : "xor" ,
  0xE : "mul" ,
  0xF : "bnez",
}

def print_regs(_range:range, dut, mode = 1):
  for j in _range:
    reg = ""
    if mode == 1:
      reg = "[rs {}]: {}".format(j, dut.tt_um_tiny_processor.dcache.mem[j].value)
    else:
      reg = "[rs {}]: {}".format(j, dut.tt_um_tiny_processor.icache.mem[j].value)
    dut._log.info(reg)

@cocotb.test()
async def test_tproc(dut):
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())
  dut.rst_n.value   = 0
  dut.proc_en.value = 0
  dut.csi.value     = 1
  dut.csd.value     = 1
  dut.mosi.value    = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 1)

  for i in range(16):
    dut._log.info(f"------------ cc {i} ------------")
    await ClockCycles(dut.clk, 1)

  print_regs(range(15), dut)
