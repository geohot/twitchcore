# cherrycore

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