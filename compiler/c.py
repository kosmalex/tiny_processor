import argparse
import re

insts = {
  "add"  :0x0,
  "sub"  :0x4,
  "addi" :0x8,

  "mulu" :0x1,
  "mul"  :0x5,
  "mulh"  :0x9,

  "sll"  :0x2,
  "slli" :0xA,
  "srl"  :0x6,

  "la"   :0x3,
  "sa"   :0x7,
  "li"   :0xB,
  
  "or"  :0xC,
  "slt" :0xD,
  "and" :0xE,
  "bnez":0xF
}

def main():
  parser = argparse.ArgumentParser("Compiler for tiny processor")
  parser.add_argument("input", type=str, help="Input file")
  parser.add_argument("-o", type=str, help="Output file", default="a.mem")
  parser.add_argument("-f", type=str, help="Output format", default="hex")
  args = parser.parse_args()

  INFILE  = args.input
  OUTFILE = INFILE.split('/')[-1].split('.')[0] + ".mem"

  inst_list = []
  with open(INFILE, "r") as f:
    raw_list = f.readlines()

    """ Extract list of commands """
    cmds = []
    for cmd in raw_list:
      cmds.append(cmd.strip())

    """ Remove empty strings """
    cmds = list(filter(None, cmds))

    """ Detect labels """
    off = 0
    labels = {}
    for i, cmd in enumerate(cmds):
      if re.search(":", cmd) is not None:
        labels[cmd.split(":")[0].strip()] = (i, off)
        off += 1
    
    """ Remove labels """
    for pos in labels.values():
      cmds.pop(pos[0] - pos[1])

    """ Subs labels """
    raw_cmds = []
    off = 0
    for cmd in cmds:
      for label, info in labels.items():
        if re.search(rf'{label}$', cmd):
          cmd = re.sub(label, str(info[0] - info[1]), cmd)
      raw_cmds.append(cmd)

    outf = open(OUTFILE, "w")

    print(raw_cmds)

    """ Make numbers out of them """
    for cmd in raw_cmds:
      # parts[0] -> instruction mnemonic
      # parts[1] -> rs or imm
      parts = cmd.split(" ")
      
      opcode = insts[parts[0]]

      op = 0
      m  = re.match('(x[0-9])|(x[1][0-4])', parts[1])
      if m is not None:
        op = int(m.string.split("x")[1])
      else:
        op = int(parts[1])

      if op < 0:
        op = abs(op)
        negop = (op ^ 15) + 1
        op = negop

      if args.f == "hex":
        inst = "{:X}{:X}".format(op, opcode)
      elif args.f == "bin":
        inst = "{:4b}{:4b}".format(op, opcode).replace(" ", "0")
      elif args.f == "dec":
        tot = op + opcode
        inst = "{:0^3d}".format(tot)
      else:
        raise Exception(f"[FILE: {__file__}]: Format [{args}] not supported.")
      inst_list.append(inst)
    
    nInsts = len(inst_list)
    nEmpty = 16 - nInsts
    while nEmpty > 0:
      inst = ""
      if args.f == "hex":
        inst = "{:X}{:X}".format(0, 0)
      elif args.f == "bin":
        inst = "{:4b}{:4b}".format(0, 0).replace(" ", "0")
      elif args.f == "dec":
        inst = "{:0^3d}".format(0)
      else:
        raise Exception(f"[FILE: {__file__}]: Format [{args}] not supported.")
      inst_list.append(inst)
      nEmpty -= 1

    outf.write('\n'.join(inst_list))
    
    outf.close()
    f.close()

  pass

if __name__ == "__main__":
  main()