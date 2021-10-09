#!/usr/bin/env python3
from compiler import cherry_kernel, riski_load, riski_unop, riski_store, SZ, cherry_range
import numpy as np

# ==== Define your kernels ====

@cherry_kernel(title="Relu")
def cherry_relu(x, out_address):
  for i in cherry_range(0, np.prod(x.shape), SZ*SZ):
    riski_load(x.address+i)
    riski_unop()
    riski_store(out_address+i)


@cherry_kernel(title="Super dumb loads and stores")
def dumb_loads_in_loop(x, out_address):
    for v in range(2):
        for i in cherry_range(10):
            for j in cherry_range(20):
                for k in cherry_range(5):
                    # Can I make the loop variable name match whats defined here
                    # If not, make it so when I print i, I see "cherry_loop_var_k" instead of possibly "k"
                    riski_load(address=x.address + 2*i + 3*(j + k) + 2*k + 3 + v)
                    riski_load(address=x.address + 2*i + 3*(j + k) + 2*k + 3 + v)
                    riski_store(address=out_address)


# ==== Run your kernels ====

dumb_loads_in_loop(np.ones((10,)))
print()
print()
print()
cherry_relu(np.ones((1024, 10)))