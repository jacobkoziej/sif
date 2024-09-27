/* SPDX-License-Identifier: MPL-2.0 */
/*
 * default.ld -- default link
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */


INCLUDE memory.ld

REGION_ALIAS("flash_lma", FLASH)
REGION_ALIAS("flash_vma", FLASH)
REGION_ALIAS("sram",      SRAM)

ENTRY(_start)

SECTIONS {
	.stage2 (READONLY) : {
		KEEP(*(.stage2))
	} > flash_vma AT> flash_lma

	INCLUDE sections.ld
	INCLUDE copy.ld
	INCLUDE zero.ld
}

INCLUDE symbols.ld

ASSERT(SIZEOF(.stage2) == stage2_size, "SIZEOF(.stage2) != stage2_size")
