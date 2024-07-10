/* SPDX-License-Identifier: MPL-2.0 */
/*
 * sections.ld -- section mapping
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

.rodata._vectors (READONLY) : ALIGN(256) {
	KEEP(*(.rodata._vectors))
} > flash

.text (READONLY) : ALIGN(4) {
	*(.text)
	*(.text.*)
} > flash

.ARM.exidx (READONLY) : ALIGN(4) {
	*(.ARM.exidx)
	*(.ARM.exidx.*)
} > flash

.rodata (READONLY) : ALIGN(4) {
	*(.rodata)
	*(.rodata.*)
} > flash

.data : ALIGN(4) {
	*(.data)
	*(.data.*)
} > sram AT> flash

.bss (NOLOAD) : ALIGN(4) {
	*(.bss)
	*(.bss.*)
} > sram
