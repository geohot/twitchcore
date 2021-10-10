# Cherry Core

![Indicator of if Unit Tests workflow are passing](https://github.com/evanmays/cherrycore/actions/workflows/SVUT.yml/badge.svg)

A deep learning training core, first in Verilog, then on FPGA, then on tinygrad, then on pytorch.

ISA in Cherry ISA.pdf
Superscalar notes below

[How faster than 3090](https://docs.google.com/presentation/d/1JEysqlI_p8qhONiCQVEdrohAqypjY5eJTStA6SZking/edit#slide=id.p)

![Diagram of Cherry Core architecture](https://github.com/evanmays/cherrycore/blob/master/architecture.png?raw=true)
# Getting Started

### Prerequisites
* icarus-verilog 
* riscv-gnu-toolchain
```sh
brew install icarus-verilog riscv-gnu-toolchain
```

### Installation
1. Clone this repo
```sh
git clone https://github.com/geohot/twitchcore
cd twitchcore
 ```
2. Clone and build `riscv-tests`
```sh
git clone https://github.com/riscv/riscv-tests
cd riscv-tests
git submodule update --init --recursive
autoconf
./configure
make
make install
cd ..
```
3. Create a virtual environment (optional)
```sh
python3 -m venv env
source env/bin/activate
```
4. Install Python packages
```sh
pip install -r requirements.txt
```

# TODO

* Write verilog. Search for the word TODO throughout this README
* Fix unaligned loads/stores (I think this is good now, at least acceptable)
* Clean up this repo
* Add github actions tests
* Regression testing
* Improve this readme


# Superscalar Notes

We can cheat on the superscalar. All deep learning kernels have lots of loops (to tile the tensors they are computing on), and each iteration of the loop can be run independently. Kernel programmer will add an annotation to their loop when it's OK to execute the iterations out of order.

Example

```python
@cherry_loop(independent=True)
for i in range(2):
     load
     load
     matmul
     store
```
Instead of executing load, load, matmul, store, load, load, matmul, store. We will do some time multiplexing on each loop iteration. We execute, load, load, load, load, matmul, matmul, store, store. This hides the latency. NVIDIA does a similar thing but the CUDA programmer must think about threads and warps. Our "threads" are implicit.

# Tensor Cores

These all should be straightforward but annoying to get to IEEE specification.

They can be pipelined. Ideal latency is 3 or less cycles. Every doubling of latency requires us to double our superscalar width which means double the L0 registers which means double the processing core multiplexer which means we not happy.

* Test floating point multiply
* Write & test floating point add
* Write & test floating point fused multiply add
* Write & test Relu (should be an easy intro, save for noobs)
* Write & test GT0 (should be an easy intro, save for noobs)
* Write & test the other unops and binops

# Notes on Memory system

8 million elements (20MB) = 23-bit address path

We want to support a load/store instruction into 32x32 matrix register (2432 bytes) like this:
* Would be R-Type with rs1 and rs2 (64-bit)
* rs1 contains the 23-bit base address, plus two masks in the upper bytes (0 is no mask)
* rs2 contains two 24-bit strides for x and y. Several of these bits aren't connected
* "rd" is the extension register to load into / store from

Use some hash function on the addresses to avoid "bank conflicts", can upper bound the fetch time.

TODO
* load with stride 0 in X
* signal stalls due to bank conflicts

# Notes on ALU

matmul/mulacc are the big ones, 65536 FLOPS and 2048 FLOPS respectively

Have to think this through more with the reduce instructions too.

It's okay if the matmul takes multiple cycles I think, but the mulacc would be nice to be one.

TODO
* add tests for matmul
* add remaining vector ops
* add reduce ops

# Notes on mini edition in 100T

16x16 registers (608 bytes), 256 FMACs (does it fit)

* 128k elements = 17-bit address path
* rs1 = 2x4-bit masks + 17-bit address
* rs2 = 2x16-bit strides

# Compiler

Basic example in `experiments/compiler`

Compiles code written in python to the Cherry ISA.

Take code from tiny grad, add a `@cherry_kernel` decorator to a function and replace a `for i in range(n)` with `for i in cherry_range(n)`.

`cherry_range()` the Cherry device can run the loop iterations out of order and concurrently. So the loop body iterations must be independent. This helps with latency.

TODO:
* Support the entire instruction set
* Create assembler
* More todo's in the `experiments/compiler/compiler.py`

# DMA Notes

DMA is driven by CPU. this code should be straight forward. Simple malloc algorithm determines where we have free space and what to evict. Then check if any active kernels are using the memory space, if not, do memory operations on the BRAMs. On small cherry 1 (mini edition), memory has 5 ports of width 18*4. 4 ports are for running kernels, 5th port is for DMA. 4 ports have priority. 5th port stalls a bunch. Perhaps reordering can happen on the 5th port to prevent stalls. Software side won't know exact timing so reordering must happen in hardware. Simple algorithm, pull 2 memory dma ops at a time, do the first one if you can, if doesn't work, try second one, if doesn't work stall. This should get us to maybe 5% stall rate. Can increase decode width to 4 for ~0% stall rate. I'm just guestimating on this percent but it feels accurate.

Small Cherry 1
`100e6` bits per second @ 50MHz is 2 bits per cycle. Can't even use full 5th port. Must have a hardware generated mask

Big Cherry 1
`8*12e9` bits per second @ 500MHz is 192 bits per cycle. But now port is `16*18=288` bits wide. Still can't use full port. Must have a hardware generated mask

Cherry 2
`8*12e9` bits per second @ 500MHz is 192 bits per cycle. But now port is `32*18=576` bits wide. Still can't use full port. Must have a hardware generated mask. Even with next gen PCIE still need mask.

TODO: Can we add this 5th port? Does a mask work? Can we keep the fifth port and other DMA stuff under 5% LUT usage?