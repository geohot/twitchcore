import bitstring
from operator import iconcat
from functools import reduce
from enum import IntEnum, Enum

LOOP_CNT_MAX = 8

class InstructionName(IntEnum):
    MATMUL = 0
    MULACC = 1
    ADD = 2
    SUB = 3
    MUL = 4
    DIV = 5
    POW = 6
    MAX = 7
    SUM = 8
    RELU = 9
    EXP = 10
    LOG = 11
    GTZ = 12
    COPY = 13
    ZERO = 14
    LOAD = 15
    STORE = 16
    START_INDEPENDENT_LOOP = 17
    START_LOOP = 18
    JUMP_OR_END_LOOP = 19

    @property
    def category(self):
        if (self == 15 or self == 16):
            return InstructionCategory.MEMORY
        if (self == 17 or self == 18 or self == 19):
            return InstructionCategory.LOOP
        if self >= 20:
            raise ValueError("Nah bro, this dont exist")
        return InstructionCategory.PROCESSING

class InstructionCategory(Enum):
    PROCESSING = 1
    MEMORY = 2
    LOOP = 3

def bit_pack_processing_instruction(instr_name: InstructionName, target, src, is_default):
    # TODO: assert the params valid
    assert instr_name.category == InstructionCategory.PROCESSING
    return bitstring.pack('uint:5, 2*uint:2, uint:1, uint:8', instr_name, target, src, is_default, 0)

def bit_pack_loop_instruction(instr_name: InstructionName, loop_address):
    assert instr_name.category == InstructionCategory.LOOP
    assert loop_address < LOOP_CNT_MAX
    return bitstring.pack('uint:5, uint:3, uint:10', instr_name, loop_address, 0)

def bit_pack_memory_instruction(instr_name: InstructionName, apu_address, target, height, width, zero_flag, skip_flag):
    # TODO: assert the params valid
    assert instr_name.category == InstructionCategory.MEMORY
    return bitstring.pack('uint:5, uint:3, 3*uint:2, 2*uint:1, uint:2', instr_name, apu_address, target, height, width, zero_flag, skip_flag, 0)

def bit_pack_program_header(loop, apu_formulas):
    # TODO: assert the params valid
    loop_ro_data = reduce(iconcat, loop, []) # flatten
    apu_ro_data = reduce(iconcat, apu_formulas, []) # flatten

    assert(len(loop_ro_data) == 8*2)
    assert(len(apu_ro_data) == 8*3*(8+1))
    
    # TODO: can any coefficient in the APU formula be negative?
    return bitstring.pack('16*uint:15, 216*uint:15', *loop_ro_data, *apu_ro_data)

def bit_pack_entire_program(header, instructions):
    assert len(instructions) < 100, "Maybe you don't really need 100 instruction programs?"
    prog = header
    for instr in instructions:
        prog = prog + instr # bitstring doesn't like +=
    return prog


m = bit_pack_memory_instruction(InstructionName.LOAD, 0, 1, 2, 3, 0, 1)
print(m)
m = bit_pack_loop_instruction(InstructionName.START_INDEPENDENT_LOOP, 0)
print(m)
m = bit_pack_loop_instruction(InstructionName.JUMP_OR_END_LOOP, 0)
print(m)