/* SPDX-License-Identifier: MPL-2.0 */
/*
 * stage2.ld -- second stage flash boot
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

INCLUDE memory.ld

HIDDEN(flash_length = stage2_length);

REGION_ALIAS("flash_vma", SRAM5)
REGION_ALIAS("flash_lma", FLASH)
REGION_ALIAS("sram",      SRAM5)

ENTRY(_start)

SECTIONS {
	INCLUDE sections.ld
}
