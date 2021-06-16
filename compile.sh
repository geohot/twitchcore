#!/usr/bin/env bash
set -ex
mkdir -p out
cd out

# see tinygrad/fpga

BASE=/Users/taylor/fun/fpga
$BASE/yosys/yosys -p "synth_xilinx -flatten -nowidelut -nodsp -abc9 -arch xc7 -top top; write_json attosoc.json" ../cpu.v ../top.v # ../risk.v
$BASE/nextpnr-xilinx/nextpnr-xilinx --chipdb $BASE/nextpnr-xilinx/xilinx/xc7a100t.bin --xdc ../arty.xdc --json attosoc.json --write attosoc_routed.json --fasm attosoc.fasm

XRAY_UTILS_DIR=$BASE/prjxray/utils
XRAY_TOOLS_DIR=$BASE/prjxray/build/tools
XRAY_DATABASE_DIR=$BASE/prjxray/database

"${XRAY_UTILS_DIR}/fasm2frames.py" --db-root "${XRAY_DATABASE_DIR}/artix7" --part xc7a100tcsg324-1 attosoc.fasm > attosoc.frames
"${XRAY_TOOLS_DIR}/xc7frames2bit" --part_file "${XRAY_DATABASE_DIR}/artix7/xc7a100tcsg324-1/part.yaml" --part_name xc7a100tcsg324-1 --frm_file attosoc.frames --output_file attosoc.bit


