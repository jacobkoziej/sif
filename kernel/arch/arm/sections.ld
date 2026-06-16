/* SPDX-License-Identifier: MPL-2.0 */
/*
 * sections.ld -- Arm sections
 * Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>
 */

SECTIONS {
	.data.vector_table : {
		. = ALIGN(DATA_VECTOR_TABLE_ALIGN);
		HIDDEN(DATA_VECTOR_TABLE_START = .);
		*(.data.vector_table)
		HIDDEN(DATA_VECTOR_TABLE_END = .);
	} > rw_vm AT> ro_lm =0xFF

	HIDDEN(DATA_VECTOR_TABLE_SIZE = DATA_VECTOR_TABLE_END - DATA_VECTOR_TABLE_START);
	HIDDEN(DATA_VECTOR_TABLE_ALIGN = MAX(1 << LOG2CEIL(DATA_VECTOR_TABLE_SIZE), 128));

	ASSERT(
		DATA_VECTOR_TABLE_ALIGN >= DATA_VECTOR_TABLE_SIZE,
		"vector_table alignment must be at least its size"
	)
	ASSERT(!(vector_table % DATA_VECTOR_TABLE_ALIGN), "vector_table misaligned")

	.ARM.exidx : {
		*(.ARM.exidx*)
	} > ro_vm AT> ro_lm =0xFF

	.ARM.attributes 0 : { *(.ARM.attributes) }
}
