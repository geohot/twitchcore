# This code is mostly taken from SERV project by Olof Kindgren
# Please take a look at the project: https://github.com/olofk/serv

all: $(patsubst %.S,%.elf,$(wildcard *.S))

%.elf: %.S
	riscv64-unknown-elf-gcc -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $< -o $(notdir $(basename $<)).elf
%.defs: %.S
	riscv64-unknown-elf-gcc -E -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $< > $(notdir $(basename $<)).i
%.obj: %.elf
	riscv64-unknown-elf-objdump -D $(notdir $(basename $<)).elf > $(notdir $(basename $<)).obj
%.test: %.S
	riscv64-unknown-elf-gcc -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $< -o $(notdir $(basename $<)).elf
	riscv64-unknown-elf-objdump -D $(notdir $(basename $<)).elf > $(notdir $(basename $<)).obj
	python3 makehex.py $(notdir $(basename $<)).elf 2048 > $(notdir $(basename $<)).hex
%.bin: %.elf
	riscv64-unknown-elf-objcopy -O binary $< $@
%.hex: %.bin
	python3 makehex.py $< 4096 > $@
clean:
	rm -f *.elf *.bin *.hex *.o *.obj 
