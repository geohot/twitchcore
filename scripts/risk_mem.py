#!/usr/bin/env python3
import random
import numpy as np
from tqdm import trange
from collections import Counter

# in xilinx, we have 270x 18-bit BRAMs with 1024 elements
# in achronix, we have 2560x 18-bit BRAMs with 4096 elements
# for simplicity, lets assume we get one read per cycle
# array is SZxSZ

#ELE, CNT, SZ = 4096, 2048, 32   #  4.6 TB/s
ELE, CNT, SZ = 1024, 128, 8      # 28.8 GB/s
#brams = [np.zeros(ELE, dtype=np.float32) for x in range(CNT)]

# ideal hash function
lookup = list(range(ELE*CNT))
random.shuffle(lookup)

def ahash(address):
  # 8388608 possible
  address = lookup[address & ((ELE*CNT)-1)]
  return address&(CNT-1), (address>>(int(np.log2(CNT)))&(ELE-1))

def riski_load(target, address, stride_y=SZ, stride_x=1, len_y=SZ, len_x=SZ):
  # in one cycle, compute SZ*SZ hashed addresses
  addrs = []
  for y in range(len_y):
    for x in range(len_x):
      addrs.append(ahash(address + y*stride_y + x*stride_x))

  # in n cycles, do the loads from the BRAMs (ignore duplicate loads, special case stride=0)
  # with that lookup, i'm getting a worst case of 8 or 9
  banks = Counter([x[0] for x in set(addrs)])
  ret = max(banks.values())

  return ret

if __name__ == "__main__":
  cnts = []

  try:
    """
    # real access patterns
    cc = open("/tmp/risk_load_log").read().strip().split("\n")
    random.shuffle(cc)

    for i in (t:=trange(len(cc))):
      address, stride_y, stride_x, len_y, len_x = [int(x) for x in cc[i].split(" ")]
      cnt = riski_load(None, address, stride_y, stride_x, len_y, len_x)
      cnts.append(cnt)
      t.set_description("worst: %d" % max(cnts))
    """

    # random access patterns, still seeing 8 worst case
    for i in (t:=trange(100000)):
      address, stride_y, stride_x = random.randint(0, ELE*CNT), random.randint(0, ELE*CNT), random.randint(0, ELE*CNT)
      cnt = riski_load(None, address, stride_y, stride_x)
      cnts.append(cnt)
      t.set_description("worst: %d" % max(cnts))
  except KeyboardInterrupt:
    pass

  cnts = Counter(cnts)
  print(cnts) 


