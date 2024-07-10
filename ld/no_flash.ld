/* SPDX-License-Identifier: MPL-2.0 */
/*
 * default.ld -- default link
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

INCLUDE memory.ld

REGION_ALIAS("flash", SRAM)
REGION_ALIAS("sram",  SRAM)

ENTRY(_start)

SECTIONS {
	.text._start (READONLY) : ALIGN(4) {
		KEEP(*(.text._start))
	} > flash

	INCLUDE sections.ld
}

INCLUDE symbols.ld
