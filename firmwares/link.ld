/**
 * This script was generated from
 *     riscv64-elf-gcc -march=rv32i -mabi=ilp32 -nostartfiles -nodefaultlibs -Wl,-z,now,--verbose
 * and then heavily modified.
 */
/*
GNU ld (GNU Binutils; openSUSE Leap 15.1) 2.32.0.20190909-lp151.3.3
  Supported emulations:
   elf64lriscv
   elf64lriscv_lp64f
   elf64lriscv_lp64
   elf32lriscv
   elf32lriscv_ilp32f
   elf32lriscv_ilp32
using internal linker script:
==================================================
*/
/* Script for -z combreloc -z now -z relro: combine and sort reloc sections */
/* Copyright (C) 2014-2019 Free Software Foundation, Inc.
   Copying and distribution of this script, with or without modification,
   are permitted in any medium without royalty provided the copyright
   notice and this notice are preserved.  */
OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)
OUTPUT(a.out)
ENTRY(_start)
SEARCH_DIR("=/usr/riscv64-suse-linux/lib");
SEARCH_DIR("=/usr/local/lib");
SEARCH_DIR("=/lib");
SEARCH_DIR("=/usr/lib");
MEMORY{
  text (X)     : ORIGIN =  8K, LENGTH = 8K
  data (RWA!X) : ORIGIN = 16K, LENGTH = 8K
  stack        : ORIGIN = 24K, LENGTH = 8K
}
SECTIONS{
  /**************** Text Segment ****************/
  /**
   * Pretty simple: Contains the program text.
   * 
   * Define magic symbols around the code, and provide a default _start
   * entry point pointing into the first byte of text.
   */
  
  . = ORIGIN(text);
  PROVIDE(__stext = .);
  PROVIDE(_stext = .);
  PROVIDE(stext = .);
  PROVIDE(_start = .);
  .init               : { KEEP (*(SORT_NONE(.init))) }
  .text               : {
    *(.text.unlikely .text.*_unlikely .text.unlikely.*)
    *(.text.exit .text.exit.*)
    *(.text.startup .text.startup.*)
    *(.text.hot .text.hot.*)
    *(.text .stub .text.* .gnu.linkonce.t.*)
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
  }
  .fini               : { KEEP (*(SORT_NONE(.fini))) }
  PROVIDE (__etext = .);
  PROVIDE (_etext = .);
  PROVIDE (etext = .);
  
  
  /**************** Data Segment ****************/
  /**
   * There are a large number of data sections fulfilling various roles:
   * 
   *    - Small/medium/large data
   *    - Read-only/read-write data
   *    - Initialized/uninitialized data
   *    - Function pointer tables for constructors/destructors
   *    ...
   * 
   * The microprocessor we're designing has no R/W protection and a
   * Harvard-architecture memory. Our strategy is therefore as follows:
   */
  
  . = ORIGIN(data);
  
  /* 1. Function Pointer tables. Simple, highly-regular, rarely used. */
  .preinit_array      : {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  }
  .init_array         : {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
    PROVIDE_HIDDEN (__init_array_end = .);
  }
  .fini_array         : {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
    KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
    PROVIDE_HIDDEN (__fini_array_end = .);
  }
  .ctors              : {
    /* gcc uses crtbegin.o to find the start of
       the constructors, so we make sure it is
       first.  Because this is a wildcard, it
       doesn't matter if the user does not
       actually link against crtbegin.o; the
       linker won't look for a file to match a
       wildcard.  The wildcard also means that it
       doesn't matter which directory crtbegin.o
       is in.  */
    KEEP (*crtbegin.o(.ctors))
    KEEP (*crtbegin?.o(.ctors))
    /* We don't want to include the .ctor section from
       the crtend.o file until after the sorted ctors.
       The .ctor section from the crtend file contains the
       end of ctors marker and it must be last */
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
  }
  .dtors              : {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*crtbegin?.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
  }
  
  /* 2. Exception Handling crap. */
  .eh_frame_hdr       : { *(.eh_frame_hdr) *(.eh_frame_entry .eh_frame_entry.*) }
  .eh_frame           : { KEEP (*(.eh_frame)) *(.eh_frame.*) }
  .gcc_except_table   : { *(.gcc_except_table .gcc_except_table.*) }
  .gnu_extab          : { *(.gnu_extab*) }
  
  /**
   * 3. "Read-only" and "read-write data", mishmashed.
   *
   * Unlike on regular platforms, we have no read-only memory. We therefore
   * interleave readable and writable data sections together, arranging them
   * such that:
   *     - The "big" initialized data is first,
   *     - The "small" initialized data is next,
   *     - The "small" uninitialized data is next,
   *     - The "big" uninitialized data is last.
   * By aiming the __global_pointer$ at the middle, a maximum of coverage can
   * be achieved within the +-2KB range of the pointer.
   */
  
  /* INITIALIZED DATA */
  /* "Big" initialized data. */
  .data               : {
    __DATA_BEGIN__ = .;
    *(.data .data.* .gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
  }
  .rodata             : { *(.rodata .rodata.* .gnu.linkonce.r.*) }
  .data1              : { *(.data1) }
  .rodata1            : { *(.rodata1) }
  .data.rel.ro        : { *(.data.rel.ro.local* .gnu.linkonce.d.rel.ro.local.*) *(.data.rel.ro .data.rel.ro.* .gnu.linkonce.d.rel.ro.*) }
  
  /* "Small" initialized data. */
  .sdata              : {
    __SDATA_BEGIN__ = .;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
    /* __global_pointer$ points somewhere here! */
  }
  .sdata2             : { *(.sdata2 .sdata2.* .gnu.linkonce.s2.*) }
  __DATA_END__ = .;
  __SDATA_END__ = .;
  
  /* UNINITIALIZED DATA */
  /* "Small" uninitialized data. */
  . = ALIGN(4);
  __BSS_BEGIN__ = .;
  .sbss               : {
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
  }
  .sbss2              : { *(.sbss2 .sbss2.* .gnu.linkonce.sb2.*) }
  
  /* "Big" uninitialized data. */
  .bss                : {
    *(.dynbss)
    *(.bss .bss.* .gnu.linkonce.b.*)
    *(COMMON)
  }
  . = ALIGN(4);
  __BSS_END__ = .;
  _end = .;
  
  /**
   * From https://gnu-mcu-eclipse.github.io/arch/riscv/programmer/ :
   * 
   *   The gp (Global Pointer) register is a solution to further optimise memory
   *   accesses within a single 4KB region.
   *   
   *   The linker uses the __global_pointer$ symbol definition to compare the
   *   memory addresses and, if within range, it replaces absolute/pc-relative
   *   addressing with gp-relative addressing, which makes the code more efficient.
   *   This process is also called relaxing, and can be disabled by -Wl,--no-relax.
   * 
   *   The gp register should be loaded during startup with the address of the
   *   __global_pointer$ symbol and should not be changed later.
   *   
   *   The 4K region can be anywhere in the addressed memory, but, for the
   *   optimisation to be effective, it should preferably cover the most intensely
   *   used RAM area. For standard newlib applications, this is the area where the
   *   .sdata section is allocated, since it includes variables like _impure_ptr,
   *   __malloc_sbrk_base, etc. Thus, the definition should be placed right before
   *   the .sdata section. For example:
   *   
   *     PROVIDE( __global_pointer$ = . + (4K / 2) );
   *     (.sdata .sdata.*)
   */
  
  __global_pointer$ = MIN(   __SDATA_BEGIN__ + 0x800,
                          MAX(__DATA_BEGIN__ + 0x800,
                              __BSS_END__    - 0x800));
  
  
  /**************** Stack Segment ****************/
  /**
   * Define references to the Top-Of-Stack (TOS) for every thread.
   */
  
  __TOS  = ORIGIN(stack) + LENGTH(stack);
  __TOS0 = ORIGIN(stack) + LENGTH(stack) - LENGTH(stack) * 0 / 8;
  __TOS1 = ORIGIN(stack) + LENGTH(stack) - LENGTH(stack) * 1 / 8;
  __TOS2 = ORIGIN(stack) + LENGTH(stack) - LENGTH(stack) * 2 / 8;
  __TOS3 = ORIGIN(stack) + LENGTH(stack) - LENGTH(stack) * 3 / 8;
  __TOS4 = ORIGIN(stack) + LENGTH(stack) - LENGTH(stack) * 4 / 8;
  __TOS5 = ORIGIN(stack) + LENGTH(stack) - LENGTH(stack) * 5 / 8;
  __TOS6 = ORIGIN(stack) + LENGTH(stack) - LENGTH(stack) * 6 / 8;
  __TOS7 = ORIGIN(stack) + LENGTH(stack) - LENGTH(stack) * 7 / 8;
  
  
  /**************** Everything Else ****************/
  /**
   * This contains things like .interp, build IDs and debug information.
   */
  
  . = .;
  
  /* Header information */
  .interp             : { *(.interp) }
  .note.gnu.build-id  : { *(.note.gnu.build-id) }
  .hash               : { *(.hash) }
  .gnu.hash           : { *(.gnu.hash) }
  .gnu.version        : { *(.gnu.version) }
  .gnu.version_d      : { *(.gnu.version_d) }
  .gnu.version_r      : { *(.gnu.version_r) }
  
  /* Stabs debugging sections.  */
  .stab               0 : { *(.stab) }
  .stabstr            0 : { *(.stabstr) }
  .stab.excl          0 : { *(.stab.excl) }
  .stab.exclstr       0 : { *(.stab.exclstr) }
  .stab.index         0 : { *(.stab.index) }
  .stab.indexstr      0 : { *(.stab.indexstr) }
  .comment            0 : { *(.comment) }
  .gnu.build.attributes : { *(.gnu.build.attributes .gnu.build.attributes.*) }
  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug              0 : { *(.debug) }
  .line               0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo      0 : { *(.debug_srcinfo) }
  .debug_sfnames      0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges      0 : { *(.debug_aranges) }
  .debug_pubnames     0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info         0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev       0 : { *(.debug_abbrev) }
  .debug_line         0 : { *(.debug_line .debug_line.* .debug_line_end) }
  .debug_frame        0 : { *(.debug_frame) }
  .debug_str          0 : { *(.debug_str) }
  .debug_loc          0 : { *(.debug_loc) }
  .debug_macinfo      0 : { *(.debug_macinfo) }
  /* SGI/MIPS DWARF 2 extensions */
  .debug_weaknames    0 : { *(.debug_weaknames) }
  .debug_funcnames    0 : { *(.debug_funcnames) }
  .debug_typenames    0 : { *(.debug_typenames) }
  .debug_varnames     0 : { *(.debug_varnames) }
  /* DWARF 3 */
  .debug_pubtypes     0 : { *(.debug_pubtypes) }
  .debug_ranges       0 : { *(.debug_ranges) }
  /* DWARF Extension.  */
  .debug_macro        0 : { *(.debug_macro) }
  .debug_addr         0 : { *(.debug_addr) }
  .gnu.attributes     0 : { KEEP (*(.gnu.attributes)) }
  
  
  /**************** Dynamic crap ****************/
  /**
   * Rather than discarding these unsupported sections, we assert if any input
   * object files provide any of them.
   */
  
  .dynamic            : { *(.dynamic) }
  .dynsym             : { *(.dynsym) }
  .dynstr             : { *(.dynstr) }
  .rela.dyn           : {
      *(.rela.init)
      *(.rela.text .rela.text.* .rela.gnu.linkonce.t.*)
      *(.rela.fini)
      *(.rela.rodata .rela.rodata.* .rela.gnu.linkonce.r.*)
      *(.rela.data .rela.data.* .rela.gnu.linkonce.d.*)
      *(.rela.tdata .rela.tdata.* .rela.gnu.linkonce.td.*)
      *(.rela.tbss .rela.tbss.* .rela.gnu.linkonce.tb.*)
      *(.rela.ctors)
      *(.rela.dtors)
      *(.rela.got)
      *(.rela.sdata .rela.sdata.* .rela.gnu.linkonce.s.*)
      *(.rela.sbss .rela.sbss.* .rela.gnu.linkonce.sb.*)
      *(.rela.sdata2 .rela.sdata2.* .rela.gnu.linkonce.s2.*)
      *(.rela.sbss2 .rela.sbss2.* .rela.gnu.linkonce.sb2.*)
      *(.rela.bss .rela.bss.* .rela.gnu.linkonce.b.*)
      *(.rela.iplt)
  }
  .rela.plt           : { *(.rela.plt) }
  .plt                : { *(.plt) }
  .iplt               : { *(.iplt) }
  .got                : { *(.got.plt) *(.igot.plt) *(.got) *(.igot) }
  
  ASSERT(SIZEOF(.dynamic)  == 0, ".dynamic not zero-sized! Dynamic linking not supported!")
  ASSERT(SIZEOF(.dynsym)   == 0, ".dynsym not zero-sized! Dynamic linking not supported!")
  ASSERT(SIZEOF(.dynstr)   == 0, ".dynstr not zero-sized! Dynamic linking not supported!")
  ASSERT(SIZEOF(.rela.dyn) == 0, ".rela.dyn not zero-sized! Dynamic linking not supported!")
  ASSERT(SIZEOF(.rela.plt) == 0, ".rela.plt not zero-sized! Dynamic linking not supported!")
  ASSERT(SIZEOF(.plt)      == 0, ".plt not zero-sized! Dynamic linking not supported!")
  ASSERT(SIZEOF(.iplt)     == 0, ".iplt not zero-sized! Dynamic linking not supported!")
  ASSERT(SIZEOF(.got)      == 0, ".got not zero-sized! Dynamic linking not supported!")
  
  
  /**************** Thread-Local Storage crap ****************/
  /**
   * Rather than discarding these unsupported sections, we assert if any input
   * object files provide any of them.
   */
  
  .tdata              : { *(.tdata .tdata.* .gnu.linkonce.td.*) }
  .tbss               : { *(.tbss .tbss.* .gnu.linkonce.tb.*) *(.tcommon) }
  
  ASSERT(SIZEOF(.tdata)    == 0, ".tdata not zero-sized! Thread-local storage not supported!")
  ASSERT(SIZEOF(.tbss)     == 0, ".tbss not zero-sized! Thread-local storage not supported!")
  
  
  /**************** Discarded Sections ****************/
  /DISCARD/ : {
      *(.note.GNU-stack)
      *(.gnu_debuglink)
      *(.gnu.lto_*)
      *(.exception_ranges*)
      *(.jcr)
  }
}