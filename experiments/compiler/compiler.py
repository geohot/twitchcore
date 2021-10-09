import numpy as np
from sympy import expand, Symbol
import functools
from dataclasses import dataclass

# ==== Compiler Constants ====

APU_LIMIT = 16
loop_variables = ['i', 'j', 'k', 'l', 'm', 'n', 'o', 'p']

# ==== Importable Constants ====
SZ = 4 # TODO: Dynamically change depending on cherry device version

# ==== Compiler state ====

is_kernel_active = False
loop_var_next = 0

loop_ro_data = [False] * len(loop_variables) # We could actually make this larger if we want
apu_ro_data = [False] * APU_LIMIT
next_apu = 0
kernel = []

# ==== Internal stuffs ====

@dataclass(frozen=True)
class KernelGhostTensor():
    address: int
    shape: tuple

class CherryError(Exception):
    pass

def _assert(target_true, error_msg):
    if not target_true:
        raise CherryError(error_msg)

def assert_kernel_active(func):
    @functools.wraps(func)
    def f(*args, **kwargs):
        if not is_kernel_active:
            raise CherryError(f"Kernel active status: {is_kernel_active}. Try calling our riski_* instructions in a kernel. You can add @cherry_kernel to your function")
        func(*args, **kwargs)
    return f


# ==== Importable accelerator functions ====

fakeaddresses = 0 # TODO: Replace with malloc implementation
def cherry_kernel(func=None, title=None):
    if not func:
        return functools.partial(cherry_kernel, title=title)
    @functools.wraps(func)
    def f(*args, **kwargs):
        global loop_ro_data, apu_ro_data, kernel, loop_var_next, next_apu, fakeaddresses, is_kernel_active
        is_kernel_active = True

        # reset variables
        loop_ro_data = [False for _ in range(len(loop_ro_data))]
        apu_ro_data = [False for _ in range(len(apu_ro_data))]
        kernel = []
        loop_var_next = 0
        next_apu = 0

        # Run kernel
        # TODO: convert tensor to a dumby cherry ghost tensor that has tensor.addr and tensor.shape
        new_args = list(args)
        for i, arg in enumerate(args):
            if isinstance(arg, np.ndarray):
                new_args[i] = KernelGhostTensor(address=fakeaddresses, shape=args[0].shape)
                fakeaddresses += 1024
        new_args.append(fakeaddresses)
        fakeaddresses += 2048
        ret = func(*(tuple(new_args)), **kwargs)

        # Finish creating kernel
        header = f"""Title:          {title}
loop_ro_data:   {loop_ro_data}
apu_ro_data:    {apu_ro_data}

body:
"""
        print(header + "\n".join(kernel))
        is_kernel_active = False
        return ret
    return f


def cherry_range(*args):
    """Want loops that run fast? Replace for `range(n)` with `cherry_range(n)`"""
    global loop_var_next
    # TODO: Create a CherryException class
    _assert(loop_var_next < len(loop_variables), f"You exceeded the maximum number of loops allowed: {len(loop_variables)}. Use less cherry_range loops.")
    kernel.append(f"loop_start {loop_var_next}")

    if len(args) == 1:
        slope = 1
        y_intercept = 0
        iterations = args[0]
    elif len(args) == 2:
        slope = 1
        y_intercept = 0
        _assert(False, "TODO: support 2 args")
    elif len(args) == 3:
        slope = args[2]
        y_intercept = args[0]
        iterations = (args[1]-args[0]) // args[2]
        loop_unroll_count_remainder = (args[1]-args[0]) % args[2] # TODO: support non zero remainder. Just unroll loop
        _assert(loop_unroll_count_remainder == 0, "TODO: Support this as nonzero remainder. unroll the loop this many times.")

    loop_ro_data[loop_var_next] = iterations
    loop_var_cur = loop_var_next
    loop_var_next += 1
    yield slope * Symbol(loop_variables[loop_var_cur]) + y_intercept
    kernel.append("loop_end")


@assert_kernel_active
def riski_unop():
    kernel.append("relu")


@assert_kernel_active
def riski_load(address):
    global next_apu
    _assert(next_apu < APU_LIMIT, f"All available APUs used up. Try using less load store instructions. Or having load store instructions share the same formula to calculate their address and strides.")
    # TODO: support rest of riski_load parameters
    # TODO: support combining of multiple APUs with same formula. If expand(new_address - old_address) == 0 don't insert and use old_address position
    # TODO: more asserts that tell user what they are doing wrong
    # TODO: Help the linters understand what we want
    address_formula = expand(address)
    apu_ro_data[next_apu] = address_formula
    kernel.append(f"riski_load {next_apu}")
    next_apu += 1


@assert_kernel_active
def riski_store(address):
    global next_apu
    _assert(next_apu < APU_LIMIT, f"All available APUs used up. Try using less loops.")
    # TODO: what's cleanest way of making this function nearly exactly like riski_load
    address_formula = expand(address)
    apu_ro_data[next_apu] = address_formula
    kernel.append(f"riski_store {next_apu}")
    next_apu += 1