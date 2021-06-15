#!/bin/bash
iverilog -o run testbench.v cpu.v risk.v && vvp run

