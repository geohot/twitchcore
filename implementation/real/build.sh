#!/bin/bash -ex
BASE=/Users/taylor/fun/fpga
XRAY_UTILS_DIR=$BASE/prjxray/utils
XRAY_TOOLS_DIR=$BASE/prjxray/build/tools
XRAY_DATABASE_DIR=$BASE/prjxray/database

# disable mmcm, xadc, sdcard, icap_bitstream
# remove BSCANE2 from file
#$BASE/yosys/yosys -p "synth_xilinx -flatten -nowidelut -nodsp -abc9 -arch xc7 -top arty_a7; write_json out/attosoc.json" /Users/taylor/fun/linux-on-litex-vexriscv/build/arty_a7/gateware/arty_a7.v /Users/taylor/fun/litex/pythondata-cpu-vexriscv-smp/pythondata_cpu_vexriscv_smp/verilog/Ram_1w_1rs_Generic.v /Users/taylor/fun/litex/pythondata-cpu-vexriscv-smp/pythondata_cpu_vexriscv_smp/verilog/VexRiscvLitexSmpCluster_Cc1_Iw32Is4096Iy1_Dw32Ds4096Dy1_Ldw128_Ood.v FD.v
#$BASE/nextpnr-xilinx/nextpnr-xilinx --chipdb $BASE/nextpnr-xilinx/xilinx/xc7a100t.bin --xdc arty_a7.xdc --json out/attosoc.json --write out/attosoc_routed.json --fasm out/attosoc.fasm

"${XRAY_UTILS_DIR}/fasm2frames.py" --db-root "${XRAY_DATABASE_DIR}/artix7" --part xc7a100tcsg324-1 out/attosoc.fasm > out/attosoc.frames
"${XRAY_TOOLS_DIR}/xc7frames2bit" --part_file "${XRAY_DATABASE_DIR}/artix7/xc7a100tcsg324-1/part.yaml" --part_name xc7a100tcsg324-1 --frm_file out/attosoc.frames --output_file out/attosoc.bit

