# This code is mostly taken from SERV project by Olof Kindgren
# Please take a look at the project: https://github.com/olofk/serv

CROSS_COMPILE ?= riscv64-unknown-elf-

all: $(patsubst %.S,%.elf,$(wildcard *.S))

%.elf: %.S
	$(CROSS_COMPILE)gcc -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $< -o $(notdir $(basename $<)).elf
%.defs: %.S
	$(CROSS_COMPILE)gcc -E -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $< > $(notdir $(basename $<)).i
%.obj: %.elf
	$(CROSS_COMPILE)objdump -D $(notdir $(basename $<)).elf > $(notdir $(basename $<)).obj
%.test: %.S
	$(CROSS_COMPILE)gcc -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $< -o $(notdir $(basename $<)).elf
	$(CROSS_COMPILE)objdump -D $(notdir $(basename $<)).elf > $(notdir $(basename $<)).obj
	python3 makehex.py $(notdir $(basename $<)).elf 2048 > $(notdir $(basename $<)).hex
%.bin: %.elf
	$(CROSS_COMPILE)objcopy -O binary $< $@
%.hex: %.bin
	python3 makehex.py $< 4096 > $@
clean:
	rm -f *.elf *.bin *.hex *.o *.obj 
