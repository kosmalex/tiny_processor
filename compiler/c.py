import argparse
import re

insts = {
  "add"  :0x0,
  "sub"  :0x4,
  "addi" :0x8,

  "sll"  :0x2,
  "slli" :0xA,
  "srl"  :0x6,

  "la"   :0x3,
  "sa"   :0x7,
  "li"   :0xB,
  
  "or"  :0xC,
  "xor" :0xD,
  "mul" :0xE,
  "bnez":0xF
}

def main():
  parser = argparse.ArgumentParser("Compiler for tiny processor")
  parser.add_argument("input", type=str, help="Input file")
  parser.add_argument("-o", type=str, help="Output file", default="a.out")
  args = parser.parse_args()

  INFILE  = args.input
  OUTFILE = args.o

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

      inst = "{:X}{:X}".format(op, opcode)
      inst_list.append(inst)
    
    outf.write('\n'.join(inst_list))

    outf.close()
    f.close()

  pass

if __name__ == "__main__":
  main()