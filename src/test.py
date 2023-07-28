import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

states = {
  0 : "IDLE",
  1 : "EXEC",
  2 : "RECV",
  3 : "WRITE",
}

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
  
  0x1 : "mulu" ,
  0x5 : "mul"  ,
  
  0x9 : "NaI" ,
  
  0x2 : "sll"  ,
  0xA : "slli" ,
  0x6 : "srl"  ,
  
  0x3 : "la"  ,
  0xB : "li"  ,
  0x7 : "sa"  ,
  
  0xC : "or"  ,
  0xD : "xor" ,
  0xE : "and" ,
  0xF : "bnez",
}

def print_regs(_range:range, dut, mode = 1):
  for j in _range:
    reg = ""
    if mode == 1:
      reg = "[rs {:0>2}]: 0b{:0>8}, {:0>3}".format(j, str(dut.tt_um_tiny_processor.dcache.mem[j].value), int(dut.tt_um_tiny_processor.dcache.mem[j].value))
    else:
      reg = "[rs {:0>2}]: 0b{:0>8}, 0x{:0>2X}".format(j, str(dut.tt_um_tiny_processor.icache.mem[j].value), int(dut.tt_um_tiny_processor.icache.mem[j].value))
    dut._log.info(reg)

def print_info(dut, mode = 0):
  dut._log.info("pc: {}".format(dut.tt_um_tiny_processor.pc.value))
  dut._log.info("state: {}".format(states[int(dut.tt_um_tiny_processor.control_logic_0.st.value)]))

  if mode == 0:
    dut._log.info("mosi: {}".format(dut.mosi.value))
    dut._log.info("dbuf: {}".format(dut.tt_um_tiny_processor.buff_data.value))

    dut._log.info(" -- fsm --")
    dut._log.info("mstr_wr   : {}".format(dut.tt_um_tiny_processor.master_wr.value))
    dut._log.info("fsmmstr_wr: {}".format(dut.tt_um_tiny_processor.control_logic_0.master_wr_in.value))

    dut._log.info(" -- icache --")
    dut._log.info("data_in: {}".format(dut.tt_um_tiny_processor.icache.data_in.value))
    dut._log.info("addr_in: {}".format(dut.tt_um_tiny_processor.icache.addr_in.value))
    dut._log.info("en_in: {}".format(dut.tt_um_tiny_processor.icache.en_in.value))
  elif mode == 1:
    dut._log.info("Inst: {}".format(insts[int(dut.tt_um_tiny_processor.opcode.value)]))
    dut._log.info(" Acc: {}".format(dut.tt_um_tiny_processor.acc.value))
    dut._log.info(" Src: {}".format(dut.tt_um_tiny_processor.src.value))
    dut._log.info(" Alu: {}".format(dut.tt_um_tiny_processor.alu_res.value))
    # dut._log.info(" Acc: {:d}".format(int(dut.tt_um_tiny_processor.acc.value)))
    # dut._log.info(" Src: {:d}".format(int(dut.tt_um_tiny_processor.src.value)))
    # dut._log.info(" Alu: {:d}".format(int(dut.tt_um_tiny_processor.alu_res.value)))

def load_insts(file_name):
  ''' Bit widths '''
  PC_W     = 4  # Program counter 
  BUFFER_W = 12 # Shift register

  bit_matrix = []
  with open(file_name, 'r') as f:
    bit_strings = f.read().split('\n')
    
    for ind, bit_string in enumerate(bit_strings):
      bit_list = []
      
      integer = int(bit_string, 2)
      integer <<= PC_W
      integer |= ind
      
      bi = BUFFER_W
      while bi > 0:
        bit = integer & 1
        bit_list.append(bit)
        integer >>= 1
        bi -= 1
      bit_matrix.append(bit_list)

    f.close()

  return bit_matrix

async def serial_send(_dut, _cc, _bits):
  nb = len(_bits)
  
  data = _bits
  cc   = _cc
  dut  = _dut 

  j = 0
  for i in range(nb + 3):
    # dut._log.info(f"------------ cc {cc} ------------")

    if i == 0:
      dut.csi.value = 0
    elif i == (nb+1):
      dut.csi.value = 1
    elif j < nb:
      dut.mosi.value = data[j]
      j += 1 
    else:
      dut.mosi.value = 0

    await FallingEdge(dut.clk)
    # print_info(dut)
    await RisingEdge(dut.clk)
    cc += 1

  return cc

async def show_reg(_dut, _cc, regidx):
  dut = _dut
  cc  = _cc

  dut._log.info(f"------------ cc {cc} ------------")
  dut.lsB.value = 0
  dut.display_on.value = 1
  dut.addr_in.value    = regidx
  await Timer(2, units="us")
    
  dut._log.info("ctrl_disp_on {}".format(dut.tt_um_tiny_processor.ctrl_display_on.value))
  dut._log.info("      lsByte {}".format(dut.lsB.value))
  dut._log.info(" dcache_addr {}".format(dut.tt_um_tiny_processor.dcache_addr.value))
  dut._log.info("       value {}".format(dut.tt_um_tiny_processor.value.value))
  dut._log.info("    segments {}".format(dut.segments.value))
  await Timer(2, units="us")

  dut.lsB.value = 1
  await Timer(2, units="us")
  
  dut._log.info("ctrl_disp_on {}".format(dut.tt_um_tiny_processor.ctrl_display_on.value))
  dut._log.info("      lsByte {}".format(dut.lsB.value))
  dut._log.info(" dcache_addr {}".format(dut.tt_um_tiny_processor.dcache_addr.value))
  dut._log.info("       value {}".format(dut.tt_um_tiny_processor.value.value))
  dut._log.info("    segments {}".format(dut.segments.value))
  await Timer(2, units="us")
  
  return cc

@cocotb.test()
async def test_tproc(dut):
  insts = load_insts('../compiler/fact.tx')

  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())
  dut.rst_n.value   = 0
  dut.proc_en.value = 0
  dut.csi.value     = 1
  dut.csd.value     = 1
  dut.mosi.value    = 1

  dut.display_on.value = 0
  dut.addr_in.value    = 0
  dut.lsB.value        = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 1)
  cc = 0
  
  for i in range(2):
    dut._log.info(f"------------ cc {cc} ------------")

    print_info(dut)
    await ClockCycles(dut.clk, 1)
    cc += 1

  for inst in insts:
    # dut._log.info('Sending: {}'.format(''.join(list(map(str, inst)))))
    cc = await serial_send(dut, cc, inst)

  for i in range(2):
    dut._log.info(f"------------ cc {cc} ------------")

    print_info(dut)
    await ClockCycles(dut.clk, 1)
    cc += 1

  print_regs(range(16), dut, 0)
  print_regs(range(15), dut, 1)

  for i in range(80):
    dut._log.info(f"------------ cc {cc} ------------")
    if i == 0:
      dut.proc_en.value = 1
    if (int(dut.done.value) == 1) and i > 1: # delay one cycle
      dut.proc_en.value = 0

    await FallingEdge(dut.clk)
    print_info(dut, 1)
    await RisingEdge(dut.clk)
    cc += 1

  print_regs(range(15), dut, 1)

  cc = await show_reg(dut, cc, 0)
  cc = await show_reg(dut, cc, 1)
  cc = await show_reg(dut, cc, 2)