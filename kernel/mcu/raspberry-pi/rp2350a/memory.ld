/* SPDX-License-Identifier: MPL-2.0 */
/*
 * memory.ld -- rp2350a memory map
 * Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
 */

INCLUDE "elf.ld"

MEMORY {
	/*
	 * #cite(<rpi-rp2350-datasheet>)
	 * 4.1 :: ROM
	 */
	ROM (RX) : ORIGIN = 0x00000000, LENGTH = 32K

	/*
	 * #cite(<rpi-rp2350-datasheet>)
	 * 4.4.1 :: XIP cache
	 */
	XIP_CACHE (RWX) : ORIGIN = 0x15000000, LENGTH = 16K

	/*
	 * #cite(<rpi-rp2350-datasheet>)
	 * 4.2 :: SRAM
	 */
	SRAM  (RWX) : ORIGIN = 0x20000000, LENGTH = 512K
	SRAM0 (RWX) : ORIGIN = 0x20000000, LENGTH = 256K
	SRAM1 (RWX) : ORIGIN = 0x20040000, LENGTH = 256K
	SRAM4 (RWX) : ORIGIN = 0x20080000, LENGTH = 4K
	SRAM5 (RWX) : ORIGIN = 0x20081000, LENGTH = 4K

	/*
	 * #cite(<rpi-rp2350-datasheet>)
	 * 4.3 :: Boot RAM
	 */
	BOOT_RAM (RW) : ORIGIN = 0x400E0000, LENGTH = 1K

	/*
	 * #cite(<rpi-rp2350-datasheet>)
	 * 4.2.1 :: Other on-chip memory
	 */
	DPRAM (RW) : ORIGIN = 0x50100000, LENGTH = 4K
}

HIDDEN(KERNEL_SIZE = 64K);

MEMORY {
	KERNEL_SRAM (RWX) : ORIGIN = 0x20000000 + ELF32_HEADER_SIZE, LENGTH = KERNEL_SIZE - ELF32_HEADER_SIZE
	USPACE_SRAM (RWX) : ORIGIN = 0x20000000 + KERNEL_SIZE, LENGTH = LENGTH(SRAM) - KERNEL_SIZE
}
