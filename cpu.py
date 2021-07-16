#!/usr/bin/env python3
import os
import struct
import glob
import binascii
from elftools.elf.elffile import ELFFile

regnames = \
  ['x0', 'ra', 'sp', 'gp', 'tp'] + ['t%d'%i for i in range(0,3)] + ['s0', 's1'] +\
  ['a%d'%i for i in range(0,8)] +\
  ['s%d'%i for i in range(2,12)] +\
  ['t%d'%i for i in range(3,7)] + ["PC"]

class Regfile:
  def __init__(self):
    self.regs = [0]*33
  def __getitem__(self, key):
    return self.regs[key]
  def __setitem__(self, key, value):
    if key == 0:
      return
    self.regs[key] = value & 0xFFFFFFFF

PC = 32

regfile = None
memory = None
def reset():
  global regfile, memory
  regfile = Regfile()
  # 16kb at 0x80000000
  memory = b'\x00'*0x4000

from enum import Enum
# RV32I Base Instruction Set
class Ops(Enum):
  LUI = 0b0110111    # load upper immediate
  LOAD = 0b0000011
  STORE = 0b0100011

  AUIPC = 0b0010111  # add upper immediate to pc
  BRANCH = 0b1100011
  JAL = 0b1101111
  JALR = 0b1100111

  IMM = 0b0010011
  OP = 0b0110011

  MISC = 0b0001111
  SYSTEM = 0b1110011

class Funct3(Enum):
  ADD = SUB = ADDI = 0b000
  SLLI = 0b001
  SLT = SLTI = 0b010
  SLTU = SLTIU = 0b011

  XOR = XORI = 0b100
  SRL = SRLI = SRA = SRAI = 0b101
  OR = ORI = 0b110
  AND = ANDI = 0b111

  BEQ = 0b000
  BNE = 0b001
  BLT = 0b100
  BGE = 0b101
  BLTU = 0b110
  BGEU = 0b111

  LB = SB = 0b000
  LH = SH = 0b001
  LW = SW = 0b010
  LBU = 0b100
  LHU = 0b101

  # stupid instructions below this line
  ECALL = 0b000
  CSRRW = 0b001
  CSRRS = 0b010
  CSRRC = 0b011
  CSRRWI = 0b101
  CSRRSI = 0b110
  CSRRCI = 0b111


def ws(addr, dat):
  global memory
  #print(hex(addr), len(dat))
  addr -= 0x80000000
  assert addr >=0 and addr < len(memory)
  memory = memory[:addr] + dat + memory[addr+len(dat):]

def r32(addr):
  addr -= 0x80000000
  if addr < 0 or addr >= len(memory):
    raise Exception("read out of bounds: 0x%x" % addr)
  return struct.unpack("<I", memory[addr:addr+4])[0]

def dump():
  pp = []
  for i in range(33):
    if i != 0 and i % 8 == 0:
      pp += "\n"
    pp += " %3s: %08x" % (regnames[i], regfile[i])
  print(''.join(pp))

def sign_extend(x, l):
  if x >> (l-1) == 1:
    return -((1 << l) - x)
  else:
    return x

def arith(funct3, x, y, alt):
  if funct3 == Funct3.ADDI:
    if alt:
      return x-y
    else:
      return x+y
  elif funct3 == Funct3.SLLI:
    return x<<(y&0x1f)
  elif funct3 == Funct3.SRLI:
    if alt:
      # this is srai
      sb = x >> 31
      out = x >> (y&0x1f)
      out |= (0xFFFFFFFF * sb) << (32-(y&0x1f))
      return out
    else:
      return x>>(y&0x1f)
  elif funct3 == Funct3.ORI:
    return x|y
  elif funct3 == Funct3.XORI:
    return x^y
  elif funct3 == Funct3.ANDI:
    return x&y
  elif funct3 == Funct3.SLT:
    return int(sign_extend(x, 32) < sign_extend(y, 32))
  elif funct3 == Funct3.SLTU:
    return int(x&0xFFFFFFFF < y&0xFFFFFFFF)
  else:
    dump()
    raise Exception("write arith funct3 %r" % funct3)

def cond(funct3, vs1, vs2):
  ret = False
  if funct3 == Funct3.BEQ:
    ret = vs1 == vs2
  elif funct3 == Funct3.BNE:
    ret = vs1 != vs2
  elif funct3 == Funct3.BLT:
    ret = sign_extend(vs1, 32) < sign_extend(vs2, 32)
  elif funct3 == Funct3.BGE:
    ret = sign_extend(vs1, 32) >= sign_extend(vs2, 32)
  elif funct3 == Funct3.BLTU:
    ret = vs1 < vs2
  elif funct3 == Funct3.BGEU:
    ret = vs1 >= vs2
  else:
    dump()
    raise Exception("write %r funct3 %r" % (opcode, funct3))
  return ret

