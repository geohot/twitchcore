#!/bin/bash
iverilog -Wall -g2012 -o run testbench.sv cpu.v risk.v && vvp run +firmware=$1

