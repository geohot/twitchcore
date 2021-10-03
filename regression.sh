#!/usr/bin/env bash

# Homebrew install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# Icarus Verilog install
brew install icarus-verilog

# From SVUT examples
# install SVUT
export SVUT=$HOME/.svut
git clone https://github.com/dpretet/svut.git $SVUT
export PATH=$SVUT:$PATH

# Get script's location
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
set -ex
# pipe fails if first command fails. Else is always successful
set -o pipefail


# First testsuite running over the adder, supposed to be successful
cd core/ControlUnit
"svutRun" -test "single_loop_unit_test.sv" -define "MYDEF1=5;MYDEF2" | tee log
cd ../../
ret=$?

if [[ $ret != 0 ]]; then
    echo "Execution failed but should not..."
    exit 1
else
    echo "OK testsuite execution completed successfully ^^"
fi

# Add more testsuites here

echo "Regression finished successfully. SVUT sounds alive ^^"
exit 0