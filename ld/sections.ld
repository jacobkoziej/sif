/* SPDX-License-Identifier: MPL-2.0 */
/*
 * sections.ld -- section mapping
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

.rodata._vectors (READONLY) : ALIGN(vector_align) {
	KEEP(*(.rodata._vectors))
} > flash_vma AT> flash_lma

.text (READONLY) : ALIGN(word_align) {
	*(.text)
	*(.text.*)
} > flash_vma AT> flash_lma

.ARM.exidx (READONLY) : ALIGN(word_align) {
	*(.ARM.exidx)
	*(.ARM.exidx.*)
} > flash_vma AT> flash_lma

.rodata (READONLY) : ALIGN(word_align) {
	*(.rodata)
	*(.rodata.*)
} > flash_vma AT> flash_lma

.data : ALIGN(word_align) {
	*(.data)
	*(.data.*)
} > sram AT> flash_lma

.bss (NOLOAD) : ALIGN(word_align) {
	*(.bss)
	*(.bss.*)
} > sram
