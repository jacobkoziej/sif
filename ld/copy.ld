/* SPDX-License-Identifier: MPL-2.0 */
/*
 * copy.ld -- copy table
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

.copy : ALIGN(word_align) {
	LONG(ADDR(.data))
	LONG(LOADADDR(.data))
	LONG(SIZEOF(.data))
} > flash_vma AT> flash_lma

__copy_start__ = ADDR(.copy);
__copy_end__   = __copy_start__ + SIZEOF(.copy);
