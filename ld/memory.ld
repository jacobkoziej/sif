/* SPDX-License-Identifier: MPL-2.0 */
/*
 * memory.ld -- memory blocks
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

MEMORY {
	ROM   (RX)  : ORIGIN = 0x00000000, LENGTH = 16K
	FLASH (RX)  : ORIGIN = 0x10000000, LENGTH = 2048K
	SRAM  (RWX) : ORIGIN = 0x20000000, LENGTH = 256K
	SRAM4 (RWX) : ORIGIN = 0x20040000, LENGTH = 4K
	SRAM5 (RWX) : ORIGIN = 0x20041000, LENGTH = 4K
}
