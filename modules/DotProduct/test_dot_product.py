# TOPLEVEL=DotProduct MODULE=test_dot_product make

import cocotb
from cocotb.binary import BinaryValue
from cocotb.triggers import Timer
import numpy as np
import math

def FAKE_IEEE_bits_to_double(bits):
    sign = 1 if bits[0] == '0' else -1
    mantissa = 1.0
    for i, bit in enumerate(bits[9:]):
        mantissa += int(bit) * ((0.5) ** (i + 1))
    exponent = 0
    for i, bit in enumerate(reversed(bits[1:9])):
        exponent += int(bit) * int((2 ** i))
    assert len(bits[9:]) == 27-8-1, f"is {len(bits[9:])} but should be {27-8-1}"
    assert len(bits[1:9]) == 8, f"is {len(bits[1:9])} but should be {8}"
    bias = 127
    print(mantissa, exponent, sign)
    return sign * mantissa * (2 ** (exponent - bias))

@cocotb.test()
async def test_all_same(dut):
    val = '110101000100101010101010011'
    input_float = FAKE_IEEE_bits_to_double(val)

    vector_bits = val * 32
    dut.A <= BinaryValue(value=vector_bits, n_bits=27*32)
    dut.B <= BinaryValue(value=vector_bits, n_bits=27*32)
    await Timer(10, units='ns')
    output_bits = dut.OUT.value.binstr
    expected_float = input_float * input_float * 32
    output_float = FAKE_IEEE_bits_to_double(output_bits)
    assert math.isclose(expected_float, output_float, rel_tol=1e-4), f"Not close, expected {expected_float} and actually got {output_float}. The input was {input_float}"


# @cocotb.test()
# async def test_vector_mul(dut):
#     val = '110101000100101010101010011'
#     input_float = FAKE_IEEE_bits_to_double(val)

#     vector_bits = val * 32
#     dut.A <= BinaryValue(value=vector_bits, n_bits=27*32)
#     dut.B <= BinaryValue(value=vector_bits, n_bits=27*32)
#     await Timer(10, units='ns')
#     output_bits = dut.OUT.value.binstr
#     chunks = [output_bits[x:x+27] for x in range(0, len(output_bits), 27)]
#     last_output_chunk = chunks[0]
#     for output_chunk_bits in chunks:
#         assert output_chunk_bits == last_output_chunk, f"Not all of the values were the same"
#         output_float = FAKE_IEEE_bits_to_double(output_chunk_bits)
#         assert math.isclose(input_float * input_float, output_float, rel_tol=1e-4), f"Not close, expected {input_float * input_float} and actually got {output_float}. The input was {input_float}"