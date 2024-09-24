/* SPDX-License-Identifier: MPL-2.0 */
/*
 * zero.ld -- zero table
 * Copyright (C) 2024  Jacob Koziej <jacobkoziej@gmail.com>
 */

.zero : ALIGN(word_align) {
	LONG(ADDR(.bss))
	LONG(SIZEOF(.bss))
} > flash_vma AT> flash_lma

__zero_start__ = ADDR(.zero);
__zero_end__   = __zero_start__ + SIZEOF(.zero);
