/* SPDX-License-Identifier: MPL-2.0 */
/*
 * sections.ld -- Arm sections
 * Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
 */

SECTIONS {
	.ARM.exidx : {
		*(.ARM.exidx*)
	} > ro_vm AT> ro_lm =0xFF

	.ARM.attributes 0 : { *(.ARM.attributes) }
}
