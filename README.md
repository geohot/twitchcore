# twitchcore

A RISC-V core, first in Python, then in Verilog, then on FPGA.

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

* Fix unaligned loads/stores (I think this is good now, at least acceptable)
* Make pipelining work
* Add M instructions for fast multiply and divide
* Add better introspection
* Switch to 64-bit
* Add "RISK" ML accelerator ("K" Standard Extension)

# TODO (later)

* Many ROBs like M1 go very fast

# Notes on Memory system

8 million elements (20MB) = 23-bit address path

We want to support a load/store instruction into 32x32 matrix register (2432 bytes) like this:
* Would be R-Type with rs1 and rs2 (64-bit)
* rs1 contains the 23-bit base address, plus two masks in the upper bytes (0 is no mask)
* rs2 contains two 24-bit strides for x and y. Several of these bits aren't connected
* "rd" is the extension register to load into / store from

Use some hash function on the addresses to avoid "bank conflicts", can upper bound the fetch time.

# Notes on ALU

matmul/mulacc are the big ones, 65536 FLOPS and 2048 FLOPS respectively

Have to think this through more with the reduce instructions too.

It's okay if the matmul takes multiple cycles I think, but the mulacc would be nice to be one.

matmul
* load with stride 0 in X
* mul
* reduce


# Notes on mini edition in 100T

16x16 registers (608 bytes), 256 FMACs (does it fit)

* 128k elements = 17-bit address path
* rs1 = 2x4-bit masks + 17-bit address
* rs2 = 2x16-bit strides


# How to run a RISC-V test:
You can run a risc-v test (source code available in firmwares) by:

     ./simulate.sh firmwares/add.hex    
