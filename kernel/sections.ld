/* SPDX-License-Identifier: MPL-2.0 */
/*
 * sections.ld -- generic sections
 * Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
 */

SECTIONS {
	.text._start : {
		*(.text._start)
	} > ro_lm AT> ro_lm =0xFF

	ASSERT(ADDR(.text._start) == LOADADDR(.text._start), ".text._start must be XIP")

	HIDDEN(TEXT_START_START = ADDR(.text._start));
	HIDDEN(TEXT_START_END = TEXT_START_START + SIZEOF(.text._start));

	ASSERT(
		(_start >= ADDR(.text._start)) && (_start < (ADDR(.text._start) + SIZEOF(.text._start))),
		"_start must reside in .text._start"
	)

	.text : {
		*(.text*)
	} > ro_vm AT> ro_lm =0xFF

	.rodata.ehdr : ALIGN(WORD_ALIGN) {
		. += ELF_HEADER_SIZE;
	} > ro_lm =0xFF

	.rodata.phdrs : ALIGN(WORD_ALIGN) {
		. += ELF_PROGRAM_HEADERS_ALLOCATION;
	} > ro_lm =0xFF

	.rodata : {
		*(.rodata*)
	} > ro_vm AT> ro_lm =0xFF

	.bss.swapper_stack (NOLOAD) : ALIGN(STACK_ALIGN) {
		. += SWAPPER_STACK_SIZE;
	} > rw_vm

	.data : {
		*(.data*)
	} > rw_vm AT> ro_lm =0xFF

	.bss (NOLOAD) : {
		*(.bss*)
	} > rw_vm

	.comment 0 : { *(.comment) }
	.debug_abbrev 0 : { *(.debug_abbrev) }
	.debug_aranges 0 : { *(.debug_aranges) }
	.debug_frame 0 : { *(.debug_frame) }
	.debug_info 0 : { *(.debug_info) }
	.debug_line 0 : { *(.debug_line) }
	.debug_loc 0 : { *(.debug_loc) }
	.debug_ranges 0 : { *(.debug_ranges) }
	.debug_str 0 : { *(.debug_str) }
	.shstrtab 0 : { *(.shstrtab) }
	.strtab 0 : { *(.strtab) }
	.symtab 0 : { *(.symtab) }
}
