#!/bin/bash
iverilog -o run testbench.v cpu.v && vvp run

