#!/bin/bash -e
python3 makehex.py $1 > /tmp/test.bin
iverilog -Wall -g2012 -o run testbench.sv cpu.v risk.v && vvp run +firmware=/tmp/test.bin