def step():
  # *** Instruction Fetch ***
  ins = r32(regfile[PC])

  # *** Instruction decode and register fetch ***
  def gibi(s, e):
    return (ins >> e) & ((1 << (s-e+1))-1)
  opcode = Ops(gibi(6, 0))
  funct3 = Funct3(gibi(14, 12))
  funct7 = gibi(31, 25)
  imm_i = sign_extend(gibi(31, 20), 12)
  imm_s = sign_extend(gibi(31, 25)<<5 | gibi(11, 7), 12)
  imm_b = sign_extend((gibi(31, 31)<<12) | (gibi(30, 25)<<5) | (gibi(11, 8)<<1) | (gibi(7, 7)<<11), 13)
  imm_u = sign_extend(gibi(31, 12)<<12, 32)
  imm_j = sign_extend((gibi(31, 31)<<20) | (gibi(30, 21)<<1) | (gibi(20, 20)<<11) | (gibi(19, 12)<<12), 21)

  # register write set up
  rd = gibi(11, 7)

  # register reads
  vs1 = regfile[gibi(19, 15)]
  vs2 = regfile[gibi(24, 20)]
  vpc = regfile[PC]

  # *** Execute ***
  reg_writeback = opcode in [Ops.JAL, Ops.JALR, Ops.AUIPC, Ops.LUI, Ops.OP, Ops.IMM, Ops.LOAD]
  do_load = opcode == Ops.LOAD
  do_store = opcode == Ops.STORE

  alt = (funct7 == 0b0100000) and (opcode == Ops.OP or (opcode == Ops.IMM and funct3 == Funct3.SRAI))
  imm = {Ops.JAL: imm_j, Ops.JALR: imm_i, Ops.BRANCH: imm_b, Ops.AUIPC: imm_u,
         Ops.LUI: imm_u, Ops.OP: vs2, Ops.IMM: imm_i, Ops.LOAD: imm_i, Ops.STORE: imm_s,
         Ops.SYSTEM: imm_i, Ops.MISC: imm_i}[opcode]
  arith_left = vpc if opcode in [Ops.JAL, Ops.BRANCH, Ops.AUIPC] else (0 if opcode == Ops.LUI else vs1)
  arith_func = funct3 if opcode in [Ops.OP, Ops.IMM] else Funct3.ADD
  pend_is_new_pc = opcode in [Ops.JAL, Ops.JALR] or (opcode == Ops.BRANCH and cond(funct3, vs1, vs2))
  pend = arith(arith_func, arith_left, imm, alt)

  if opcode == Ops.SYSTEM:
    # I-type instruction
    if funct3 == Funct3.ECALL:
      print("  ecall", regfile[3])
      if regfile[3] > 1:
        raise Exception("FAILURE IN TEST, PLZ CHECK")
      elif regfile[3] == 1:
        # hack for test exit
        return False

  # *** Memory access ***
  if do_load:
    if funct3 == Funct3.LB:
      pend = sign_extend(r32(pend)&0xFF, 8)
    elif funct3 == Funct3.LH:
      pend = sign_extend(r32(pend)&0xFFFF, 16)
    elif funct3 == Funct3.LW:
      pend = r32(pend)
    elif funct3 == Funct3.LBU:
      pend = r32(pend)&0xFF
    elif funct3 == Funct3.LHU:
      pend = r32(pend)&0xFFFF
  elif do_store:
    if funct3 == Funct3.SB:
      ws(pend, struct.pack("B", vs2&0xFF))
    elif funct3 == Funct3.SH:
      ws(pend, struct.pack("H", vs2&0xFFFF))
    elif funct3 == Funct3.SW:
      ws(pend, struct.pack("I", vs2))

  # *** Register write back ***
  if pend_is_new_pc:
    if reg_writeback:
      regfile[rd] = vpc + 4
    regfile[PC] = pend
  else:
    if reg_writeback:
      regfile[rd] = pend
    regfile[PC] = vpc + 4
  return True


if __name__ == "__main__":
  if not os.path.isdir('test-cache'):
    os.mkdir('test-cache')
  for x in glob.glob("riscv-tests/isa/rv32ui-p-*"):
    if x.endswith('.dump'):
      continue
    with open(x, 'rb') as f:
      reset()
      print("test", x)
      e = ELFFile(f)
      for s in e.iter_segments():
        ws(s.header.p_paddr, s.data())
      with open("test-cache/%s" % x.split("/")[-1], "wb") as g:
        g.write(b'\n'.join([binascii.hexlify(memory[i:i+4][::-1]) for i in range(0,len(memory),4)]))
        #g.write(b'\n'.join([binascii.hexlify(memory[i:i+1]) for i in range(0,len(memory))]))
      regfile[PC] = 0x80000000
      inscnt = 0
      while step():
        inscnt += 1
      print("  ran %d instructions" % inscnt)

