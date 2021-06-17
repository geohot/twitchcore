#!/bin/bash
iverilog -g2012 -o run testbench.v cpu.v risk.v && vvp run +firmware=$1

