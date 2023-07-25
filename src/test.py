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

def print_info(dut):
  dut._log.info("pc: {}".format(dut.tt_um_tiny_processor.pc.value))
  dut._log.info("state: {}".format(dut.tt_um_tiny_processor.control_logic_0.st.value))
  
  dut._log.info("icache_data: {}".format(dut.tt_um_tiny_processor.icache_data.value))
  
  dut._log.info("acc: {}".format(dut.tt_um_tiny_processor.acc.value))
  dut._log.info("src: {}".format(dut.tt_um_tiny_processor.src.value))
  dut._log.info("ctrl_src_sel: {}".format(dut.tt_um_tiny_processor.ctrl_src_sel.value))
  
  dut._log.info("pc_sel: {}".format(dut.tt_um_tiny_processor.ctrl_pc_sel.value))
  dut._log.info("isnotz: {}".format(dut.tt_um_tiny_processor.control_logic_0.is_not_zero.value))

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
  cc = 0
  
  for i in range(10):
    dut._log.info(f"------------ cc {cc} ------------")

    if i == 2:
      dut.proc_en.value = 1

    print_info(dut)
    await ClockCycles(dut.clk, 1)
    cc += 1

  dut.proc_en.value = 0

  for i in range(4):
    dut._log.info(f"------------ cc {cc} ------------")

    print_info(dut)
    await ClockCycles(dut.clk, 1)
    cc += 1

  print_regs(range(15), dut)
