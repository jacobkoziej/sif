/* SPDX-License-Identifier: MPL-2.0 */
/*
 * memory.ld -- memory blocks
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */


HIDDEN(stage2_length       = 252);
HIDDEN(stage2_crc32_length = 4);

HIDDEN(stage2_size = stage2_length + stage2_crc32_length);

HIDDEN(flash_length = 2048K);

HIDDEN(sram5_origin = 0x20041000);
HIDDEN(sram5_length = 5K);

MEMORY {
	ROM   (RX)  : ORIGIN = 0x00000000,   LENGTH = 16K
	FLASH (RX)  : ORIGIN = 0x10000000,   LENGTH = flash_length
	SRAM  (RWX) : ORIGIN = 0x20000000,   LENGTH = 256K
	SRAM4 (RWX) : ORIGIN = 0x20040000,   LENGTH = 4K
	SRAM5 (RWX) : ORIGIN = sram5_origin, LENGTH = sram5_length
}

HIDDEN(vector_align = 256);
HIDDEN(word_align   = 4);
