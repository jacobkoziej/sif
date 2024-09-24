/* SPDX-License-Identifier: MPL-2.0 */
/*
 * default.ld -- default link
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

INCLUDE memory.ld

REGION_ALIAS("flash_lma", SRAM)
REGION_ALIAS("flash_vma", SRAM)
REGION_ALIAS("sram",      SRAM)

ENTRY(_start)

SECTIONS {
	.text._start (READONLY) : ALIGN(word_align) {
		KEEP(*(.text._start))
	} > flash_vma AT> flash_lma

	INCLUDE sections.ld
	INCLUDE zero.ld
}

INCLUDE symbols.ld
