#!/bin/bash
git clone https://github.com/riscv/riscv-tests.git
cd riscv-tests
git submodule update --init --recursive
autoconf
./configure
make -j

